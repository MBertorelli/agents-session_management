# CLAUDE.md — Session-Managed Project

This project uses a session-management framework so work survives usage-limit cutoffs across multiple Claude Code sessions.

## On EVERY run, in this order

1. Read `agents/session_management_instructions.md` — the framework rules. Follow them for the whole session.
2. Read `agents/session_handling.md` — what the last session did and what to do next.
3. Read `agents/tasks.md` — the live checklist.
4. Read `agents/architecture.md` — stack, patterns, and decisions already made.

## Which kind of run is this?

- **`agents/plan.md` does NOT exist → planning run.** Read `agents/description.txt`, ask the user any clarifying questions, identify gaps and risks, then write `agents/plan.md` (it is immutable once written). Seed `agents/tasks.md` with the full task list and `agents/architecture.md` with the initial decisions.
- **`agents/plan.md` exists → implementation run.** Verify repo state matches the docs (`git status`, `git log`, run build/tests if cheap), then continue from the "Next steps" in `agents/session_handling.md`.

## Hard rule

NEVER end a session — voluntarily or because tokens are running low — without `agents/session_handling.md` and `agents/tasks.md` reflecting current reality. If in doubt, checkpoint now.
