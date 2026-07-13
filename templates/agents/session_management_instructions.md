# Session Management Instructions

Rules for every agent session in this project. Goal: no session ever ends in a state the next agent can't resume from.

## 1. Session lifecycle

- **Start**: Read the files listed in `CLAUDE.md`. Verify the repo matches what `session_handling.md` claims (git status/log, quick build or test if cheap). If reality and docs disagree, trust reality and note the discrepancy in `session_handling.md`.
- **Work**: Execute tasks from `tasks.md` in order. One task in progress (`[~]`) at a time.
- **End**: Run the handoff ritual (section 4). Ending without it is a framework violation.

## 2. Checkpoint discipline

After EVERY completed task:
1. Tick its checkbox in `tasks.md` (`[~]` → `[x]`).
2. Append one line under "Progress log" in `session_handling.md`: what was done + any resume-relevant detail.

Never start a task you cannot describe a resume point for. If a task is too big to finish safely, split it in `tasks.md` first.

## 3. Token-budget heuristics

You cannot see the real usage limit, so treat these as "running low" signals:
- The conversation has grown long (many turns / dozens of tool calls).
- A context-compaction or summarization notice appeared.
- You have read several large files or produced large outputs.

When any signal fires: do NOT start a new task. Finish or safely park the current one, then run the handoff ritual immediately.

## 4. Handoff ritual

Rewrite `session_handling.md` using its fixed headings:
- **Last session summary** — what this session accomplished, concisely.
- **In-progress state** — exact file paths, half-done edits, failing tests, uncommitted changes.
- **Next steps** — ordered, imperative instructions the next agent can execute cold ("1. Finish X in `src/y.py`, the loop at ~L40 still lacks error handling…").
- **Gotchas & decisions** — surprises, pitfalls, decisions made this session.

Then: update `tasks.md` to current reality, and append to `architecture.md` if any engineering decision was made or changed.

## 5. File contract

| File | Written by | When | Mutability |
|---|---|---|---|
| `description.txt` | User | Before planning run | Read-only after planning |
| `plan.md` | Planning agent | First run only | Write-once, never edited |
| `session_handling.md` | Every agent | Checkpoints + handoff | Rewritten each handoff |
| `tasks.md` | Every agent | Continuously | Always current |
| `architecture.md` | Every agent | On decisions | Append-only |
| `session_management_instructions.md` | Framework | Never | Read-only |

## 6. Style

Write concisely — these files are read at the start of every session and cost tokens. Prefer precise file paths and imperative next steps over prose.
