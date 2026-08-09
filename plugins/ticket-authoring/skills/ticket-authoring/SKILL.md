---
name: ticket-authoring
description: Guides filing tickets as user stories — one ticket, one user-visible capability — so the purpose stays in charge of the means. Use when you hear "file a ticket", "draft a ticket", "write a user story", "ticket structure", or "チケットを起票したい". For premise audits of a draft or existing ticket, the ticket-review agent is preferred.
---

# Ticket Authoring

File tickets as user stories to keep the purpose in charge of the means — the antibody against code-anchored tickets, whose means quietly become their end (mechanism and failure chain: design.md).

Read [guidelines.md](guidelines.md) for the structure rules — the user-story unit, value anchoring, subject and details layout, header metadata, and filing principles. [checklist.md](checklist.md) holds the binary premise checks (T1–T5) used during the audit pass below.

For premise audits ("review this ticket", "audit this draft"), the `ticket-review` Custom SubAgent runs in an isolated context — a reader with no project knowledge — and returns a findings report. It preloads this skill via the `skills:` field, so the criteria are shared — no duplication.

## Intent detection

| Intent | Example triggers | Action |
|--------|-----------------|--------|
| **File / draft a ticket** | "file a ticket", "draft a user story" | Apply [guidelines.md](guidelines.md), then run the audit pass below |
| **Audit a draft or existing ticket** | "review this ticket", "ticket premise check" | Invoke the `ticket-review` agent |
| **Rule lookup** | "ticket structure", "how should tickets be cut" | Answer from [guidelines.md](guidelines.md) |

## Premise audit pass before filing

Run the `ticket-review` agent (when installed via plugin, subagent type `ticket-authoring:ticket-review:ticket-review`) on the draft before filing it, and on any existing ticket before handing it to an autonomous pipeline.

1. **Invoke `ticket-review`** with the draft (pasted content, file path, or tracker ID). Pass the project's value anchor — a purpose-doc path or summary — when you already hold it; otherwise the agent discovers one itself.
2. **Read the findings report.** Each NG names what an outside reader could not read, plus a proposed direction. If the agent reports it could not obtain the ticket (missing tracker script, unresolvable ID), supply the body as pasted content and re-run — do not act on a partial audit.
3. **Apply the smallest edit that turns each NG into OK.** If a fix needs information the requester has not given (whose value this serves, where the boundary lies), handle the gap per the filing principles in [guidelines.md](guidelines.md).
4. **Re-run after substantial rewrites**; a wording tweak does not need a second pass.

## Notes

- Prose readability (one-pass structure, wording) is a general writing concern — this skill owns ticket structure and premise validity only. If a writing skill such as `docs-authoring` is installed, apply both.
- Drafting runs in the main session (iterative); only the audit pass is delegated to the SubAgent.
