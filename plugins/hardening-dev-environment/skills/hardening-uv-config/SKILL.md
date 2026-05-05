---
name: hardening-uv-config
description: Hardens uv-managed Python projects against PyPI supply chain risk. Migrates legacy pip / setup.py projects to a uv-native shape, writes baseline `[tool.uv]` settings into pyproject.toml, and replaces `pip install` / `pipx run` invocations with pinned `uv add` / `uvx`. Use when you hear "harden uv config", "harden python project", "python supply chain hardening", "migrate pip to uv".
---

# Hardening uv Config

Reduce PyPI supply chain attack surface by applying uv hardening settings to a Python project. Configuration-time hardening stops known attack patterns before any runtime or commit-time check is needed. For the full layered defense picture across `hardening-dev-environment`, see `hardening-overview`.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Workflow](#workflow)
- [Target Settings](#target-settings)
- [pip / pipx Migration Rules](#pip--pipx-migration-rules)
- [Recommended External Tools](#recommended-external-tools)
- [Optional Pre-commit Hook](#optional-pre-commit-hook)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Python project rooted at the working directory (any of: `pyproject.toml`, `requirements.txt`, `setup.py`)
- uv installed (see [Troubleshooting](#troubleshooting) if absent)

## Workflow

### 1. Detect current state

Run these in the project root and read the outputs:

- `uv --version` — verify uv is installed
- `[ -f pyproject.toml ] && cat pyproject.toml || echo "no pyproject.toml"`
- `[ -f uv.lock ] && echo "uv.lock present" || echo "no uv.lock"`
- `ls requirements*.txt setup.py setup.cfg poetry.lock Pipfile pdm.lock 2>/dev/null`

Classify the project shape from the outputs:

| Shape | Markers | Migration needed in Step 2? |
|-------|---------|------------------------------|
| **uv-native** | `pyproject.toml` with `[tool.uv]` or `uv.lock` | No |
| **pyproject (non-uv)** | `pyproject.toml` without `[tool.uv]`, no `uv.lock` | Light — add `[tool.uv]` table only |
| **requirements-only** | `requirements*.txt`, no `pyproject.toml` | Yes — initialize pyproject.toml |
| **setup.py-only** | `setup.py` / `setup.cfg`, no `pyproject.toml` | Yes — initialize pyproject.toml |
| **other (poetry / Pipenv / pdm)** | `poetry.lock`, `Pipfile`, `pdm.lock` | Stop. See [Troubleshooting](#troubleshooting) |

Build a mental model of which target settings are missing, present, or conflicting. Do not write yet.

### 2. Migrate to uv-native shape (when needed)

Skip this step for **uv-native** projects. For **other (poetry / Pipenv / pdm)**, stop and follow [Troubleshooting](#troubleshooting) — automatic migration is out of scope.

For **requirements-only** and **setup.py-only**, propose this migration plan to the user and wait for explicit approval before any write:

| Source | Target action |
|--------|--------------|
| `requirements.txt` | Run `uv init --bare` to create a minimal pyproject.toml, then `uv add -r requirements.txt` to import deps into `[project.dependencies]` |
| `requirements-dev.txt` (or similar) | `uv add --dev -r requirements-dev.txt` |
| `setup.py` with simple `install_requires` | Read `install_requires` and propose the equivalent `uv add ...`. If `setup.py` contains custom build logic, stop and surface the file for manual migration |
| Existing `setup.py` build backend | Leave in place. Adding `[tool.uv]` does not require removing `setup.py` |

For **pyproject (non-uv)**, no dependency import is needed — proceed directly to Step 3.

After migration, regenerate the lockfile:

```sh
uv lock
```

### 3. Plan changes

Compare the current `[tool.uv]` against [Target Settings](#target-settings). For each key:

- **Missing** — queue for addition
- **Conflicting** — queue for confirmation (show current → proposed)
- **Already correct** — skip

For `no-build-isolation-package`, the safe default is an empty list. Disabling build isolation gives a package's build backend access to the project environment, which is the threat surface this setting controls. Add an entry only if the user identifies a specific package whose build legitimately requires it.

### 4. Confirm with the user

Show one consolidated diff per target file (`pyproject.toml`, and `.python-version` if it needs changes). Wait for explicit approval per file before any write.

### 5. Apply

- Use `Edit` for in-place modifications to existing files
- Use `Write` only when creating a missing file
- After each write, re-read the file to verify the change landed correctly

### 6. Verify the settings take effect

Trigger a fresh resolve so the new policy is exercised:

```sh
rm -rf .venv uv.lock && uv sync
```

Confirm each of the following:

| Expectation | What to look for |
|-------------|------------------|
| pyproject.toml parses cleanly | uv emits no warning lines about `[tool.uv]` |
| `exclude-newer` is enforced | A package published inside the cooldown window resolves to its previous version, or `uv sync` reports no candidates if no older version exists |
| `required-version` is enforced | Running uv from a non-matching version fails with a clear error |
| `index-strategy = "first-index"` is in effect | `uv sync` does not consider later-listed indexes for a package available on the first |

If a step fails, stop and revisit Step 3's plan rather than relaxing the config.

### 7. Migrate `pip install` / `pipx run` invocations to uv

`pip install` and `pipx run` invocations bypass every config-level setting written above (they shell out to a different tool). Replace them with `uv add <pkg>` (project-scoped) or `uvx <pkg>@<version>` (one-shot) so the same policy (`exclude-newer`, `index-strategy`) applies. This step is self-contained: detect → classify → resolve versions → confirm → apply.

#### 7.1 Detect

Scan tracked files for pip/pipx usage; gitignored paths are excluded automatically:

```sh
git ls-files | grep -vE '\.(md|markdown|txt|rst)$' | \
  xargs grep -nE '\b(pip install|pipx run|pipx install)\b' 2>/dev/null
```

Documentation files are intentionally excluded — README rewrites are user-driven and out of scope for this skill.

#### 7.2 Classify

For each match, classify per [pip / pipx Migration Rules](#pip--pipx-migration-rules). Auto-migratable matches proceed to 7.3. Report-only matches are surfaced at the end of the step as `file:line: <original command>`; the user decides them manually.

#### 7.3 Resolve versions

For each auto-migratable package, fetch the latest stable version from the registry:

```sh
uv pip index versions <pkg> | head -1
```

Propose the replacement using the resolved version. The user may override the version. Reject `@latest` as a literal tag — a floating tag reproduces the unpinned-execution risk this step is meant to remove.

#### 7.4 Confirm and apply

Present a per-file diff (one consolidated diff per file with multiple hunks). After explicit approval per file, apply each change with `Edit`. Re-read each file after writing to verify.

### 8. Share recommended external tools

After config is in place, print the install instructions in [Recommended External Tools](#recommended-external-tools). Do not run the install commands automatically — they are global / per-developer decisions.

## Target Settings

| Key | Location | Value | Purpose |
|-----|----------|-------|---------|
| `required-version` | `[tool.uv]` in `pyproject.toml` | `">=<detected-version>"` (e.g. `">=0.5.0"`) | Pin a uv version floor |
| `exclude-newer` | `[tool.uv]` | `"P3D"` (ISO 8601 duration, 72h sliding window) | Reject freshly-published packages |
| `index-strategy` | `[tool.uv]` | `"first-index"` | Prevent dependency confusion across multiple indexes |
| `no-build-isolation-package` | `[tool.uv]` | `[]` (empty allowlist) | Keep build isolation on for every package by default |

Reference: <https://docs.astral.sh/uv/reference/settings/>

### Example `pyproject.toml` `[tool.uv]` after apply

```toml
[tool.uv]
required-version = ">=0.5.0"
exclude-newer = "P3D"
index-strategy = "first-index"
no-build-isolation-package = []
```

### Optional stricter setting

`no-build = true` rejects all source distributions, removing build-time arbitrary code execution entirely. Recommend it only when the project's dependencies all ship wheels for the target Python and platform. Common ML/data stacks (some `numpy` / `pandas` build matrices) may break under this setting, so it is opt-in rather than default.

## pip / pipx Migration Rules

| Pattern | Class | Replacement |
|---------|-------|-------------|
| `pip install pkg` (project dep) | auto | `uv add pkg` (resolves a pin into pyproject.toml + uv.lock) |
| `pip install pkg==X.Y` | auto | `uv add 'pkg==X.Y'` |
| `pip install -r requirements.txt` | auto | `uv add -r requirements.txt` |
| `pipx install pkg` | auto | `uv tool install pkg` |
| `pipx run pkg` / `pipx run pkg arg…` | auto | `uvx pkg@<version>` |
| `pip install -e .` (editable self-install) | report-only | (project install pattern; user judgment needed) |
| `pip install --user pkg` | report-only | (per-user global install — surface for review) |
| `pip install pkg --no-deps` | report-only | (intentional bypass of resolver — surface for review) |

## Recommended External Tools

These complement the config-level prevention. The skill does not install them on behalf of the user.

### pip-audit

Audits installed packages or `pyproject.toml` against the PyPI Advisory Database. Suitable for both pre-commit and CI.

```sh
uv tool install pip-audit
pip-audit
```

Reference: <https://github.com/pypa/pip-audit>

### Aikido Safe Chain

Wraps `npm` / `pnpm` / `pip` / etc. via shell aliases to block known-malicious installs against the Aikido Intel feed. Best installed per-developer — interactive prompts make it unsuitable for CI. The installer command below uses `curl`, which `hardening-claude-permissions` denies for Claude — run it in your own shell.

Use the official one-line installer (Unix/Linux/macOS):

```sh
curl -fsSL https://github.com/AikidoSec/safe-chain/releases/latest/download/install-safe-chain.sh | sh
```

For reproducibility, pin to a specific release (recommended) by replacing `latest` with `vX.Y.Z` from the [releases page](https://github.com/AikidoSec/safe-chain/releases):

```sh
curl -fsSL https://github.com/AikidoSec/safe-chain/releases/download/vX.Y.Z/install-safe-chain.sh | sh
```

Restart the terminal to load aliases.

Reference: <https://github.com/AikidoSec/safe-chain>

### OSV-Scanner

Scans `uv.lock` against the OSV.dev CVE database. Suitable for both pre-commit and CI.

```sh
osv-scanner -L uv.lock
```

Reference: <https://google.github.io/osv-scanner>

## Optional Pre-commit Hook

If the project uses `.githooks/`, append the following to `.githooks/pre-commit` (create the file with `chmod +x` if absent):

```sh
if command -v osv-scanner >/dev/null 2>&1; then
  osv-scanner -L uv.lock || exit 1
fi
```

Activate per clone with `git config core.hooksPath .githooks`. This is a per-clone setting and cannot be checked into the repository — document the activation step in the project README.

## Troubleshooting

| Situation | Action |
|-----------|--------|
| `uv` not installed | Stop. Recommend `curl -LsSf https://astral.sh/uv/install.sh \| sh` for Unix-like, or `pipx install uv` if `pipx` is already trusted on the host. Re-run from Step 1 after install |
| `pyproject.toml` not found and no `requirements*.txt` / `setup.py` | Stop. This skill targets Python projects only |
| Project shape is **other** (poetry / Pipenv / pdm) | Stop. Automatic migration is out of scope. Recommend the user follow uv's official migration guide for their toolchain, then re-run from Step 1. Settings written by this skill apply identically once `[tool.uv]` is present |
| `pyproject.toml` is malformed TOML | Report the parse error and ask the user to fix manually before retrying |
| `setup.py` contains custom build logic beyond `install_requires` | Surface the file and ask the user to migrate manually. Do not auto-rewrite — `setup.py` semantics are not statically analyzable in general |
| `exclude-newer = "P3D"` blocks a needed dependency | Add a per-package override under `exclude-newer-package` rather than lowering the global value |
| `uv pip index versions <pkg>` fails (offline / restricted registry) | Skip auto-resolution; ask the user to provide each version manually, or defer Step 7 until network is available |
