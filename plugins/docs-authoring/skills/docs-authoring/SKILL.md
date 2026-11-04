---
name: docs-authoring
description: Guides writing and tightening engineering documents (design docs, tickets) so readers understand them in one pass. Use when you hear "write a design doc", "draft a ticket", "tighten this doc", "make this clearer", or "読みやすくしたい". For read-only audits, the docs-review agent is preferred.
---

# Docs Authoring

Write and tighten engineering documents so a reader understands them in one pass.

This file tells you, the session that loaded the skill, what to read and when to self-review:

| File | Holds | Read by |
|---|---|---|
| [guidelines.md](guidelines.md) | The writing model: core concept, content identification (A1–A3), six principles (P0–P5), how to apply | You, before writing or tightening; the docs-review agent, when it audits |
| [checklist.md](checklist.md) | The binary checks (A + V/T/S/W/C/B) | The docs-review agent, during the self-review below |

Apply the principles, not output templates. Markdown is the only supported output format. Jira / Confluence / Notion-specific shapes are out of scope.

You write and tighten in the main session, where the user reacts to each edit. The self-review is the only writing step you delegate. The agent returns only its verdicts. Your context stays on the edits.

For read-only audits ("review this document", "audit this doc"), the `docs-review` agent audits the document in an isolated context. It preloads this skill. It judges by the same writing model.

## Self-review after writing or tightening

Run the `docs-review` agent on substantive output before handing back. The agent's load — guidelines.md, checklist.md, and the full draft, in an isolated context — pays off only there.

Run it on:

- **Long-form documents**: design docs, RFCs, postmortems, README sections, multi-paragraph ticket bodies
- Documents with several reader types, or content that asks the reader to decide
- A draft you wrote from scratch, and a heavy rewrite of an existing doc

Skip it on:

- **Short output**: a one-line ticket subject, a comment, a fix of a few lines
- A quick draft the user asked for, or output the user waived review for
- A minor follow-up edit on a doc that was just reviewed

When unclear, ask the user one short question: *"Self-review this with docs-review?"*

When you run it:

1. Invoke `docs-review` on the document: its path if it was written to a file, otherwise its text in the prompt.
2. Read the report's NG checks, each with a one-line rationale and a proposed direction.
3. Apply the smallest edit that turns each NG into OK, where the report gives what the edit needs. Confirm a non-trivial change with the user before applying it.
4. Ask the user about an NG that needs information only they can supply (e.g., A1 NG when the draft names no reader).
