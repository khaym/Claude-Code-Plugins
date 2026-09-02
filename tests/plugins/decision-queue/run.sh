#!/bin/bash
# Test harness for the decision-queue plugin scripts.
#
# Pins the business rules the resident view rests on:
#   - the renderer prints nothing for an empty, absent, or blank-only queue
#     (silence is the steady state; no dead header row)
#   - the renderer shows only the session named in its stdin JSON — parallel
#     sessions in one project never see each other's items
#   - control bytes in an item are stripped before rendering, so a hostile
#     item cannot replay escape sequences into the terminal on every refresh
#   - a non-UTF-8 byte in one item must not suppress the listing under a
#     UTF-8 locale (the renderer processes bytes, not locale text)
#   - the SessionStart hook keeps the stable symlink pointing at the current
#     script location (the self-heal that survives plugin updates) and
#     announces the session's queue path as SessionStart context
#   - announce-queue.sh emits the same line under the hook event named in
#     its stdin, and hooks.json runs it on every UserPromptSubmit (the
#     delivery that reaches a resumed session — design.md)
#   - a session's items never carry over: on-session-end.sh deletes exactly
#     the ending session's file on every end reason (hooks.json has no
#     SessionEnd matcher), and a SessionStart with source=resume deletes it
#     too, while compact leaves it; the age fallback removes only 31+-day
#     leftovers — a week-old queue of a live resident session survives
#
# Usage: bash tests/plugins/decision-queue/run.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel)"
STATUSLINE="$REPO_ROOT/plugins/decision-queue/scripts/statusline.sh"
SESSION_START="$REPO_ROOT/plugins/decision-queue/scripts/on-session-start.sh"
SESSION_END="$REPO_ROOT/plugins/decision-queue/scripts/on-session-end.sh"
ANNOUNCE="$REPO_ROOT/plugins/decision-queue/scripts/announce-queue.sh"
HOOKS_JSON="$REPO_ROOT/plugins/decision-queue/hooks/hooks.json"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
export HOME="$WORK_DIR"
DIR="$WORK_DIR/.claude/decision-queue"

PASS=0
FAIL=0

check() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label (expected: $expected, actual: $actual)"
  fi
}

SID_A="aaaa1111-2222-3333-4444-555566667777"
SID_B="bbbb1111-2222-3333-4444-555566667777"

# --- renderer: silence is the steady state ------------------------------------

out=$(echo "{\"session_id\":\"$SID_A\"}" | bash "$STATUSLINE")
check "absent queue renders nothing" "" "$out"

mkdir -p "$DIR"
: > "$DIR/$SID_A.md"
out=$(echo "{\"session_id\":\"$SID_A\"}" | bash "$STATUSLINE")
check "empty queue renders nothing" "" "$out"

printf '\n  \n\n' > "$DIR/$SID_A.md"
out=$(echo "{\"session_id\":\"$SID_A\"}" | bash "$STATUSLINE")
check "blank-only queue renders nothing" "" "$out"

out=$(echo '{}' | bash "$STATUSLINE")
check "missing session_id renders nothing" "" "$out"

# --- renderer: items, count, isolation -----------------------------------------

printf -- '- merge approval for #40\n\n- release note wording\n' > "$DIR/$SID_A.md"
out=$(echo "{\"session_id\":\"$SID_A\"}" | bash "$STATUSLINE")
check "header counts non-blank lines only" ok "$(printf '%s' "$out" | head -1 | grep -q 'pending decisions: 2' && echo ok || echo "got: $(printf '%s' "$out" | head -1)")"
check "items render verbatim, blanks dropped" ok "$([ "$(printf '%s' "$out" | tail -n +2)" = "$(printf -- '- merge approval for #40\n- release note wording')" ] && echo ok || echo mismatch)"

out=$(echo "{\"session_id\":\"$SID_B\"}" | bash "$STATUSLINE")
check "another session sees nothing" "" "$out"

# --- renderer: hostile and non-UTF-8 content ------------------------------------

printf -- '- evil \033]0;EVIL\007\033[2Jitem\n' > "$DIR/$SID_A.md"
out=$(echo "{\"session_id\":\"$SID_A\"}" | bash "$STATUSLINE")
body=$(printf '%s' "$out" | tail -n +2)
check "control bytes are stripped from items" "- evil ]0;EVIL[2Jitem" "$body"
check "header still carries its own color" ok "$(printf '%s' "$out" | head -1 | grep -q $'\033\[33m' && echo ok || echo stripped)"

printf -- '- d\351cider\n- plain item\n' > "$DIR/$SID_A.md"
out=$(echo "{\"session_id\":\"$SID_A\"}" | LC_ALL=C.UTF-8 bash "$STATUSLINE" 2>/dev/null)
check "non-UTF-8 byte does not suppress the listing" ok "$(printf '%s' "$out" | grep -q 'plain item' && echo ok || echo suppressed)"
check "count survives non-UTF-8 content" ok "$(printf '%s' "$out" | head -1 | grep -q 'pending decisions: 2' && echo ok || echo wrong)"

# --- session-start hook: symlink self-heal, context, age fallback ----------------

rm -rf "$DIR"
ctx=$(echo "{\"session_id\":\"$SID_A\",\"hook_event_name\":\"SessionStart\",\"source\":\"startup\"}" | bash "$SESSION_START")
check "hook creates the queue dir" ok "$([ -d "$DIR" ] && echo ok || echo missing)"
check "hook links statusline.sh to the current script" "$STATUSLINE" "$(readlink "$DIR/statusline.sh")"
check "hook announces this session's queue path" ok "$(printf '%s' "$ctx" | jq -re --arg p "$DIR/$SID_A.md" '.hookSpecificOutput | select(.hookEventName == "SessionStart") | .additionalContext | contains("`" + $p + "`")' > /dev/null && echo ok || echo bad-json)"

ln -sfn /nonexistent/statusline.sh "$DIR/statusline.sh"
echo "{\"session_id\":\"$SID_A\"}" | bash "$SESSION_START" > /dev/null
check "hook repoints a stale symlink (self-heal)" "$STATUSLINE" "$(readlink "$DIR/statusline.sh")"

echo "- crashed leftover" > "$DIR/$SID_B.md"
touch -d '31 days ago' "$DIR/$SID_B.md"
echo "- week-old but alive" > "$DIR/$SID_A.md"
touch -d '8 days ago' "$DIR/$SID_A.md"
echo "{\"session_id\":\"$SID_A\",\"hook_event_name\":\"SessionStart\",\"source\":\"startup\"}" | bash "$SESSION_START" > /dev/null
check "31-day leftover is deleted by the fallback" ok "$([ ! -e "$DIR/$SID_B.md" ] && echo ok || echo survived)"
check "week-old queue of a live session survives" ok "$([ -e "$DIR/$SID_A.md" ] && echo ok || echo pruned)"
check "symlink survives the fallback" "$STATUSLINE" "$(readlink "$DIR/statusline.sh")"

out=$(echo '{"hook_event_name":"SessionStart","source":"startup"}' | bash "$SESSION_START")
check "hook without session_id emits no context" "" "$out"

echo "- carried over" > "$DIR/$SID_A.md"
echo "{\"session_id\":\"$SID_A\",\"hook_event_name\":\"SessionStart\",\"source\":\"compact\"}" | bash "$SESSION_START" > /dev/null
check "compact keeps the session's queue" ok "$([ -e "$DIR/$SID_A.md" ] && echo ok || echo deleted)"
echo "{\"session_id\":\"$SID_A\",\"hook_event_name\":\"SessionStart\",\"source\":\"resume\"}" | bash "$SESSION_START" > /dev/null
check "resume starts the session from an empty queue" ok "$([ ! -e "$DIR/$SID_A.md" ] && echo ok || echo survived)"

# --- announce: the queue path reaches Claude on every prompt ---------------------

ctx=$(echo "{\"session_id\":\"$SID_A\",\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":\"hi\"}" | bash "$ANNOUNCE")
check "announce emits the queue path as UserPromptSubmit context" ok "$(printf '%s' "$ctx" | jq -re --arg p "$DIR/$SID_A.md" '.hookSpecificOutput | select(.hookEventName == "UserPromptSubmit") | .additionalContext | contains("`" + $p + "`")' > /dev/null && echo ok || echo bad-json)"

start_line=$(echo "{\"session_id\":\"$SID_A\",\"hook_event_name\":\"SessionStart\",\"source\":\"startup\"}" | bash "$SESSION_START" | jq -r '.hookSpecificOutput.additionalContext')
prompt_line=$(printf '%s' "$ctx" | jq -r '.hookSpecificOutput.additionalContext')
check "SessionStart and UserPromptSubmit announce the same line" "$start_line" "$prompt_line"

out=$(echo '{"hook_event_name":"UserPromptSubmit"}' | bash "$ANNOUNCE")
check "announce without session_id emits nothing" "" "$out"

out=$(echo "{\"session_id\":\"$SID_A\"}" | bash "$ANNOUNCE")
check "announce without hook_event_name emits nothing" "" "$out"

out=$(echo '{"session_id":"../escape","hook_event_name":"UserPromptSubmit"}' | bash "$ANNOUNCE")
check "announce rejects a non-uuid session id" "" "$out"

check "hooks.json wires announce-queue.sh to UserPromptSubmit" ok "$(jq -e '.hooks.UserPromptSubmit[].hooks[] | select(.command | endswith("/scripts/announce-queue.sh"))' "$HOOKS_JSON" > /dev/null && echo ok || echo unwired)"

# --- session-end hook: cleanup on real ends --------------------------------------

echo "- a item" > "$DIR/$SID_A.md"
echo "- b item" > "$DIR/$SID_B.md"
echo "{\"session_id\":\"$SID_A\"}" | bash "$SESSION_END"
check "session end deletes exactly its own queue" ok "$([ ! -e "$DIR/$SID_A.md" ] && [ -e "$DIR/$SID_B.md" ] && echo ok || echo wrong-file)"

check "hooks.json runs on-session-end.sh on every end reason (no matcher)" ok "$(jq -e '.hooks.SessionEnd[] | select(.hooks[].command | endswith("/scripts/on-session-end.sh")) | has("matcher") | not' "$HOOKS_JSON" > /dev/null && echo ok || echo matcher-present)"

echo "{\"session_id\":\"../escape\"}" | bash "$SESSION_END"
check "session end rejects a non-uuid session id" ok "$([ -e "$DIR/$SID_B.md" ] && echo ok || echo deleted)"

# --- result --------------------------------------------------------------------

echo ""
echo "decision-queue: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
