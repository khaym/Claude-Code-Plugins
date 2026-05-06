---
name: hardening-pnpm-config
description: Hardens pnpm 10.26+ config to reduce npm supply chain risk. Writes baseline settings into pnpm-workspace.yaml and package.json, and migrates npx invocations to pinned pnpm dlx. Use when you hear "harden pnpm config", "pnpm supply chain hardening", "replace npx with pnpm dlx".
---

# Hardening pnpm Config

Reduce npm supply chain attack surface by applying pnpm 10.26+ hardening settings to a project. Configuration-time hardening stops known attack patterns before any runtime or commit-time check is needed. For the full layered defense picture across `hardening-dev-environment`, see `hardening-overview`.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Workflow](#workflow)
- [Target Settings](#target-settings)
- [npx Migration Rules](#npx-migration-rules)
- [Recommended External Tools](#recommended-external-tools)
- [Optional Pre-commit Hook](#optional-pre-commit-hook)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Node.js project with `package.json` at the project root
- pnpm 10.26 or higher (see [Troubleshooting](#troubleshooting) if older)

## Workflow

### 1. Detect current state

Run these in the project root and read the outputs:

- `pnpm --version` — verify 10.26+
- `jq -r '.packageManager // "unset"' package.json` — current pin
- `[ -f .npmrc ] && cat .npmrc || echo "no .npmrc"`
- `[ -f pnpm-workspace.yaml ] && cat pnpm-workspace.yaml || echo "no pnpm-workspace.yaml"`

Build a mental model of which target settings are missing, present, or
conflicting. Do not write yet.

### 2. Plan changes

Compare the current state against [Target Settings](#target-settings).
For each key:

- **Missing** — queue for addition
- **Conflicting** — queue for confirmation (show current → proposed)
- **Already correct** — skip

For `allowBuilds`, enumerate packages from `node_modules` whose `package.json` declares any install script. pnpm's default isolated layout symlinks `node_modules/<pkg>` into `.pnpm/<pkg>@<ver>/...`, so `find` must follow symlinks (`-L`):

```sh
find -L node_modules -maxdepth 2 -name package.json -exec \
  jq -r 'select(.scripts.preinstall or .scripts.install or .scripts.postinstall) | .name' {} + \
  2>/dev/null | sort -u
```

`2>/dev/null` suppresses "Too many levels of symbolic links" noise from `.bin`; `sort -u` dedups when multiple versions of the same package exist.

Present the list to the user and ask which packages to allowlist. Default to none — packages omitted from `allowBuilds` will have their install scripts blocked, which is the safe default.

### 3. Confirm with the user

Show one consolidated diff per target file (`package.json`, `pnpm-workspace.yaml`, and `.npmrc` if it needs changes). Wait for explicit approval per file before any write.

### 4. Apply

- Use `Edit` for in-place modifications to existing files
- Use `Write` only when creating a missing file
- After each write, re-read the file to verify the change landed correctly

### 5. Verify the settings take effect

Trigger a fresh install so the new policy is exercised:

```sh
rm -rf node_modules pnpm-lock.yaml && pnpm install
```

Confirm each of the following:

| Expectation | What to look for |
|-------------|------------------|
| YAML parses cleanly | pnpm emits no warning lines about `pnpm-workspace.yaml` |
| `allowBuilds` entries actually build | A `postinstall`/`install` log line appears for each allowlisted package |
| Empty `allowBuilds` enforces the policy | If no packages are allowlisted but at least one dependency declares an install script, install exits with `ERR_PNPM_IGNORED_BUILDS` (exit code 1) — this is the intended behavior |

If a step fails, stop and revisit Step 2's plan rather than relaxing the config.

### 6. Migrate `npx` invocations to `pnpm dlx`

`npx` invocations bypass every config-level setting written above. Replace them with `pnpm dlx <pkg>@<version>` so the same policy (registry verification, `minimumReleaseAge`, install-script blocking) applies to one-shot executions. This step is self-contained: detect → classify → resolve versions → confirm → apply.

#### 6.1 Detect

Scan tracked files for `npx` usage; gitignored paths are excluded automatically:

```sh
git ls-files | grep -vE '\.(md|markdown|txt|rst)$' | \
  xargs grep -nE '\bnpx\b' 2>/dev/null
```

Documentation files are intentionally excluded — README rewrites are user-driven and out of scope for this skill.

#### 6.2 Classify

For each match, classify per [npx Migration Rules](#npx-migration-rules). Auto-migratable matches proceed to 6.3. Report-only matches are surfaced at the end of the step as `file:line: <original command>`; the user decides them manually.

#### 6.3 Resolve versions

For each auto-migratable package, fetch the latest stable version from the registry:

```sh
npm view <pkg> version
```

Propose the replacement as `pnpm dlx <pkg>@<resolved-version>`. The user may override the version. Reject `@latest` as a literal tag — a floating tag reproduces the unpinned-execution risk this step is meant to remove.

#### 6.4 Confirm and apply

Present a per-file diff (one consolidated diff per file with multiple hunks). After explicit approval per file, apply each change with `Edit`. Re-read each file after writing to verify.

### 7. Share recommended external tools

After config is in place, print the install instructions in [Recommended External Tools](#recommended-external-tools). Do not run the install commands automatically — they are global / per-developer decisions.

## Target Settings

| Key | Location | Value | Purpose |
|-----|----------|-------|---------|
| `packageManager` | `package.json` | `pnpm@<detected-version>` (e.g. `pnpm@10.26.0`) | Pin pnpm version |
| `minimumReleaseAge` | `pnpm-workspace.yaml` | `4320` (minutes = 72h) | Reject freshly-published packages |
| `blockExoticSubdeps` | `pnpm-workspace.yaml` | `true` | Reject git/tarball transitive deps |
| `strictDepBuilds` | `pnpm-workspace.yaml` | `true` | Fail install when unreviewed install scripts found |
| `allowBuilds` | `pnpm-workspace.yaml` | `{ ...user-confirmed }` | Allowlist for install scripts |

Reference: <https://pnpm.io/supply-chain-security>

### Example `pnpm-workspace.yaml` after apply

```yaml
minimumReleaseAge: 4320
blockExoticSubdeps: true
strictDepBuilds: true
allowBuilds:
  esbuild: true
  "@swc/core": true
```

### Example `package.json` field

```json
{
  "packageManager": "pnpm@10.26.0"
}
```

## npx Migration Rules

| Pattern | Class | Replacement |
|---------|-------|-------------|
| `npx pkg` / `npx pkg arg…` | auto | `pnpm dlx pkg@<version>` |
| `npx --yes pkg` / `npx -y pkg` | auto | `pnpm dlx pkg@<version>` |
| `npx @scope/pkg` | auto | `pnpm dlx @scope/pkg@<version>` |
| `npx -p other pkg` / `npx --package=…` | report-only | (executed binary differs from named package) |
| `npx -c '…'` / `npx --call=…` | report-only | (shell-level construct, ambiguous to rewrite) |
| `npx pkg --no-install` | report-only | (intentional bypass of install — surface for human review) |

## Recommended External Tools

These complement the config-level prevention. The skill does not install them on behalf of the user.

### Aikido Safe Chain

Wraps `npm`/`pnpm`/`pip`/etc. via shell aliases to block known-malicious installs against the Aikido Intel feed. Best installed per-developer — interactive prompts make it unsuitable for CI. The installer commands below use `curl`, which `hardening-claude-permissions` denies for Claude — run them in your own shell.

Use the official one-line installer (Unix/Linux/macOS):

```sh
curl -fsSL https://github.com/AikidoSec/safe-chain/releases/latest/download/install-safe-chain.sh | sh
```

For reproducibility, pin to a specific release (recommended) by replacing `latest` with `vX.Y.Z` from the [releases page](https://github.com/AikidoSec/safe-chain/releases):

```sh
curl -fsSL https://github.com/AikidoSec/safe-chain/releases/download/vX.Y.Z/install-safe-chain.sh | sh
```

Restart the terminal to load aliases, then verify:

```sh
pnpm safe-chain-verify
```

Reference: <https://github.com/AikidoSec/safe-chain>

#### Apply to Claude Code's Bash tool

Safe Chain's shell aliases only load in interactive shells. Claude Code's `Bash` tool runs `bash -c` non-interactively, so the aliases do not apply to Claude-issued installs by default. To extend coverage, set `BASH_ENV` in your **user-level** `~/.claude/settings.json` so every `Bash` invocation sources the Safe Chain init script:

```json
{
  "env": {
    "BASH_ENV": "${HOME}/.safe-chain/scripts/init-posix.sh"
  }
}
```

Edit this file from your own shell — `hardening-claude-permissions` denies Claude write access to `~/.claude/settings.json`. Keep the entry in user-level settings (not project `.claude/settings.json`), since Safe Chain is a per-developer install and the path will not exist for collaborators who have not installed it. Bash silently ignores a missing `BASH_ENV` target, but install Safe Chain first to avoid surprises. Restart Claude Code to pick up the new env, then run `pnpm --version` (or `npm` / `pip`) under the `Bash` tool to confirm Safe Chain's banner appears.

### OSV-Scanner

Scans `pnpm-lock.yaml` against the OSV.dev CVE database. Suitable for both pre-commit and CI.

```sh
osv-scanner -L pnpm-lock.yaml
```

Reference: <https://google.github.io/osv-scanner>

## Optional Pre-commit Hook

If the project uses `.githooks/`, append the following to `.githooks/pre-commit` (create the file with `chmod +x` if absent):

```sh
if command -v osv-scanner >/dev/null 2>&1; then
  osv-scanner -L pnpm-lock.yaml || exit 1
fi
```

Activate per clone with `git config core.hooksPath .githooks`. This is a per-clone setting and cannot be checked into the repository — document the activation step in the project README.

## Troubleshooting

| Situation | Action |
|-----------|--------|
| `pnpm` not installed | Stop. Recommend `corepack enable && corepack prepare pnpm@latest --activate` |
| pnpm < 10.26 | Stop. Show upgrade path; explain that `blockExoticSubdeps` and `allowBuilds` require 10.26+ |
| `package.json` not found | Stop. This skill targets Node.js projects only |
| Existing `pnpm-workspace.yaml` is malformed YAML | Report the parse error and ask the user to fix manually before retrying |
| User rejects all `allowBuilds` candidates | Apply with `allowBuilds: {}`. Install scripts will be blocked; document `pnpm approve-builds` for case-by-case approval |
| `minimumReleaseAge` blocks a needed dependency | Add the package name to `minimumReleaseAgeExclude` rather than lowering the global value |
| `npm view <pkg> version` fails (offline / restricted registry) | Skip auto-resolution; ask the user to provide each version manually, or defer Step 6 until network is available |
