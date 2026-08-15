#!/bin/bash
# Test harness for the gnome-loop lease script (session exclusion).
#
# Pins the business rules the loop's exclusivity rests on:
#   - acquisition is atomic and idempotent for the same session id
#   - a fresh lease held by another session is never touched (exit 2)
#   - a stale lease is reported (exit 3), never taken over automatically
#   - heartbeat only advances the holder's own lease
#   - release only removes the holder's own lease, unless --force
#     (the human-confirmed stale-takeover path)
#
# Usage: bash tests/plugins/gnome-loop/run.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel)"
LEASE="$REPO_ROOT/plugins/gnome-loop/skills/gnome-loop/scripts/lease.sh"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

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

DIR="$WORK_DIR/loop.lease"

# --- acquire ----------------------------------------------------------------

bash "$LEASE" acquire "$DIR" session-a > /dev/null
check "acquire on empty exits 0" 0 $?
check "holder line 1 is the session id" "session-a" "$(head -1 "$DIR/holder")"
check "holder has a timestamp line" 2 "$(wc -l < "$DIR/holder")"

bash "$LEASE" acquire "$DIR" session-a > /dev/null
check "re-acquire by the same id is idempotent (0)" 0 $?

out=$(bash "$LEASE" acquire "$DIR" session-b)
check "acquire against a fresh foreign lease exits 2" 2 $?
case "$out" in *session-a*) check "foreign-acquire prints the holder" ok ok ;;
  *) check "foreign-acquire prints the holder" ok missing ;; esac
check "foreign acquire does not steal" "session-a" "$(head -1 "$DIR/holder")"

# --- heartbeat ---------------------------------------------------------------

touch -d '2 hours ago' "$DIR/holder"
old_mtime=$(stat -c %Y "$DIR/holder")
bash "$LEASE" heartbeat "$DIR" session-a > /dev/null
check "heartbeat by holder exits 0" 0 $?
new_mtime=$(stat -c %Y "$DIR/holder")
[ "$new_mtime" -gt "$old_mtime" ] && check "heartbeat advances mtime" ok ok \
  || check "heartbeat advances mtime" ok stale

touch -d '2 hours ago' "$DIR/holder"
bash "$LEASE" heartbeat "$DIR" session-b > /dev/null
check "heartbeat by non-holder exits 2" 2 $?
check "non-holder heartbeat does not advance mtime" \
  "$(date -d '2 hours ago' +%Y%m%d%H%M)" \
  "$(date -d "@$(stat -c %Y "$DIR/holder")" +%Y%m%d%H%M)"

# --- staleness ----------------------------------------------------------------

touch -d '200 minutes ago' "$DIR/holder"
out=$(bash "$LEASE" acquire "$DIR" session-b --stale-minutes 90)
check "acquire against a stale lease exits 3" 3 $?
case "$out" in *session-a*) check "stale-acquire prints the holder" ok ok ;;
  *) check "stale-acquire prints the holder" ok missing ;; esac
check "stale lease is not taken over automatically" "session-a" "$(head -1 "$DIR/holder")"

touch "$DIR/holder"
bash "$LEASE" acquire "$DIR" session-b --stale-minutes 90 > /dev/null
check "freshened lease is foreign again (2)" 2 $?

# --- heartbeat after loss ------------------------------------------------------

rm -rf "$DIR"
bash "$LEASE" heartbeat "$DIR" session-a > /dev/null 2>&1
check "heartbeat on a missing lease exits 4 (lost)" 4 $?

# --- release -------------------------------------------------------------------

bash "$LEASE" acquire "$DIR" session-a > /dev/null
bash "$LEASE" release "$DIR" session-a
check "release by holder exits 0" 0 $?
[ ! -d "$DIR" ] && check "release removes the lease dir" ok ok \
  || check "release removes the lease dir" ok remains

bash "$LEASE" release "$DIR" session-a
check "release when not held is idempotent (0)" 0 $?

bash "$LEASE" acquire "$DIR" session-a > /dev/null
bash "$LEASE" release "$DIR" session-b > /dev/null
check "release by non-holder exits 2" 2 $?
[ -d "$DIR" ] && check "non-holder release leaves the lease" ok ok \
  || check "non-holder release leaves the lease" ok removed

bash "$LEASE" release "$DIR" session-b --force
check "forced release (human-confirmed takeover path) exits 0" 0 $?
[ ! -d "$DIR" ] && check "forced release removes the lease" ok ok \
  || check "forced release removes the lease" ok remains

# --- status --------------------------------------------------------------------

bash "$LEASE" acquire "$DIR" session-a > /dev/null
check "status for holder says mine" "mine" "$(bash "$LEASE" status "$DIR" session-a | head -1)"
check "status for other says other-fresh" "other-fresh" "$(bash "$LEASE" status "$DIR" session-b | head -1)"
touch -d '200 minutes ago' "$DIR/holder"
check "status past threshold says other-stale" "other-stale" \
  "$(bash "$LEASE" status "$DIR" session-b --stale-minutes 90 | head -1)"
rm -rf "$DIR"
check "status with no lease says none" "none" "$(bash "$LEASE" status "$DIR" session-b | head -1)"

# --- summary ---------------------------------------------------------------------

echo "PASS: $PASS  FAIL: $FAIL"
[ "$FAIL" -eq 0 ]
