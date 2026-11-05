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
#   - add never hands out an ID a row already has: when .counter is
#     behind the highest ID in tasks.tsv (rows added outside task.sh;
#     an ID with a trailing CR still counts), is missing while the index
#     has rows, or is not a non-negative integer (a CR or spaces around
#     the number are tolerated), add fails, writes neither a row nor the
#     counter, and names the cause and the command a human runs to
#     recover — for a missing or non-numeric counter with a note that
#     deleted IDs above the highest row must not be reused; a counter
#     equal to or ahead of that ID (e.g. after deleting the top row), or
#     no counter with an empty index, adds as before
#   - the bundled PreToolUse hook blocks a Claude session's writes to
#     the index and counter outside task.sh — Edit/Write, and the Bash
#     write shapes (>, >>, tee, sed -i, the mv/cp last operand) — when the
#     target, resolved against the payload's cwd and the literal cds
#     before it (a cd in ( ... ) ending at its ")"), is tasks.tsv or
#     .counter in a directory named .tasks;
#     with no usable base (no cwd, a non-literal cd) a bare name counts
#     too. Reads, task.sh calls whose arguments mention tasks.tsv, quoted
#     text (incl. $'...'), heredoc bodies, details/<id>.md, and the same
#     names elsewhere pass, and a hook that cannot parse its input lets
#     the call through silently
#
# Usage: bash tests/plugins/task-tracker/run.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel)"
TASK="$REPO_ROOT/plugins/task-tracker/scripts/task.sh"
GUARD="$REPO_ROOT/plugins/task-tracker/hooks/scripts/tracker-write-guard.py"

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

# --- add with a counter behind the rows ----------------------------------------------

LAG_DIR="$WORK_DIR/lag"
mkdir -p "$LAG_DIR"
cd "$LAG_DIR"
bash "$TASK" init > /dev/null
bash "$TASK" add -s "One" > /dev/null
bash "$TASK" add -s "Two" > /dev/null
# A row appended outside task.sh, the way the incident did: the counter stays at 2.
printf '3\topen\ttask\tHand-appended\t2026-01-01T00:00:00Z\t2026-01-01T00:00:00Z\t\t\t\n' >> .tasks/tasks.tsv
cp .tasks/tasks.tsv "$WORK_DIR/lag-before.tsv"

err=$(bash "$TASK" add -s "Collides" -d "body" 2>&1 > /dev/null)
rc=$?
check "add with a lagging counter fails" ok "$([ "$rc" -ne 0 ] && echo ok || echo "exit $rc")"
cmp -s "$WORK_DIR/lag-before.tsv" .tasks/tasks.tsv \
  && check "the lagging add appends no row" ok ok \
  || check "the lagging add appends no row" ok "$(tail -n1 .tasks/tasks.tsv)"
check "the lagging add leaves .counter unchanged" 2 "$(cat .tasks/.counter)"
[ ! -e .tasks/details/3.md ] && check "the lagging add writes no details" ok ok \
  || check "the lagging add writes no details" ok written
case "$err" in *"outside task.sh"*) check "the error names rows added outside task.sh" ok ok ;;
  *) check "the error names rows added outside task.sh" ok "$err" ;; esac
case "$err" in *"echo 3 > "*".tasks/.counter"*) check "the error gives the recovery command" ok ok ;;
  *) check "the error gives the recovery command" ok "$err" ;; esac

# The human's recovery: the counter equal to the highest ID adds as before.
echo 3 > .tasks/.counter
bash "$TASK" add -s "After recovery" > /dev/null
check "add with the counter equal to the highest ID exits 0" 0 $?
check "the recovered add takes the next free ID" "After recovery" \
  "$(awk -F'\t' '$1 == 4 { print $4 }' .tasks/tasks.tsv)"
check "the recovered add advances the counter" 4 "$(cat .tasks/.counter)"

# Deleting the top row leaves the counter ahead of the rows: IDs are not reused.
bash "$TASK" delete 4 > /dev/null
bash "$TASK" add -s "Ahead" > /dev/null
check "add with the counter ahead of the highest ID exits 0" 0 $?
check "the counter-ahead add skips the deleted ID" "Ahead" \
  "$(awk -F'\t' '$1 == 5 { print $4 }' .tasks/tasks.tsv)"

# A row written with a CRLF line ending keeps its \r in the ID column; it still
# counts as an ID, or the counter check would miss it and hand out a duplicate.
CR_DIR="$WORK_DIR/crlf"
mkdir -p "$CR_DIR"
cd "$CR_DIR"
bash "$TASK" init > /dev/null
bash "$TASK" add -s "One" > /dev/null
printf '2\r\n' >> .tasks/tasks.tsv
err=$(bash "$TASK" add -s "Collides" 2>&1 > /dev/null)
rc=$?
check "an ID with a trailing CR counts toward the highest ID" ok \
  "$([ "$rc" -ne 0 ] && echo ok || echo "exit $rc")"
case "$err" in *"echo 2 > "*) check "the CR row's ID is the one in the recovery command" ok ok ;;
  *) check "the CR row's ID is the one in the recovery command" ok "$err" ;; esac
check "the CR case leaves .counter unchanged" 1 "$(cat .tasks/.counter)"

# A counter that is not a non-negative integer is reported, never computed with.
BAD_DIR="$WORK_DIR/badcounter"
mkdir -p "$BAD_DIR"
cd "$BAD_DIR"
bash "$TASK" init > /dev/null
bash "$TASK" add -s "One" > /dev/null
cp .tasks/tasks.tsv "$WORK_DIR/bad-before.tsv"
for content in "abc" "-1" "1+1" ""; do
  printf '%s\n' "$content" > .tasks/.counter
  err=$(bash "$TASK" add -s "X" 2>&1 > /dev/null)
  rc=$?
  check "a counter of '$content' fails add" ok "$([ "$rc" -ne 0 ] && echo ok || echo "exit $rc")"
  case "$err" in *".tasks/.counter"*"'$content'"*) check "the error names the counter and its content '$content'" ok ok ;;
    *) check "the error names the counter and its content '$content'" ok "$err" ;; esac
  cmp -s "$WORK_DIR/bad-before.tsv" .tasks/tasks.tsv \
    && check "a counter of '$content' adds no row" ok ok \
    || check "a counter of '$content' adds no row" ok "$(tail -n1 .tasks/tasks.tsv)"
  check "a counter of '$content' is left as it was" "$content" "$(cat .tasks/.counter)"
done

# The deleted-IDs hint: the highest index ID is only a lower bound for the last
# ID handed out, so the not-a-number recovery says so (the behind case does not:
# there the counter itself is the better value and is kept).
case "$err" in *"were deleted"*"last ID handed out"*) check "the not-a-number recovery warns about deleted IDs" ok ok ;;
  *) check "the not-a-number recovery warns about deleted IDs" ok "$err" ;; esac
cd "$LAG_DIR"
printf '1\n' > .tasks/.counter
err=$(bash "$TASK" add -s "X" 2>&1 > /dev/null)
case "$err" in *"were deleted"*) check "the behind recovery has no deleted-IDs line" ok "$err" ;;
  *) check "the behind recovery has no deleted-IDs line" ok ok ;; esac
cd "$BAD_DIR"

# The counter is read like the index's ID column: a CR or spaces around the
# number are not part of it.
printf '5\r\n' > .tasks/.counter
bash "$TASK" add -s "After CRLF counter" > /dev/null
check "a counter of 5 with CRLF exits 0" 0 $?
check "a counter of 5 with CRLF hands out 6" "After CRLF counter" \
  "$(awk -F'\t' '$1 == 6 { print $4 }' .tasks/tasks.tsv)"
printf ' 6 \n' > .tasks/.counter
bash "$TASK" add -s "After spaced counter" > /dev/null
check "a counter of 6 with spaces exits 0" 0 $?
check "a counter of 6 with spaces hands out 7" "After spaced counter" \
  "$(awk -F'\t' '$1 == 7 { print $4 }' .tasks/tasks.tsv)"

# A missing counter has a cause of its own; with an empty index it is a fresh
# tracker and numbering starts at 1.
cp .tasks/tasks.tsv "$WORK_DIR/missing-before.tsv"
rm .tasks/.counter
err=$(bash "$TASK" add -s "X" 2>&1 > /dev/null)
rc=$?
check "add with the counter missing and rows present fails" ok "$([ "$rc" -ne 0 ] && echo ok || echo "exit $rc")"
case "$err" in *".tasks/.counter is missing"*) check "the error says the counter is missing" ok ok ;;
  *) check "the error says the counter is missing" ok "$err" ;; esac
case "$err" in *"outside task.sh"*) check "the missing-counter error does not blame added rows" ok "$err" ;;
  *) check "the missing-counter error does not blame added rows" ok ok ;; esac
case "$err" in *"echo 7 > "*".tasks/.counter"*"were deleted"*) check "the missing-counter recovery gives the command and the deleted-IDs line" ok ok ;;
  *) check "the missing-counter recovery gives the command and the deleted-IDs line" ok "$err" ;; esac
cmp -s "$WORK_DIR/missing-before.tsv" .tasks/tasks.tsv \
  && check "the missing-counter add appends no row" ok ok \
  || check "the missing-counter add appends no row" ok "$(tail -n1 .tasks/tasks.tsv)"
[ ! -e .tasks/.counter ] && check "the missing-counter add creates no counter" ok ok \
  || check "the missing-counter add creates no counter" ok "$(cat .tasks/.counter)"

FRESH_DIR="$WORK_DIR/fresh"
mkdir -p "$FRESH_DIR"
cd "$FRESH_DIR"
bash "$TASK" init > /dev/null
rm .tasks/.counter
bash "$TASK" add -s "First ever" > /dev/null
check "add with no counter and an empty index exits 0" 0 $?
check "numbering starts at 1 with no counter and an empty index" "First ever" \
  "$(awk -F'\t' '$1 == 1 { print $4 }' .tasks/tasks.tsv)"

cd "$WORK_DIR"

# --- hook: writes to the index and counter outside task.sh --------------------------

# Payloads carry the session's cwd the way Claude Code sends it; the default is
# a project root /p. An explicit empty cwd leaves the field out, which is the
# hook's fallback path (base directory unknown). HOME is pinned for ~ and cd.
# usage: bash_payload <command> [cwd]
bash_payload() {
  python3 -c '
import json, sys
p = {"tool_name": "Bash", "tool_input": {"command": sys.argv[1]}}
if sys.argv[2]:
    p["cwd"] = sys.argv[2]
print(json.dumps(p))' "$1" "${2-/p}"
}
# usage: file_payload <tool> <file_path> [cwd]
file_payload() {
  python3 -c '
import json, sys
p = {"tool_name": sys.argv[1], "tool_input": {"file_path": sys.argv[2], "content": "x"}}
if sys.argv[3]:
    p["cwd"] = sys.argv[3]
print(json.dumps(p))' "$1" "$2" "${3-/p}"
}
run_guard() { HOME=/h python3 "$GUARD"; }

# usage: guard_deny <label> <payload>
guard_deny() {
  local out
  out=$(printf '%s' "$2" | run_guard)
  if echo "$out" | grep -q '"permissionDecision": *"deny"'; then
    check "hook blocks: $1" ok ok
  else
    check "hook blocks: $1" deny "${out:-silent}"
  fi
}

# Allow is a silent exit 0 with nothing on stderr either: a traceback is not
# an allow, even when Claude Code would let the call through.
# usage: guard_allow <label> <payload>
guard_allow() {
  local out rc
  out=$(printf '%s' "$2" | run_guard 2>&1)
  rc=$?
  check "hook allows: $1" "0|" "$rc|$out"
}

INCIDENT=$'cd /home/ras/project/claude-system/.tasks && now=$(date -u +%Y-%m-%dT%H:%M:%SZ) && printf \'39\\topen\\t...\\t%s\\t%s\\t\\t38\\t\\n\' "$now" "$now" >> tasks.tsv && cat > details/39.md <<\'EOF\'\n## Purpose\nThe owner\'s ticket body, with "quotes" and it\'s apostrophes.\nEOF\ntail -1 tasks.tsv'

guard_deny "the incident command (cd .tasks && printf >> tasks.tsv)" "$(bash_payload "$INCIDENT")"
guard_deny "printf >> .tasks/tasks.tsv"        "$(bash_payload 'printf x >> .tasks/tasks.tsv')"
guard_deny "echo > .tasks/.counter"            "$(bash_payload 'echo 40 > .tasks/.counter')"
guard_deny "fd-prefixed 1> .tasks/.counter"    "$(bash_payload 'echo 40 1> .tasks/.counter')"
guard_deny "&> .tasks/tasks.tsv"               "$(bash_payload 'echo x &> .tasks/tasks.tsv')"
guard_deny "redirect with no space"            "$(bash_payload 'echo 40 >.tasks/.counter')"
guard_deny "quoted redirect target"            "$(bash_payload 'echo 40 > ".tasks/.counter"')"
guard_deny "absolute redirect target"          "$(bash_payload 'echo 40 > /p/.tasks/.counter')"
guard_deny "tee -a .tasks/tasks.tsv"           "$(bash_payload 'echo x | tee -a .tasks/tasks.tsv')"
guard_deny "tee .tasks/tasks.tsv"              "$(bash_payload 'echo x | tee .tasks/tasks.tsv > /dev/null')"
guard_deny "sed -i on .tasks/tasks.tsv"        "$(bash_payload "sed -i 's/a/b/' .tasks/tasks.tsv")"
guard_deny "sed -i.bak on .tasks/tasks.tsv"    "$(bash_payload "sed -i.bak -e 's/a/b/' .tasks/tasks.tsv")"
guard_deny "mv tmp .tasks/tasks.tsv"           "$(bash_payload 'mv tmp .tasks/tasks.tsv')"
guard_deny "cp a .tasks/.counter"              "$(bash_payload 'cp a .tasks/.counter')"
guard_deny "cp with a trailing 2> (fd is no operand)" "$(bash_payload 'cp a .tasks/.counter 2> /dev/null')"
guard_deny "write on a later line"             "$(bash_payload $'ls\necho 40 > .tasks/.counter')"
guard_deny "write after a heredoc with an apostrophe" \
  "$(bash_payload $'cat > .tasks/details/41.md <<\'EOF\'\nit\'s done\nEOF\necho 40 > .tasks/.counter')"
guard_deny "heredoc written into .tasks/tasks.tsv (<<EOF before >)" \
  "$(bash_payload $'cat <<\'EOF\' > .tasks/tasks.tsv\nrow\nEOF')"
guard_deny "write after a <<- heredoc ending at a tab-indented delimiter" \
  "$(bash_payload $'cat > .tasks/details/41.md <<-EOF\n\tdone\n\tEOF\necho 40 > .tasks/.counter')"
guard_deny "Edit, absolute .tasks/tasks.tsv"   "$(file_payload Edit /p/.tasks/tasks.tsv)"
guard_deny "Write, absolute .tasks/.counter"   "$(file_payload Write /p/.tasks/.counter)"
guard_deny "Edit, relative .tasks/tasks.tsv"   "$(file_payload Edit .tasks/tasks.tsv)"
guard_deny "Write, relative .tasks/.counter"   "$(file_payload Write .tasks/.counter)"

# Targets resolve against the payload's cwd and the literal cds before them;
# protected means: named tasks.tsv or .counter, in a directory named .tasks.
# A cd inside ( ... ) ends at the closing parenthesis, as in the shell.
guard_allow "a subshell cd does not leak past )" \
  "$(bash_payload '(cd .tasks); echo x > .counter' /p)"
guard_deny "a subshell cd out of .tasks does not leak past )" \
  "$(bash_payload '(cd /tmp); echo 9 > .counter' /p/.tasks)"
guard_deny "a cd inside the subshell applies within it" \
  "$(bash_payload '(cd .tasks && echo x > .counter)' /p)"
guard_deny "cd .tasks/details, then > ../.counter" \
  "$(bash_payload 'cd .tasks/details && echo 1 > ../.counter')"
guard_deny "bare tasks.tsv with cwd inside .tasks" \
  "$(bash_payload 'printf x >> tasks.tsv' /p/.tasks)"
guard_deny "the incident command from a cwd outside the tracker" \
  "$(bash_payload "$INCIDENT" /somewhere/else)"
guard_deny "plain cd goes to HOME" \
  "$(bash_payload 'cd && echo 1 > .tasks/.counter' /p)"
guard_deny "cd ~/... expands from HOME" \
  "$(bash_payload 'cd ~/proj/.tasks && echo 1 > .counter' /p)"
guard_deny "~/ in the target expands from HOME" \
  "$(bash_payload 'echo 1 > ~/proj/.tasks/.counter' /p)"
guard_deny "Edit, bare tasks.tsv with cwd inside .tasks" \
  "$(file_payload Edit tasks.tsv /p/.tasks)"
guard_deny "non-literal cd falls back to the bare-name rule" \
  "$(bash_payload 'cd "$D" && echo > tasks.tsv')"
guard_deny "no cwd falls back to the bare-name rule" \
  "$(bash_payload 'printf x >> tasks.tsv' '')"
guard_deny "no cwd, Write .tasks/.counter" \
  "$(file_payload Write .tasks/.counter '')"
guard_deny "cwd that is not a string falls back" \
  '{"tool_name":"Bash","tool_input":{"command":"printf x >> tasks.tsv"},"cwd":5}'
guard_deny "ANSI-C quoting before a write" \
  "$(bash_payload "echo \$'it\\'s'; echo 40 > .tasks/.counter")"

reason=$(printf '%s' "$(bash_payload 'printf x >> .tasks/tasks.tsv')" | run_guard)
for word in "task.sh" "add" "update" "close" "delete" "terminal"; do
  case "$reason" in *"$word"*) check "the deny reason mentions '$word'" ok ok ;;
    *) check "the deny reason mentions '$word'" ok "$reason" ;; esac
done

guard_allow "grep -P on .tasks/tasks.tsv"      "$(bash_payload "grep -P '^41\\t' .tasks/tasks.tsv")"
guard_allow "awk on .tasks/tasks.tsv"          "$(bash_payload "awk -F'\\t' '\$1 == 41 { print \$4 }' .tasks/tasks.tsv")"
guard_allow "head .tasks/tasks.tsv"            "$(bash_payload 'head -n 3 .tasks/tasks.tsv')"
guard_allow "tail .tasks/tasks.tsv"            "$(bash_payload 'tail -1 .tasks/tasks.tsv')"
guard_allow "cat .tasks/tasks.tsv"             "$(bash_payload 'cat .tasks/tasks.tsv')"
guard_allow "input redirect from .tasks/tasks.tsv" "$(bash_payload 'wc -l < .tasks/tasks.tsv')"
guard_allow "cp from .tasks/tasks.tsv"         "$(bash_payload 'cp .tasks/tasks.tsv backup.tsv')"
# The mv/cp destination is the last operand as written; a directory there is
# not joined with the source's name.
guard_allow "cp into the .tasks/ directory"     "$(bash_payload 'cp /backup/tasks.tsv .tasks/')"
guard_allow "sed without -i on .tasks/tasks.tsv" "$(bash_payload "sed -n '2p' .tasks/tasks.tsv")"
guard_allow "task.sh add -d mentioning >> tasks.tsv" \
  "$(bash_payload 'task.sh add -s "x" -d "printf ... >> tasks.tsv"')"
guard_allow "task.sh update -a mentioning > .tasks/.counter" \
  "$(bash_payload '${CLAUDE_PLUGIN_ROOT}/scripts/task.sh update 41 -a "the fix: echo 40 > .tasks/.counter, run by a human"')"
# Heredoc bodies are skipped, not parsed: the first body has no quote to trip
# the tokenizer into its degrade path, so only skipping lets it pass; the second
# body's apostrophe would hide the write after it unless the body is skipped.
guard_allow "heredoc body mentioning >> tasks.tsv" \
  "$(bash_payload $'cat > .tasks/details/41.md <<\'EOF\'\nThe incident: printf ... >> tasks.tsv, then fixed.\nEOF')"
guard_allow "<<- heredoc with a tab-indented delimiter" \
  "$(bash_payload $'cat > .tasks/details/41.md <<-EOF\n\tprintf x >> tasks.tsv\n\tEOF')"
guard_allow "Edit .tasks/details/41.md"        "$(file_payload Edit /p/.tasks/details/41.md)"
guard_allow "Write .tasks/details/41.md"       "$(file_payload Write .tasks/details/41.md)"
guard_allow "echo > data/tasks.tsv"            "$(bash_payload 'echo x > data/tasks.tsv')"
guard_allow "Write data/tasks.tsv"             "$(file_payload Write /p/data/tasks.tsv)"
guard_allow ".counter outside .tasks (cwd unrelated)" \
  "$(bash_payload 'echo 0 > .counter' /work/src)"
guard_allow "bare tasks.tsv at the project root" \
  "$(bash_payload 'echo x > tasks.tsv' /p)"
guard_allow "cd out of .tasks before the write" \
  "$(bash_payload 'cd /p/.tasks && cd .. && echo x > tasks.tsv' /q)"
guard_allow "cd ~/proj, then bare .counter" \
  "$(bash_payload 'cd ~/proj && echo 1 > .counter' /p/.tasks)"
guard_allow "Write bare tasks.tsv with cwd outside .tasks" \
  "$(file_payload Write tasks.tsv /p)"
guard_allow "ANSI-C string mentioning > .tasks/.counter" \
  "$(bash_payload "echo \$'a > .tasks/.counter\\n'")"
guard_allow "file_path that is not a string" \
  '{"tool_name":"Write","tool_input":{"file_path":5},"cwd":"/p"}'
guard_allow "command that is not a string" \
  '{"tool_name":"Bash","tool_input":{"command":["echo",">",".tasks/.counter"]},"cwd":"/p"}'
guard_allow "tool_input that is not an object" \
  '{"tool_name":"Bash","tool_input":"echo 1 > .tasks/.counter","cwd":"/p"}'
guard_allow "payload that is not an object"    '[1, 2]'
guard_allow "malformed stdin"                  'not json'
guard_allow "unterminated quote"               "$(bash_payload 'echo "x > .tasks/.counter')"
guard_allow "unrelated tool"                   '{"tool_name":"Read","tool_input":{"file_path":".tasks/tasks.tsv"}}'

# --- summary -----------------------------------------------------------------------

echo "PASS: $PASS  FAIL: $FAIL"
[ "$FAIL" -eq 0 ]
