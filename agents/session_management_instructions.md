# Session Management Instructions

Rules for every agent session in this project. Goal: no session ever ends in a state the next agent can't resume from. Roles, task tagging, and delegation rules live in `AGENTS.md`.

## 1. Session lifecycle

- **Start**: Read the files listed in `AGENTS.md`. Verify the repo matches what `session_handling.md` claims (git status/log, `git worktree list`, quick build or test if cheap). If reality and docs disagree, trust reality and note the discrepancy in `session_handling.md`.
- **Work**: Execute tasks from `tasks.md` in dependency order, routing each to its tagged executor (`AGENTS.md` → Delegation). One task in progress (`[~]`) at a time, unless fanning out (section 3).
- **End**: Run the handoff ritual (section 6). Ending without it is a framework violation.

## 2. Checkpoint discipline

The lead owns every checkpoint. After EVERY completed task (including merged worktree tasks and `-R` test reviews):
1. Tick its checkbox in `tasks.md` (`[~]` → `[x]`).
2. Append one line under "Progress log" in `session_handling.md`: what was done, executor used, branch merged (if any), resume-relevant detail.
3. Commit and push: `git add -A && git commit -m "task: <ID> <short description>" && git push`. If push fails (no remote/network), commit anyway and note the failure in `session_handling.md`.

**Batched checkpoints:** when several fanned-out tasks with disjoint files come back close together, the lead may merge them all, run one combined verify (the affected suites), and checkpoint them in a single commit (`task: <ID> <ID> …`), still with one progress line per task. A failing combined verify means bisecting by merge before checkpointing.

Never start a task you cannot describe a resume point for. If a task is too big to finish safely, split it in `tasks.md` first (and tag the pieces).

## 3. Parallel execution (fan-out)

Fan pending tasks out to parallel subagents (Agent tool, `subagent_type` = the tagged executor) when their `deps` are merged and they are independent or are declared `coreqs`. Rules:
- Every parallel editing executor runs in its own worktree (section 4). Never let two editors share a working tree.
- **Commit before spawning.** A worktree starts from the last commit, not from uncommitted edits — commit `tasks.md` (with `[~]` marks) and any contract files first, so executors can read the plan and tasks from their tree.
- Mark every fanned-out task `[~]` in `tasks.md` before launching (exception to the one-`[~]` rule; note "fanned out → task/<ID>" beside each).
- EVERY subagent must end with the exit ritual defined in its agent file: files changed, branch + commit SHA, verify output, resume point, gotchas, reclassification proposal. A result without this is treated as failed — re-verify its work before trusting it.
- The lead merges and checkpoints each result (sections 2 and 4). The lead must NOT end — and must not start new fan-outs — until every launched subagent's result is merged-or-recorded and the handoff ritual (section 6) is done.
- If tokens run low with subagents still out, wait for them, checkpoint their results, and hand off. Never abandon in-flight subagents silently; if one is lost, record it under "In-progress state".
- **Recovering a lost subagent:** one cut off by a session ending can usually be resumed with SendMessage; one the user stopped cannot. Otherwise spawn a fresh executor in the SAME worktree (no isolation flag; give the absolute worktree path and list the partial files in a continuation brief). A worktree with no changes may have been auto-removed: check `git log <session-branch>..task/<ID>` and `git worktree list` before assuming work exists.
- **Long-running commands** (builds, full test suites): run them in the background or keep them inside the shell tool's timeout limit. A command killed at the limit looks like a crash and can take the lead session down with it.

## 4. Worktree & sync protocol

- **When to isolate**: use `isolation: "worktree"` when spawning an executor that edits files while any other executor is editing. A single active editor may work in the main tree. Read-only work (searches, running tests, reviews that only report) never needs a worktree.
- **Branching**: in a worktree, the executor first runs `git switch -c task/<ID>`, commits its work there (never pushes), and reports the branch and SHA.
- **Prerequisites (`deps`)**: spawn a dependent task only after the lead has merged every prerequisite branch into the session branch and committed — the dependent's worktree then already contains the dependency.
- **Co-requisites (`coreqs`)** — tasks that must change together:
  1. First, the lead (or `high-executor` if any coreq is risk:H) commits the shared **contract** on the session branch: interfaces, types, stubs, schemas, fixtures.
  2. Fan the coreq tasks out from that commit; each brief names the contract file and SHA.
  3. If an executor finds the contract must change, it stops and reports — it never edits the contract unilaterally. The lead updates the contract on the session branch, commits, and resumes each affected executor (SendMessage) with: "run `git merge <session-branch>` in your worktree, then continue".
  4. If the tasks can't share a stable contract, merge them into one task or run them sequentially.
- **Merge-back**: the lead merges `task/<ID>` branches into the session branch in dependency order (`git merge --no-ff task/<ID>`), runs each task's `verify` plus the affected suite, then checkpoints (section 2). Conflicts the lead can't resolve trivially go to `high-executor`. Remove merged worktrees (`git worktree remove <path>`) and delete merged branches.
- **Test review**: an `<ID>-R` review runs after `<ID>` is merged. The reviewer checks that assertions match the acceptance criteria, edge cases are covered, and tests aren't vacuous (always-pass, over-mocked, asserting the implementation instead of behavior). It fixes small gaps itself and reports anything larger to the lead.

## 5. Token-budget heuristics

You cannot see the real usage limit, so treat these as "running low" signals:
- The conversation has grown long (many turns / dozens of tool calls).
- A context-compaction or summarization notice appeared.
- You have read several large files or produced large outputs.

When any signal fires: do NOT start a new task or fan-out. Finish or safely park the current work, then run the handoff ritual immediately.

## 6. Handoff ritual

Rewrite `session_handling.md` using its fixed headings:
- **Last session summary** — what this session accomplished, concisely.
- **In-progress state** — exact file paths, half-done edits, failing tests, uncommitted changes, and every **unmerged `task/<ID>` branch** with its worktree path and status (done-unmerged / partial / failed).
- **Next steps** — ordered, imperative instructions the next agent can execute cold ("1. Merge `task/T04` after re-running `npm test -- client`; 2. Finish X in `src/y.py`…").
- **Gotchas & decisions** — surprises, pitfalls, decisions made this session, reclassified tasks.

Then: update `tasks.md` to current reality, append to `architecture.md` if any engineering decision was made or changed, and finish with a handoff commit: `git add -A && git commit -m "handoff: <one-line session summary>" && git push`.

## 7. File contract

| File | Written by | When | Mutability |
|---|---|---|---|
| `AGENTS.md` (+ `CLAUDE.md` shim) | Framework | Never | Read-only |
| `.claude/agents/*.md` | Framework | Never | Read-only |
| `description.txt` | User | Before planning run | Read-only after planning |
| `plan.md` | Planning agent | First run only | Write-once, never edited |
| `session_handling.md` | Lead | Checkpoints + handoff | Rewritten each handoff |
| `tasks.md` | Lead | Continuously | Always current |
| `architecture.md` | Lead | On decisions | Append-only |
| `session_management_instructions.md` | Framework | Never | Read-only |

Executors read these files but never write them.

## 8. Style

Write concisely — these files are read at the start of every session and by every spawned executor, so they cost tokens many times over. Prefer precise file paths and imperative next steps over prose.
