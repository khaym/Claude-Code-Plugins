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
#   - update -a appends after a blank line and never rewrites the
#     existing bytes (the safe path for progress notes on long-lived
#     ticket bodies; -d's fetch-edit-replace round trip destroyed one)
#   - older TSV files (6 columns pre-relations, 8 pre-PARENT) are
#     migrated to the current schema by any command, not just init,
#     and migration never alters an existing row's values
#   - short rows are repaired too, not only the header: an older
#     installed task.sh keeps appending rows of its own width to a
#     file this version already migrated
#   - a ticket's parent is recorded on its own row (-p/--parent),
#     replaced (not accumulated) by update, and surfaced by list and
#     show so a child reveals its parent without opening it
#   - PARENT references are as loose as BLOCKED_BY/RELATED: never
#     validated, never cleaned up when the parent is deleted
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

# --- update -a appends without touching existing bytes ---------------------------

bash "$TASK" update 1 -a "appended note" > /dev/null
check "update -a exits 0" 0 $?
printf 'replacement body\n\nappended note\n' > expected.md
cmp -s expected.md .tasks/details/1.md \
  && check "append keeps the body and adds after a blank line" ok ok \
  || check "append keeps the body and adds after a blank line" ok "$(cat .tasks/details/1.md)"

bash "$TASK" add -s "Second" > /dev/null
bash "$TASK" update 2 --append-details "first note" > /dev/null
check "append to a task with no details exits 0" 0 $?
printf 'first note\n' > expected.md
cmp -s expected.md .tasks/details/2.md \
  && check "append to empty details starts the file" ok ok \
  || check "append to empty details starts the file" ok "$(cat .tasks/details/2.md)"
rm -f expected.md

bash "$TASK" close 1 -d "done" > /dev/null
check "close exits 0" 0 $?
out=$(bash "$TASK" list)
case "$out" in *First*) check "closed task leaves the default list" ok still-listed ;;
  *) check "closed task leaves the default list" ok ok ;; esac

# --- parent/child relation -------------------------------------------------------

PAR_DIR="$WORK_DIR/parent"
mkdir -p "$PAR_DIR"
cd "$PAR_DIR"
bash "$TASK" init > /dev/null
bash "$TASK" add -s "Parent1" > /dev/null
# The child also carries a RELATED value so the list assertion below tells
# the two columns apart: with RELATED empty, a swap of $8 and $9 in cmd_list
# would print the same single token and pass.
bash "$TASK" add -s "ChildA" -r 5 -p 1 > /dev/null
check "add -p exits 0" 0 $?

# Normalize the runs of padding spaces away: these assertions are about the
# value in each column, not the table's widths.
check "show prints the child's parent" "Parent: 1" \
  "$(echo $(bash "$TASK" show 2 | grep '^Parent:'))"
check "show prints an empty parent on a parent row" "Parent:" \
  "$(echo $(bash "$TASK" show 1 | grep '^Parent:'))"
check "list names PARENT between RELATED and SUBJECT" \
  "ID STATUS CATEGORY BLOCKED_BY RELATED PARENT SUBJECT" \
  "$(echo $(bash "$TASK" list | sed -n 1p))"
check "the child's list row shows RELATED then PARENT" "2 open task 5 1 ChildA" \
  "$(echo $(bash "$TASK" list | grep ChildA))"
check "the parent lands in the TSV's 9th column, not RELATED" "5|1" \
  "$(awk -F'\t' '$1 == 2 { print $8 "|" $9 }' .tasks/tasks.tsv)"

# Loose references: an ID is never checked for existence on the way in, and a
# reference to a deleted ticket is left standing (memo notes, not links).
bash "$TASK" add -s "Orphan" -p 99 > /dev/null
check "add accepts a parent id that does not exist" 0 $?
check "the unvalidated parent is stored as given" "Parent: 99" \
  "$(echo $(bash "$TASK" show 3 | grep '^Parent:'))"

bash "$TASK" update 2 -p 3 > /dev/null
check "update -p exits 0" 0 $?
check "update replaces the parent instead of accumulating" "Parent: 3" \
  "$(echo $(bash "$TASK" show 2 | grep '^Parent:'))"

bash "$TASK" delete 3 > /dev/null
check "delete of the parent exits 0" 0 $?
check "the dangling parent reference survives the delete" "Parent: 3" \
  "$(echo $(bash "$TASK" show 2 | grep '^Parent:'))"

cd "$WORK_DIR"

# --- schema migration --------------------------------------------------------------

MIG_DIR="$WORK_DIR/migrate"
mkdir -p "$MIG_DIR/.tasks/details"
printf 'ID\tSTATUS\tCATEGORY\tSUBJECT\tCREATED\tUPDATED\n' > "$MIG_DIR/.tasks/tasks.tsv"
printf '1\topen\ttask\tOld row\t2026-01-01T00:00:00Z\t2026-01-01T00:00:00Z\n' >> "$MIG_DIR/.tasks/tasks.tsv"
echo "1" > "$MIG_DIR/.tasks/.counter"
row6=$(sed -n 2p "$MIG_DIR/.tasks/tasks.tsv")
(cd "$MIG_DIR" && bash "$TASK" list > /dev/null)
check "command on a 6-column file exits 0" 0 $?
check "migration pads the header to 9 columns" 9 \
  "$(head -n1 "$MIG_DIR/.tasks/tasks.tsv" | awk -F'\t' '{ print NF }')"
check "migration pads a 6-column row to 9 columns in one command" 9 \
  "$(sed -n 2p "$MIG_DIR/.tasks/tasks.tsv" | awk -F'\t' '{ print NF }')"
check "migration leaves the 6-column row's values untouched" \
  "$(printf '%s\t\t\t' "$row6")" "$(sed -n 2p "$MIG_DIR/.tasks/tasks.tsv")"

MIG8_DIR="$WORK_DIR/migrate8"
mkdir -p "$MIG8_DIR/.tasks/details"
printf 'ID\tSTATUS\tCATEGORY\tSUBJECT\tCREATED\tUPDATED\tBLOCKED_BY\tRELATED\n' > "$MIG8_DIR/.tasks/tasks.tsv"
printf '1\topen\ttask\tEight\t2026-01-01T00:00:00Z\t2026-01-02T00:00:00Z\t2,3\t4\n' >> "$MIG8_DIR/.tasks/tasks.tsv"
echo "1" > "$MIG8_DIR/.tasks/.counter"
row8=$(sed -n 2p "$MIG8_DIR/.tasks/tasks.tsv")
(cd "$MIG8_DIR" && bash "$TASK" list > /dev/null)
check "command on an 8-column file exits 0" 0 $?
check "migration pads the 8-column header to 9 columns" 9 \
  "$(head -n1 "$MIG8_DIR/.tasks/tasks.tsv" | awk -F'\t' '{ print NF }')"
check "migration leaves the 8-column row's values untouched" \
  "$(printf '%s\t' "$row8")" "$(sed -n 2p "$MIG8_DIR/.tasks/tasks.tsv")"

# Mixed widths: the installed older task.sh appends rows of its own width to a
# file this version already migrated, so the header alone cannot decide.
MIXED_DIR="$WORK_DIR/mixed"
mkdir -p "$MIXED_DIR/.tasks/details"
printf 'ID\tSTATUS\tCATEGORY\tSUBJECT\tCREATED\tUPDATED\tBLOCKED_BY\tRELATED\tPARENT\n' > "$MIXED_DIR/.tasks/tasks.tsv"
printf '1\topen\ttask\tCurrent\t2026-01-01T00:00:00Z\t2026-01-01T00:00:00Z\t\t\t7\n' >> "$MIXED_DIR/.tasks/tasks.tsv"
printf '2\topen\ttask\tAppended by the old script\t2026-01-03T00:00:00Z\t2026-01-03T00:00:00Z\t1\t\n' >> "$MIXED_DIR/.tasks/tasks.tsv"
echo "2" > "$MIXED_DIR/.tasks/.counter"
mixed_current=$(sed -n 2p "$MIXED_DIR/.tasks/tasks.tsv")
mixed_short=$(sed -n 3p "$MIXED_DIR/.tasks/tasks.tsv")
(cd "$MIXED_DIR" && bash "$TASK" list > /dev/null)
check "command on a mixed-width file exits 0" 0 $?
check "the short row is repaired to 9 columns" 9 \
  "$(sed -n 3p "$MIXED_DIR/.tasks/tasks.tsv" | awk -F'\t' '{ print NF }')"
check "the already-current row is left as it was" "$mixed_current" \
  "$(sed -n 2p "$MIXED_DIR/.tasks/tasks.tsv")"
check "the repaired row keeps its 8 values" "$(printf '%s\t' "$mixed_short")" \
  "$(sed -n 3p "$MIXED_DIR/.tasks/tasks.tsv")"

# A blank line (an editor's trailing newline, a hand edit) is not a short row:
# it must stay blank rather than be padded into an all-empty 9-field record.
printf '\n' >> "$MIXED_DIR/.tasks/tasks.tsv"
(cd "$MIXED_DIR" && bash "$TASK" list > /dev/null)
check "a blank line is left blank, not padded into a record" "" \
  "$(sed -n 4p "$MIXED_DIR/.tasks/tasks.tsv")"

cp "$MIXED_DIR/.tasks/tasks.tsv" "$WORK_DIR/mixed-after-first.tsv"
(cd "$MIXED_DIR" && bash "$TASK" list > /dev/null)
cmp -s "$WORK_DIR/mixed-after-first.tsv" "$MIXED_DIR/.tasks/tasks.tsv" \
  && check "a second command rewrites nothing (idempotent)" ok ok \
  || check "a second command rewrites nothing (idempotent)" ok rewritten

# --- summary -----------------------------------------------------------------------

echo "PASS: $PASS  FAIL: $FAIL"
[ "$FAIL" -eq 0 ]
