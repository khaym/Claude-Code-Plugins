# hardening-auto-mode Design Doc

## Purpose

Configure Claude Code auto mode (introduced in v2.1.83) so a project gets the prompt-fatigue reduction of auto mode without losing hard guarantees. Sets `defaultMode: "auto"` and writes a small deny/ask overlay that fills gaps the best-effort classifier may leave open.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Layer on top of `hardening-claude-permissions` rather than duplicate its rules | The static deny rules from that skill are mode-agnostic hard guarantees. This skill assumes they are present and adds only auto-mode-specific overlay |
| Hard-deny `Bash(curl *)` / `Bash(wget *)` (not classifier-implicit only) | Per Claude Code docs, Bash arg patterns cannot reliably constrain URLs. Deny outright and route HTTP through `WebFetch(domain:...)` for trusted domains |
| Do not duplicate classifier defaults (force push, prod deploy, mass delete, push to `main`) | Classifier already blocks these. Redundant deny rules inflate the rule surface without adding guarantee, except where the docs explicitly recommend deny |
| `Bash(ssh / scp / sftp *)` are deny, not ask | Verified 2026-04 (v2.1.123): the auto-mode classifier auto-approves `ask`-matching commands it judges low-risk, including ssh with arguments that imply connection intent. `ask` cannot enforce human confirmation under auto mode, so the only way to keep remote-egress under explicit human control is `deny`. acceptEdits via Shift+Tab is the documented case-by-case override |
| `WebFetch` stays as `ask`, not deny | The vendor allowlist (`WebFetch(domain:...)` allow rules) is the primary control. Vendor URLs pass, non-vendor URLs fall through `ask`. Although the classifier auto-approves non-vendor `ask` matches under auto mode, the bundled PostToolUse `untrusted-content-reminder` hook (owned by `hardening-untrusted-content`) injects a trust-boundary reminder so the agent treats non-vendor content as data. Promoting `WebFetch` to deny would erase the auto-mode utility without adding guarantee — the trust boundary is enforced by the hook, not the classifier |
| `ask` rule kept as classifier hint, not human-confirmation gate | `ask` is documented as "ask the user" but empirically the auto-mode classifier may resolve `ask` itself. The doc says modes set the baseline and rules layer on top, but the prompt-step is not contractually guaranteed under auto mode. The skill records this in Caveats and Section C so users do not rely on `ask` as a hard gate |
| `disableBypassPermissionsMode: "disable"` is opt-in | Locking out bypass mode is security-positive but a one-way door; user opts in explicitly so they understand the consequence |
| Eligibility check before any change | Auto mode silently rejects ineligible plans / models / versions. Failing fast saves the user a confusing partial setup |
| Three section gates (A mode / B deny / C ask) | Predictable surface that lets users opt out per section without per-rule micro-decisions |
| Bootstrap when `Edit(/.claude/settings.json)` is already denied | Once `hardening-claude-permissions` has applied, the Edit/Write tools cannot modify `settings.json` — the skill has to use the documented Bash + `jq` + `mv` route instead. The deny rule covers in-place tool writes; `mv` is a path operation the deny pattern does not match. Documented in Workflow Step 5 |
| Freedom level: Medium-Low | Rule sets are fixed; eligibility check requires user-supplied facts; only merge conflicts and section opt-outs need flexibility |

## Data Flow

```
Input: project root, eligible Claude Code session, hardening-claude-permissions applied
  ↓
Step 1: Verify — claude --version + ask user (plan / model / provider)
  ↓
Step 2: Detect — read .claude/settings.json, parse defaultMode + permissions.{deny, ask, allow}
  ↓
Step 3: Plan — for each rule from overlay: missing / present / conflicting / broad-allow-warning
  ↓
Step 4: Confirm — three sections (A mode / B deny / C ask), per-section opt-out
  ↓
Step 5: Apply — Edit existing or Write new settings.json; re-read to verify JSON
  ↓
Step 6: Verify — jq dump + restart-required notice
```

## Constraints & Tradeoffs

- Eligibility depends on user self-report for plan / model / provider. The skill cannot detect these directly from the running session
- `ask` rules are not a human-confirmation gate under auto mode — the classifier auto-approves matches it judges low-risk. Verified 2026-04 (v2.1.123) with `ssh -V`, `ssh <invalid-host>`, `WebFetch https://example.com`, `WebFetch https://github.com/<user>` — all auto-approved. Project policy that requires human confirmation must use `deny` instead, and unblock case-by-case via Shift+Tab to acceptEdits
- Bash deny on `curl` / `wget` / `ssh` blocks legitimate use; pair with `WebFetch(domain:...)` allowlist (documented by `hardening-claude-permissions`) for sanctioned outbound HTTP, and switch to acceptEdits when an interactive ssh session is needed
- Classifier accumulates counters (3 consecutive or 20 total blocks) that pause auto mode. Frequent pauses are usually a trusted-infra-config issue, not a deny-rule issue; this skill does not configure `autoMode.environment`
- Settings precedence (managed > project > user) is not reconciled. Cross-layer conflicts are out of scope
- The Bash patterns are written as both `Bash(name)` and `Bash(name *)` because Claude Code matches each subcommand independently and `Bash(name)` only matches the bare invocation (e.g., `... | curl`); the wildcard variant covers `name <args>`
