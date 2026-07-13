# Session Management Instructions

Rules for every agent session in this project. Goal: no session ever ends in a state the next agent can't resume from.

## 1. Session lifecycle

- **Start**: Read the files listed in `CLAUDE.md`. Verify the repo matches what `session_handling.md` claims (git status/log, quick build or test if cheap). If reality and docs disagree, trust reality and note the discrepancy in `session_handling.md`.
- **Work**: Execute tasks from `tasks.md` in order. One task in progress (`[~]`) at a time, unless fanning out independent tasks to parallel subagents (section 3).
- **End**: Run the handoff ritual (section 5). Ending without it is a framework violation.

## 2. Checkpoint discipline

After EVERY completed task:
1. Tick its checkbox in `tasks.md` (`[~]` → `[x]`).
2. Append one line under "Progress log" in `session_handling.md`: what was done + any resume-relevant detail.
3. Commit and push: `git add -A && git commit -m "task: <short task description>" && git push`. If push fails (no remote/network), commit anyway and note the failure in `session_handling.md`.

Never start a task you cannot describe a resume point for. If a task is too big to finish safely, split it in `tasks.md` first.

## 3. Parallel execution (fan-out)

When several pending tasks have NO dependencies between them and touch disjoint files, fan them out to parallel subagents (Task/Agent tool) instead of working them sequentially. Rules:
- Only fan out tasks that are independent — no shared files, no ordering constraints. When in doubt, run sequentially.
- Mark every fanned-out task `[~]` in `tasks.md` before launching (exception to the one-`[~]` rule; note "fanned out" beside each).
- EVERY subagent must end with the exit ritual for its own work: report exactly what it changed, its resume point, and any gotchas back to the parent. A subagent result without this is treated as failed — re-verify its work before trusting it.
- The parent session owns the checkpoint: after each subagent returns, tick its task, log progress, and commit (section 2). The parent must NOT end — and must not start new fan-outs — until every launched subagent's result is checkpointed and the handoff ritual (section 5) is done.
- If tokens run low with subagents still out, wait for them, checkpoint their results, and hand off. Never abandon in-flight subagents silently; if one is lost, record it under "In-progress state".

## 4. Token-budget heuristics

You cannot see the real usage limit, so treat these as "running low" signals:
- The conversation has grown long (many turns / dozens of tool calls).
- A context-compaction or summarization notice appeared.
- You have read several large files or produced large outputs.

When any signal fires: do NOT start a new task. Finish or safely park the current one, then run the handoff ritual immediately.

## 5. Handoff ritual

Rewrite `session_handling.md` using its fixed headings:
- **Last session summary** — what this session accomplished, concisely.
- **In-progress state** — exact file paths, half-done edits, failing tests, uncommitted changes.
- **Next steps** — ordered, imperative instructions the next agent can execute cold ("1. Finish X in `src/y.py`, the loop at ~L40 still lacks error handling…").
- **Gotchas & decisions** — surprises, pitfalls, decisions made this session.

Then: update `tasks.md` to current reality, append to `architecture.md` if any engineering decision was made or changed, and finish with a handoff commit: `git add -A && git commit -m "handoff: <one-line session summary>" && git push`.

## 6. File contract

| File | Written by | When | Mutability |
|---|---|---|---|
| `description.txt` | User | Before planning run | Read-only after planning |
| `plan.md` | Planning agent | First run only | Write-once, never edited |
| `session_handling.md` | Every agent | Checkpoints + handoff | Rewritten each handoff |
| `tasks.md` | Every agent | Continuously | Always current |
| `architecture.md` | Every agent | On decisions | Append-only |
| `session_management_instructions.md` | Framework | Never | Read-only |

## 7. Style

Write concisely — these files are read at the start of every session and cost tokens. Prefer precise file paths and imperative next steps over prose.
