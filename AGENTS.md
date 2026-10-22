# AGENTS.md — Session-Managed Project

This project uses a session-management framework so work survives usage-limit cutoffs across multiple Claude Code sessions. Work is planned by an Opus **lead** and executed by model-tiered subagents. (`CLAUDE.md` only imports this file — edit here, not there.)

## On EVERY run, in this order

1. Read `agents/session_management_instructions.md` — the framework rules (checkpointing, worktrees, handoff). Follow them for the whole session.
2. Read `agents/session_handling.md` — what the last session did and what to do next.
3. Read `agents/tasks.md` — the live, tagged checklist.
4. Read `agents/architecture.md` — stack, patterns, and decisions already made.

## Which kind of run is this?

- **`agents/plan.md` does NOT exist → planning run.** Read `agents/description.txt`, do reconnaissance of the repo (structure, conventions, build/test commands, risks), ask the user any clarifying questions, identify gaps and risks, then write `agents/plan.md` (it is immutable once written). Seed `agents/tasks.md` with the full **tagged** task list (see "Task tagging") and `agents/architecture.md` with the initial decisions.
- **`agents/plan.md` exists → implementation run.** Verify repo state matches the docs (`git status`, `git log`, `git worktree list`, run build/tests if cheap), then continue from the "Next steps" in `agents/session_handling.md`.

## Roles

The main session is the **lead** and runs on Opus (default model in `.claude/settings.json`). Executors are subagents defined in `.claude/agents/`:

| Agent | Model | Owns |
|---|---|---|
| lead (main session) | Opus | Recon, planning, tagging, routing, delegation briefs, merging worktrees, reviewing diffs, final integration, ALL `agents/` doc updates and checkpoint commits |
| `low-executor` | Haiku | Mechanical/localized edits, pattern-following tests, running tests, repo searches |
| `medium-executor` | Sonnet | Normal features, moderate refactors, edge-case test design, bounded debugging, **reviewing Haiku-written tests** |
| `high-executor` | Opus | Architecture, cross-cutting changes, high-risk work, hard debugging, diagrams/visuals, co-requisite contracts, merge-conflict resolution, reviewing tests of high-risk tasks |

Executors never edit `agents/*` docs and never commit to the session branch (sole exception: a co-requisite contract commit the lead explicitly asks `high-executor` for) — they report back; the lead checkpoints.

## Task tagging

Every task in `agents/tasks.md` carries tags (written in the planning run, and whenever a task is split or reclassified):

```
- [ ] T03 Add retry handling to API client · diff:M · risk:H · exec:high · deps:T02 · coreqs:- · files:src/client.ts,test/client.test.ts · verify:`npm test -- client`
```

- **diff** = reasoning/implementation complexity; **risk** = cost of getting it wrong. Each is `L`/`M`/`H`.
- **Route by the higher of diff and risk:** L → `low-executor`, M → `medium-executor`, H → `high-executor`.
- A small diff is still **risk:H** if it touches auth, permissions, billing, privacy, data integrity, concurrency, migrations, or public APIs.
- Diagrams and technical visuals are always `exec:high`.
- `deps` = must be merged before this task starts. `coreqs` = tasks edited at the same time that share a contract (see worktree protocol in `agents/session_management_instructions.md` §4).
- **Test review is mandatory for Haiku tests:** any task where `low-executor` writes tests gets a follow-up `<ID>-R` task, `exec:medium` (or `exec:high` if the parent's risk is H), `deps:<ID>`.

## Delegation

- **Inline threshold:** the lead may implement trivial edits itself (≈≤10 lines in one file) and always does doc/checkpoint updates. Everything else is delegated to the tagged executor — delegation has overhead, so don't delegate trivia, but don't hoard real work either.
- **Brief every delegation fully.** Executors start with no conversation context. Use:

```
Task <ID> from agents/tasks.md (read AGENTS.md, agents/plan.md, agents/tasks.md, agents/architecture.md first).
Objective: …
Scope / files: … (do not touch anything else)
Acceptance criteria: …
Verify: <command>
Worktree: yes|no — branch task/<ID> from <session-branch>@<sha>
Deps merged: … · Coreqs in flight: … (contract at <file>@<sha>)
Escalate (stop and report) if: task is riskier/harder than tagged, scope must grow, contract must change, tests fail twice.
```

- **Escalation path:** Haiku → Sonnet → Opus. Pass the previous executor's findings and failed attempts forward; reclassify the task in `tasks.md`.
- **After every delegated task** the lead inspects the actual diff, checks scope, runs `verify`, confirms acceptance criteria, then checkpoints. Log the executor actually used in the progress line (auditable routing).

## Hard rule

NEVER end a session — voluntarily or because tokens are running low — without `agents/session_handling.md` and `agents/tasks.md` reflecting current reality (including unmerged worktree branches), committed and pushed. If in doubt, checkpoint now.
