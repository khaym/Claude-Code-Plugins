# Docs Authoring Guidelines

Identify what the reader came for, then choose the shortest path to it.

This is the shared writing model for the reader loading this skill to write or review an engineering document: a core concept, a content-identification process (Phase A), five principles for readable prose (Phase B), a failure-pattern map, and how to apply both phases.

---

## Core Concept

**Identify what the reader came for, then choose the shortest path to it.**

Writing has two phases. Phase A decides *what* to convey — the questions or decisions the named reader uses this document for. Phase B structures that content into a path readable in one pass.

"Less, but better" (Dieter Rams) cuts in two directions, and confusing them is the central error:

- **Words** — cut every word that doesn't carry meaning. Throat-clearing, hedging, and restated context are detours.
- **Facts** — keep every fact the reader needs; when it doesn't fit the structure, **relocate, don't delete**. Cutting a needed fact for cleanness is the failure this model exists to prevent.

So: *fewer words, not fewer facts.* When the two pull against each other, shorten the sentence, not the substance.

When writing, identify before structuring. When reviewing, check content completeness (Phase A) and path shortness (Phase B) as separate passes.

---

## Process — Phase A (content identification)

Phase B assumes Phase A is done; skip it and you get a structurally clean document missing what the reader came for.

### A1. Name the reader specifically

Not "the team" but "the on-call SRE during an incident"; not "engineers" but "a backend engineer evaluating libraries for adoption". Specific naming forces you to know who you write for. If the document serves multiple reader types, name each — every segment has its own anchors (A2).

### A2. List what the reader came for

The questions or decisions they use this document to answer or decide ("What does this do?" "How much integration cost?" "Adopt it?"). Write the list down before drafting the body. **This list is the contract**: every fact either serves an item on it or supports one that does — otherwise it is a detour. When the requester's intent is unclear, ask; a guess that misses the anchor fails silently, producing a clean document about the wrong question.

### A3. Select by usefulness, not cleanness

If a fact serves an anchor but doesn't fit the chosen structure, relocate it (another section, footnote, parenthesis) — don't delete it. Two tells that A2 was skipped: ordering items by their *type* ("Language → Backend → License") instead of reader-relevance, and dropping a fact because it "doesn't fit the section". Check A2 first — usually the fact serves an anchor and stays.

---

## Principles — Phase B (properties of readable prose)

P0 is foundational — the other four assume it holds. Binary checks for each live in [checklist.md](checklist.md). Detour/Direct examples appear only for the easy-to-misread principles (P0, P2).

### P0. Hold one viewpoint throughout (foundational)

Every shift in viewpoint forces the reader to rebuild "whose stance am I reading from now?" — a cost that compounds across the whole document and can't be patched section by section. Pin the viewpoint and the right vocabulary (P3) largely follows; let it slide and word choices drift even when each is individually defensible.

- **Subject stance** (most important): keep the stance's subject consistent across sections — user, system, we, the function, the investigator. If the natural subject changes by section, the viewpoint has slid.
- **Abstraction level**: don't move strategy → implementation → strategy between sections.
- **Role declaration**: state the stance once near the top, in one sentence ("This document is the shape of the library"; "This ticket commissions an investigation, not an implementation").
- **Argument frame**: keep "the problem being solved" constant; mark any change explicitly.

*Detour*: a ticket whose Purpose, Investigation, and Success sections each speak from a different person's view — the reader switches stance three times in thirty lines. *Direct*: every section frames its output as "what this investigation produces for the implementer of #10"; the analyst and investigator views become supporting context, not load-bearing stances.

### P1. Build top-down

A reader who reads only the apex should know what the document is for. Below it, claims precede their evidence, premises precede the sections that use them, examples sit under the claims they illustrate. A broken chain forces the reader to backtrack.

- Apex = one sentence that names the action or outcome the document delivers, not its topic: the title for short docs (tickets, comments); the first sentence after the title for long ones.
- Premises above what depends on them — inline if short, a Background section before Goal if long.
- For each section, ask: is this an apex, or support for an earlier apex? A section that is neither doesn't belong in the chain.

### P2. Keep sibling items independent

A list of N items claims N independent points sharing one axis. If items restate each other, sit at different abstraction levels, or chain (one's output is another's input), the reader must reverse-engineer the list before reading it — a top source of "hard to follow" even when every sentence is clear.

- Name the shared axis before listing (outcomes, candidates, options, criteria); test each item against it.
- Merge restatements into the wording closest to the document's purpose.
- Pull an umbrella item up a level — into the intro, the parent heading, or a separate sibling section.
- Lift a dependency out of the parallel list — nest it under what it depends on, merge the two, or move the shared outcome elsewhere.

*Detour*: a "Done" list of (a) classify the pattern, (b) catalogue the axes, (c) extract parameters from (b), (d) write up the above — a→b→c is a pipeline and d covers them all; none are siblings. *Direct*: "Done" lists two independent end-states; the deliverable and the implicit pipeline live in their own sections.

### P3. Use concrete words — and only the words that carry the claim

Prose goes empty two ways: abstract verbs ("process", "manage", "handle", "apply") that give a sentence shape without content, and padding (throat-clearing, hedging, restated context) that adds length without meaning. Author-side terms add a third cost — the reader translates from your side to theirs.

- **Substitution test**: swap the apex's main noun and verb for another domain. If the sentence still reads, it was empty.
- **Cut filler**: delete any word the sentence survives without. "In order to" → "to"; "it is important to note that" → nothing.
- **Translation cost**: for each load-bearing term, does the reader know it from their own side, or only from yours? Gloss or replace the latter.
- **Vocabulary consistency**: success criteria and evidence speak the goal's vocabulary; reserve implementation-side terms for background.

### P4. Mark the boundary

An unbounded claim is harder to verify and easier to misread. Naming what a section excludes prevents the reader from speculating about scope and tightens the claim itself.

- Add a one-line "Out of scope" where scope ambiguity is likely; for tickets, treat it as a standard field.
- Naming the rejected alternative marks a decision's boundary by contrast.
- Skip it when scope is obvious from title + apex — a boundary statement that adds nothing is itself a detour.

---

## Common Failure Patterns

Symptoms a reviewer catches first; each maps back to the missed step or principle, whose [checklist.md](checklist.md) items guide the fix.

| # | Failure | Reader's experience | Missed |
|---|---------|---------------------|--------|
| F1 | Repetition / verbosity | "I read this point already" / "every sentence carries padding" | P2, P3 |
| F2 | Flat surface, no point of issue | "I can't tell which sentence carries the claim" | P1, P3 |
| F3 | Broken logical thread | "I had to scroll back to follow this" | P0, P1, P3 |
| F4 | Missing decision-relevant facts | "Reads cleanly, but doesn't tell me what to decide" | A2, A3 |

---

## How to Apply

### When writing

Phase A then Phase B. Top-down (P1) is the target shape, not the drafting order — Phase B iterates between bottom-up exploration and top-down restructuring.

1. **A1–A3**: name the reader, list what they came for, select facts by usefulness.
2. **Pin the viewpoint (P0)** in one sentence, then apply **P1–P4** in order. These iterate — the first apex is usually wrong, and sharpening it sharpens the body. If no single sentence covers the content, it isn't one document yet: split or narrow.
3. **Re-read for viewpoint drift (P0)** once the body has grown.
4. **Self-review with docs-review** when the output is substantive (run/skip criteria in SKILL.md). Apply the smallest edit that turns each NG to OK before handing back.

### When reviewing

1. Run the [checklist](checklist.md) as a full sweep — mark each OK / NG / N/A.
2. **A (Process) NG** may mean missing content; ask what reader anchors the writer identified. Structural edits alone won't fix Phase A failures.
3. **V/T/S/W/B NG**: consult the matching principle. If any V (P0) item is NG, fix viewpoint first — local edits leak when it slides.
4. Still feels off? Scan symptoms F1–F4 and trace to the missed step via the table.
5. Propose the smallest edit that turns NG to OK; confirm with the writer before applying. The skill diagnoses; the writer decides.
