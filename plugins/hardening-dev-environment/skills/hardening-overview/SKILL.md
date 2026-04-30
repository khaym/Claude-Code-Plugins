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
| 1 | Auto-mode classifier + setup | `hardening-auto-mode` (Claude Code v2.1.83+, plan-gated) | Scope escalation, untrusted infrastructure, prompt-injection-driven actions |
| 2 | Static `permissions.{deny, ask}` rules | `hardening-claude-permissions` | Persistence (config writes), credential exfil (reads), plugin-authoring confirmation gate |
| 3 | Bundled runtime hooks (auto-active) | This plugin (`sensitive-bash-guard`, `package-json-scripts-guard`, `untrusted-content-reminder`) | Bash credential-read bypass, `package.json` scripts tampering, indirect prompt injection from `WebFetch` results |
| 4 | WebFetch trust discipline | `hardening-untrusted-content` | Indirect prompt injection — trust-boundary checklist + vendor allowlist that drives the PostToolUse hook |
| 5 | npm supply chain config | `hardening-pnpm-config` | Malicious package install / build-script execution / unpinned `npx` |
| 6 | Pre-commit secret scan | `checking-oss-release` plugin (sibling) | Plaintext secrets reaching commit-time |

Layer 3 hooks auto-activate when this plugin is enabled — no setup. Layer 1's classifier is a Claude Code runtime feature; the skill in that row turns it on.

## Workflow

### 1. Inspect

Read settings and project configuration. Treat absent files as "layer unapplied" — never fail on a missing file.

```bash
[ -f .claude/settings.json ] && jq '{defaultMode: .permissions.defaultMode, deny: .permissions.deny, ask: .permissions.ask, allow: .permissions.allow}' .claude/settings.json 2>/dev/null || echo "no .claude/settings.json"
[ -f .claude/settings.local.json ] && jq '.enabledPlugins' .claude/settings.local.json 2>/dev/null
[ -f package.json ] && jq '{packageManager, pnpm}' package.json 2>/dev/null || echo "no package.json"
```

### 2. Classify each layer

| State | Meaning |
|-------|---------|
| **applied** | All expected rules / settings present |
| **partial** | Some present, others missing |
| **unapplied** | None present |
| **N/A** | Layer does not apply (pnpm row on a non-Node project; auto-mode rows on Pro plan) |

For layer 1, report "active in auto mode" if `defaultMode: "auto"`, else "available but inactive" / "unavailable" depending on plan tier.

### 3. Confirm plan and use case

Ask the user:

- **Plan tier**: Pro, Max, Team, Enterprise, API, or unsure?
- **Project type**: Node / TypeScript? Other?
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

### Plan-tier paths

| Plan tier | Auto mode | Recommended order |
|-----------|-----------|-------------------|
| Pro | Not available | `hardening-claude-permissions` → `hardening-pnpm-config` (if Node) → `hardening-untrusted-content` |
| Max | Yes — Opus 4.7 only | `hardening-claude-permissions` → `hardening-auto-mode` → `hardening-pnpm-config` (if Node) → `hardening-untrusted-content` |
| Team / Enterprise / API | Yes — Sonnet 4.6, Opus 4.6, Opus 4.7 | Same as Max. Confirm an admin has enabled auto mode in admin settings before applying `hardening-auto-mode` |

`hardening-claude-permissions` runs first: its deny rules are hard guarantees that hold under any mode, including auto mode where the classifier is best-effort. `hardening-auto-mode` is applied after, so the classifier has hard backstops for cases it cannot decide.

### Use-case overlays

| Use case | Adjustment |
|----------|------------|
| CI-only (no interactive session) | Use `dontAsk` mode instead of auto / acceptEdits — denies everything not pre-allowed; the auto-mode classifier is not active in non-interactive runs |
| Plugin-authoring repo | Keep `permissions.ask` on `.claude/{skills,agents,commands}/**` — do not promote to deny |
| Production-touching | Add explicit deny on production-deploy commands (`gcloud deploy`, `kubectl apply`) beyond defaults |

### Adjacent plugins

For commit-time content scanning, see the sibling `checking-oss-release` plugin. Independent of this plugin; composes without overlap.

## See Also

| Skill | Purpose |
|-------|---------|
| `hardening-auto-mode` | Auto-mode setup + deny/ask overlay |
| `hardening-claude-permissions` | Static `permissions.{deny, ask}` rules |
| `hardening-untrusted-content` | WebFetch trust boundary + vendor allowlist |
| `hardening-pnpm-config` | pnpm 10.26+ config + `npx → pnpm dlx` |

External:

- [Choose a permission mode](https://code.claude.com/docs/en/permission-modes)
- [Auto mode for Claude Code](https://claude.com/blog/auto-mode)
