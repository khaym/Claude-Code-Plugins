#!/usr/bin/env bash
set -euo pipefail

# task-tracker: Lightweight TSV-based task manager
# Usage: task.sh <command> [options]

TASKS_DIR=".tasks"
TSV_FILE="$TASKS_DIR/tasks.tsv"
DETAILS_DIR="$TASKS_DIR/details"
COUNTER_FILE="$TASKS_DIR/.counter"
TSV_HEADER="ID\tSTATUS\tCATEGORY\tSUBJECT\tCREATED\tUPDATED"

# ── Helpers ──────────────────────────────────────────────────

die() { echo "Error: $*" >&2; exit 1; }

now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

ensure_init() {
  if [[ ! -f "$TSV_FILE" ]]; then
    cmd_init
  fi
}

next_id() {
  local current=0
  if [[ -f "$COUNTER_FILE" ]]; then
    current=$(cat "$COUNTER_FILE")
  fi
  local next=$((current + 1))
  echo "$next" > "$COUNTER_FILE"
  echo "$next"
}

find_line() {
  local id="$1"
  awk -F'\t' -v id="$id" 'NR>1 && $1 == id { print NR; found=1 } END { if (!found) exit 1 }' "$TSV_FILE"
}

get_field() {
  local id="$1" field="$2"
  case "$field" in
    id)       col=1 ;;
    status)   col=2 ;;
    category) col=3 ;;
    subject)  col=4 ;;
    created)  col=5 ;;
    updated)  col=6 ;;
    *) die "Unknown field: $field" ;;
  esac
  awk -F'\t' -v id="$id" -v col="$col" 'NR>1 && $1 == id { print $col }' "$TSV_FILE"
}

update_field() {
  local line="$1" col="$2" value="$3"
  awk -F'\t' -v OFS='\t' -v line="$line" -v col="$col" -v val="$value" \
    'NR == line { $col = val } { print }' "$TSV_FILE" > "$TSV_FILE.tmp"
  mv "$TSV_FILE.tmp" "$TSV_FILE"
}

# ── Commands ─────────────────────────────────────────────────

cmd_init() {
  if [[ -f "$TSV_FILE" ]]; then
    echo "Already initialized: $TSV_FILE"
    return 0
  fi
  mkdir -p "$DETAILS_DIR"
  printf '%b\n' "$TSV_HEADER" > "$TSV_FILE"
  echo "0" > "$COUNTER_FILE"

  # Add .tasks to .gitignore if not already present
  if [[ -f .gitignore ]]; then
    grep -qxF '.tasks' .gitignore || echo '.tasks' >> .gitignore
  else
    echo '.tasks' > .gitignore
  fi

  echo "Initialized task tracker in $TASKS_DIR/"
}

cmd_add() {
  local subject="" category="task" details=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -s|--subject) subject="$2"; shift 2 ;;
      -c|--category) category="$2"; shift 2 ;;
      -d|--details) details="$2"; shift 2 ;;
      *) die "Unknown option: $1" ;;
    esac
  done
  [[ -z "$subject" ]] && die "Subject is required: task.sh add -s \"Subject\""

  ensure_init
  local id
  id=$(next_id)
  local ts
  ts=$(now)

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "open" "$category" "$subject" "$ts" "$ts" >> "$TSV_FILE"

  if [[ -n "$details" ]]; then
    mkdir -p "$DETAILS_DIR"
    echo "$details" > "$DETAILS_DIR/$id.md"
  fi

  echo "Created task #$id: $subject"
}

cmd_list() {
  local status_filter="open" category_filter=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --status) status_filter="$2"; shift 2 ;;
      --category) category_filter="$2"; shift 2 ;;
      *) die "Unknown option: $1" ;;
    esac
  done

  ensure_init

  # Build awk filter
  local awk_filter='NR > 1'
  if [[ "$status_filter" != "all" ]]; then
    awk_filter="$awk_filter && \$2 == \"$status_filter\""
  fi
  if [[ -n "$category_filter" ]]; then
    awk_filter="$awk_filter && \$3 == \"$category_filter\""
  fi

  local count
  count=$(awk -F'\t' "$awk_filter { count++ } END { print count+0 }" "$TSV_FILE")

  if [[ "$count" -eq 0 ]]; then
    echo "No tasks found (filter: status=$status_filter${category_filter:+, category=$category_filter})"
    return 0
  fi

  # Print header and matching rows as a table
  printf '%-4s  %-8s  %-12s  %s\n' "ID" "STATUS" "CATEGORY" "SUBJECT"
  printf '%-4s  %-8s  %-12s  %s\n' "----" "--------" "------------" "-------"
  awk -F'\t' "$awk_filter"' { printf "%-4s  %-8s  %-12s  %s\n", $1, $2, $3, $4 }' "$TSV_FILE"
  echo ""
  echo "Total: $count task(s)"
}

cmd_show() {
  local id="${1:-}"
  [[ -z "$id" ]] && die "Usage: task.sh show <id>"

  ensure_init
  find_line "$id" > /dev/null 2>&1 || die "Task #$id not found"

  echo "── Task #$id ──"
  echo "Subject:  $(get_field "$id" subject)"
  echo "Status:   $(get_field "$id" status)"
  echo "Category: $(get_field "$id" category)"
  echo "Created:  $(get_field "$id" created)"
  echo "Updated:  $(get_field "$id" updated)"

  if [[ -f "$DETAILS_DIR/$id.md" ]]; then
    echo ""
    echo "── Details ──"
    cat "$DETAILS_DIR/$id.md"
  fi
}

cmd_update() {
  local id="${1:-}"
  [[ -z "$id" ]] && die "Usage: task.sh update <id> [-s subject] [-c category] [--status status] [-d details]"
  shift

  ensure_init
  local line
  line=$(find_line "$id") || die "Task #$id not found"

  local updated=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -s|--subject) update_field "$line" 4 "$2"; updated=true; shift 2 ;;
      -c|--category) update_field "$line" 3 "$2"; updated=true; shift 2 ;;
      --status) update_field "$line" 2 "$2"; updated=true; shift 2 ;;
      -d|--details)
        mkdir -p "$DETAILS_DIR"
        echo "$2" > "$DETAILS_DIR/$id.md"
        updated=true; shift 2
        ;;
      *) die "Unknown option: $1" ;;
    esac
    # Re-read line number after each field update (line number doesn't change, but file was rewritten)
    line=$(find_line "$id") || die "Task #$id not found after update"
  done

  if $updated; then
    update_field "$line" 6 "$(now)"
    echo "Updated task #$id"
  else
    die "No fields specified to update"
  fi
}

cmd_close() {
  local id="${1:-}"
  [[ -z "$id" ]] && die "Usage: task.sh close <id> [-d comment]"
  shift

  ensure_init
  local line
  line=$(find_line "$id") || die "Task #$id not found"

  local current_status
  current_status=$(get_field "$id" status)
  [[ "$current_status" == "closed" ]] && die "Task #$id is already closed"

  update_field "$line" 2 "closed"
  line=$(find_line "$id")
  update_field "$line" 6 "$(now)"

  # Append closing comment if provided
  local details=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--details) details="$2"; shift 2 ;;
      *) die "Unknown option: $1" ;;
    esac
  done

  if [[ -n "$details" ]]; then
    mkdir -p "$DETAILS_DIR"
    if [[ -f "$DETAILS_DIR/$id.md" ]]; then
      printf '\n---\n**Closed:** %s\n' "$details" >> "$DETAILS_DIR/$id.md"
    else
      printf '**Closed:** %s\n' "$details" > "$DETAILS_DIR/$id.md"
    fi
  fi

  echo "Closed task #$id"
}

cmd_delete() {
  local id="${1:-}"
  [[ -z "$id" ]] && die "Usage: task.sh delete <id>"

  ensure_init
  find_line "$id" > /dev/null 2>&1 || die "Task #$id not found"

  awk -F'\t' -v id="$id" 'NR == 1 || $1 != id' "$TSV_FILE" > "$TSV_FILE.tmp"
  mv "$TSV_FILE.tmp" "$TSV_FILE"

  rm -f "$DETAILS_DIR/$id.md"

  echo "Deleted task #$id"
}

# ── Main ─────────────────────────────────────────────────────

cmd="${1:-}"
shift || true

case "$cmd" in
  init)   cmd_init "$@" ;;
  add)    cmd_add "$@" ;;
  list)   cmd_list "$@" ;;
  show)   cmd_show "$@" ;;
  update) cmd_update "$@" ;;
  close)  cmd_close "$@" ;;
  delete) cmd_delete "$@" ;;
  ""|help|-h|--help)
    cat <<'USAGE'
task-tracker: Lightweight TSV-based task manager

Usage: task.sh <command> [options]

Commands:
  init                          Initialize .tasks/ directory
  add -s "Subject" [-c cat] [-d "Details"]
                                Add a new task
  list [--status open|closed|all] [--category cat]
                                List tasks (default: open)
  show <id>                     Show task details
  update <id> [-s subject] [-c cat] [--status status] [-d details]
                                Update task fields
  close <id> [-d "Comment"]     Close a task
  delete <id>                   Delete a task
USAGE
    ;;
  *) die "Unknown command: $cmd (try 'task.sh help')" ;;
esac
