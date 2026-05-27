# Docs Authoring Guidelines

Identify what the reader came for, then choose the shortest path to it.

This file is the foundation for both writing new documents and reviewing existing ones. It defines the core concept, a content-identification process, five principles that shape readable prose, and a small set of failure patterns that map back to the principles when something feels off.

## Table of Contents

- [Core Concept](#core-concept) — The two phases of writing
- [Process](#process) — Identify what to convey (Phase A)
- [Principles](#principles) — Properties of readable prose (Phase B)
- [Common Failure Patterns](#common-failure-patterns) — Symptoms that map back to missed steps or principles
- [How to Apply](#how-to-apply) — Writing and reviewing workflows

---

## Core Concept

**Identify what the reader came for, then choose the shortest path to it.**

Writing has two phases. The first decides *what* to convey — the questions or decisions the named reader uses this document for. The second structures that content into a path the reader can follow in one pass.

"Less, but better" (Dieter Rams) applies to both phases: every fact and every word should serve a function — nothing extra, nothing missing. The mistake is to cut for cleanness, dropping facts the reader needs because they don't fit the structure. **Useful trumps clean — relocate, don't delete.**

The same two phases drive writing and reviewing. When writing, identify before structuring. When reviewing, verify content completeness (Phase A) and path shortness (Phase B) as separate passes.

---

## Process

Phase A — content identification. These are actions the writer takes before structural work begins. The structural principles (Phase B) assume Phase A is done; skipping it leads to structurally clean documents that are missing what the reader came for.

### A1. Identify the reader

**Name the reader specifically.** Not "the team" but "the on-call SRE during an incident"; not "engineers" but "a backend engineer evaluating libraries for adoption". Specific naming forces the writer to know who they are writing for.

**Segment if diverse.** When the document serves multiple reader types (e.g., PMs and engineers reading the same RFC), name each segment. Each segment will have different anchors in A2.

### A2. Identify what the reader came for

**List the reader's questions or decisions.** What are they using this document to answer or decide? "What does this library do?" "How much integration cost?" "Should we adopt it?" Write the list down (or hold it explicitly) before drafting the body.

**Ask if unclear.** When the requester's intent is not obvious, ask. A guess that misses the anchor fails silently — the writer produces a clean document about the wrong question.

**The anchor list is the contract.** Every fact in the document either serves an item on this list or supports a fact that does. If a fact does not trace back, it is a detour.

### A3. Select content by usefulness, not cleanness

**Useful trumps clean.** If a fact serves a reader anchor (A2) but doesn't fit the chosen structure, relocate it — different section, footnote, parenthesis — rather than delete it. The reader's need is the test, not the structure's symmetry.

**Watch for the attribute-order trap.** Listing items by their type ("Implementation language → Backend → License") instead of by reader-relevance signals that A2 was skipped: the structure looks tidy but does not lead the reader.

**Catch the cleanness reflex.** When you find yourself dropping a fact because it "doesn't fit the section", check A2. Usually the fact fits a reader anchor and needs to stay (possibly under a different section).

---

## Principles

Phase B — five principles that describe what readable prose looks like once the content is identified. The first is foundational; the remaining four are specific tactics for structure, lists, words, and scope.

Each principle is presented as: **Why this matters** (what the reader gains), **In practice** (how to apply), and **Example** (Detour vs. Direct). Verification of each principle lives in [checklist.md](checklist.md) as binary OK/NG checks.

### P0. Hold one viewpoint throughout (Foundational)

**Why this matters**: A document is a sequence of sections. Each shift in viewpoint forces the reader to rebuild "whose stance am I reading from now?" That rebuild cost is one of the largest drains on comprehension, and unlike local problems it cannot be patched section by section — it compounds across the whole document. The other principles assume the viewpoint is already pinned; their effect leaks if it slides. In particular, once viewpoint is pinned, the right vocabulary (P3) is largely determined; without that pin, word choices drift even when they are individually defensible.

**In practice**:

- **Subject stance** (most important). Keep the grammatical subject consistent across sections — user, system, we, the function, the investigator. If the natural subject changes by section, the viewpoint has slid.
- **Abstraction level**. Do not move up and down the stack between sections (strategy → implementation → strategy makes the reader reset).
- **Role declaration**. State the document's stance once near the top — one sentence is enough. Examples: "This document is the shape of the library." "This ticket commissions an investigation, not an implementation."
- **Argument frame**. Keep "the problem being solved" constant. If the frame must change, mark the change explicitly.

**Example**:

- Detour (ticket): the "Purpose" section speaks from the analyst's view, "Investigation targets" speaks from the investigator's view, "Success conditions" speaks from the downstream implementer's view. The reader switches stance three times in thirty lines.
- Direct: every section frames outputs as "what this investigation will produce for the implementer of #10". The implementer is the consistent subject; analyst and investigator viewpoints are absorbed as supporting context, not load-bearing stances.

### P1. Build top-down

**Why this matters**: A reader who reads only the apex should know what the document is for. Below the apex, claims come before their evidence, premises before the sections that use them, examples below the claims they illustrate. The vertical chain (apex → support → detail) is the document's primary path; a broken chain forces the reader to backtrack.

**In practice**:

- Start with the apex as one verb-first sentence. For short documents (tickets, comments), the title is the apex; for longer documents, place the apex as the first sentence after the title.
- Place premises above the sections that depend on them. Short premises inline at first use; long premises in a "Background" section before "Goal".
- Place claim above example. Use "for example", "such as", or nest the example as a sub-bullet or parenthetical.
- For each section, ask: "is this the apex for what follows, or part of the support for an earlier apex?" Either is fine; a section that is neither has no place in the chain.

**Example**:

- Detour: a ticket where "Goal" states two parallel sentences (one general claim, one specific example), both reading as equal in standing. "Background" placed at the end, after the sections that already used the background terms.
- Direct: the title is the apex. Below the title, a one-sentence role declaration. "Background" comes first, "Goal" as one sentence with the example subordinated in parenthesis.

### P2. Keep sibling items independent

**Why this matters**: A list of N items implies N independent points sharing one axis. If items overlap (restatement), differ in level of abstraction (one item covers the others), or chain (one item's output is another's input), the reader must reverse-engineer the list before reading the content. That reverse-engineering is one of the most common sources of "this document is hard to follow" even when no individual sentence is unclear.

**In practice**:

- **Name the axis** the items share before listing — outcomes, candidates, options, criteria. Test each item against the axis.
- **Merge restated items.** Keep the wording closest to the document's purpose.
- **Pull umbrella items up one level** — into the introduction, the parent heading, a closing sentence, or a separate sibling section.
- **Lift dependencies out of the parallel list.** If item B uses item A's output, the two are not siblings. Either merge them, nest one under the other, or move the umbrella outcome (the thing both produce) to a separate section.

**Example**:

- Detour: a "Done" list with (a) classify the pattern per table, (b) catalogue the meta-axes for matching tables, (c) extract the rule parameters from (b), (d) write up the above under `docs/`. Items (a)→(b)→(c) form a pipeline; item (d) covers them all. Four items, none of them siblings.
- Direct: "Done" lists two independent outcomes — "pattern catalogue exists with axis/value entries" and "pivot rule parameters listed for #10". A separate "Deliverable" section names the report under `docs/`. The pipeline is implicit in the work; the list shows only what is true at the end.

### P3. Use concrete words from the reader's vocabulary

**Why this matters**: Abstract verbs ("process", "manage", "handle", "apply") give a sentence shape without content. Author-side terms — words obvious from inside the codebase — give the same shape with extra translation cost for the reader. Once viewpoint (P0) is pinned, the right vocabulary is largely determined by the reader's side; this principle keeps individual word choices consistent with that pin.

**In practice**:

- **Substitution test**: swap the main noun and verb in the apex for words from another domain. If the sentence still reads, it was empty.
- **Translation cost**: for each load-bearing term, ask whether the reader knows it from their own side, or only from the writer's side. Gloss or replace the latter.
- **Vocabulary consistency**: success criteria, evidence, and support should speak in the same vocabulary as the goal. Reserve implementation-side terms for "background" or "context" sections.

**Example**:

- Detour: "Applies the matched rule's transformations to the row stream." Survives substitution by any domain. Combined with success conditions stated in implementation-side terms ("meta-axis", "rule declarative form requirements"), the reader translates every supporting line back to the goal before judging it.
- Direct: "Renames fields and casts values (date / number / string) per the matched rule." Success conditions in the goal's vocabulary ("axes that need aggregation, with observed patterns") — no translation needed.

### P4. Mark the boundary

**Why this matters**: An unbounded claim is harder to verify and easier to misread. Stating what a section does not cover prevents the reader from speculating about scope, and tightens the claim itself.

**In practice**:

- Add a one-line "Out of scope" or "Not in this document" note where scope ambiguity is likely. For tickets, treat "Out of scope" as a standard field.
- When stating an architectural decision, name the alternative that was rejected — this marks the boundary by contrast.
- Skip the section entirely when scope is already obvious from the title and apex. A boundary statement that adds nothing is itself a detour.

**Example**:

- Detour: a ticket with "Goals" and "Done" but no explicit out-of-scope. The reader wonders whether implementation is part of this ticket.
- Direct: the same ticket with "Out of scope: implementing the pivot feature itself (#10); writing per-table pivot rules." Two lines remove all ambiguity.

---

## Common Failure Patterns

These are the symptoms a reviewer most often catches first. Each maps back to one or more steps or principles that were missed.

| # | Failure | Reader's experience | Missed step / principle |
|---|---------|---------------------|--------------------------|
| F1 | Repetition / verbosity | "I read this same point already, phrased differently" | P2 |
| F2 | Flat surface, no point of issue | "I cannot tell which sentence carries the claim" | P1, P3 |
| F3 | Broken logical thread | "I had to scroll back to follow this" | P0, P1, P3 |
| F4 | Missing decision-relevant facts | "This reads cleanly but doesn't tell me what I need to decide" | A2, A3 |

When reviewing, scan for symptoms first; the table points to the missed step or principle, and the matching [checklist.md](checklist.md) items guide the fix.

---

## How to Apply

### When writing

The two phases run in order: Phase A identifies what to convey, Phase B structures it. Top-down structure (P1) is the target shape of Phase B, not the drafting process — Phase B itself iterates between bottom-up exploration and top-down restructuring.

**Phase A — Identify:**

1. **Identify the reader (A1).** Name specifically. Segment if the document serves multiple reader types.
2. **Identify what the reader came for (A2).** List the questions or decisions. Ask the requester if intent is unclear.
3. **Select content for usefulness (A3).** Each candidate fact either serves an A2 anchor or supports one. Useful trumps clean.

**Phase B — Structure:**

4. **Pin the viewpoint (P0).** One sentence — who is the reader, who is the subject, what does this document do.
5. **Abstract toward an apex (P1).** Find the one verb-first sentence that all selected content supports. If no single sentence covers the list, the topic is not yet one document — split or narrow.
6. **Restructure the list against the apex (P2).** Group siblings by their shared axis. Pull umbrella items up. Lift dependencies out of the parallel list.
7. **Refine words (P3).** Apply the substitution test. Replace abstract verbs and writer-side terms.
8. **Mark the boundary (P4)** where ambiguity is plausible.
9. **Re-read for viewpoint drift (P0).** After the body has expanded, check that every section still reads from the same stance.
10. **Run the [checklist](checklist.md) as a final sweep.** Turn each item OK; fix any NG.

Steps 4–8 are iterative. The first apex is usually wrong; refining it sharpens the structure of the body, which in turn sharpens the apex.

### When reviewing

1. **Run the [checklist](checklist.md)** as a full sweep on the document. Mark each item OK / NG / N/A.
2. **For A (Process) NG items**, the document may be missing content. Ask the writer what reader anchors they identified, and verify the body addresses them. Phase A failures cannot be fixed by structural edits alone.
3. **For V/T/S/W/B NG items**, consult the matching principle's "Why this matters" and "In practice" for resolution guidance. Exception: if any V (P0) item is NG, fix viewpoint first — local edits leak when viewpoint slides.
4. **If the document still feels off** after the sweep, scan for symptoms (F1–F4) and trace to the missed step or principle via the failure-pattern table.
5. **Propose the smallest edit** that turns the failing item to OK. Do not rewrite the whole document if a sentence move fixes it.
6. **Confirm with the writer** before applying. The skill diagnoses; the writer decides.
