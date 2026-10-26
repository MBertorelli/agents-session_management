# Session Management Tool

A reusable framework that makes long-running Claude Code projects survive usage-limit cutoffs, and spends tokens where they matter. Each session checkpoints its state into `agents/` markdown files. A cron job launches the next session when the limit resets, and the new agent resumes exactly where the last one stopped. An Opus **lead** plans and reviews; model-tiered **executors** (Haiku / Sonnet / Opus) do the work, in isolated git worktrees when they run in parallel.

This repository *is* the template: copy its files into a project (see Install).

## How it works

1. **Planning run** (first session, interactive): the Opus lead reads `agents/description.txt`, does reconnaissance, asks clarifying questions, writes `agents/plan.md` (immutable forever after), and seeds `agents/tasks.md` with a **tagged** task list + `agents/architecture.md`. Each task is tagged with difficulty, risk, executor, deps, coreqs, files, and a verify command.
2. **Implementation runs**: the lead reads `AGENTS.md` (loaded via the `CLAUDE.md` shim) → `agents/session_management_instructions.md` → `agents/session_handling.md` → `agents/tasks.md` → `agents/architecture.md`, verifies the repo matches the docs, and continues from "Next steps".
3. **Routing**: each task goes to the executor its tags call for (the higher of difficulty and risk decides):
   - `low-executor` (Haiku): mechanical edits, pattern tests, running tests, searches
   - `medium-executor` (Sonnet): normal features, refactors, edge-case tests, debugging, **review of every Haiku-written test**
   - `high-executor` (Opus): architecture, high-risk work, diagrams, co-requisite contracts, merge conflicts

   Every executor reads `AGENTS.md`, `agents/architecture.md`, and only its own (plus deps/coreqs) lines of `agents/tasks.md` when it spawns (`agents/plan.md` only in the sections its brief names), then works only on its task ID. Small tasks and test reviews are bundled into one executor to save cold starts. Executors escalate (Haiku → Sonnet → Opus) rather than force a task they've outgrown.
4. **Worktrees & sync**: executors that run in parallel each get their own git worktree on a `task/<ID>` branch. Prerequisite tasks are merged before dependents spawn. Co-requisite tasks fan out from a shared contract committed first, and resync with `git merge` if the contract changes. The lead merges branches back in dependency order and verifies each one.
5. **Checkpointing**: after every completed task the lead ticks `tasks.md`, logs one progress line (including the executor used), and **autocommits + pushes**. When the session grows long (token-budget heuristics), it stops taking new tasks and runs the **handoff ritual**: a full rewrite of `session_handling.md` (summary, in-progress state including unmerged task branches, exact next steps, gotchas), sealed with a final `handoff:` commit.

## Install into a project

Either create the project from this repo (GitHub → **Use this template**), or copy the framework files into an existing repo without overwriting anything:

```bash
TOOL=/path/to/agents-session_management
cd /path/to/project
cp -n "$TOOL/AGENTS.md" "$TOOL/CLAUDE.md" .
mkdir -p agents .claude/agents
cp -n "$TOOL"/agents/* agents/
cp -n "$TOOL/.claude/settings.json" .claude/
cp -n "$TOOL"/.claude/agents/* .claude/agents/
```

If the project already has a `CLAUDE.md`, add the line `@AGENTS.md` to it instead of copying the shim. If it already has `.claude/settings.json`, merge in `"model": "opus"` and the git allowlist. Without the allowlist, headless sessions stall waiting for permission to commit, merge, or create worktrees.

The project must be a **git repo with a push-ready remote** (e.g. GitHub over SSH or a credential helper; cron can't answer auth prompts). Then fill in `agents/description.txt` and start the planning run interactively, since it asks you questions:

```bash
cd /path/to/project && claude
```

Accept the workspace trust dialog in this first interactive run. Until a folder is trusted, headless (`-p`) sessions ignore the `permissions.allow` entries in `.claude/settings.json`, so cron runs would be unable to commit, merge, or create worktrees.

## Cron-driven resume

Each cron run starts one headless implementation session and logs to `agents/logs/`:

```cron
CLAUDE_BIN=/abs/path/to/claude
0 */5 * * * cd /path/to/project && mkdir -p agents/logs && "$CLAUDE_BIN" -p "Read AGENTS.md and follow it: review agents/session_handling.md and agents/tasks.md, verify repo state, then continue the implementation. Checkpoint after every task and ALWAYS end with the handoff ritual so agents/session_handling.md and agents/tasks.md are current." --permission-mode acceptEdits >> agents/logs/run-$(date +\%Y\%m\%d-\%H\%M).log 2>&1
```

Notes:
- Every 5 hours matches a typical usage-limit reset window. Tune it to your plan.
- Cron has a minimal `PATH`, so set `CLAUDE_BIN` to the absolute path from `command -v claude`.
- `%` must be escaped as `\%` inside crontab lines.
- `--permission-mode acceptEdits` allows unattended file edits. Shell commands are limited to the allowlist in `.claude/settings.json`. Use `bypassPermissions` only if you accept fully unattended execution.

## File contract

| File | Purpose | Mutability |
|---|---|---|
| `AGENTS.md` | Entry point: run order, roles, task tagging, routing, delegation | Static |
| `CLAUDE.md` | One-line shim (`@AGENTS.md`) so Claude Code loads `AGENTS.md` | Static |
| `.claude/settings.json` | Default model (Opus lead) + git allowlist for headless runs | Static |
| `.claude/agents/*.md` | `low-` / `medium-` / `high-executor` subagent definitions | Static |
| `agents/description.txt` | What to build (written by you) | Read-only after planning |
| `agents/plan.md` | The generated plan | Write-once |
| `agents/session_handling.md` | Last session summary + next steps + unmerged branches | Rewritten each handoff |
| `agents/tasks.md` | Live tagged checklist (`[ ]`/`[~]`/`[x]`) | Always current |
| `agents/architecture.md` | Stack, patterns, decisions | Append-only |
| `agents/session_management_instructions.md` | Framework rules (checkpoints, worktrees, handoff) | Read-only |

## Known limitations

- **No true token visibility**: agents can't see your remaining usage, so the framework relies on per-task checkpointing (any loss is limited to one task) plus conversation-length heuristics for the full handoff. A hard cutoff mid-task can still lose that task's uncommitted progress.
- **Headless sessions can't ask questions**: resolve anything ambiguous during the interactive planning run. Implementation agents note open questions in `session_handling.md` rather than guess on big decisions.
- **Routing is instruction-driven**: Claude Code doesn't route by tags natively. The lead follows `AGENTS.md`. Check the `exec:` field in the progress log to confirm delegation is actually happening.
- **Delegation has overhead**: each executor starts cold and re-reads the docs. That's why trivial edits stay with the lead, and why the agents/ docs should stay concise.
- **Worktrees start from the last commit**: the lead must commit `tasks.md` and any contract files before spawning executors. A cutoff with worktrees out leaves `task/<ID>` branches that the next session merges or discards (listed in `session_handling.md`).
- **Cron timing is yours to tune**: the reset window depends on your subscription plan.
- **Autocommit needs non-interactive git auth**: if `git push` prompts for credentials, cron runs fail to push. Agents still commit locally and note it in `session_handling.md`.
