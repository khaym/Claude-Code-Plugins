---
name: hardening-claude-permissions
description: Writes mode-agnostic deny/ask rules into .claude/settings.json — deny Edit on settings/CI/hook configs and .env*, deny Read on ~30 credential paths, ask on plugin-author paths. Use when you hear "harden claude permissions", "lock down claude code", "set up claude code deny rules".
---

# Hardening Claude Code Permissions

Reduce the blast radius of prompt injection or compromised dependencies on a Claude Code session by writing recommended `permissions.deny` and `permissions.ask` rules into `.claude/settings.json`. These deny rules are hard guarantees that hold under any permission mode (default, plan, acceptEdits, auto), and they complement runtime checks (auto-mode classifier, bundled hooks). For the full layered defense picture and where this skill fits, see `hardening-overview`.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Workflow](#workflow)
- [Target Rules](#target-rules)
- [Interaction with Existing Settings](#interaction-with-existing-settings)
- [Limitations](#limitations)
- [Auto Mode Interaction](#auto-mode-interaction)
- [Recommended Supplements](#recommended-supplements)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- A Claude Code project (`.claude/` directory may or may not exist yet)
- The skill writes to project-level settings (`.claude/settings.json`), not user-level (`~/.claude/settings.json`) or managed settings

## Workflow

### 1. Detect current state

Read the existing settings file if present:

```sh
[ -f .claude/settings.json ] && cat .claude/settings.json || echo "no settings.json"
```

If it exists, parse the `permissions.deny`, `permissions.ask`, and `permissions.allow` arrays. Build a mental model of which target rules are already present, missing, or conflicting.

If `.claude/` does not exist, it is created in Step 4.

### 2. Plan changes

For each target rule from [Target Rules](#target-rules), classify against the existing settings:

- **Missing** — queue for addition
- **Present (exact match)** — skip
- **Covered by a superset** (e.g., user has `Edit(/.claude/**)` and we want `Edit(/.claude/settings.json)`) — skip; user's broader rule already protects ours
- **Coexisting allow rule** (e.g., user has `allow: Edit(/.npmrc)` and we want `deny:`) — note for the user; cleanup recommended (see [Interaction with Existing Settings](#interaction-with-existing-settings))

Do not write yet.

### 3. Confirm with the user

Present a consolidated proposal in three sections (A / B-1 / C-1) showing:

- Rules to add (default: all in scope)
- Rules already covered (skipped, no action)
- Coexisting allow rules to clean up (user decides)

The user may opt out of any individual rule. Wait for explicit per-section approval before proceeding.

### 4. Apply

- If `.claude/settings.json` exists: use `Edit` to merge approved rules into the existing `permissions.deny` and `permissions.ask` arrays
- If not: use `Write` to create the file with the approved rule set
- Re-read the file after writing to verify it parses as valid JSON

### 5. Verify

List the resulting rules:

```sh
jq '.permissions' .claude/settings.json
```

Tell the user the rules take effect on the **next** Claude Code session; the running session does not pick up project-settings changes mid-flight.

## Target Rules

### A. Edit deny — persistence prevention

```json
{
  "permissions": {
    "deny": [
      "Edit(/.claude/settings.json)",
      "Edit(/.claude/settings.local.json)",
      "Edit(/.git/hooks/**)",
      "Edit(/.github/workflows/**)",
      "Edit(/.gitlab-ci.yml)",
      "Edit(/.circleci/**)",
      "Edit(/.husky/**)",
      "Edit(/.envrc)",
      "Edit(/.env)",
      "Edit(/.env.*)",
      "Edit(/.npmrc)",
      "Edit(/.mcp.json)"
    ]
  }
}
```

| Path | Threat blocked |
|------|----------------|
| `/.claude/settings*.json` | Attacker installs malicious hooks or relaxes permissions (CVE-2025-59536-class) |
| `/.git/hooks/**` | Attacker installs `pre-commit` / `post-checkout` for code execution at git events |
| `/.github/workflows/**`, `/.gitlab-ci.yml`, `/.circleci/**` | CI tampering — next push runs attacker code |
| `/.husky/**` | git hook (alternative form) |
| `/.envrc`, `/.env`, `/.env.*` | Secret overwrite or poisoning |
| `/.npmrc` | Registry override → malicious package install |
| `/.mcp.json` | MCP server addition — new tool surface for the attacker |

### B-1. Edit ask — confirmation gate for plugin-author paths

```json
{
  "permissions": {
    "ask": [
      "Edit(/.claude/skills/**)",
      "Edit(/.claude/agents/**)",
      "Edit(/.claude/commands/**)"
    ]
  }
}
```

These directories receive legitimate writes during plugin / skill / agent / command authoring. `ask` (not `deny`) preserves a confirmation gate without breaking the workflow. Under default / acceptEdits mode the user is prompted on each write; under auto mode the classifier may auto-approve `ask` matches it judges low-risk (see [Auto Mode Interaction](#auto-mode-interaction) below).

If the project will never author Claude Code plugins, the user may opt to promote these from `ask` to `deny` during Step 3.

### C-1. Read deny — credential file paths

Coverage of common credential locations across major cloud / VCS /
registry / database / IaC providers.

```json
{
  "permissions": {
    "deny": [
      "Read(/.env)",
      "Read(/.env.*)",
      "Read(/.envrc)",

      "Read(~/.ssh/**)",
      "Read(~/.gnupg/**)",

      "Read(~/.aws/**)",
      "Read(~/.azure/**)",
      "Read(~/.config/gcloud/**)",
      "Read(~/.config/doctl/**)",
      "Read(~/.heroku/**)",
      "Read(~/.netlify/**)",
      "Read(~/.vercel/**)",
      "Read(~/.fly/**)",

      "Read(~/.config/gh/**)",
      "Read(~/.config/glab-cli/**)",
      "Read(~/.netrc)",
      "Read(~/.config/git/credentials)",

      "Read(~/.docker/config.json)",
      "Read(~/.config/containers/auth.json)",

      "Read(~/.npmrc)",
      "Read(~/.yarnrc)",
      "Read(~/.yarnrc.yml)",
      "Read(~/.cargo/credentials*)",
      "Read(~/.pypirc)",
      "Read(~/.gem/credentials)",
      "Read(~/.composer/auth.json)",
      "Read(~/.nuget/NuGet.Config)",

      "Read(~/.pgpass)",
      "Read(~/.my.cnf)",
      "Read(~/.snowsql/config)",

      "Read(~/.terraform.d/credentials.tfrc.json)",
      "Read(~/.config/pulumi/credentials.json)",
      "Read(~/.kube/config)",

      "Read(~/.password-store/**)",
      "Read(~/.config/sops/**)",
      "Read(~/.config/age/**)"
    ]
  }
}
```

## Interaction with Existing Settings

Per Claude Code's permission system, rules evaluate in order **deny → ask → allow** with first-match-wins:

- A new `deny` rule blocks the matched tool regardless of any pre-existing `allow` rule for the same path. If the user later wants to relax it, they must remove the `deny` rule itself — adding a more-specific `allow` does not override it
- `Edit` and `Read` rule keywords expand to multiple built-in tools (`Edit` → Edit / Write / NotebookEdit, `Read` → Read / Grep / Glob)

Project-level settings take precedence over user-level (`~/.claude/settings.json`) when they conflict; managed settings (org-level) override both. See the [settings precedence docs](https://code.claude.com/docs/en/permissions#settings-precedence).

## Limitations

This skill is **one layer** of defense-in-depth. Gaps that fall outside this skill's scope and the layer that addresses each:

| Gap | Layer that addresses it |
|-----|--------------------------|
| Plaintext secrets in source content (e.g. `ghp_...` written into a file) | `checking-oss-release` pre-commit content scan |
| WebFetch exfiltration to arbitrary domain | User-supplied `WebFetch(domain:...)` allowlist (see [Recommended Supplements](#recommended-supplements)) |
| Bash route to security-config writes (`sed -i .claude/settings.json`, `tee .git/hooks/*`) | Not blocked by this skill. Mode-dependent visibility: default / acceptEdits prompt the user; auto mode may auto-approve. The bundled `sensitive-bash-guard` hook covers credential reads (not writes) |

## Auto Mode Interaction

When `defaultMode: "auto"` is set (typically via `hardening-auto-mode`), the rules in this skill behave as follows:

| Rule type | Auto mode behavior |
|-----------|--------------------|
| Section A `Edit` deny | **Hard guarantee** — Claude Code blocks the matched tool call regardless of classifier judgment. The Bash route is the gap (see Limitations) |
| Section C-1 `Read` deny | **Hard guarantee** — same as above. The Bash route is covered by the bundled `sensitive-bash-guard` PreToolUse hook |
| Section B-1 `Edit` ask (`.claude/{skills,agents,commands}/`) | **Soft hint** — verified 2026-04 (v2.1.123): the auto-mode classifier auto-approves `ask` matches it judges low-risk, with no prompt. If a confirmation gate is required for plugin-author paths even under auto mode, promote B-1 from `ask` to `deny` during Step 3 |
| Recommended `WebFetch(domain:...)` allowlist | **Hard guarantee for vendor URLs** — the allow rule passes them through. Non-vendor URLs fall through to `WebFetch` `ask`, which auto mode may auto-approve; the bundled `untrusted-content-reminder` PostToolUse hook injects a trust-boundary reminder so the agent treats the content as data |

This skill **does not** generate broad `allow` rules (`Bash(*)`, `Bash(awk *)`, `Bash(python *)`, `Agent(*)`, etc.). Auto mode silently drops these on entry, so generating them would create rules that vanish without notice. Narrow allows like `Bash(npm test)` are preferred and survive auto mode.

## Recommended Supplements

These are not generated by default but are documented for users who want to extend coverage.

### WebFetch domain allowlist

Restrict outbound HTTP via `WebFetch` to vendor-controlled documentation domains only:

```json
{
  "permissions": {
    "ask": ["WebFetch"],
    "allow": [
      "WebFetch(domain:docs.anthropic.com)",
      "WebFetch(domain:code.claude.com)"
    ]
  }
}
```

**Do not** allowlist domains that serve arbitrary user-generated content (`github.com`, `registry.npmjs.org`, `gist.github.com`, package registries, Stack Overflow, etc.). These return attacker-controlled text — README files, issue bodies, package metadata — that the agent would then process as trusted input. Allowlisting them defeats the purpose of an allowlist and creates a prompt-injection vector.

When the agent needs to fetch from a user-content site, leave `WebFetch` as `ask` for those domains rather than allow-listing them, so each fetch remains an explicit, visible decision. Note that under auto mode `ask` is a soft hint and the classifier may auto-approve the fetch — the bundled `untrusted-content-reminder` PostToolUse hook backstops this by injecting a trust-boundary reminder for non-vendor results.

### Outbound Bash deny

```json
{
  "permissions": {
    "deny": [
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(nc *)"
    ]
  }
}
```

Trade-off: legitimate `curl` invocations get blocked. Pair with the WebFetch allowlist above so the agent has a sanctioned route for vendor docs.

## Troubleshooting

| Situation | Action |
|-----------|--------|
| `.claude/settings.json` is malformed JSON | Stop. Report the parse error and ask the user to fix it manually before retrying — destructive merge is unsafe |
| `.claude/` directory does not exist | Create it as part of Step 4. `Write` on `.claude/settings.json` will create the directory automatically |
| All target rules are already present | Report no-op and exit. Do not rewrite the file |
| User has user-level (`~/.claude/settings.json`) overlapping rules | Note that project-level rules take precedence; user-level rules remain in effect for projects that lack the same rules |
| User wants to skip B-1 (`.claude/{skills,agents,commands}/**`) entirely | Apply A and C-1 only. The B-1 ask rules are independent of the others |
| Existing `permissions.allow` overlaps with our new `deny` | Show the overlap. Deny still takes effect (precedence), but recommend removing the redundant allow for clarity |
| Rules don't seem active after apply | The current Claude Code session does not reload project settings mid-flight. Restart the session and re-test |
