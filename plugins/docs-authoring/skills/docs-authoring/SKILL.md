---
name: docs-authoring
description: Guides writing and tightening engineering documents (design docs, tickets) so readers understand them in one pass. Use when you hear "write a design doc", "draft a ticket", "tighten this doc", "make this clearer", or "読みやすくしたい". For read-only audits, the docs-review agent is preferred.
---

# Docs Authoring

Write and tighten engineering documents so a reader understands them in one pass. Apply principles, not output templates.

Read [guidelines.md](guidelines.md) for the writing model — core concept, content-identification process (A1–A3), five principles (P0–P4), failure-pattern mapping, and how-to-apply workflows. [checklist.md](checklist.md) holds the binary checks (A + V/T/S/W/B) used during the self-review pass below.

For read-only audits ("review this document", "audit this doc"), the `docs-review` Custom SubAgent runs in an isolated context and returns a findings report. It preloads this skill via the `skills:` field, so the writing model is shared — no duplication.

## Self-review pass after writing or tightening

For substantive output, run the `docs-review` agent on what was just written or revised before handing back. **Skip for trivial cases** — the agent's load (guidelines.md + checklist.md + the full draft, in an isolated context) only pays off when the writing model has surface to bite on.

**Run** when:

- The document is substantive: design doc, RFC, postmortem, README section, multi-paragraph ticket body
- Multiple readers or decision-loaded content (where reader-anchor drift hurts)
- AI-generated draft, or a heavy rewrite of an existing doc

**Skip** when:

- Short output: one-line ticket subject, comment, a fix of a few lines
- The user asked for a quick draft or said review isn't needed
- A minor follow-up edit on a doc that was just reviewed

When unclear, ask one short question — *"Self-review this with docs-review?"* — and proceed with the answer.

When you do run it:

1. **Invoke `docs-review`** on the document (path if it was written to a file, otherwise pasted content).
2. **Read the returned findings report.** The report names NG checks with one-line rationales and proposed directions.
3. **Apply the smallest edit that turns each NG into OK.** For non-trivial changes, confirm with the user before applying.
4. **Surface unresolvable NGs explicitly.** If a finding requires information the user has not given (e.g., A1 NG because the reader was never named), ask the user rather than silently dropping it.

The self-review keeps the heavy reads (guidelines.md, checklist.md, the full draft) out of the main session — the agent returns only the verdicts, and the main session focuses on the edits.

## Notes

- Writing and tightening run in the main session (iterative); the optional self-review pass is the only step delegated to a SubAgent
- The skill diagnoses and proposes; the writer decides whether to accept each suggestion
- Markdown is the only supported output format at v0.1. Jira / Confluence / Notion-specific shapes are out of scope
