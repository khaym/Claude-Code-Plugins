---
name: docs-authoring
description: Guides writing and reviewing engineering documents (design docs, tickets) so readers understand them in one pass. Use when you hear "write a design doc", "draft a ticket", "review this document", "make this clearer", "tighten this doc", or "読みやすくしたい".
---

# Docs Authoring

Write and review engineering documents so a reader understands them in one pass. Apply principles, not output templates.

## Intent Detection

| Intent | Example triggers | Reference |
|--------|-----------------|-----------|
| **Write a new doc** | "write a design doc", "draft a ticket", "ドキュメントを書きたい" | [guidelines.md](guidelines.md) |
| **Review / tighten** | "review this document", "make this clearer", "tighten this doc", "読みやすくしたい" | [guidelines.md](guidelines.md) |
| **Rule lookup** | "writing rules", "doc guidelines" | [guidelines.md](guidelines.md) |

Ask the user to clarify if intent is ambiguous.

## Reference Files

| File | Content | When to reference |
|------|---------|-------------------|
| [guidelines.md](guidelines.md) | Core concept, content-identification process (A1–A3), five principles (P0–P4), failure-pattern mapping, how-to-apply workflows | Always — both writing and review draw from the same model |
| [checklist.md](checklist.md) | Observable binary checks — A for the content process, V/T/S/W/B for the structural principles | Final verification sweep during writing; primary scanner during review |

## Notes

- Writing and review are both iterative, so this skill runs in the main session (not delegated to a SubAgent)
- The skill diagnoses and proposes; the writer decides whether to accept each suggestion
- Markdown is the only supported output format at v0.1. Jira / Confluence / Notion-specific shapes are out of scope
