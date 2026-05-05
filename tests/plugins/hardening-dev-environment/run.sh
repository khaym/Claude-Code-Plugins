#!/bin/bash
# Test harness for hardening-dev-environment runtime hooks.
#
# Drives each hook script as a subprocess, feeding a JSON payload on stdin
# and asserting on its decision. Four hooks are exercised:
#
#   - sensitive-bash-guard.py        PreToolUse on Bash;  silent allow / JSON deny
#   - package-json-scripts-guard     PreToolUse on Edit/Write of package.json
#   - pyproject-buildsystem-guard    PreToolUse on Edit/Write of pyproject.toml & setup.py
#   - untrusted-content-reminder     PostToolUse on WebFetch; silent / additionalContext
#
# package.json and pyproject.toml / setup.py tests need a real file at the
# path the hook will open(), so a temp workspace is materialized per-test.
# The reminder hook collects `WebFetch(domain:...)` allowlist entries from
# $CWD/.claude/settings.json and $HOME/.claude/settings.json, so its tests
# pin both via subshell.
#
# Usage: bash tests/plugins/hardening-dev-environment/run.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel)"
HOOKS_DIR="$REPO_ROOT/plugins/hardening-dev-environment/hooks/scripts"
SENS_BASH="$HOOKS_DIR/sensitive-bash-guard.py"
PKG_GUARD="$HOOKS_DIR/package-json-scripts-guard.py"
PYBS_GUARD="$HOOKS_DIR/pyproject-buildsystem-guard.py"
UNTRUSTED="$HOOKS_DIR/untrusted-content-reminder.py"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

PASS=0
FAIL=0

# --- assertions -------------------------------------------------------------

# usage: assert_silent <label> <stdout>
assert_silent() {
  local label="$1" out="$2"
  if [ -z "$out" ]; then
    echo "PASS  $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL  $label  expected silent allow, got: $out"
    FAIL=$((FAIL + 1))
  fi
}

# usage: assert_deny <label> <stdout>
assert_deny() {
  local label="$1" out="$2"
  if echo "$out" | grep -q '"permissionDecision": *"deny"'; then
    echo "PASS  $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL  $label  expected deny decision, got: $out"
    FAIL=$((FAIL + 1))
  fi
}

# usage: assert_reminder <label> <stdout>
assert_reminder() {
  local label="$1" out="$2"
  if echo "$out" | grep -q '"additionalContext"' \
      && echo "$out" | grep -q 'hardening-untrusted-content'; then
    echo "PASS  $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL  $label  expected reminder, got: $out"
    FAIL=$((FAIL + 1))
  fi
}

# --- sensitive-bash-guard ---------------------------------------------------

run_bash_guard() {
  local cmd="$1"
  printf '{"tool_name":"Bash","tool_input":{"command":%s}}' \
    "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$cmd")" \
    | python3 "$SENS_BASH"
}

bash_deny() {
  local label="$1" cmd="$2"
  assert_deny "bash-guard: $label" "$(run_bash_guard "$cmd")"
}

bash_allow() {
  local label="$1" cmd="$2"
  assert_silent "bash-guard: $label" "$(run_bash_guard "$cmd")"
}

echo "=== sensitive-bash-guard: deny on credential reads ==="
bash_deny "cat ~/.aws/credentials"          'cat ~/.aws/credentials'
bash_deny "grep AKIA in ~/.aws"             'grep -r AKIA ~/.aws'
bash_deny "find ~/.ssh"                     'find ~/.ssh -type f'
bash_deny "cat .env"                        'cat .env'
bash_deny "head .env.local"                 'head .env.local'
bash_deny "tail .envrc"                     'tail .envrc'
bash_deny "cat \$HOME/.ssh/id_rsa"          'cat $HOME/.ssh/id_rsa'
bash_deny "cat /home/user/.netrc"           'cat /home/user/.netrc'
bash_deny "cat /Users/x/.aws/config"        'cat /Users/x/.aws/config'
bash_deny "cat ~/.kube/config"              'cat ~/.kube/config'
bash_deny "cat ~/.docker/config.json"       'cat ~/.docker/config.json'
bash_deny "cat ~/.npmrc"                    'cat ~/.npmrc'
bash_deny "base64 ~/.ssh/id_rsa"            'base64 ~/.ssh/id_rsa'
bash_deny "xxd ~/.gnupg/secring"            'xxd ~/.gnupg/secring.gpg'

echo ""
echo "=== sensitive-bash-guard: deny through wrappers ==="
bash_deny "sudo cat ~/.aws/credentials"     'sudo cat ~/.aws/credentials'
bash_deny "timeout 30 cat ~/.aws/creds"     'timeout 30 cat ~/.aws/credentials'
bash_deny "nice -n 5 cat ~/.netrc"          'nice -n 5 cat ~/.netrc'
bash_deny "env FOO=1 cat ~/.aws/creds"      'env cat ~/.aws/credentials'

echo ""
echo "=== sensitive-bash-guard: deny in compound commands ==="
bash_deny "ls && cat ~/.aws/credentials"    'ls && cat ~/.aws/credentials'
bash_deny "ls; cat ~/.netrc"                'ls; cat ~/.netrc'
bash_deny "ls || cat ~/.ssh/id_rsa"         'ls || cat ~/.ssh/id_rsa'
bash_deny "ls | cat ~/.aws/credentials"     'ls | cat ~/.aws/credentials'

echo ""
echo "=== sensitive-bash-guard: allow on safe commands ==="
bash_allow "cat README.md"                  'cat README.md'
bash_allow "cat package.json"               'cat package.json'
bash_allow "ls -la"                         'ls -la'
bash_allow "rm -rf node_modules"            'rm -rf node_modules'
# .envoy.yaml must NOT match .env regex (negative lookahead on \w)
bash_allow "cat .envoy.yaml (lookahead)"    'cat .envoy.yaml'
# ~/.aws_notes must NOT match ~/.aws regex (negative lookahead on \w)
bash_allow "cat ~/.aws_notes (lookahead)"   'cat ~/.aws_notes'
# write commands are out of scope for this hook even on credential paths
bash_allow "echo > ~/.aws/credentials"      'echo "x" > ~/.aws/credentials'
bash_allow "git status"                     'git status'

echo ""

# --- package-json-scripts-guard --------------------------------------------

PKG_DIR="$WORK_DIR/pkg"
mkdir -p "$PKG_DIR"
PKG_FILE="$PKG_DIR/package.json"

write_pkg() {
  printf '%s\n' "$1" > "$PKG_FILE"
}

run_pkg_guard_edit() {
  local old="$1" new="$2"
  python3 -c '
import json, sys
print(json.dumps({
    "tool_name": "Edit",
    "tool_input": {
        "file_path": sys.argv[1],
        "old_string": sys.argv[2],
        "new_string": sys.argv[3],
    },
}))' "$PKG_FILE" "$old" "$new" | python3 "$PKG_GUARD"
}

run_pkg_guard_write() {
  local content="$1"
  python3 -c '
import json, sys
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]},
}))' "$PKG_FILE" "$content" | python3 "$PKG_GUARD"
}

echo "=== package-json-scripts-guard: deny scripts modification ==="

# Add a postinstall script via Edit
write_pkg '{"name":"x","scripts":{"test":"jest"}}'
out=$(run_pkg_guard_edit \
  '"scripts":{"test":"jest"}' \
  '"scripts":{"test":"jest","postinstall":"node x.js"}')
assert_deny "pkg-guard: add postinstall via Edit" "$out"

# Modify an existing script via Edit
write_pkg '{"name":"x","scripts":{"test":"jest"}}'
out=$(run_pkg_guard_edit '"test":"jest"' '"test":"jest && node x.js"')
assert_deny "pkg-guard: modify existing script via Edit" "$out"

# Remove a script via Edit
write_pkg '{"name":"x","scripts":{"test":"jest","build":"tsc"}}'
out=$(run_pkg_guard_edit \
  '"scripts":{"test":"jest","build":"tsc"}' \
  '"scripts":{"build":"tsc"}')
assert_deny "pkg-guard: remove script via Edit" "$out"

# Replace whole file via Write, introducing scripts
write_pkg '{"name":"x","scripts":{"test":"jest"}}'
out=$(run_pkg_guard_write \
  '{"name":"x","scripts":{"test":"jest","postinstall":"node x.js"}}')
assert_deny "pkg-guard: introduce postinstall via Write" "$out"

echo ""
echo "=== package-json-scripts-guard: allow non-scripts changes ==="

# Edit a non-scripts field
write_pkg '{"name":"x","version":"1.0.0","scripts":{"test":"jest"}}'
out=$(run_pkg_guard_edit '"version":"1.0.0"' '"version":"1.0.1"')
assert_silent "pkg-guard: bump version via Edit" "$out"

# Add a dependency (no scripts diff)
write_pkg '{"name":"x","scripts":{"test":"jest"},"dependencies":{}}'
out=$(run_pkg_guard_edit '"dependencies":{}' '"dependencies":{"lodash":"^4"}')
assert_silent "pkg-guard: add dependency via Edit" "$out"

# Write same scripts back (no diff)
write_pkg '{"name":"x","scripts":{"test":"jest"}}'
out=$(run_pkg_guard_write '{"name":"x","scripts":{"test":"jest"}}')
assert_silent "pkg-guard: rewrite identical scripts via Write" "$out"

# Edit on a non-package.json file: hook is matcher-scoped, but defensively allow
NONPKG="$PKG_DIR/other.json"
echo '{"foo":1}' > "$NONPKG"
out=$(python3 -c '
import json, sys
print(json.dumps({
    "tool_name": "Edit",
    "tool_input": {
        "file_path": sys.argv[1],
        "old_string": "1",
        "new_string": "2",
    },
}))' "$NONPKG" | python3 "$PKG_GUARD")
assert_silent "pkg-guard: ignores non-package.json files" "$out"

# New file (no existing content): allow per spec
NEWPKG="$PKG_DIR/new/package.json"
mkdir -p "$(dirname "$NEWPKG")"
out=$(python3 -c '
import json, sys
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]},
}))' "$NEWPKG" '{"name":"new","scripts":{"postinstall":"x"}}' \
  | python3 "$PKG_GUARD")
assert_silent "pkg-guard: new file creation is allowed" "$out"

echo ""

# --- pyproject-buildsystem-guard -------------------------------------------

PY_DIR="$WORK_DIR/py"
mkdir -p "$PY_DIR"
PYPROJECT="$PY_DIR/pyproject.toml"
SETUP_PY="$PY_DIR/setup.py"

write_pyproject() {
  printf '%s\n' "$1" > "$PYPROJECT"
}

write_setup() {
  printf '%s\n' "$1" > "$SETUP_PY"
}

run_pybs_edit() {
  local target="$1" old="$2" new="$3"
  python3 -c '
import json, sys
print(json.dumps({
    "tool_name": "Edit",
    "tool_input": {
        "file_path": sys.argv[1],
        "old_string": sys.argv[2],
        "new_string": sys.argv[3],
    },
}))' "$target" "$old" "$new" | python3 "$PYBS_GUARD"
}

run_pybs_write() {
  local target="$1" content="$2"
  python3 -c '
import json, sys
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]},
}))' "$target" "$content" | python3 "$PYBS_GUARD"
}

PYPROJ_BASE='[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "demo"
version = "0.1.0"

[tool.uv]
exclude-newer = "P3D"
'

echo "=== pyproject-buildsystem-guard: deny [build-system] modification ==="

# Modify build-backend value via Edit
write_pyproject "$PYPROJ_BASE"
out=$(run_pybs_edit "$PYPROJECT" \
  'build-backend = "hatchling.build"' \
  'build-backend = "evil.backend"')
assert_deny "pybs-guard: change build-backend via Edit" "$out"

# Add a requires entry via Edit
write_pyproject "$PYPROJ_BASE"
out=$(run_pybs_edit "$PYPROJECT" \
  'requires = ["hatchling"]' \
  'requires = ["hatchling", "evil-plugin"]')
assert_deny "pybs-guard: add requires entry via Edit" "$out"

# Replace whole file via Write, mutating [build-system]
write_pyproject "$PYPROJ_BASE"
out=$(run_pybs_write "$PYPROJECT" '[build-system]
requires = ["hatchling", "evil-plugin"]
build-backend = "hatchling.build"

[project]
name = "demo"
version = "0.1.0"
')
assert_deny "pybs-guard: mutate [build-system] via Write" "$out"

# Sub-table [build-system.<x>] modification
write_pyproject '[build-system]
requires = ["setuptools"]
build-backend = "setuptools.build_meta"

[build-system.config]
backend-path = ["./_build"]

[project]
name = "demo"
'
out=$(run_pybs_edit "$PYPROJECT" \
  'backend-path = ["./_build"]' \
  'backend-path = ["./_build", "./evil"]')
assert_deny "pybs-guard: mutate [build-system.config] sub-table" "$out"

echo ""
echo "=== pyproject-buildsystem-guard: allow non-[build-system] changes ==="

# Edit [project] field
write_pyproject "$PYPROJ_BASE"
out=$(run_pybs_edit "$PYPROJECT" 'version = "0.1.0"' 'version = "0.1.1"')
assert_silent "pybs-guard: bump project.version via Edit" "$out"

# Edit [tool.uv] field — this is the whole reason the hook is section-scoped
write_pyproject "$PYPROJ_BASE"
out=$(run_pybs_edit "$PYPROJECT" \
  'exclude-newer = "P3D"' \
  'exclude-newer = "P7D"')
assert_silent "pybs-guard: bump tool.uv.exclude-newer via Edit" "$out"

# Add [project.dependencies]
write_pyproject "$PYPROJ_BASE"
out=$(run_pybs_edit "$PYPROJECT" \
  'name = "demo"' \
  'name = "demo"
dependencies = ["requests"]')
assert_silent "pybs-guard: add project.dependencies via Edit" "$out"

# Rewrite identical [build-system] via Write
write_pyproject "$PYPROJ_BASE"
out=$(run_pybs_write "$PYPROJECT" "$PYPROJ_BASE")
assert_silent "pybs-guard: identical Write is allowed" "$out"

# New pyproject.toml (no existing file): allow per spec
NEWPY="$PY_DIR/new/pyproject.toml"
mkdir -p "$(dirname "$NEWPY")"
out=$(run_pybs_write "$NEWPY" "$PYPROJ_BASE")
assert_silent "pybs-guard: new pyproject.toml is allowed" "$out"

# Pyproject without [build-system]: editing other tables still allowed
write_pyproject '[project]
name = "demo"
version = "0.1.0"

[tool.uv]
exclude-newer = "P3D"
'
out=$(run_pybs_edit "$PYPROJECT" 'version = "0.1.0"' 'version = "0.1.1"')
assert_silent "pybs-guard: file with no [build-system] is allowed" "$out"

echo ""
echo "=== pyproject-buildsystem-guard: setup.py is fully sensitive ==="

# Any modification to setup.py blocks
write_setup 'from setuptools import setup
setup(name="demo", version="0.1.0")
'
out=$(run_pybs_edit "$SETUP_PY" 'version="0.1.0"' 'version="0.1.1"')
assert_deny "pybs-guard: any setup.py Edit blocks" "$out"

# Write replacing setup.py blocks
write_setup 'from setuptools import setup
setup(name="demo")
'
out=$(run_pybs_write "$SETUP_PY" 'from setuptools import setup
setup(name="demo", install_requires=["evil"])
')
assert_deny "pybs-guard: setup.py Write blocks" "$out"

# Identical Write is a no-op — allow. Uses printf '%s' (no appended newline)
# so file bytes and Write payload match exactly.
SETUP_IDENTICAL='from setuptools import setup
setup(name="demo")
'
printf '%s' "$SETUP_IDENTICAL" > "$SETUP_PY"
out=$(run_pybs_write "$SETUP_PY" "$SETUP_IDENTICAL")
assert_silent "pybs-guard: setup.py identical Write is allowed" "$out"

# New setup.py (no existing file): allow per spec
NEWSETUP="$PY_DIR/new/setup.py"
mkdir -p "$(dirname "$NEWSETUP")"
out=$(run_pybs_write "$NEWSETUP" 'from setuptools import setup
setup(name="new")
')
assert_silent "pybs-guard: new setup.py is allowed" "$out"

echo ""
echo "=== pyproject-buildsystem-guard: irrelevant inputs pass silently ==="

# Edit on an unrelated file — hook is matcher-scoped but defensively allows
NONPY="$PY_DIR/other.toml"
echo '[a]
b = 1
' > "$NONPY"
out=$(run_pybs_edit "$NONPY" 'b = 1' 'b = 2')
assert_silent "pybs-guard: ignores non-pyproject/setup.py files" "$out"

# Bash tool — hook is matcher-scoped to Edit/Write
out=$(echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' \
  | python3 "$PYBS_GUARD")
assert_silent "pybs-guard: Bash tool name is ignored" "$out"

# Malformed stdin
out=$(echo 'not json' | python3 "$PYBS_GUARD")
assert_silent "pybs-guard: malformed stdin is ignored" "$out"

echo ""

# --- untrusted-content-reminder --------------------------------------------

# Build an isolated $HOME with a settings.json containing a vendor allowlist.
FAKE_HOME="$WORK_DIR/home"
mkdir -p "$FAKE_HOME/.claude"
cat > "$FAKE_HOME/.claude/settings.json" <<'JSON'
{
  "permissions": {
    "allow": [
      "WebFetch(domain:docs.anthropic.com)",
      "WebFetch(domain:code.claude.com)"
    ]
  }
}
JSON

# Empty project-level settings dir so cwd lookup is well-defined.
PROJ_DIR="$WORK_DIR/proj"
mkdir -p "$PROJ_DIR"

run_untrusted() {
  local payload="$1"
  ( cd "$PROJ_DIR" && HOME="$FAKE_HOME" \
      bash -c 'python3 "$1"' _ "$UNTRUSTED" <<<"$payload" )
}

webfetch_payload() {
  python3 -c '
import json, sys
print(json.dumps({"tool_name":"WebFetch","tool_input":{"url":sys.argv[1]}}))
' "$1"
}

echo "=== untrusted-content-reminder: vendor allowlist passes silently ==="
out=$(run_untrusted "$(webfetch_payload https://docs.anthropic.com/en/docs)")
assert_silent "reminder: docs.anthropic.com is vendor-allowed" "$out"
out=$(run_untrusted "$(webfetch_payload https://code.claude.com/docs)")
assert_silent "reminder: code.claude.com is vendor-allowed" "$out"

echo ""
echo "=== untrusted-content-reminder: non-vendor injects reminder ==="
out=$(run_untrusted "$(webfetch_payload https://github.com/user/repo)")
assert_reminder "reminder: github.com is non-vendor" "$out"
out=$(run_untrusted "$(webfetch_payload https://registry.npmjs.org/foo)")
assert_reminder "reminder: registry.npmjs.org is non-vendor" "$out"
out=$(run_untrusted "$(webfetch_payload https://example.com:8443/path)")
assert_reminder "reminder: port stripped from host" "$out"

echo ""
echo "=== untrusted-content-reminder: irrelevant inputs pass silently ==="
out=$(run_untrusted '{"tool_name":"Bash","tool_input":{"command":"ls"}}')
assert_silent "reminder: non-WebFetch tool is ignored" "$out"
out=$(run_untrusted '{"tool_name":"WebFetch","tool_input":{"url":""}}')
assert_silent "reminder: empty url is ignored" "$out"
out=$(run_untrusted 'not json')
assert_silent "reminder: malformed stdin is ignored" "$out"

echo ""
echo "=== Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
[ "$FAIL" -eq 0 ]
