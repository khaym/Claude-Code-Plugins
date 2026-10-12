---
name: coding-guideline
description: Keeps a story's implementation on its purpose and changeable — tests, code, and comments built from what the design documents or the ticket decided, by correspondence rules, structure rules, and a Data-Oriented Programming method, with the means left to the author. Use before writing or reviewing code for a story, or when you hear "coding guideline", "where does this rule go in the code", "what should this comment say", "implement this design", "コーディングガイドライン", or "この規則はコードのどこに置く".
---

# Coding Guideline

This file says when the author and the reviewer read which part of the guideline. The author is whoever writes the change: a developer or a Claude session, including an implementer agent. The reviewer is whoever checks the finished change. The requester is whoever owns the story. The rules, the method, and the terms are [guidelines.md](guidelines.md); the rationale for their shape is [design.md](design.md).

## Intent detection

| Intent | Example triggers | Action |
|---|---|---|
| Write for a story | "implement this design", "implement #N", "write the tests for this rule" | Run the [author's pass](#authors-pass) |
| Review a change | "review this diff against the guideline", "does this change keep the rules" | Run the [reviewer's pass](#reviewers-pass) |
| Place one thing | "where does this rule go in the code", "is this a record or a derived value", "what should this comment say" | Answer from [guidelines.md](guidelines.md): Input element in the code for a Business Rule or a record, the One derivation rule for a derived value, Comments for a comment |
| Rule lookup | "coding guideline", "what must hold for a write", "how is failure handled" | Answer from the two rule tables in [guidelines.md](guidelines.md) |

## Author's pass

The input is the story's design documents or, when the story has no design, its ticket. The output is tests, code, and comments for the change; without a design, the written decisions as well; and any gap found outside the change, recorded where Scope of duty in [guidelines.md](guidelines.md) says.

1. Read the input in full, starting from the purpose, before the code. An input that cannot be built from stops the pass, and the story goes back to the requester. Building from the code instead is the failure the guideline exists to prevent. The stops:
   - a ticket without success criteria, or with a criterion that names no observable outcome
   - a design the ticket names but that cannot be found
   - a design whose undecided index is not empty
   - an input that works against the purpose (guidelines.md, Input against the purpose)
2. Read [guidelines.md](guidelines.md) in the order it is written. Without a design, make and write down the decisions its Without a design section names before coding.
3. Find the home first. Then build toward the purpose under the structure rules, with Input element in the code as the reference, pinning each Business Rule or success criterion with tests as the correspondence rules say. Comments last.

## Reviewer's pass

The input is the change and the story's input: the design documents, or the ticket and the author's written decisions. The output is findings — a rule broken within what the change touches — and observations — a gap outside what the change touches. A choice of means the rules allow is neither.

1. Read the story's input in full, starting from the purpose. The stops of the author's pass apply here too: a stopped review reports which stop was hit and that the story goes back to the requester, and returns no findings. Missing written decisions are a finding, not something to fill in from the code.
2. Read Input, output, freedom in [guidelines.md](guidelines.md): the terms, and the scope of duty.
3. Check the change against the correspondence rules. A change that claims no Business Rule or success criterion is itself a finding under "Unit from the input".
4. Check it against the structure rules. Each rule's "Rules out" column is what to look for.
5. Check each comment against Comments.
6. Sort what was found into findings and observations by the scope of duty; record observations where that section says.

A finding names the rule, the location, and what was found against what holds.

## Notes

- This skill owns the code-side discipline. What it leaves to its siblings, and where each of those lives, is the Not here table in [guidelines.md](guidelines.md). The guideline reads the design documents; the design skill never reads the guideline.
