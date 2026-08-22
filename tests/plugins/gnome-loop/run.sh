#!/bin/bash
# Test harness for the gnome-loop plugin scripts.
#
# lease.sh (session exclusion) — pins the business rules the loop's
# exclusivity rests on:
#   - acquisition is atomic and idempotent for the same session id
#   - a fresh lease held by another session is never touched (exit 2)
#   - a stale lease is reported (exit 3), never taken over automatically
#   - heartbeat only advances the holder's own lease
#   - release only removes the holder's own lease, unless --force
#     (the human-confirmed stale-takeover path)
#
# audit.sh (onboarding) — pins the audit's reading of a host:
#   - every missing required item is named and sets exit 1
#   - a fully wired host exits 0
#   - gitignored slot files are informational (listed), not a gap;
#     a missing git repository is a gap
#   - pattern lanes are discovered by their frontmatter marker
#
# Usage: bash tests/plugins/gnome-loop/run.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel)"
LEASE="$REPO_ROOT/plugins/gnome-loop/skills/gnome-loop/scripts/lease.sh"
AUDIT="$REPO_ROOT/plugins/gnome-loop/skills/onboarding/scripts/audit.sh"

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

# === audit.sh ====================================================================

# item's status column from an audit run: audit_status <item> <root> [audit args...]
audit_status() {
  local item="$1" root="$2"; shift 2
  bash "$AUDIT" "$root" "$@" | awk -v i="$item" '$1==i{print $2}'
}

EMPTY_CACHE="$WORK_DIR/empty-cache"
mkdir -p "$EMPTY_CACHE"

# --- unwired host: every required item missing -----------------------------------

BARE="$WORK_DIR/bare-host"
mkdir -p "$BARE"

bash "$AUDIT" "$BARE" --cache-dir "$EMPTY_CACHE" > /dev/null
check "unwired host exits 1" 1 $?
for item in config tracker tracker-data verify-skill observe-skill trigger-line; do
  check "unwired host: $item is missing" missing \
    "$(audit_status "$item" "$BARE" --cache-dir "$EMPTY_CACHE")"
done
check "unwired host: vcs is no-git" no-git \
  "$(audit_status vcs "$BARE" --cache-dir "$EMPTY_CACHE")"

# --- fully wired host exits 0 -----------------------------------------------------

HOST="$WORK_DIR/wired-host"
mkdir -p "$HOST/.claude/skills/verify" "$HOST/.claude/skills/observe" "$HOST/.tasks"
git -C "$HOST" init -q
echo "you MUST invoke the dev-cycle skill" > "$HOST/CLAUDE.md"
echo "[paths]" > "$HOST/.claude/gnome-loop.toml"
echo "name: verify" > "$HOST/.claude/skills/verify/SKILL.md"
echo "name: observe" > "$HOST/.claude/skills/observe/SKILL.md"
CACHE="$WORK_DIR/cache"
mkdir -p "$CACHE/mp/task-tracker/1.0.0/scripts"
touch "$CACHE/mp/task-tracker/1.0.0/scripts/task.sh"

bash "$AUDIT" "$HOST" --cache-dir "$CACHE" > /dev/null
check "wired host exits 0" 0 $?
check "wired host: vcs is tracked" tracked "$(audit_status vcs "$HOST" --cache-dir "$CACHE")"
check "tracker resolves the newest version" ok "$(audit_status tracker "$HOST" --cache-dir "$CACHE")"

# --- gitignored slot files: listed, not a gap --------------------------------------

echo ".claude/" > "$HOST/.gitignore"
out=$(bash "$AUDIT" "$HOST" --cache-dir "$CACHE")
check "ignored slot files keep exit 0" 0 $?
check "vcs reports ignored" ignored "$(echo "$out" | awk '$1=="vcs"{print $2}')"
case "$out" in *gnome-loop.toml*) check "ignored line names the files" ok ok ;;
  *) check "ignored line names the files" ok missing ;; esac
rm "$HOST/.gitignore"

# --- lane discovery via frontmatter marker ------------------------------------------

mkdir -p "$HOST/.claude/skills/add-widget-kind"
printf -- '---\nname: add-widget-kind\nmetadata: { lane: pattern }\n---\n' \
  > "$HOST/.claude/skills/add-widget-kind/SKILL.md"
out=$(bash "$AUDIT" "$HOST" --cache-dir "$CACHE" | awk '$1=="lanes"')
case "$out" in *add-widget-kind*) check "lanes line names the lane skill" ok ok ;;
  *) check "lanes line names the lane skill" ok missing ;; esac

# --- usage -------------------------------------------------------------------------

bash "$AUDIT" --bad-flag > /dev/null 2>&1
check "unknown flag exits 64" 64 $?

# --- summary ---------------------------------------------------------------------

echo "PASS: $PASS  FAIL: $FAIL"
[ "$FAIL" -eq 0 ]
