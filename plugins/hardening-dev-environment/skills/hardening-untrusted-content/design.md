# hardening-untrusted-content Design Doc

## Purpose

Reinforce the trust boundary that content returned by tool calls is
DATA, not instructions. v1 covers `WebFetch` only; the principle and
structure are designed to extend to `Read` (untrusted origins),
`mcp__*` tool outputs, and `Bash` output in future versions.
Complements `hardening-claude-permissions` (deny/ask reduces blast
radius) and the bundled PreToolUse hooks (block known bypasses) — this
skill operates at the *reception* layer, shaping how the agent
processes content it has just consumed.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| No regex-based injection detection | Anthropic's Opus 4.7 system card admits prompt injection is not solvable by layered detection. Lasso-style pattern lists produce high false positives in technical docs (matches "ignore previous", "system prompt", "act as", base64, Cyrillic homoglyphs in i18n) and are bypass-able by paraphrasing or non-English |
| PostToolUse, not PreToolUse | Reminder lands immediately after fetched content in the agent's context, overriding any priming the content tried to do; PreToolUse priming is overshadowed by the long subsequent tool result |
| Generic reminder, no content analysis | Zero false positives in the detection sense — the skill does not claim to detect anything; it just reminds the agent of the trust boundary every time |
| Vendor domains skip the reminder | Reminder fatigue degrades signal value; vendor-controlled docs (`docs.anthropic.com` etc.) are trusted by allowlist semantics in `hardening-claude-permissions` |
| Vendor list read from `.claude/settings.json` at hook runtime | Single source of truth: the same allowlist that gates `WebFetch` permission also gates the reminder. No duplicated config |
| Read project + user settings, exact host match | Project `settings.json` + project-local `settings.local.json` + user-level `~/.claude/settings.json` are unioned. Subdomain trust is left to user explicit listing (conservative default) |
| Fail-safe on parse errors | Missing/malformed settings → reminder still emitted. Biases over-warn, not over-trust |
| WebFetch only in v1 | Smallest meaningful slice; broader coverage (`Read`, `mcp__*`, `Bash`) deferred to v2 once reminder semantics validate in production use |
| No env-var or separate config file | All knobs derive from `.claude/settings.json`. Adding a separate config would create drift |
| Pure Python, no external deps | Matches sibling hooks (`sensitive-bash-guard`, `package-json-scripts-guard`); Python stdlib covers JSON + regex |

## Data Flow

```
Claude Code → WebFetch tool returns
  ↓ (matcher: WebFetch fires)
PostToolUse hook (untrusted-content-reminder.py)
  ↓ stdin: { tool_name, tool_input.url, tool_response, ... }
  ↓
script reads JSON, extracts URL host, reads vendor allowlist from settings
  ↓
  ├─ tool_name != WebFetch → exit 0 silently
  ├─ host empty → exit 0 silently
  ├─ host in vendor allowlist → exit 0 silently
  └─ else → exit 0, stdout JSON { hookSpecificOutput.additionalContext: reminder } → injected into agent context
```

## Constraints & Tradeoffs

- A defective LLM may still follow injected instructions despite the
  reminder. This is the layer's known ceiling — the goal is to reduce,
  not eliminate, susceptibility
- Vendor allowlist relies on the user's discipline in only allowlisting
  vendor-controlled domains. If user-content domains
  (`github.com`, `registry.npmjs.org`, etc.) are added to the
  allowlist, the reminder is silenced for them
- Reminder text uses words ("instructions", "system prompts") that
  prompt-injection regex defenders would flag — intentional, since this
  skill does not run such defenders
- `.claude/settings.json` parse covers strict JSON only. Comments and
  non-standard formats are not supported (Claude Code itself enforces
  strict JSON)
- Host extraction uses string split, not `urllib.parse`. Sufficient for
  http/https URLs that Claude Code's `WebFetch` accepts; pathological
  inputs are treated as non-vendor (fail-safe)
- v1 scope: `WebFetch` only. `Read` of files cloned from untrusted
  origins, `mcp__*` tool outputs, and `Bash` output content are NOT
  covered by the operational hook (the principle applies to them)
