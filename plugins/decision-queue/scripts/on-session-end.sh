#!/bin/bash
# Hook: SessionEnd — delete the ending session's queue file, whatever the end
# reason (no matcher in hooks.json). A session's items never carry over; the
# 30-day age fallback in on-session-start.sh catches runs that died without
# this hook firing (rationale: skills/decision-queue/design.md).

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
case "$sid" in
  *[!0-9a-fA-F-]*|"") exit 0 ;;
esac

rm -f "$HOME/.claude/decision-queue/$sid.md"
