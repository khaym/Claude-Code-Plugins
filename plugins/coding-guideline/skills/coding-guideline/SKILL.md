---
name: coding-guideline
description: Keeps a story's implementation on its purpose and changeable — tests, code, and comments built from what the design documents or the ticket decided, by correspondence rules and by a Data-Oriented Programming method that turns the design's contract into records and operations, leaving the structure rules in the code and the means to the author. Use before writing or reviewing code for a story, or when you hear "coding guideline", "where does this rule go in the code", "what should this comment say", "implement this design", "コーディングガイドライン", or "この規則はコードのどこに置く".
---

# Coding Guideline

This file says when the author and the reviewer read which part of the guideline. The rules, the method, and the terms — author, reviewer, requester among them — are [guidelines.md](guidelines.md); the rationale for their shape is [design.md](design.md).

## Intent detection

| Intent | Example triggers | Action |
|---|---|---|
| Write for a story | "implement this design", "implement #N", "write the tests for this rule" | Run the [author's pass](#authors-pass) |
| Review a change | "review this diff against the guideline", "does this change keep the rules" | Run the [reviewer's pass](#reviewers-pass) |
| Place one thing | "where does this rule go in the code", "is this a record or a derived value", "what should this comment say" | Answer from [guidelines.md](guidelines.md): the method's table (From the contract to the code) for a Business Rule, a record, or a derived value; Comments for a comment |
| Rule lookup | "coding guideline", "what must hold for a write", "how is failure handled" | Answer from [guidelines.md](guidelines.md): the correspondence rules, and the row of the method's table whose question the lookup is about |

## Author's pass

The input is the story's design documents or, when the story has no design, its ticket. The output is tests, code, and comments for the change; without a design, the written decisions as well; and any gap found outside the change, recorded where Scope of duty in [guidelines.md](guidelines.md) says.

1. Read the input in full, starting from the purpose, before the code. An input that cannot be built from (guidelines.md, Input that cannot be built from) stops the pass: the author writes nothing, reports which stop was hit, and the story goes back to the requester.
2. Read [guidelines.md](guidelines.md) in the order it is written. Without a design, make and write down the decisions its Without a design section names before coding.
3. Answer the method's questions in order (guidelines.md, From the contract to the code) and build toward the purpose from the answers, pinning each Business Rule or success criterion with tests as the correspondence rules say. Comments last.

## Reviewer's pass

The input is the change and the story's input: the design documents, or the ticket and the author's written decisions. The output is what the change breaks — each item naming what it breaks, the location, and what was found against what holds — sorted into findings and gaps (guidelines.md, Terms). A choice of means the rules allow is neither.

1. Read the story's input in full, starting from the purpose. The stops of the author's pass apply here too: a stopped review reports which stop was hit and that the story goes back to the requester, and returns neither findings nor gaps.
2. Read Terms, and Scope of duty in Input, output, freedom, in [guidelines.md](guidelines.md).
3. Check the change against the correspondence rules.
4. Check it against the structure rules in the method's table.
5. Without a design, check the written decisions against Without a design.
6. Check each comment against Comments.
7. Sort what was found into findings and gaps; record the gaps where Scope of duty in [guidelines.md](guidelines.md) says.

## Notes

- This skill owns the code-side discipline. What it leaves to its siblings, and where each of those lives, is the Not here table in [guidelines.md](guidelines.md).
