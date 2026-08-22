#!/bin/bash
# Hook: SessionStart — keep the statusline registration stable and tell the
# session where its queue lives.
#
#   - refreshes the stable symlink ~/.claude/decision-queue/statusline.sh to
#     point at the current plugin version; the user's statusLine setting
#     targets the symlink, so a plugin update heals at the next session start
#   - deletes queue files not touched for over 30 days — the fallback for
#     sessions that ended without their SessionEnd hook firing (crash, kill);
#     normal cleanup happens in on-session-end.sh
#   - announces this session's queue file path as injected context, so the
#     model never has to guess its own session id

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

input=$(cat)

dir="$HOME/.claude/decision-queue"
mkdir -p "$dir"
ln -sfn "$SCRIPT_DIR/statusline.sh" "$dir/statusline.sh"
find "$dir" -maxdepth 1 -name '*.md' -mtime +30 -delete 2>/dev/null

command -v jq >/dev/null 2>&1 || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
case "$sid" in
  *[!0-9a-fA-F-]*|"") exit 0 ;;
esac

jq -cn --arg qfile "$dir/$sid.md" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: ("decision-queue: this session'"'"'s pending-decisions file is `\($qfile)` — one item per line; load the decision-queue skill for the update convention.")
  }
}'
