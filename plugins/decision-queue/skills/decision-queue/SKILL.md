---
name: decision-queue
description: Maintains the session's pending-decisions queue file so the statusline always shows every judgment currently waiting on the user - add a line when a question for the user arises, remove it when answered. Use when a decision, confirmation, or audit request for the user starts or stops waiting, or when you hear "decision queue", "pending decisions", "要判断", or "判断待ち".
---

# Decision Queue

Keep every judgment awaiting the user visible in the statusline. The
conversation log is linear and shows only the latest topic; this queue is the
resident list of "everything waiting on you" (rationale: [design.md](design.md)).

## The queue file

The SessionStart hook injects a context line naming this session's file:

> decision-queue: this session's pending-decisions file is `<path>` …

Use that exact path. Do not derive the path yourself or touch other sessions'
files. If the context line is missing, the plugin's hook did not run — tell
the user instead of guessing a path.

## Convention

- **When a judgment starts waiting on the user** — a question asked, a
  confirmation or audit requested, a report parked for approval — append one
  line to the file: `- <topic>`.
- **When the user answers it** — delete that line. Delete does not mean
  "resolved in spirit": remove the line only when the user actually decided.
- **When the file has no items left** — leave it empty; the statusline goes
  silent by design.

Rules for the line itself:

- One line per awaited judgment; never bundle two questions into one line.
- Carry the point in the first ~50 characters — depending on the terminal,
  the statusline truncates or wraps an over-long line, and the point must
  survive either way.
- Session-local judgments only. Anything that must outlive the session
  (a ticket decision, a document review) belongs in the project's tracker or
  docs, not here.
- `/clear` starts a new session: the old queue is deleted with the old
  session, so re-add any item that is still genuinely waiting on the user.

## Troubleshooting

- Statusline shows nothing while items exist: check that `jq` is on PATH
  (hook and renderer both need it), and that the `statusLine` setting points
  at the stable symlink `statusline.sh` in the queue directory — the parent
  directory of the injected queue-file path. The one-time registration lives
  in the plugin [README](../../README.md).
- Items from an old session linger: a session's queue file is deleted when
  that session ends; files from crashed sessions go once untouched for over
  30 days. A stale file in between is harmless — only the owning session's
  statusline reads it.
