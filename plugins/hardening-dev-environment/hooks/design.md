# Hooks Design Doc

## Purpose

Hooks bundled with `hardening-dev-environment` to catch attack patterns the static `permissions.{deny,ask}` rules cannot:

**PreToolUse (block):**

1. **sensitive-bash-guard** — Read-only Bash commands (`cat`, `find`, `grep`, etc.) targeting credential paths bypass the `Read(...)` deny rules in `.claude/settings.json` (per Claude Code docs, Read deny applies only to built-in tools, not Bash subprocesses). This hook is the dynamic backstop for the static C-1 rule set.
2. **package-json-scripts-guard** — `package.json`'s `"scripts"` field is a high-value supply-chain persistence vector, but file-level `Edit(/package.json)` deny is too coarse (legitimate dependency edits would be blocked). This hook detects `"scripts"` diffs only.
3. **pyproject-buildsystem-guard** — `pyproject.toml`'s `[build-system]` table selects and parameterizes the PEP 517 build backend, which executes arbitrary code at build/install time. `setup.py` is itself executable at sdist build / install time. File-level deny on `pyproject.toml` would block legitimate `[tool.uv]` / `[project]` / `[project.dependencies]` edits, so this hook is section-scoped for `pyproject.toml` and file-scoped for `setup.py`.

**PostToolUse (context inject):**

4. **untrusted-content-reminder** — Marks `WebFetch` results from non-vendor URLs as untrusted DATA via `additionalContext`, reinforcing the trust-boundary principle owned by the `hardening-untrusted-content` skill. Design rationale, data flow, and constraints are documented at `../skills/hardening-untrusted-content/design.md` (single source of truth for this hook's design).

The remaining sections of this document apply to the PreToolUse hooks. PostToolUse design details live in the skill's design doc above.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Pure Python (not bash + jq) | All three PreToolUse scripts handle JSON I/O and string operations; Python's stdlib covers both with no escape-noise. Removes the `jq` dependency |
| Block via JSON `permissionDecision: "deny"` (Option B in hooks docs) | Provides a clean reason string visible to the user, vs `exit 2`'s stderr-only message |
| Bash command split on `;`, `&&`, `\|\|`, `\|`, `&`, `\|&`, newline | Matches Claude Code's documented compound-command separators; each subcommand evaluated independently |
| Wrappers stripped: `timeout`, `time`, `nice`, `nohup`, `stdbuf`, `sudo`, `env` | First five mirror Claude Code's matcher; `sudo` and `env` are common but not in Claude's matcher list — adding them closes the obvious wrapper bypass |
| Sensitive path regex mirrors C-1 of `hardening-claude-permissions` skill | Single source of pattern truth; static deny + dynamic block target the same path set |
| Sensitive path prefixes include `/home/<user>`, `/Users/<user>`, `/root` in addition to `~` and `$HOME` | Absolute-path forms (`/home/alice/.aws/credentials`) are an obvious tilde bypass |
| File-level checks match by basename (any depth) | Monorepo workspaces have one `package.json` / `pyproject.toml` per package; same threat applies to all |
| New file (Write to non-existent file) — allow | `npm init` / `uv init` / `pip install -e .` etc. write fresh files; no old config to compare against |
| Edit simulated via `old_string.replace(...)` against current file | Claude Code's Edit guarantees `old_string` uniqueness, so single-replace is exact |
| package.json: block on any `scripts` change (add / modify / remove) | Removal is also a tampering vector (clear-then-replace pattern) |
| pyproject.toml: section-scoped to `[build-system]` and `[build-system.*]` sub-tables | Covers PEP 517 backend selection and backend-specific config; excludes legitimate `[project]` / `[tool.uv]` edits |
| pyproject.toml `[build-system]` extracted by line-based parser, not TOML library | Avoids `tomllib` (Python 3.11+) hard dependency. Covers canonical TOML table headers (`[build-system]`, `[build-system.config]`); deeply unusual whitespace forms (`[ build-system ]`) are not in scope |
| setup.py: any modification blocks (no section scoping) | Entire file is executable at sdist build / install time; static analysis of `setup()` call boundaries is unreliable |
| No allowlist or opt-out config in v1 | Keep the surface small; add when concrete false-positive cases arise |

## Data Flow

```
Claude Code → tool call (Bash | Edit | Write)
  ↓ (matcher fires)
PreToolUse hook (one or more scripts based on matcher;
  Edit|Write fans out to package-json-scripts-guard
  AND pyproject-buildsystem-guard)
  ↓ stdin: { tool_name, tool_input, ... }
  ↓
script reads JSON, evaluates threat patterns
  ↓
  ├─ no match → exit 0, no stdout → tool call proceeds
  └─ match    → exit 0, stdout JSON { permissionDecision: "deny", reason: ... } → tool call blocked
```

## Known Bypass Vectors (Acknowledged)

The static patterns intentionally do not cover:

- Variable expansion: `f=.env; cat $f`
- Argument piping: `echo .env | xargs cat`
- Process substitution: `cat <(cat .env)`
- Heredoc, `eval`, `base64` decoded paths
- File renamed before read: `cp .env /tmp/x; cat /tmp/x`

These are out of scope for a static regex. The hook is one layer; an adversary who fully controls the agent's bash output can bypass it. The defense relies on combining this with: settings.json deny rules (`hardening-claude-permissions` skill), pre-commit secret scan (`checking-oss-release`), and the user's awareness of unusual Bash commands in transcript review.

## Constraints & Tradeoffs

- Hook depends on `python3` (standard on Linux / macOS / WSL)
- Sensitive path regex is best-effort string matching, not shell-aware semantics (no AST parser)
- pyproject.toml section detection is line-based, not a full TOML parser; canonical table headers are covered, exotic whitespace forms (`[ build-system ]`) are not
- File Edit simulation reads disk for the existing file; if the file is modified between hook fire and tool execution (rare race), the comparison is stale
- Single-version pattern set, no per-project tuning. Adding allowlist / opt-out config is deferred to v2 when concrete need surfaces
