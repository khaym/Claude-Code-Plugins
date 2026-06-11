# Docs Authoring Checklist

Evaluation criteria used during both writing and reviewing.
Rate each item as **OK / NG / N/A**.

Two layers:

- **A** verifies the content-identification process (Phase A — what to convey).
- **V / T / S / W / B** verify the structural principles (Phase B — properties of readable prose).

Run as a full sweep on the document. For each NG, consult the matching section in [guidelines.md](guidelines.md).

---

## A: Process (Phase A)

| # | Check item |
|---|-----------|
| A1 | The role declaration names a specific reader (not a generic group like "developers" or "the team") |
| A2 | The body addresses the questions or decisions a reader of the named role would have |
| A3 | Facts that serve the reader but don't fit the main structure are relocated (background section, footnote, parenthesis), not deleted |

---

## V: Viewpoint (P0)

| # | Check item |
|---|-----------|
| V1 | A one-line role declaration appears near the top (who the reader is, what the document does) |
| V2 | The stance's subject is consistent across sections, or any shift is signposted |
| V3 | Abstraction level does not move up and down between sections |
| V4 | The argument frame (problem being solved) stays constant; any change is marked explicitly |

## T: Top-down (P1)

| # | Check item |
|---|-----------|
| T1 | The apex is one sentence naming the action or outcome the document delivers (not its topic) — the title for short docs, the first sentence after the title for long docs |
| T2 | A reader who reads only the apex can answer "what is this document for?" |
| T3 | Premises sit above the sections that depend on them (inline if short, in a Background section if long) |
| T4 | Every example or piece of evidence is placed below the claim it serves, not beside it |
| T5 | Each section is identifiable as either an apex or part of support for an earlier apex — no floating sections |
| T6 | Reading only the first sentence of each paragraph reconstructs the section's argument (one topic per paragraph, claim first) |

## S: Sibling Independence (P2)

| # | Check item |
|---|-----------|
| S1 | For each list, one shared axis of comparison is named or obvious from context — and the axis serves the reader's purpose (A2), not whatever decomposes most cleanly |
| S2 | No list item summarizes, contains, or restates another (no umbrella sibling) |
| S3 | No list item's output is another item's input (no chained dependency presented as siblings) |
| S4 | Restated items are merged into the wording closest to the document's purpose |
| S5 | Sibling items share one surface form — same grammatical shape, same element order — so position predicts content |
| S6 | No sentence enumerates three or more parallel items in prose — they are broken out into a list |

## W: Words (P3)

| # | Check item |
|---|-----------|
| W1 | The apex verb names a domain-specific action — swapping its noun and verb for another domain breaks the sentence (substitution test) |
| W2 | Load-bearing terms come from the reader's vocabulary; author-side terms are glossed or replaced |
| W3 | Success criteria, evidence, and support speak in the same vocabulary as the goal |
| W4 | No filler — every word carries meaning; throat-clearing, hedging, and restated context are cut (fewer words, not fewer facts) |
| W5 | No sentence joins two claims that could each stand alone (split test) |
| W6 | Claims are stated in positive form; negation appears only in prohibitions or warnings, and is never doubled |
| W7 | The document passes the strip test: with all bold removed, each claim is still findable in one pass (one glance for scan-type documents) |
| W8 | Remaining bold marks only first-use definitions or warnings — a handful per document, not per section |

## B: Boundary (P4)

| # | Check item |
|---|-----------|
| B1 | Scope boundary is stated, or clearly inferable from title + apex |
| B2 | Where ambiguity is plausible, out-of-scope items or rejected alternatives are named explicitly |
| B3 | No boundary statement is added that the title + apex already make obvious (such a statement would itself be a detour) |
