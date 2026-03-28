#!/bin/bash
# Hook: Notification (permission_prompt) — notify when permission is needed
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TITLE="${WSL_NOTIFY_PERMISSION_TITLE:-Claude Code}"
BODY="${WSL_NOTIFY_PERMISSION_BODY:-Permission required}"
ICON="${WSL_NOTIFY_PERMISSION_ICON:-warning}"

"$SCRIPT_DIR/notify.sh" "$TITLE" "$BODY" "$ICON"
