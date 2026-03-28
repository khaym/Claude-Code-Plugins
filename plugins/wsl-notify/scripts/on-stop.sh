#!/bin/bash
# Hook: Stop — notify when Claude finishes a response
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TITLE="${WSL_NOTIFY_STOP_TITLE:-Claude Code}"
BODY="${WSL_NOTIFY_STOP_BODY:-Task completed}"
ICON="${WSL_NOTIFY_STOP_ICON:-success}"

"$SCRIPT_DIR/notify.sh" "$TITLE" "$BODY" "$ICON"
