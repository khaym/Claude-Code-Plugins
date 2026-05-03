---
name: hardening-claude-permissions
description: Writes acceptEdits-tuned permission rules into .claude/settings.json — deny on config writes, credential reads, outbound and privilege-escalation Bash; ask on plugin-author paths; safe-bash allow baseline. Use when you hear "harden claude permissions" or "lock down claude code".
---

# Hardening Claude Code Permissions

Reduce the blast radius of prompt injection or compromised dependencies on a Claude Code session by writing recommended `permissions.{deny, ask, allow}` rules into `.claude/settings.json`. The rule set is tuned for `defaultMode: "acceptEdits"` — file edits are auto-approved by the mode, so denying them at the rule layer is the only way to gate persistence; Bash actions are asked by the mode, so this skill hard-denies the bash routes that should never run and pre-allows a baseline of safe commands to reduce prompt fatigue. For the full layered defense picture and where this skill fits, see `hardening-overview`.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Workflow](#workflow)
- [Target Rules](#target-rules)
- [Interaction with Existing Settings](#interaction-with-existing-settings)
- [Limitations](#limitations)
- [Operational Modes](#operational-modes)
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

If it exists, parse the `permissions.deny`, `permissions.ask`, `permissions.allow`, and `permissions.defaultMode` keys. Build a mental model of which target rules are already present, missing, or conflicting.

If `.claude/` does not exist, it is created in Step 4.

### 2. Plan changes

For each target rule from [Target Rules](#target-rules), classify against the existing settings:

- **Missing** — queue for addition
- **Present (exact match)** — skip
- **Covered by a superset** (e.g., user has `Edit(/.claude/**)` and we want `Edit(/.claude/settings.json)`) — skip; user's broader rule already protects ours
- **Coexisting allow rule** (e.g., user has `allow: Edit(/.npmrc)` and we want `deny:`) — note for the user; cleanup recommended (see [Interaction with Existing Settings](#interaction-with-existing-settings))

Do not write yet.

### 3. Confirm with the user

Present a consolidated proposal in five sections (A / B-1 / C-1 / D-1 / D-2) showing:

- Rules to add (default: all in scope)
- Rules already covered (skipped, no action)
- Coexisting allow rules to clean up (user decides)

The user may opt out of any individual rule. Wait for explicit per-section approval before proceeding.

### 4. Apply

Pick the apply path based on the existing settings:

- **`.claude/settings.json` does not exist** — use `Write` to create the file with the approved rule set
- **File exists, Section A's `Edit(/.claude/settings.json)` is not yet in `permissions.deny`** (typical first run) — use `Edit` to merge approved rules into the existing `permissions.deny`, `permissions.ask`, and `permissions.allow` arrays, and set `permissions.defaultMode` if not already present
- **File exists, Section A's `Edit(/.claude/settings.json)` is already in `permissions.deny`** (typical re-run, e.g. adding new rules later) — the deny rule blocks the `Edit` tool. Use the bash route instead:

  ```sh
  TMP=$(mktemp --suffix=.json)
  jq '<merge expression>' .claude/settings.json > "$TMP" && mv "$TMP" .claude/settings.json
  ```

  This is intentional: the deny rule scopes to Claude Code's `Edit` / `Write` / `NotebookEdit` tools, while the bash route via `jq` + atomic `mv` is the documented escape hatch. Use it only inside this skill's workflow, after explicit user approval in Step 3 — not as a general-purpose bypass

After every write path, re-read the file to verify it parses as valid JSON.

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
      "Edit(/.vscode/**)",
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
| `/.vscode/**` | IDE config tampering — `tasks.json` runs shell on task invocation, `launch.json` chains `preLaunchTask`, `settings.json` overrides terminal profiles to poison shell startup |
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

These directories receive legitimate writes during plugin / skill / agent / command authoring. `ask` (not `deny`) preserves a confirmation gate without breaking the workflow.

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

### D-1. Bash deny — outbound, privilege escalation, and unsafe package execution

```json
{
  "permissions": {
    "deny": [
      "Bash(curl)",
      "Bash(curl *)",
      "Bash(wget)",
      "Bash(wget *)",
      "Bash(nc)",
      "Bash(nc *)",
      "Bash(eval *)",
      "Bash(sudo)",
      "Bash(sudo *)",
      "Bash(su)",
      "Bash(su *)",
      "Bash(npx)",
      "Bash(npx *)"
    ]
  }
}
```

| Pattern | Threat blocked |
|---------|----------------|
| `Bash(curl/wget/nc *)` | Outbound exfiltration of repository contents or credentials to attacker infrastructure |
| `Bash(eval *)` | Indirect execution of dynamically-constructed command strings — a primary obfuscation vector |
| `Bash(sudo/su *)` | Privilege escalation. On NOPASSWD-sudo environments (typical of devcontainers), Claude can otherwise run `sudo tee .claude/settings.json` to overwrite a Section A-protected file via the bash route. Hard-denying sudo/su closes that gap (verified 2026-05) |
| `Bash(npx *)` | Registry fetch + arbitrary code execution. The `hardening-pnpm-config` skill migrates `npx` to `pnpm dlx`, which applies registry verification, `minimumReleaseAge`, and install-script blocking. A Claude-initiated `npx` is either pre-migration legacy or a bypass attempt |

These rules are `deny` rather than `ask` because:
- Outbound HTTP from Claude Code should funnel through `WebFetch` (which has its own `WebFetch(domain:...)` allowlist, see [Recommended Supplements](#recommended-supplements)), not arbitrary `curl`
- Privilege escalation has no legitimate Claude use case — administrative tasks belong to the user, performed in their own terminal where this rule does not apply
- `npx` has a sanctioned replacement (`pnpm dlx <pkg>@<version>`) shipped by the sibling skill, so denying it does not remove a needed capability

If a project legitimately needs `curl` against a known vendor API, prefer adding the specific `WebFetch(domain:...)` allow rule rather than relaxing this deny.

### D-2. Operating mode and safe Bash allow baseline

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(ls)",
      "Bash(ls *)",
      "Bash(pwd)",
      "Bash(echo *)",
      "Bash(git status)",
      "Bash(git diff)",
      "Bash(git diff *)",
      "Bash(git log)",
      "Bash(git log *)",
      "Bash(git branch)",
      "Bash(git branch *)"
    ]
  }
}
```

`defaultMode: "acceptEdits"` auto-approves file edits but keeps Bash asked. The allow baseline reduces prompt fatigue on read-only commands with no security implications:

- All listed commands are read-only; none mutate state, write files, or send network traffic
- The list is intentionally minimal — extend it incrementally for your project using the `fewer-permission-prompts` skill, which scans your transcript for repeated read-only Bash and proposes additions

Do **not** allow broad patterns like `Bash(*)`, `Bash(npm *)`, `Bash(python *)`, or any package-manager script runner (`Bash(npm run *)`, `Bash(pnpm run *)`, `Bash(yarn run *)`, `Bash(bun run *)`). Broad patterns include destructive subcommands (`npm publish`, `python -c "open(...,'w').write(...)"`) that should remain asked. Script runners execute arbitrary `package.json` `scripts` entries, which a compromised dependency or fork can rewrite — the bundled `package-json-scripts-guard` hook blocks tampering with `scripts`, but a *pre-existing* malicious script will still run if the user pre-allows the runner. Pre-allow specific scripts only (e.g. `Bash(npm run test)`).

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
| Writes to security-config or credential paths via Bash or arbitrary-language scripts (`sed -i .claude/settings.json`, `tee .git/hooks/*`, `python -c "open(...,'w')"`, npm install postinstall hooks running `node`) | Not blocked by this skill — the bundled `sensitive-bash-guard` hook covers Bash credential **reads** but not writes, and arbitrary-language script writes never appear on the bash command line. Full coverage requires an OS-layer approach (ACL with Claude running under a separate user) |

## Operational Modes

This skill targets `defaultMode: "acceptEdits"` as the **recommended permission mode**. The rule set assumes this mode and is tuned for its prompt behavior:

- `Edit/Write/NotebookEdit` are auto-approved by the mode itself, so denying them at the rule layer (Section A) is the only way to gate persistence-target writes
- `Bash` is asked by default in acceptEdits, so Section D-1 hard-denies the bash routes that should never run and Section D-2 sets a baseline of safe always-allow commands

### Other modes

| Mode | Compatibility | Notes |
|------|---------------|-------|
| `default` | Compatible | All Edit and Bash actions are asked anyway; Section D-2's allow baseline still reduces fatigue on safe Bash |
| `acceptEdits` | **Recommended** | The rule set is tuned for this mode |
| `dontAsk` | Compatible (CI use) | Denies everything not explicitly allowed; users must extend Section D-2 with their CI's required Bash patterns. The auto-mode classifier is not active in non-interactive runs |
| `auto` | Out of scope | Auto mode is a research-preview Claude Code feature whose `ask` / `allow` interaction with the classifier is non-deterministic. This skill does not target auto mode. Users who choose auto mode should rely on Sections A, C-1, and D-1 (mode-agnostic deny — verified hard guarantees) and treat all `ask` / `allow` rules as advisory under that mode |

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

When the agent needs to fetch from a user-content site, leave `WebFetch` as `ask` for those domains rather than allow-listing them, so each fetch remains an explicit, visible decision. The bundled `untrusted-content-reminder` PostToolUse hook backstops this by injecting a trust-boundary reminder for non-vendor results.

### Git remote tampering guard

Threat: a compromised dependency rewrites `.git/config` (or adds a new remote), then a subsequent `git push` exfiltrates repository contents to attacker infrastructure. Section A's `.git/hooks/**` deny stops the hook-write path, but `.git/config` is intentionally writable so legitimate remote setup can proceed — leaving the remote-URL surface as a residual exfiltration channel.

```json
{
  "permissions": {
    "ask": [
      "Bash(git remote add *)",
      "Bash(git remote set-url *)",
      "Bash(git config remote.* *)",
      "Bash(git push --mirror *)",
      "Bash(git push --all *)"
    ]
  }
}
```

Trade-offs:

- Scoped to **remote-mutating** subcommands and **broad-scope pushes**, not every `git push`. Daily push to an established `origin` is high-frequency; gating every push creates prompt fatigue
- `ask` preserves visibility at the moment a remote is being added or rewritten — the actual exfiltration trigger
- For stricter projects, promote these to `deny` and perform remote setup manually
- The Bash-route caveat from [Limitations](#limitations) still applies: an attacker reaching `.git/config` via `sed -i` or `tee` is not gated by these rules. The first three patterns above narrow that gap by covering the canonical `git config` invocation

## Troubleshooting

| Situation | Action |
|-----------|--------|
| `.claude/settings.json` is malformed JSON | Stop. Report the parse error and ask the user to fix it manually before retrying — destructive merge is unsafe |
| `.claude/` directory does not exist | Create it as part of Step 4. `Write` on `.claude/settings.json` will create the directory automatically |
| All target rules are already present | Report no-op and exit. Do not rewrite the file |
| User has user-level (`~/.claude/settings.json`) overlapping rules | Note that project-level rules take precedence; user-level rules remain in effect for projects that lack the same rules |
| User wants to skip B-1 (`.claude/{skills,agents,commands}/**`) entirely | Apply A, C-1, D-1, D-2 only. The B-1 ask rules are independent of the others |
| User wants to skip D-2 default mode | Apply A, B-1, C-1, D-1 only. Note that without `defaultMode: "acceptEdits"` the workflow falls back to `default` mode, which prompts for every Edit; this is a usability regression but does not weaken security |
| Existing `permissions.allow` overlaps with our new `deny` | Show the overlap. Deny still takes effect (precedence), but recommend removing the redundant allow for clarity |
| Existing `permissions.defaultMode` differs from `acceptEdits` | Show the value and note the rule set is tuned for `acceptEdits`. If the user prefers their existing mode, apply A / C-1 / D-1 (mode-agnostic) and skip D-2; warn that `ask` rules become advisory under `auto` mode |
| Rules don't seem active after apply | The current Claude Code session does not reload project settings mid-flight. Restart the session and re-test |
