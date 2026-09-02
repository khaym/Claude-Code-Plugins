#!/bin/bash
# Hook body: emit the one context line naming this session's queue file, under
# the hook event named in stdin. Runs for SessionStart (via on-session-start.sh)
# and for every UserPromptSubmit — the per-prompt delivery is what reaches a
# resumed session (rationale: skills/decision-queue/design.md).

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
event=$(printf '%s' "$input" | jq -r '.hook_event_name // empty')
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -n "$event" ] || exit 0
case "$sid" in
  *[!0-9a-fA-F-]*|"") exit 0 ;;
esac

jq -cn --arg event "$event" --arg qfile "$HOME/.claude/decision-queue/$sid.md" '{
  hookSpecificOutput: {
    hookEventName: $event,
    additionalContext: ("decision-queue: this session'"'"'s pending-decisions file is `\($qfile)` — one item per line; load the decision-queue skill for the update convention.")
  }
}'
