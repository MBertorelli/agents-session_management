#!/usr/bin/env bash
# Resume an implementation session headlessly. Intended to be run from cron
# after the usage-limit window resets.
# Usage: ./resume_session.sh /path/to/project
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/project" >&2
    exit 1
fi

PROJECT="$1"

# Cron runs with a minimal PATH; allow an explicit override via CLAUDE_BIN.
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude || true)}"
if [[ -z "$CLAUDE_BIN" ]]; then
    for candidate in "$HOME/.local/bin/claude" "$HOME/.claude/local/claude" /usr/local/bin/claude; do
        [[ -x "$candidate" ]] && CLAUDE_BIN="$candidate" && break
    done
fi
if [[ -z "$CLAUDE_BIN" ]]; then
    echo "ERROR: claude binary not found; set CLAUDE_BIN" >&2
    exit 1
fi

LOG_DIR="$PROJECT/agents/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/run-$(date +%Y%m%d-%H%M%S).log"

PROMPT='Read CLAUDE.md and follow it: review agents/session_handling.md and agents/tasks.md, verify repo state, then continue the implementation. Checkpoint after every task and ALWAYS end with the handoff ritual so agents/session_handling.md and agents/tasks.md are current.'

# --permission-mode acceptEdits lets the agent edit files unattended but still
# blocks arbitrary commands. Use "bypassPermissions" only if you accept the
# risk of fully unattended shell access.
cd "$PROJECT"
"$CLAUDE_BIN" -p "$PROMPT" --permission-mode acceptEdits >"$LOG_FILE" 2>&1
echo "Session finished. Log: $LOG_FILE"
