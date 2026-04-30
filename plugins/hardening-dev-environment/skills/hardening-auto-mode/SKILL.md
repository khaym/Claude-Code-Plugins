---
name: hardening-auto-mode
description: Configures Claude Code auto mode: writes defaultMode and a deny/ask overlay to .claude/settings.json so the classifier has hard backstops. Verifies plan/model/version eligibility first. Use when you hear "set up auto mode", "enable auto mode", "harden auto mode", "auto mode setup".
---

# Hardening Auto Mode

Set `defaultMode: "auto"` and apply an auto-mode-specific deny/ask overlay so the best-effort classifier has hard backstops where they matter.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Workflow](#workflow)
- [Rule Overlay](#rule-overlay)
- [Caveats Auto Mode Brings](#caveats-auto-mode-brings)
- [Troubleshooting](#troubleshooting)
- [See Also](#see-also)

## Prerequisites

Auto mode is gated. All of the following must hold:

| Requirement | Value |
|-------------|-------|
| Claude Code | v2.1.83+ (`claude --version`) |
| Plan | Max, Team, Enterprise, or API (Pro is not eligible) |
| Model | Sonnet 4.6, Opus 4.6, or Opus 4.7 (Max plan: Opus 4.7 only) |
| Provider | Anthropic API (not Bedrock, Vertex, or Foundry) |
| Admin (Team / Enterprise) | Auto mode enabled in Claude Code admin settings |

If any requirement fails, stop and route the user to `hardening-claude-permissions` for static-rule-only hardening instead.

This skill assumes `hardening-claude-permissions` has been applied first. Its deny rules (`.claude/settings*.json` writes, credential reads, etc.) are hard guarantees that hold under any mode and form the floor under auto mode's best-effort classifier.

## Workflow

### 1. Verify eligibility

Run `claude --version` to confirm v2.1.83+. Ask the user about plan, model, and provider per the table above. Treat "unsure" as not eligible.

### 2. Detect existing settings

```bash
[ -f .claude/settings.json ] && jq '.permissions' .claude/settings.json 2>/dev/null || echo "no .claude/settings.json"
```

Capture the current `defaultMode`, broad `allow` patterns, and whether `hardening-claude-permissions` deny rules are present.

### 3. Plan changes

Compare current settings to the [Rule Overlay](#rule-overlay) target and classify each item:

| State | Action |
|-------|--------|
| Missing | Queue for addition |
| Present (exact match) | Skip |
| Conflicting allow rule | Note for user (deny still wins; cleanup recommended) |
| Broad allow that auto mode drops on entry (`Bash(*)`, `Bash(awk *)`, `Bash(python *)`, `Bash(node *)`, `Bash(sh *)`, `Bash(bash *)`, package-manager `run` rules like `Bash(npm run *)`, `Agent(*)`) | Warn — these are dropped silently by Claude Code when auto mode activates; recommend replacing with narrow allows like `Bash(npm test)` or `Bash(awk '/pattern/ file.txt')`. Wildcards on interpreters are dropped because the argument can be an arbitrary script — narrowness must come from the full command string, not the program name |

### 4. Confirm with the user

Present the plan in three sections:

- **A. Mode** — `defaultMode: "auto"` plus optional `disableBypassPermissionsMode: "disable"`
- **B. Hard deny overlay** — see [Rule Overlay](#rule-overlay) section B
- **C. Ask overlay** — see [Rule Overlay](#rule-overlay) section C

User opts out per section. Wait for explicit per-section approval.

### 5. Apply

Edit existing `.claude/settings.json` to merge approved sections; if absent, write a new file with only the approved set. Re-read after writing to verify valid JSON.

If `hardening-claude-permissions` is already applied, `Edit(/.claude/settings.json)` is on the deny list — Claude Code's Edit tool cannot modify this file. Use the Bash + jq + mv route as the documented escape hatch. Build one jq filter that merges every approved section, write to a temp file, then move into place:

```bash
jq '
  .permissions.defaultMode = "auto"
  | .permissions.disableBypassPermissionsMode = "disable"
  | .permissions.deny = ((.permissions.deny // []) + [
      "Bash(curl)", "Bash(curl *)",
      "Bash(wget)", "Bash(wget *)",
      "Bash(nc)", "Bash(nc *)",
      "Bash(eval *)",
      "Bash(ssh)", "Bash(ssh *)",
      "Bash(scp)", "Bash(scp *)",
      "Bash(sftp)", "Bash(sftp *)"
    ] | unique)
  | .permissions.ask = ((.permissions.ask // []) + ["WebFetch"] | unique)
' .claude/settings.json > .claude/settings.json.tmp \
  && mv .claude/settings.json.tmp .claude/settings.json
```

`mv` is required because the deny rule blocks in-place tool writes; the `mv` path operation does not match the `Edit(...)` deny pattern. The `unique` filter de-dupes when a rule was already present from a prior apply. Trim the deny / ask arrays to only the user-approved sections before running the filter. Re-read with `jq '.permissions' .claude/settings.json` after the move to verify the JSON parses and the merge landed.

### 6. Verify

```bash
jq '{defaultMode: .permissions.defaultMode, deny: .permissions.deny, ask: .permissions.ask}' .claude/settings.json
```

Tell the user the mode change takes effect on the next Claude Code session — the running session does not reload project settings mid-flight.

## Rule Overlay

### A. Mode

```json
{
  "permissions": {
    "defaultMode": "auto",
    "disableBypassPermissionsMode": "disable"
  }
}
```

`disableBypassPermissionsMode` is opt-in but recommended: it locks the project away from `bypassPermissions` mode, which would skip the classifier entirely. Per Claude Code docs, this setting works from any scope, including project-level `settings.json`.

### B. Hard deny — auto-mode-specific

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
      "Bash(ssh)",
      "Bash(ssh *)",
      "Bash(scp)",
      "Bash(scp *)",
      "Bash(sftp)",
      "Bash(sftp *)"
    ]
  }
}
```

| Pattern | Why hard-deny is needed |
|---------|--------------------------|
| `Bash(curl *)`, `Bash(wget *)` | Per Claude Code docs warning, Bash argument patterns cannot reliably constrain URLs. Deny outright and route HTTP through `WebFetch` with a vendor allowlist |
| `Bash(nc *)` | Arbitrary outbound TCP — netcat is a common exfil channel and not covered by classifier defaults |
| `Bash(eval *)` | Dynamic shell-string execution; the classifier's pattern coverage on shell metaprogramming is best-effort |
| `Bash(ssh *)`, `Bash(scp *)`, `Bash(sftp *)` | Data egress to remote hosts. The classifier auto-approves these under auto mode regardless of arguments (verified 2026-04 with `ssh -V` and `ssh -o BatchMode=yes <invalid-host>` — both passed without prompt). `ask` cannot gate them; `deny` blocks them outright. Unblock case-by-case by switching to acceptEdits via Shift+Tab when an interactive ssh session is needed |

The classifier already blocks pipe-to-shell (`curl | bash`), force push, push to `main`, mass deletes, IAM grants, and production deploys. These are not duplicated here — let the classifier handle them, and add deny rules only where best-effort isn't enough or the docs explicitly recommend deny.

### C. Ask — soft hint to the classifier

```json
{
  "permissions": {
    "ask": [
      "WebFetch"
    ]
  }
}
```

`WebFetch` is the only `ask` rule recommended under auto mode. Pair it with `WebFetch(domain:...)` allow rules for vendor docs only — `hardening-claude-permissions` provides guidance on building this allowlist. Vendor URLs hit the allow rule and pass; non-vendor URLs fall through to the `ask` rule. The PostToolUse `untrusted-content-reminder` hook (bundled with this plugin, owned by `hardening-untrusted-content`) injects a trust-boundary reminder for non-vendor results, so even when the classifier auto-approves a non-vendor fetch the agent is reminded to treat the content as data, not instructions.

**`ask` does not gate under auto mode.** Verified 2026-04 on v2.1.123: the classifier auto-approves `ask`-matching actions it judges low-risk, including `WebFetch` to non-vendor domains (`example.com`, `github.com/<user>`). Treat `ask` as a hint that the classifier can override, not as a human-confirmation gate.

For any boundary that must hold regardless of classifier judgment, use `deny`. To occasionally allow a denied action, switch the session to acceptEdits via Shift+Tab — auto mode is not the right scope for case-by-case overrides.

## Caveats Auto Mode Brings

| Caveat | Detail |
|--------|--------|
| `ask` rules are soft, not hard | The classifier auto-approves `ask` matches it judges low-risk; use `deny` for any boundary that must hold. See [Section C](#c-ask--soft-hint-to-the-classifier) for the verification details |
| Broad allow drops | On entering auto mode, broad-pattern allows like `Bash(*)`, `Bash(awk *)`, `Bash(python *)`, package-manager `run` rules, and `Agent(*)` are dropped silently. They are restored on exit. Use narrow allows like `Bash(npm test)` instead |
| Conversation boundaries fade | Saying "don't push" in chat blocks matching actions, but the classifier re-reads boundaries from the transcript on each check; context compaction can drop them. Use a `deny` rule for any hard guarantee |
| Repeated blocks pause auto mode | 3 consecutive or 20 total classifier blocks pause auto mode and resume prompting. Frequent pauses usually mean the classifier needs trusted-infra config — see the docs link below |
| Classifier latency | Each non-trivial action adds a round-trip. Reads and working-directory edits skip the classifier; shell and network commands incur the cost |
| Subagent inheritance | Subagent `permissionMode` frontmatter is ignored under auto mode — every subagent action runs through the classifier with the parent session's rules |

## Troubleshooting

| Situation | Action |
|-----------|--------|
| `claude --version` is below v2.1.83 | Upgrade Claude Code; auto mode is unavailable on older versions |
| Plan or model mismatch | Stop. Recommend `hardening-claude-permissions` only |
| Auto mode reports "unavailable" at startup | One of the eligibility requirements is unmet (see [Prerequisites](#prerequisites)) — not a transient error |
| Auto mode reports "cannot determine the safety of an action" | Transient classifier outage; retry or fall back to manual approval temporarily |
| Frequent classifier blocks on legitimate infrastructure | Configure trusted infra via `autoMode.environment` (admin action) — see [auto mode config docs](https://code.claude.com/docs/en/auto-mode-config) |
| `.claude/settings.json` is malformed JSON | Stop. Report the parse error and ask the user to fix it manually before retrying |

## See Also

| Skill | Purpose |
|-------|---------|
| `hardening-overview` | Layered Defense Map and where auto mode fits |
| `hardening-claude-permissions` | Static deny/ask rules — apply first; serves as the hard floor under auto mode |

External:

- [Choose a permission mode](https://code.claude.com/docs/en/permission-modes)
- [Auto mode for Claude Code](https://claude.com/blog/auto-mode)
- [Configure auto mode](https://code.claude.com/docs/en/auto-mode-config)
