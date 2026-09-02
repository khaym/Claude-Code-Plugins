#!/bin/bash
# Hook: SessionStart — keep the statusline registration stable, start a
# resumed session from an empty queue, and tell the session where its queue
# lives.
#
#   - refreshes the stable symlink ~/.claude/decision-queue/statusline.sh to
#     point at the current plugin version; the user's statusLine setting
#     targets the symlink, so a plugin update heals at the next session start
#   - deletes queue files not touched for over 30 days — the fallback for
#     sessions that ended without their SessionEnd hook firing (crash, kill)
#   - on source=resume, deletes this session's queue file: a session's items
#     never carry over into a resumed run, however the previous run ended
#     (rationale: skills/decision-queue/design.md). compact keeps the file —
#     the session continues.
#   - announces this session's queue file path via announce-queue.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

input=$(cat)

dir="$HOME/.claude/decision-queue"
mkdir -p "$dir"
ln -sfn "$SCRIPT_DIR/statusline.sh" "$dir/statusline.sh"
find "$dir" -maxdepth 1 -name '*.md' -mtime +30 -delete 2>/dev/null

if command -v jq >/dev/null 2>&1; then
  sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
  source=$(printf '%s' "$input" | jq -r '.source // empty')
  case "$sid" in
    *[!0-9a-fA-F-]*|"") ;;
    *) [ "$source" = "resume" ] && rm -f "$dir/$sid.md" ;;
  esac
fi

printf '%s' "$input" | "$SCRIPT_DIR/announce-queue.sh"
