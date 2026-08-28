---
name: ticket-authoring
description: Guides filing tickets as user stories — one ticket, one user-visible capability — so the purpose stays in charge of the means. Use when you hear "file a ticket", "draft a ticket", "write a user story", "ticket structure", or "チケットを起票したい". For premise audits of a draft or existing ticket, the ticket-review agent is preferred.
---

# Ticket Authoring

File tickets as user stories to keep the purpose in charge of the means — the antibody against code-anchored tickets, whose means quietly become their end (mechanism and failure chain: design.md).

Read [guidelines.md](guidelines.md) for the structure rules — the user-story unit, value anchoring, subject, the Done shape, details layout, what the tracker carries, and filing principles. [checklist.md](checklist.md) holds the binary premise checks (T1–T5) used during the audit pass below.

For premise audits ("review this ticket", "audit this draft"), the `ticket-review` Custom SubAgent runs in an isolated context — a reader with no project knowledge — and returns a findings report. It preloads this skill via the `skills:` field, so the criteria are shared — no duplication.

## Intent detection

| Intent | Example triggers | Action |
|--------|-----------------|--------|
| **File / draft a ticket** | "file a ticket", "draft a user story" | Run the [filing flow](#filing-flow) below |
| **Audit a draft or existing ticket** | "review this ticket", "ticket premise check" | Invoke the `ticket-review` agent |
| **Rule lookup** | "ticket structure", "how should tickets be cut" | Answer from [guidelines.md](guidelines.md) |

## Filing flow

The order matters: a writing model loaded *before* drafting shapes the prose, while a review pass afterwards anchors on the existing text and only patches it.

1. **Load the installed writing skill** (e.g. `docs-authoring`) before drafting. Its writing model is drafting input, not a post-hoc check. Skip this step only when no writing skill is installed.
2. **Apply [guidelines.md](guidelines.md)** — the structure rules enumerated above — and draft in the main session.
3. **Audit the premises** — run the pass below.
4. **Self-review the prose** — run the writing skill's own self-review pass per its own run/skip criteria. The premise audit and the prose review are different layers; passing one says nothing about the other.

## Premise audit pass before filing

Run the `ticket-review` agent (when installed via plugin, subagent type `ticket-authoring:ticket-review:ticket-review`) on the draft before filing it, and on any existing ticket before handing it to an autonomous pipeline.

1. **Invoke `ticket-review`** with the draft (pasted content, file path, or tracker ID). Pass the project's value anchor — a purpose-doc path or summary — when you already hold it; otherwise the agent discovers one itself.
2. **Read the findings report.** Each NG names what an outside reader could not read, plus a proposed direction. If the agent reports it could not obtain the ticket (missing tracker script, unresolvable ID), supply the body as pasted content and re-run — do not act on a partial audit.
3. **Apply the smallest edit that turns each NG into OK.** If a fix needs information the requester has not given (whose value this serves, where the boundary lies), handle the gap per the filing principles in [guidelines.md](guidelines.md).
4. **Re-run after substantial rewrites**; a wording tweak does not need a second pass.

## Notes

- This skill owns ticket structure and premise validity; prose readability belongs to the writing skill (filing flow steps 1 and 4).
- Drafting runs in the main session (iterative); only the audit pass is delegated to the SubAgent.
