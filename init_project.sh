#!/usr/bin/env bash
# Scaffold the session-management framework into a target project.
# Usage: ./init_project.sh /path/to/project
set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$TOOL_DIR/templates"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/project" >&2
    exit 1
fi

TARGET="$1"
mkdir -p "$TARGET/agents"

copy_if_absent() {
    local src="$1" dst="$2"
    if [[ -e "$dst" ]]; then
        echo "SKIP (exists): $dst"
    else
        cp "$src" "$dst"
        echo "created:       $dst"
    fi
}

copy_if_absent "$TEMPLATES/CLAUDE.md" "$TARGET/CLAUDE.md"
mkdir -p "$TARGET/.claude"
copy_if_absent "$TEMPLATES/settings.json" "$TARGET/.claude/settings.json"
for f in "$TEMPLATES/agents/"*; do
    copy_if_absent "$f" "$TARGET/agents/$(basename "$f")"
done

echo
echo "Done. Next steps:"
echo "  1. Fill in $TARGET/agents/description.txt with what you want to build."
echo "  2. Make sure the project is a git repo with a push-ready remote (agents autocommit per task)."
echo "  3. Start the planning run:  cd $TARGET && claude"
echo "  4. Wire the cron job (see README.md) using resume_session.sh."
