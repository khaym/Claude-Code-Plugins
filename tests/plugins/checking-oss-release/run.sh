#!/bin/bash
# Test harness for pre-commit.sh secret detection.
#
# Fixture files under secrets/ are stored as templates: the marker `{{X}}`
# is inserted within each vendor prefix to keep literal token formats out of
# the repository (so GitHub secret scanning and push protection do not flag
# them). At test time we strip `{{X}}` to materialize realistic-looking
# values into a temp directory, then scan those.
#
# Usage: bash tests/plugins/checking-oss-release/run.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel)"
PRE_COMMIT="$REPO_ROOT/plugins/checking-oss-release/agents/oss-checker/pre-commit.sh"
SECRETS_DIR="$SCRIPT_DIR/secrets"

# shellcheck source=/dev/null
source "$PRE_COMMIT"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

# Mirror the fixture tree into $WORK_DIR with `{{X}}` markers stripped.
materialize_fixtures() {
  local src dst
  while IFS= read -r src; do
    dst="$WORK_DIR/${src#"$SECRETS_DIR/"}"
    mkdir -p "$(dirname "$dst")"
    sed 's/{{X}}//g' "$src" > "$dst"
  done < <(find "$SECRETS_DIR" -type f)
}

materialize_fixtures
DETECT="$WORK_DIR/detect/secrets.txt"
NOMATCH="$WORK_DIR/nomatch/placeholders.txt"
PRAGMA_INLINE_FILE="$WORK_DIR/pragma/inline.txt"
PRAGMA_NEXT_FILE="$WORK_DIR/pragma/next_line.txt"

PASS=0
FAIL=0

assert_count() {
  local label="$1" expected="$2" actual="$3"
  if [ "$actual" -eq "$expected" ]; then
    echo "PASS  $label  (findings=$actual)"
    PASS=$((PASS + 1))
  else
    echo "FAIL  $label  expected=$expected actual=$actual"
    FAIL=$((FAIL + 1))
  fi
}

scan_count() {
  local file="$1"
  FINDINGS=()
  scan_files "$file"
  echo "${#FINDINGS[@]}"
}

scan_count_at_least() {
  local label="$1" min="$2" file="$3"
  FINDINGS=()
  scan_files "$file"
  local actual=${#FINDINGS[@]}
  if [ "$actual" -ge "$min" ]; then
    echo "PASS  $label  (findings=$actual >= $min)"
    PASS=$((PASS + 1))
  else
    echo "FAIL  $label  expected >= $min, got $actual"
    printf '  - %s\n' "${FINDINGS[@]}"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Detection (pragma disabled) ==="
expected_detect=$(grep -cvE '^\s*(#|$)' "$DETECT")
OSS_CHECKER_NO_PRAGMA=1 scan_count_at_least \
  "detect/secrets.txt yields at least one finding per non-comment line" \
  "$expected_detect" \
  "$DETECT"

echo ""
echo "=== Negative cases (pragma disabled) ==="
OSS_CHECKER_NO_PRAGMA=1 assert_count \
  "nomatch/placeholders.txt yields no findings" 0 \
  "$(scan_count "$NOMATCH")"
unset OSS_CHECKER_NO_PRAGMA

echo ""
echo "=== Pragma silences findings (pragma enabled) ==="
assert_count "pragma/inline.txt is fully allowlisted" 0 \
  "$(scan_count "$PRAGMA_INLINE_FILE")"
assert_count "pragma/next_line.txt is fully allowlisted" 0 \
  "$(scan_count "$PRAGMA_NEXT_FILE")"
assert_count "detect/secrets.txt is fully allowlisted via inline pragma" 0 \
  "$(scan_count "$DETECT")"

echo ""
echo "=== Sanity: stored fixtures contain no literal token formats ==="
# scan_files against the on-disk template; we expect zero findings, proving
# the {{X}} markers successfully break every pattern.
OSS_CHECKER_NO_PRAGMA=1 assert_count \
  "stored detect/secrets.txt template yields no findings (markers intact)" 0 \
  "$(scan_count "$SECRETS_DIR/detect/secrets.txt")"
unset OSS_CHECKER_NO_PRAGMA

echo ""
echo "=== Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
[ "$FAIL" -eq 0 ]
