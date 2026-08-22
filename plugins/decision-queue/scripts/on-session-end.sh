#!/bin/bash
# Hook: SessionEnd — delete the ending session's queue file.
#
# Registered in hooks.json with a matcher that excludes `resume`: a resumed
# session keeps its session_id, so its queue must survive the resume
# boundary. Sessions that die without this hook firing are caught by the
# 30-day age fallback in on-session-start.sh.

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
case "$sid" in
  *[!0-9a-fA-F-]*|"") exit 0 ;;
esac

rm -f "$HOME/.claude/decision-queue/$sid.md"
