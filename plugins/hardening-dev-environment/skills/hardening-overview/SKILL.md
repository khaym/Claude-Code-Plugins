---
name: hardening-overview
description: Audits a project's hardening-dev-environment defense layers and recommends a setup order to apply them. Use when you hear "harden dev environment", "set up hardening", "hardening overview", "audit claude code hardening".
---

# Hardening Dev Environment Overview

Inspect defense layer state, recommend a setup order, and hand off to the specific layer skill. Application is delegated — this skill writes nothing.

## Table of Contents

- [Layered Defense Map](#layered-defense-map)
- [Workflow](#workflow)
- [Decision Guide](#decision-guide)
- [See Also](#see-also)

## Layered Defense Map

| # | Layer | Owner | Threats addressed |
|---|-------|-------|-------------------|
| 1 | Static `permissions.{deny, ask, allow}` rules | `hardening-claude-permissions` | Persistence (config writes), credential exfil (reads), outbound exfil, plugin-authoring confirmation gate |
| 2 | Bundled runtime hooks (auto-active) | This plugin (`sensitive-bash-guard`, `package-json-scripts-guard`, `pyproject-buildsystem-guard`, `untrusted-content-reminder`) | Bash credential-read bypass, `package.json` scripts tampering, `pyproject.toml [build-system]` / `setup.py` tampering, indirect prompt injection from `WebFetch` results |
| 3 | WebFetch trust discipline | `hardening-untrusted-content` | Indirect prompt injection — trust-boundary checklist + vendor allowlist that drives the PostToolUse hook |
| 4a | npm supply chain config | `hardening-pnpm-config` | Malicious package install / build-script execution / unpinned `npx` |
| 4b | PyPI supply chain config | `hardening-uv-config` | Fresh-malicious-package install / dependency confusion / unpinned `pip install` / `pipx run` |
| 5 | Pre-commit secret scan | `checking-oss-release` plugin (sibling) | Plaintext secrets reaching commit-time |

Layer 2 hooks auto-activate when this plugin is enabled — no setup. The other layers are applied via their owner skill.

## Workflow

### 1. Inspect

Read settings and project configuration. Treat absent files as "layer unapplied" — never fail on a missing file.

```bash
[ -f .claude/settings.json ] && jq '{defaultMode: .permissions.defaultMode, deny: .permissions.deny, ask: .permissions.ask, allow: .permissions.allow}' .claude/settings.json 2>/dev/null || echo "no .claude/settings.json"
[ -f .claude/settings.local.json ] && jq '.enabledPlugins' .claude/settings.local.json 2>/dev/null
[ -f package.json ] && jq '{packageManager, pnpm}' package.json 2>/dev/null || echo "no package.json"
[ -f pyproject.toml ] && grep -E '^\[(tool\.uv|build-system|project)\]' pyproject.toml || echo "no pyproject.toml"
ls requirements*.txt setup.py poetry.lock Pipfile pdm.lock 2>/dev/null
```

### 2. Classify each layer

| State | Meaning |
|-------|---------|
| **applied** | All expected rules / settings present |
| **partial** | Some present, others missing |
| **unapplied** | None present |
| **N/A** | Layer does not apply (e.g. row 4a on a non-Node project, row 4b on a non-Python project) |

### 3. Confirm plan and use case

Ask the user:

- **Plan tier**: Pro, Max, Team, Enterprise, API, or unsure?
- **Project type**: Node / TypeScript? Python? Mixed? Other?
- **Use case**: Personal sandbox, team repo, CI-only, or production-touching?

If the plan is unknown, treat as Pro (most conservative path).

### 4. Report

Show:

- The Layered Defense Map with the **state** column populated
- A recommended setup order (see [Decision Guide](#decision-guide))
- For each missing/partial layer, the skill or step to apply

Do not auto-invoke other skills.

### 5. Hand off

Point the user to the relevant skill name (see [See Also](#see-also)). This skill exits after the report.

## Decision Guide

### Setup order

| Order | Skill | When to apply |
|-------|-------|----------------|
| 1 | `hardening-claude-permissions` | First. Mode-agnostic deny rules are hard guarantees, regardless of `defaultMode` |
| 2 | `hardening-pnpm-config` | If Node project |
| 3 | `hardening-uv-config` | If Python project (also handles migration from legacy pip / setup.py to uv) |
| 4 | `hardening-untrusted-content` | After WebFetch trust-boundary discipline is in place |

`hardening-claude-permissions` is recommended for all plan tiers — its rule set targets an `acceptEdits`-based permission mode, which works on every plan from Pro upward. Other modes (`default`, `auto`, `dontAsk`) interact with the rule set differently; see `hardening-claude-permissions` for mode-specific guidance.

### Use-case overlays

| Use case | Adjustment |
|----------|------------|
| CI-only (non-interactive) | Use `dontAsk` mode instead of `acceptEdits` — denies everything not pre-allowed |
| Plugin-authoring repo | Keep `permissions.ask` on `.claude/{skills,agents,commands}/**` — do not promote to deny |
| Production-touching | Add explicit deny on production-deploy commands (`gcloud deploy`, `kubectl apply`) beyond defaults |

### Adjacent plugins

For commit-time content scanning, see the sibling `checking-oss-release` plugin. Independent of this plugin; composes without overlap.

## See Also

| Skill | Purpose |
|-------|---------|
| `hardening-claude-permissions` | Static `permissions.{deny, ask, allow}` rules |
| `hardening-untrusted-content` | WebFetch trust boundary + vendor allowlist |
| `hardening-pnpm-config` | pnpm 10.26+ config + `npx → pnpm dlx` |
| `hardening-uv-config` | uv `[tool.uv]` config + legacy pip / setup.py migration + `pip install` / `pipx run → uv add / uvx` |

External:

- [Choose a permission mode](https://code.claude.com/docs/en/permission-modes)
