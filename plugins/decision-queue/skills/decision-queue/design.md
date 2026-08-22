# decision-queue Design Doc

## Purpose

Keep every judgment awaiting the user visible at once. A conversation log is
linear and shows only the latest topic, so when several questions are open the
older ones silently drop off the user's radar. The queue file plus the
statusline renderer form a resident view of "everything waiting on you".

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| One queue file per session (`<queue-dir>/<session_id>.md`) | Pending decisions are session-local state; anything that must outlive the session belongs in a tracker or document. Parallel sessions in one project must not see each other's items. |
| The SessionStart hook announces the file path via injected context | The model has no reliable way to learn its own session id; injecting the resolved path removes the guess entirely. |
| One item per line, rendered as-is minus control bytes | The convention stays greppable, and stripping control bytes keeps a hostile item from replaying escape sequences into the terminal on every refresh. Terminals truncate or wrap over-long lines (officially unspecified) — hence the item-length rule, whose home is SKILL.md. |
| Empty or absent file renders nothing | A permanent "no pending decisions" row would waste a statusline line all day; silence is the correct steady state. |
| Statusline registered against a stable symlink, refreshed on every SessionStart | Plugin cache paths are versioned and change on every update; `statusLine.command` cannot use `${CLAUDE_PLUGIN_ROOT}`. The self-healing symlink is the only registration that survives updates. |
| Queue file deleted by the SessionEnd hook; 30-day age fallback | A resumed session keeps its session_id, so cleanup must fire on real ends only — the SessionEnd matcher excludes `resume`. Age alone was rejected: it deletes the still-pending queue of a long-lived resident session. The fallback catches sessions that died without the hook firing. |

## Data Flow

1. SessionStart hook → refreshes the symlink, prunes stale queues, injects
   "this session's file is X" into the model's context.
2. Claude (per SKILL.md convention) → appends a line when a judgment starts
   waiting on the user, deletes it when answered.
3. Claude Code statusline → runs the renderer each refresh; it reads the
   session's file via the session_id in its stdin JSON and prints a yellow
   header plus every non-blank line.

## Constraints & Tradeoffs

- Registration is a one-time manual step (`statusLine` cannot be shipped in
  plugin settings); the README owns that procedure.
- The queue is a convention, not an enforcement: nothing blocks a session
  that forgets to write. The skill keeps the convention loaded; the injected
  context line re-points to it every session.
- Item text is whatever language the conversation runs in; the mechanism is
  language-agnostic.
- Every failure mode (dangling symlink mid-update, missing jq, unreadable
  file) renders as the same silence that legitimately means "nothing
  pending". Accepted at 0.1.0 — the statusline is the wrong place to shout —
  revisit if it bites in practice.
- `/clear` mints a new session_id: the old queue is deleted with the old
  session, and still-relevant items must be re-added (SKILL.md carries the
  rule).
