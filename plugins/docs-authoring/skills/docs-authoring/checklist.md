# Docs Authoring Checklist

The reviewer — the docs-review agent or a person — rates every row OK / NG / N/A: layer A (Phase A) first, then the prose layers (Phase B).

A row whose object is absent from the document — bold, a list, a list's axis — is N/A.

[guidelines.md](guidelines.md) defines the terms. For each NG, consult the section the layer heading names there.

---

## A: Process (Phase A)

When A1 is NG, A2 is N/A. A2 is rated against the reader A1 names.

| # | Check item |
|---|-----------|
| A1 | The document names a specific reader, not a generic group ("developers", "the team") |
| A2 | The body addresses the questions or decisions the named reader has |
| A3 | Facts that serve the reader but fall outside the main structure are relocated (background section, footnote, parenthesis), not deleted |

---

## V: Viewpoint (P0)

| # | Check item |
|---|-----------|
| V1 | A one-line role declaration near the top states the document's stance |
| V2 | The stance's subject is consistent across sections, or any shift is signposted |
| V3 | The abstraction level stays the same across sections |
| V4 | The argument frame (the problem being solved) stays constant across sections, or any change is signposted |

## T: Top-down (P1)

Bold list-item labels (`- **Label**: text`) fall outside T10–T12.

| # | Check item |
|---|-----------|
| T1 | The apex names the action or outcome the document delivers, not its topic |
| T2 | The apex is one sentence |
| T3 | The apex is the title in a short document, the first sentence after the title in a long one |
| T4 | Premises sit above the sections that depend on them |
| T5 | A short premise sits inline, a long one in a Background section |
| T6 | Every example or piece of evidence sits below the claim it serves, not beside it |
| T7 | Each section is the apex or support for an earlier apex |
| T8 | Each paragraph holds one topic |
| T9 | Each paragraph's first sentence states its point (reading only first sentences reconstructs the section's argument) |
| T10 | Each point stays findable in one pass with all bold removed, one glance for scan-type documents (strip test) |
| T11 | Bold marks only first-use definitions or warnings |
| T12 | Bold appears five times per document at most |

## S: Sibling independence (P2)

| # | Check item |
|---|-----------|
| S1 | Each list has one shared axis, named or obvious from context |
| S2 | Each list's axis serves the reader's purpose (A2), not whatever decomposes most cleanly |
| S3 | No list item summarizes, contains, or restates another |
| S4 | No item of an unnumbered list takes another item's output as input |
| S5 | Sibling items share one surface form — the same grammatical shape, the same element order |
| S6 | No sentence enumerates three or more parallel clauses in prose |
| S7 | Each table's rows share two or more attributes, with every cell filled |

## W: Words (P3)

| # | Check item |
|---|-----------|
| W1 | The apex verb names a domain-specific action (substitution test) |
| W2 | Every load-bearing term is one the reader knows from their own side, or is glossed |
| W3 | Success criteria, evidence, and support speak the goal's vocabulary |
| W4 | Every word inside a sentence carries meaning (no throat-clearing, hedging, or restated context) |

## C: Claims — technical writing (P4)

| # | Check item |
|---|-----------|
| C1 | No sentence joins two claims that could each stand alone, a claim and its reason included |
| C2 | Every sentence states a new claim — no lead-in or restatement |
| C3 | Each claim is stated in positive form, except prohibitions, warnings, and contrasts naming the rejected alternative ("X, not Y") |
| C4 | No negations are stacked |

## B: Boundary (P5)

| # | Check item |
|---|-----------|
| B1 | The scope boundary is stated, or clearly inferable from the title and apex |
| B2 | Out-of-scope items or rejected alternatives are named where ambiguity is plausible |
| B3 | No boundary statement repeats what the title and apex already make obvious |
