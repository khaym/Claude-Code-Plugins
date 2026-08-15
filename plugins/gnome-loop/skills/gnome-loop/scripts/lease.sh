#!/bin/bash
# lease.sh — session exclusion for the gnome loop.
#
# One loop session at a time: the lease is a directory (mkdir is the atomic
# acquire) holding a `holder` file — line 1 the session id, line 2 the
# acquisition time (ISO 8601, UTC). The holder file's mtime is the heartbeat.
#
# Usage:
#   lease.sh acquire   <lease-dir> <session-id> [--stale-minutes N]
#   lease.sh heartbeat <lease-dir> <session-id>
#   lease.sh release   <lease-dir> <session-id> [--force]
#   lease.sh status    <lease-dir> <session-id> [--stale-minutes N]
#
# Exit codes (caller actions live in the gnome-loop SKILL.md lease table):
#   0  done / lease is ours (acquire is idempotent for the same id;
#      release of a lease nobody holds is a no-op)
#   2  held by another session, heartbeat fresh
#   3  held by another session, heartbeat older than the stale threshold
#   4  lease lost (heartbeat found no lease)
#   64 usage error
#
# On exit 2 and 3 the holder's two lines are printed to stdout so the caller
# can show who holds the lease and since when. `status` prints one of
# mine | other-fresh | other-stale | none on line 1, then the holder lines.

set -u

STALE_MINUTES=90

usage() { echo "usage: lease.sh <acquire|heartbeat|release|status> <lease-dir> <session-id> [--stale-minutes N] [--force]" >&2; exit 64; }

[ $# -ge 3 ] || usage
CMD="$1"; DIR="$2"; ID="$3"; shift 3

FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --stale-minutes) [ $# -ge 2 ] || usage; STALE_MINUTES="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    *) usage ;;
  esac
done

HOLDER="$DIR/holder"

holder_id() { head -1 "$HOLDER" 2>/dev/null; }

is_stale() {
  # true when the holder's last heartbeat is older than the threshold
  local mtime now
  mtime=$(stat -c %Y "$HOLDER" 2>/dev/null) || return 1
  now=$(date +%s)
  [ $((now - mtime)) -gt $((STALE_MINUTES * 60)) ]
}

report_holder() { cat "$HOLDER" 2>/dev/null; }

case "$CMD" in
  acquire)
    if mkdir "$DIR" 2>/dev/null; then
      printf '%s\n%s\n' "$ID" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$HOLDER"
      exit 0
    fi
    if [ "$(holder_id)" = "$ID" ]; then
      touch "$HOLDER"
      exit 0
    fi
    report_holder
    if is_stale; then exit 3; else exit 2; fi
    ;;
  heartbeat)
    [ -f "$HOLDER" ] || exit 4
    if [ "$(holder_id)" = "$ID" ]; then
      touch "$HOLDER"
      exit 0
    fi
    report_holder
    exit 2
    ;;
  release)
    [ -d "$DIR" ] || exit 0
    if [ "$FORCE" -eq 1 ] || [ "$(holder_id)" = "$ID" ]; then
      rm -rf "$DIR"
      exit 0
    fi
    report_holder
    exit 2
    ;;
  status)
    if [ ! -d "$DIR" ]; then echo "none"; exit 0; fi
    if [ "$(holder_id)" = "$ID" ]; then
      echo "mine"
    elif is_stale; then
      echo "other-stale"
    else
      echo "other-fresh"
    fi
    report_holder
    exit 0
    ;;
  *) usage ;;
esac
