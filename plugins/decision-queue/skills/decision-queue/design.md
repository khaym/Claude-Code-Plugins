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
| The hooks announce the queue file path via injected context, at SessionStart and on every UserPromptSubmit, through one script (`announce-queue.sh`) | The model has no reliable way to learn its own session id, so the resolved path is injected. SessionStart alone does not reach a resumed session — its additionalContext is dropped after `--resume` while UserPromptSubmit context arrives from the first prompt (Claude Code 2.1.25x, observed 2026-08-29 / 2026-09-02); one context line per turn is the accepted cost. |
| The skill forbids inferring the session id from any other path or identifier | The ids a session can see (scratchpad, tasks directories) belong to the running process and diverge from the session id after a resume; a queue written under one is a file the statusline never reads (observed 2026-08-29). |
| One item per line, rendered as-is minus control bytes | The convention stays greppable, and stripping control bytes keeps a hostile item from replaying escape sequences into the terminal on every refresh. Terminals truncate or wrap over-long lines (officially unspecified) — hence the item-length rule, whose home is SKILL.md. |
| Empty or absent file renders nothing | A permanent "no pending decisions" row would waste a statusline line all day; silence is the correct steady state. |
| Statusline registered against a stable symlink, refreshed on every SessionStart | Plugin cache paths are versioned and change on every update; `statusLine.command` cannot use `${CLAUDE_PLUGIN_ROOT}`. The self-healing symlink is the only registration that survives updates. |
| Queue file deleted by the SessionEnd hook on every end reason, and by the SessionStart hook when `source` is `resume`; 30-day age fallback | Pending items are session-local: a resumed session starts empty and re-lists what still waits, rather than carrying a file whose items may already be answered (owner decision 2026-08-29). Deleting at resume as well as at end makes that true however the previous run ended (exit, `/resume` switch, crash). Age alone was rejected — it deletes the still-pending queue of a long-lived resident session; the fallback catches files no session ever resumes. |
| Queue directory kept under `~/.claude`, its write permission left to Setup | Every default-writable alternative breaks something: `<project>/.claude/` lands session state in the user's repository; `$TMPDIR` is invisible to the hook and the renderer; `${CLAUDE_PLUGIN_DATA}` sits under the protected `~/.claude/plugins/`. `~/.claude/decision-queue` is unprotected: one allow rule reaches it. |

## Data Flow

1. SessionStart hook → refreshes the symlink, prunes stale queues, injects
   "this session's file is X" into the model's context; the UserPromptSubmit
   hook injects the same line with every prompt (the only delivery that
   reaches a resumed session).
2. Claude (per SKILL.md convention) → appends a line when a judgment starts
   waiting on the user, deletes it when answered.
3. Claude Code statusline → runs the renderer each refresh; it reads the
   session's file via the session_id in its stdin JSON and prints a yellow
   header plus every non-blank line.

## Constraints & Tradeoffs

- Setup is a one-time manual step: a plugin can ship neither `statusLine` nor
  `permissions`, so both the registration and the queue-directory allow rule
  are the user's to add. The README owns that procedure.
- The queue is a convention, not an enforcement: nothing blocks a session
  that forgets to write. The skill keeps the convention loaded; the injected
  context line re-points to it every session.
- Item text is whatever language the conversation runs in; the mechanism is
  language-agnostic.
- Every failure mode (dangling symlink mid-update, missing jq, unreadable
  file) renders as the same silence that legitimately means "nothing
  pending". Accepted at 0.1.0 — the statusline is the wrong place to shout —
  revisit if it bites in practice.
