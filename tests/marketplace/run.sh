#!/bin/bash
# Test harness for the marketplace-wide checks (not a single plugin's scripts,
# so it lives beside tests/plugins/ rather than under it).
#
# check-version-drift.sh — pins the business rules the publication gate rests
# on:
#   - a plugin whose two declarations disagree is reported by name with both
#     versions, and the check exits non-zero
#   - agreeing declarations exit 0, including the real tree of this repository
#   - a plugin declared in only one of the two files is reported the same way
#     as a drift (no version pair means nothing can be compared)
#   - entries are resolved by plugin name, so reordering marketplace.json
#     changes nothing
#   - --rev reads the manifests of that commit, not the working tree
#
# .githooks/pre-push — pins what the gate covers:
#   - a push updating refs/heads/main with drift in the pushed commit is
#     blocked; a matching one is allowed
#   - the pushed commit decides, not the working tree the push runs from
#   - a push of any other branch is never blocked by this check
#   - deleting the remote main publishes nothing, so it is not gated
#   - the gate fails closed: a check that cannot run blocks the push
#
# Usage: bash tests/marketplace/run.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel)"
CHECKER="$REPO_ROOT/scripts/check-version-drift.sh"
PRE_PUSH="$REPO_ROOT/.githooks/pre-push"

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

# Reports "ok" when every needle appears in the haystack, else the first miss.
# Keeps assertions order-independent: only presence is pinned, never position.
has_all() {
  local haystack="$1"; shift
  local needle
  for needle in "$@"; do
    case "$haystack" in
      *"$needle"*) ;;
      *) echo "missing: $needle"; return ;;
    esac
  done
  echo "ok"
}

# --- fixture repository -------------------------------------------------------
# A throwaway marketplace repo: two plugins, the checker, and the hook. Its own
# git dir means commits and pushed-commit reads are exercised for real.

FIX="$WORK_DIR/fixture"

git_fix() {
  git -C "$FIX" -c user.email='t@example.com' -c user.name='t' "$@"
}

write_plugin() { # <name> <version>
  mkdir -p "$FIX/plugins/$1/.claude-plugin"
  cat > "$FIX/plugins/$1/.claude-plugin/plugin.json" <<EOF
{
  "name": "$1",
  "version": "$2",
  "description": "fixture plugin"
}
EOF
}

write_marketplace() { # <name>:<version> ...
  local entries="" spec name version
  for spec in "$@"; do
    name="${spec%%:*}"
    version="${spec##*:}"
    [ -z "$entries" ] || entries="$entries,"
    entries="$entries
    {\"name\": \"$name\", \"source\": \"./plugins/$name\", \"version\": \"$version\"}"
  done
  mkdir -p "$FIX/.claude-plugin"
  cat > "$FIX/.claude-plugin/marketplace.json" <<EOF
{
  "name": "fixture-marketplace",
  "owner": {"name": "t"},
  "plugins": [$entries
  ]
}
EOF
}

for required in "$CHECKER" "$PRE_PUSH"; do
  if [ ! -f "$required" ]; then
    echo "FAIL: missing $required"
    FAIL=$((FAIL + 1))
  fi
done
if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "marketplace: $PASS passed, $FAIL failed"
  exit 1
fi

mkdir -p "$FIX/scripts" "$FIX/.githooks"
git -C "$FIX" init -q
cp "$CHECKER" "$FIX/scripts/check-version-drift.sh"
cp "$PRE_PUSH" "$FIX/.githooks/pre-push"
write_plugin alpha 1.0.0
write_plugin beta 2.1.0
write_marketplace alpha:1.0.0 beta:2.1.0

# --- checker: the working tree ------------------------------------------------

out=$( cd "$FIX" && bash scripts/check-version-drift.sh 2>&1 )
check "agreeing declarations exit 0" 0 $?
check "agreeing run says nothing about drift" ok \
  "$(case "$out" in *drift*) echo "reported: $out" ;; *) echo ok ;; esac)"

write_marketplace alpha:1.1.0 beta:2.1.0
out=$( cd "$FIX" && bash scripts/check-version-drift.sh 2>&1 )
check "drift exits non-zero" 1 $?
check "drift names the plugin and both versions" ok \
  "$(has_all "$out" alpha 1.0.0 1.1.0)"
check "the agreeing plugin is not reported" ok \
  "$(case "$out" in *beta*) echo "reported beta: $out" ;; *) echo ok ;; esac)"

# Reordering the entries must change nothing: entries are resolved by name.
write_marketplace beta:2.1.0 alpha:1.0.0
out=$( cd "$FIX" && bash scripts/check-version-drift.sh 2>&1 )
check "reordered marketplace entries still exit 0" 0 $?

# --- checker: a plugin declared in only one of the two files -------------------

write_marketplace beta:2.1.0
out=$( cd "$FIX" && bash scripts/check-version-drift.sh 2>&1 )
check "plugin directory with no entry exits non-zero" 1 $?
check "plugin directory with no entry is named" ok "$(has_all "$out" alpha 1.0.0)"

write_marketplace alpha:1.0.0 beta:2.1.0 gamma:0.1.0
out=$( cd "$FIX" && bash scripts/check-version-drift.sh 2>&1 )
check "entry with no plugin directory exits non-zero" 1 $?
check "entry with no plugin directory is named" ok "$(has_all "$out" gamma 0.1.0)"

# --- checker: --rev reads the commit, not the working tree ---------------------

write_marketplace alpha:1.0.0 beta:2.1.0
git_fix add -A
git_fix commit -q --no-verify -m 'matching declarations'
MATCHING_SHA=$(git -C "$FIX" rev-parse HEAD)

write_marketplace alpha:9.9.9 beta:2.1.0
out=$( cd "$FIX" && bash scripts/check-version-drift.sh --rev "$MATCHING_SHA" 2>&1 )
check "--rev ignores a drifted working tree" 0 $?
out=$( cd "$FIX" && bash scripts/check-version-drift.sh 2>&1 )
check "the same tree without --rev still reports the drift" 1 $?

git_fix add -A
git_fix commit -q --no-verify -m 'drifted declarations'
DRIFTED_SHA=$(git -C "$FIX" rev-parse HEAD)
out=$( cd "$FIX" && bash scripts/check-version-drift.sh --rev "$DRIFTED_SHA" 2>&1 )
check "--rev reports the drift of that commit" 1 $?
check "--rev drift names the plugin and both versions" ok \
  "$(has_all "$out" alpha 1.0.0 9.9.9)"

out=$( cd "$FIX" && bash scripts/check-version-drift.sh --bad-flag 2>&1 )
check "unknown flag exits 64" 64 $?

# --- checker: the real tree of this repository ---------------------------------

out=$( cd "$REPO_ROOT" && bash "$CHECKER" 2>&1 ); rc=$?
check "every plugin in this repository agrees" 0 "$rc"
[ "$rc" -eq 0 ] || echo "  (checker output: $out)"

# --- pre-push hook ------------------------------------------------------------
# Driven by a stdin line, against the fixture repo — never a real remote.
# stdin format: "<local ref> <local sha> <remote ref> <remote sha>".

ZERO=0000000000000000000000000000000000000000

run_hook() { # <local sha> <remote ref>
  ( cd "$FIX" && echo "refs/heads/main $1 $2 $ZERO" \
      | bash .githooks/pre-push origin https://example.invalid/fixture.git 2>&1 )
}

# The working tree currently holds the drifted state; the pushed commit is what
# must decide, so both directions are exercised from this one tree.
out=$(run_hook "$DRIFTED_SHA" refs/heads/main)
check "push of a drifted commit to main is blocked" 1 $?
check "blocked push reports the drift" ok "$(has_all "$out" FAIL alpha 1.0.0 9.9.9)"

out=$(run_hook "$MATCHING_SHA" refs/heads/main)
check "push of a matching commit to main is allowed" 0 $?
check "allowed push prints no failure banner" ok \
  "$(case "$out" in *FAIL*) echo "reported: $out" ;; *) echo ok ;; esac)"

out=$(run_hook "$DRIFTED_SHA" refs/heads/gnome/5-something)
check "push of a branch other than main is not gated" 0 $?

out=$(run_hook "$ZERO" refs/heads/main)
check "deleting remote main is not gated" 0 $?

out=$( cd "$FIX" && printf '' | bash .githooks/pre-push origin https://example.invalid/f.git 2>&1 )
check "a push with no ref updates is allowed" 0 $?

# --- fail closed --------------------------------------------------------------
# A check that cannot run must never read as "the declarations agree".

BROKEN="$WORK_DIR/broken"
cp -r "$FIX" "$BROKEN"

rm "$BROKEN/.claude-plugin/marketplace.json"
out=$( cd "$BROKEN" && bash scripts/check-version-drift.sh 2>&1 ); rc=$?
check "a tree with no marketplace.json exits non-zero" 1 "$rc"

rm "$BROKEN/scripts/check-version-drift.sh"
out=$( cd "$BROKEN" && echo "refs/heads/main $DRIFTED_SHA refs/heads/main $ZERO" \
        | bash .githooks/pre-push origin https://example.invalid/f.git 2>&1 ); rc=$?
check "hook blocks when the checker script is gone" 1 "$rc"
check "blocked-for-no-checker push says why" ok \
  "$(has_all "$out" FAIL check-version-drift.sh)"

# --- summary ------------------------------------------------------------------

echo ""
echo "marketplace: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
