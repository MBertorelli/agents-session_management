# Session Management Tool

A reusable framework that makes long-running Claude Code projects survive usage-limit cutoffs. Each session checkpoints its state into `agents/` markdown files; a cron job launches the next session when the limit resets, and the new agent resumes exactly where the last one stopped.

## How it works

1. **Planning run** (first session): the agent reads `agents/description.txt`, asks clarifying questions, writes `agents/plan.md` (immutable forever after), and seeds `agents/tasks.md` + `agents/architecture.md`.
2. **Implementation runs**: each agent reads `CLAUDE.md` → `agents/session_management_instructions.md` → `agents/session_handling.md` → `agents/tasks.md` → `agents/architecture.md`, verifies the repo matches the docs, and continues from "Next steps".
3. **Checkpointing**: after every completed task the agent ticks `tasks.md` and logs one progress line. When the session grows long (token-budget heuristics), it stops taking new tasks and runs the **handoff ritual** — a full rewrite of `session_handling.md` with summary, in-progress state, exact next steps, and gotchas.

## Install into a project

```bash
./init_project.sh /path/to/project
```

Copies `CLAUDE.md` to the project root and the `agents/` templates. Never overwrites existing files, so it is safe to re-run. Then fill in `/path/to/project/agents/description.txt` and start the planning run interactively:

```bash
cd /path/to/project && claude
```

Do the planning run interactively — it asks you questions.

## Cron-driven resume

`resume_session.sh` runs one headless implementation session and logs to `agents/logs/`:

```bash
./resume_session.sh /path/to/project
```

Example crontab (every 5 hours, matching a typical usage-limit reset window — tune to your plan):

```cron
0 */5 * * * /path/to/session_management_tool/resume_session.sh /path/to/project
```

Notes:
- Cron has a minimal `PATH`; the script auto-detects the `claude` binary or you can set `CLAUDE_BIN=/abs/path/to/claude` in the crontab line.
- The script uses `--permission-mode acceptEdits` (unattended file edits, but arbitrary shell commands still gated). Switch to `bypassPermissions` inside the script only if you accept fully unattended execution.

## File contract

| File | Purpose | Mutability |
|---|---|---|
| `CLAUDE.md` | Entry point routing every run through `agents/` | Static |
| `agents/description.txt` | What to build (written by you) | Read-only after planning |
| `agents/plan.md` | The generated plan | Write-once |
| `agents/session_handling.md` | Last session summary + next steps | Rewritten each handoff |
| `agents/tasks.md` | Live checklist (`[ ]`/`[~]`/`[x]`) | Always current |
| `agents/architecture.md` | Stack, patterns, decisions | Append-only |
| `agents/session_management_instructions.md` | Framework rules | Read-only |

## Known limitations

- **No true token visibility**: agents cannot see your remaining usage, so the framework relies on per-task checkpointing (bounds any loss to one task) plus conversation-length heuristics for the full handoff. A hard cutoff mid-task can still lose that task's uncommitted progress.
- **Headless sessions can't ask questions**: anything ambiguous should be resolved during the interactive planning run; implementation agents are instructed to note open questions in `session_handling.md` rather than guess on big decisions.
- **Cron timing is yours to tune**: the reset window depends on your subscription plan.
