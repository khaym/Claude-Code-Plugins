#!/bin/bash
# Compares each plugin's version where it is declared twice:
#   plugins/<name>/.claude-plugin/plugin.json  — the plugin's own manifest
#   .claude-plugin/marketplace.json            — the entry users install from
#
# Business rule: when only one of the two moves, publishing still succeeds and
# `claude plugin update` keeps serving the old version, so the change never
# reaches users (observed on checking-oss-release 1.3.0). `claude plugin
# validate` does not compare the pair and `claude plugin tag` is not operated
# here, so this script is the single home of the comparison — .githooks/pre-push
# and tests/marketplace/run.sh both call it instead of reimplementing it.
#
# A plugin declared in only one of the two files is reported like a drift rather
# than warned about: with no version pair there is nothing to compare, so a
# warning would silently exempt that plugin from the one check this script
# exists for.
#
# Plugin directories and marketplace entries pair up by plugin name — the name
# users install by — never by array position, which rebases and re-orderings
# move around.
#
# Usage:
#   check-version-drift.sh                # the manifests in the working tree
#   check-version-drift.sh --rev <commit> # the manifests as of <commit>
#
# Exit 0 = every declaration agrees, 1 = at least one drift, 64 = usage error.

set -uo pipefail

MARKETPLACE=".claude-plugin/marketplace.json"

usage() {
  echo "usage: check-version-drift.sh [--rev <commit>]" >&2
}

REV=""
while [ $# -gt 0 ]; do
  case "$1" in
    --rev)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        echo "check-version-drift: --rev needs a commit" >&2
        usage
        exit 64
      fi
      REV="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "check-version-drift: unknown argument: $1" >&2
      usage
      exit 64
      ;;
  esac
done

if ! command -v jq > /dev/null 2>&1; then
  echo "check-version-drift: jq is required" >&2
  exit 64
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || ROOT=""
if [ -z "$ROOT" ] || ! cd "$ROOT"; then
  echo "check-version-drift: not inside a git repository" >&2
  exit 64
fi

if [ -n "$REV" ] && ! git rev-parse --verify --quiet "$REV^{commit}" > /dev/null; then
  echo "check-version-drift: no such commit: $REV" >&2
  exit 64
fi

# Reads a repository-relative path from the working tree, or from --rev's commit.
read_manifest() {
  if [ -n "$REV" ]; then
    git show "$REV:$1" 2>/dev/null
  else
    cat "$1" 2>/dev/null
  fi
}

# Lists the repository-relative plugin manifests, sorted, so the report order
# does not depend on directory iteration order.
list_plugin_manifests() {
  if [ -n "$REV" ]; then
    git ls-tree -r --name-only "$REV" -- plugins 2>/dev/null \
      | grep -E '^plugins/[^/]+/\.claude-plugin/plugin\.json$'
  else
    find plugins -type f -path 'plugins/*/.claude-plugin/plugin.json' 2>/dev/null | sort
  fi
}

version_of() { # <json> -> the declared version, empty when absent
  printf '%s' "$1" | jq -r '.version // empty' 2>/dev/null
}

WHERE=${REV:+ at $REV}

marketplace_json=$(read_manifest "$MARKETPLACE")
if [ -z "$marketplace_json" ]; then
  echo "check-version-drift: $MARKETPLACE is missing or empty$WHERE" >&2
  exit 1
fi

# name<TAB>version for every marketplace entry, in the file's own order.
entries=$(printf '%s' "$marketplace_json" \
  | jq -r '.plugins[] | "\(.name)\t\(.version // "")"' 2>/dev/null)
if [ -z "$entries" ]; then
  echo "check-version-drift: $MARKETPLACE declares no plugins$WHERE" >&2
  exit 1
fi

entry_version_of() { # <plugin name> -> its marketplace version, empty when absent
  printf '%s\n' "$entries" | awk -F'\t' -v name="$1" '$1 == name { print $2; exit }'
}

drifted=0
compared=0
paired=""

while IFS= read -r manifest; do
  [ -n "$manifest" ] || continue
  name=${manifest#plugins/}
  name=${name%%/*}
  paired="$paired $name"

  declared=$(version_of "$(read_manifest "$manifest")")
  entry=$(entry_version_of "$name")

  if [ -z "$entry" ]; then
    echo "version drift: $name declares ${declared:-no version} in $manifest, no entry in $MARKETPLACE"
    drifted=$((drifted + 1))
    continue
  fi
  if [ "$declared" != "$entry" ]; then
    echo "version drift: $name declares ${declared:-no version} in $manifest, $entry in $MARKETPLACE"
    drifted=$((drifted + 1))
    continue
  fi
  compared=$((compared + 1))
done <<< "$(list_plugin_manifests)"

while IFS=$'\t' read -r name entry; do
  [ -n "$name" ] || continue
  case " $paired " in
    *" $name "*) continue ;;
  esac
  echo "version drift: $name declares ${entry:-no version} in $MARKETPLACE, no plugins/$name/.claude-plugin/plugin.json"
  drifted=$((drifted + 1))
done <<< "$entries"

if [ "$drifted" -gt 0 ]; then
  echo "$drifted plugin(s) declare a different version in the two manifests$WHERE."
  exit 1
fi

echo "version declarations agree for $compared plugin(s)$WHERE."
exit 0
