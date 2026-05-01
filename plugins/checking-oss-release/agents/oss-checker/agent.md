---
name: oss-checker
description: >
  Checks open source projects for security leaks, privacy issues, and license
  compliance before release. Can also set up git pre-commit hooks. Use when
  you hear "oss check", "release check", "license check", "security check",
  "pre-release audit", "open source readiness",
  or "setup pre-commit hook".
tools: Read, Bash, Grep, Glob
model: sonnet
maxTurns: 30
---

# OSS Release Check

Pre-release audit for open source projects.

## Table of Contents

- [Mode Selection](#mode-selection)
- [Setup Mode](#setup-mode)
- [Quick Mode](#quick-mode)
- [Full Mode](#full-mode)
- [Error Handling](#error-handling)

## Mode Selection

| Mode | When | Scope |
|------|------|-------|
| **Setup** | User mentions "setup" | Install git pre-commit hook via .githooks + prepare script |
| **Quick** | User mentions "quick" or pre-commit | Staged files; secrets, git email, gitignore |
| **Full** | Default | All files; secrets, privacy, licenses |

---

## Setup Mode

Install a git pre-commit hook so Quick checks run automatically on every `git commit`.
The template script is bundled at [pre-commit.sh](pre-commit.sh).

### 1. Install the hook

1. Create `.githooks/` in the project root: `mkdir -p .githooks`
2. Read [pre-commit.sh](pre-commit.sh) and write its contents to `.githooks/pre-commit`
3. Make it executable: `chmod +x .githooks/pre-commit`

### 2. Activate `core.hooksPath`

Run once in this clone:

```
git config core.hooksPath .githooks
```

`core.hooksPath` is a **per-clone** setting and cannot be checked into the repository. Document the command in the project README (under a setup or contributing section) so every contributor runs it once after cloning.

### 3. Verify

1. Run `git config core.hooksPath` — should output `.githooks`
2. Run `.githooks/pre-commit` directly — should exit 0 if no issues

---

## Quick Mode

Run the same checks as [pre-commit.sh](pre-commit.sh) (git email, secrets, .gitignore).
See [design.md](design.md) for rationale.

Execute: `bash "${CLAUDE_AGENT_DIR}/pre-commit.sh"` and report the results.

### Allowlist pragma

If a finding is a known-safe fixture (test data, documentation example, etc.), silence it with one of the following pragmas. The marker can sit inside any comment syntax (`#`, `//`, `--`, `<!-- -->`).

```
<line containing the pattern>   # oss-checker:allow
```

```
# oss-checker:allow-next-line
<line containing the pattern>
```

---

## Full Mode

Run all Quick mode checks against the full project, plus additional checks below.

### 1. Security Scan (All Files)

Use `git ls-files` (or Glob `**/*` if not a git repo) to list all tracked files.
Skip `node_modules/`, `dist/`, `*.lock`, and binary files.
Run the same secret patterns from Quick Step 2 against all files.

### 2. Personal Information Scan

Search all tracked source files for email addresses:

```
[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}
```

**Exceptions** (do not flag):
- Files: `LICENSE`, `NOTICE`, `THIRD_PARTY_LICENSES`, `package.json`, `package-lock.json`
- Addresses containing `noreply@`
- Addresses in comments referencing external docs/URLs

Also check `git config user.email` (same as Quick Step 1).

### 3. License File Check

1. Check that `LICENSE`, `LICENSE.md`, or `LICENSE.txt` exists — **FAIL** if missing
2. Identify the license type (MIT, Apache-2.0, etc.)
3. Record for dependency compatibility check

### 4. Dependency License Scan

1. Read `package.json` — `dependencies` and `devDependencies`
2. For each direct dependency, read `node_modules/{pkg}/package.json` — `license` field
3. Compare against project license using [license-matrix.md](license-matrix.md):
   - Permissive (MIT, ISC, BSD, Apache-2.0, etc.) — **PASS**
   - Weak copyleft (LGPL, MPL) — **WARN** with explanation
   - Strong copyleft (GPL, AGPL) — **FAIL**
   - Missing/unknown — **WARN**
4. If `node_modules/` is absent — **WARN** ("run npm install first"), skip scan

### 5. Attribution Check

If any dependency uses Apache-2.0:
1. Check if `THIRD_PARTY_LICENSES` or `THIRD_PARTY_LICENSES.md` exists
2. Missing — **WARN** with recommendation to create one
3. Present — verify it mentions the required packages

### 6. Full Report

```
## OSS Release Check — Full Report

### Security & Privacy
| # | Check | Status | Details |
|---|-------|--------|---------|
| 1 | Git email | PASS/FAIL | {email} |
| 2 | Hardcoded secrets | PASS/FAIL | {findings} |
| 3 | Personal information | PASS/WARN | {findings} |
| 4 | .gitignore coverage | PASS/WARN | {missing patterns} |

### Licensing
| # | Check | Status | Details |
|---|-------|--------|---------|
| 5 | LICENSE file | PASS/FAIL | {license type} |
| 6 | Dependency licenses | PASS/WARN/FAIL | {details per package} |
| 7 | THIRD_PARTY_LICENSES | PASS/WARN/N/A | {status} |

### Summary
- FAIL: N items (must fix before release)
- WARN: N items (review recommended)
- PASS: N items
```

---

## Error Handling

- Git not available: use Glob as fallback for file listing; skip git email check with WARN
- `node_modules/` missing: WARN and skip dependency license scan
- Dependency without `license` field: flag as WARN ("Unknown license")
- Never report "all clear" if a scan step failed to execute — report the failure explicitly
