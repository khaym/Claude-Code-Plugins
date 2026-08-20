#!/bin/bash
# Test harness for the task-tracker CLI (task.sh).
#
# Pins the business rules the tracker's data safety rests on:
#   - only 'init' creates .tasks/ — every other command on an
#     uninitialized directory fails and leaves nothing behind, so a
#     command run in the wrong CWD cannot plant a stray tracker
#     (or edit that directory's .gitignore)
#   - update -d replaces the entire details text (the documented
#     contract callers must know before passing -d)
#   - pre-relations 6-column TSV files are migrated to the current
#     schema by any command, not just init
#
# Usage: bash tests/plugins/task-tracker/run.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel)"
TASK="$REPO_ROOT/plugins/task-tracker/scripts/task.sh"

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

cd "$WORK_DIR"

# --- uninitialized directory --------------------------------------------------

for cmd in "list" "add -s X" "show 1" "update 1 -s X" "close 1" "delete 1"; do
  bash "$TASK" $cmd > /dev/null 2>&1
  rc=$?
  check "'$cmd' without a tracker fails" ok "$([ "$rc" -ne 0 ] && echo ok || echo "exit $rc")"
done
[ ! -e .tasks ] && check "no command planted .tasks/" ok ok \
  || check "no command planted .tasks/" ok planted
[ ! -e .gitignore ] && check "no command touched .gitignore" ok ok \
  || check "no command touched .gitignore" ok touched

# --- init ----------------------------------------------------------------------

bash "$TASK" init > /dev/null
check "init exits 0" 0 $?
[ -f .tasks/tasks.tsv ] && check "init creates the TSV" ok ok \
  || check "init creates the TSV" ok missing
grep -qxF '.tasks' .gitignore && check "init gitignores .tasks" ok ok \
  || check "init gitignores .tasks" ok missing
bash "$TASK" init > /dev/null
check "re-init is idempotent (0)" 0 $?

# --- lifecycle sanity ------------------------------------------------------------

bash "$TASK" add -s "First" -d "original body" > /dev/null
check "add exits 0" 0 $?
out=$(bash "$TASK" list)
case "$out" in *First*) check "list shows the open task" ok ok ;;
  *) check "list shows the open task" ok missing ;; esac
out=$(bash "$TASK" show 1)
case "$out" in *"original body"*) check "show prints the details" ok ok ;;
  *) check "show prints the details" ok missing ;; esac

# --- update -d replaces the whole details ----------------------------------------

bash "$TASK" update 1 -d "replacement body" > /dev/null
check "update -d exits 0" 0 $?
check "details are replaced, not merged" "replacement body" "$(cat .tasks/details/1.md)"

bash "$TASK" close 1 -d "done" > /dev/null
check "close exits 0" 0 $?
out=$(bash "$TASK" list)
case "$out" in *First*) check "closed task leaves the default list" ok still-listed ;;
  *) check "closed task leaves the default list" ok ok ;; esac

# --- schema migration --------------------------------------------------------------

MIG_DIR="$WORK_DIR/migrate"
mkdir -p "$MIG_DIR/.tasks/details"
printf 'ID\tSTATUS\tCATEGORY\tSUBJECT\tCREATED\tUPDATED\n' > "$MIG_DIR/.tasks/tasks.tsv"
printf '1\topen\ttask\tOld row\t2026-01-01T00:00:00Z\t2026-01-01T00:00:00Z\n' >> "$MIG_DIR/.tasks/tasks.tsv"
echo "1" > "$MIG_DIR/.tasks/.counter"
(cd "$MIG_DIR" && bash "$TASK" list > /dev/null)
check "command on a 6-column file exits 0" 0 $?
check "migration pads rows to 8 columns" 8 \
  "$(head -n1 "$MIG_DIR/.tasks/tasks.tsv" | awk -F'\t' '{ print NF }')"

# --- summary -----------------------------------------------------------------------

echo "PASS: $PASS  FAIL: $FAIL"
[ "$FAIL" -eq 0 ]
