#!/bin/bash
# statusLine renderer: prints this session's pending decisions, one row each.
#
# Register once against the stable symlink the SessionStart hook maintains
# (~/.claude/decision-queue/statusline.sh) — never against the versioned
# plugin cache path, which changes on every plugin update.
#
# Renders nothing while the queue is empty or absent, so the statusline
# stays silent instead of pinning a dead header row.

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
case "$sid" in
  *[!0-9a-fA-F-]*|"") exit 0 ;;
esac

qfile="$HOME/.claude/decision-queue/$sid.md"
[ -r "$qfile" ] || exit 0

# Single byte-mode pass: strip control bytes (a hostile item must not replay
# escape sequences into the terminal on every refresh), skip blank lines,
# and print the header only when at least one item survives. LC_ALL=C keeps
# a stray non-UTF-8 byte in one item from suppressing the whole listing.
LC_ALL=C awk '
  { gsub(/[\001-\010\013-\037\177]/, "") }
  /^[[:space:]]*$/ { next }
  { rows[++n] = $0 }
  END {
    if (n == 0) exit
    printf "\033[33m◆ pending decisions: %d\033[0m\n", n
    for (i = 1; i <= n; i++) print rows[i]
  }
' "$qfile"
