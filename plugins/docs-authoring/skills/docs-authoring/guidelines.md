# Docs Authoring Guidelines

Write an engineering document with every fact its named reader needs, only the words that carry meaning, in an order the reader follows in one pass.

This file is the writing model shared by two readers: the writer who loads this skill to write or tighten an engineering document, and the reviewer (the docs-review agent or a person) who loads it to review one.

- [Core Concept](#core-concept)
- [Process — Phase A](#process--phase-a-content-identification)
- [Principles — Phase B](#principles--phase-b-properties-of-readable-prose)
- [How to Apply](#how-to-apply)

---

## Core Concept

Writing runs in two phases:

- **Phase A — content identification**: decides what to convey, the questions or decisions the named reader uses this document for.
- **Phase B — readable prose**: decides the path that carries that content in one pass.

The model keeps fewer words, not fewer facts. "Less, but better" (Dieter Rams) cuts the two in opposite directions:

| Target | Rule | Home |
|---|---|---|
| Words | Cut every word that carries no meaning | P3 |
| Facts | Keep every fact the reader needs | A3 |

This model exists to prevent one error: confusing the two directions, that is, cutting a needed fact for cleanness. When the two pull against each other, shorten the sentence, not the substance.

Engineering documents are technical writing, not narrative. Narrative is prose that leads the reader toward a point instead of stating it. P1 places each paragraph's point first. P4 cuts the sentences that only lead on or restate.

---

## Process — Phase A (content identification)

Run Phase A before Phase B. Phase B alone yields a structurally clean document missing what the reader came for.

### A1. Name the reader specifically

Name the reader specifically, not as a group: "the on-call SRE during an incident", not "the team"; "a backend engineer evaluating libraries for adoption", not "engineers". Specific naming forces you to know who you write for.

A document serving several reader types names each. Each type has its own questions (A2).

### A2. List what the reader came for

Before drafting the body, write down the questions or decisions the reader uses this document to answer or decide ("What does this do?" "How much integration cost?" "Adopt it?"). Each item is an *anchor*, the unit completeness is checked against.

Every fact serves an anchor or supports a fact that does. The list is the contract. Any other fact is a *detour* — text the reader passes through without gaining what they came for.

When the requester's intent is unclear, ask. A guess that misses the anchor fails silently, as a clean document about the wrong question.

### A3. Select by usefulness, not cleanness

A fact that serves an anchor stays even when it falls outside the chosen structure. Relocate it to another section, a footnote, or a parenthesis; never delete it for cleanness.

Two tells show that A2 was skipped:

- items ordered by their type ("Language → Backend → License") instead of reader relevance
- a fact dropped because it "doesn't fit the section"

On either tell, check A2 first. Usually the fact serves an anchor.

---

## Principles — Phase B (properties of readable prose)

Six principles define readable prose. Each one's binary checks form one layer of [checklist.md](checklist.md):

| Principle | Checks |
|---|---|
| P0. Hold one viewpoint throughout | V |
| P1. Build top-down | T |
| P2. Keep sibling items independent | S |
| P3. Use concrete words | W |
| P4. Use technical writing, not narrative | C |
| P5. Mark the boundary | B |

The other five principles assume P0 holds.

The easy-to-misread principles (P0, P2) carry an example pair: a *Detour* shape and its *Direct* rewrite.

### P0. Hold one viewpoint throughout (foundational)

Pin the viewpoint with a *role declaration*: one sentence near the top stating the stance ("This document is the shape of the library"; "This ticket commissions an investigation, not an implementation").

Fix a viewpoint shift for the whole document. Patching section by section leaves it in place. Each shift makes the reader rebuild "whose stance am I reading from now?". That cost compounds across the document.

A pinned viewpoint largely fixes the vocabulary (P3). A sliding one lets word choices drift even when each is individually defensible.

Hold three dimensions steady:

| Dimension | Holds steady across sections | Sign it slid |
|---|---|---|
| Subject stance (most important) | The stance's subject — user, system, we, the function, the investigator | The natural subject changes by section |
| Abstraction level | One level | The sections move strategy → implementation → strategy |
| Argument frame | "The problem being solved" | The frame changes without an explicit mark |

*Detour*: a ticket whose Purpose, Investigation, and Success sections each speak from a different person's view. The reader switches stance three times in thirty lines. *Direct*: every section frames its output as "what this investigation produces for the implementer of #10". The analyst and investigator views become supporting context, not load-bearing stances.

### P1. Build top-down

Each unit sits below what it depends on and above what supports it. A broken chain forces the reader to backtrack.

- **Apex**: the apex names the action or outcome the document delivers, not its topic. It is one sentence. A reader of the apex alone knows what the document is for. A short document (ticket, comment) puts it in the title. A long one puts it in the first sentence after the title.
- **Premises**: premises sit above what depends on them. A short premise sits inline. A long one sits in a Background section above the sections that use it.
- **Evidence and examples**: they sit below the claim they serve.
- **Sections**: each section is the apex or support for an earlier apex.
- **Paragraphs**: each paragraph holds one topic. Its first sentence, the *paragraph head*, states the point — the claim the paragraph exists to make. A build-up (sentences leading from problem through consequence to the point) moves below the point. Reading only the paragraph heads traces the section's argument.

Bold is kept for the first use of a defined term or a warning. Its budget is five per document at most, not per section, scan-type documents (runbooks, facilitation scripts) included. A document with more defined terms moves them into a table or a terms section. A list item's label (`- **Label**: text`) takes bold as well and falls outside this budget and the strip test. An unbolded label blurs into its text. Bold marks what placement failed to do: before bolding, move the point to where the reader already looks — the paragraph head, the heading, the table cell. To set off a term, quoting marks (「」/ backticks) come before bold.

The strip test judges the result: remove every bold. When each point is still findable in one pass (one glance, for scan-type documents), the bold was decoration. Cut it. When a point is lost, the structure leans on typography. Fix the structure (paragraph heads, P2 parallel form), not the styling.

### P2. Keep sibling items independent

A list of N items claims N independent points sharing one axis. A list that breaks this makes the reader reverse-engineer it before reading it. It is a top source of "hard to follow" even when every sentence is clear.

A numbered list declares an order. The chain rule applies to unnumbered lists only. The axis and form rules apply to numbered lists and table rows as well.

Each defect below has its fix:

- **A missing axis**: name the axis before listing (outcomes, candidates, options, criteria). Choose the axis that serves the reader's purpose (A2), not the one that decomposes most cleanly. Test each item against it.
- **Restating items**: merge them into the wording closest to the document's purpose.
- **An umbrella item, at a different abstraction level from its siblings**: pull it up a level, into the intro, the parent heading, or a separate sibling section.
- **A chained dependency (one item's output is another's input)**: lift it out of the parallel list. Nest it under what it depends on, merge the two, move the shared outcome elsewhere, or write the chain as a numbered procedure.
- **Diverging forms**: give parallel content parallel form, the same grammatical shape and the same element order. Diverging forms make the reader re-parse each item from scratch. Scan-type documents then reach for highlighting to compensate.
- **Three or more parallel clauses in one sentence**: break them out into a list. The sibling checks then apply to it. A series of noun examples stays inline.
- **The wrong form for the items**: a table holds items that share two or more attributes, every cell filled. A label with its text is a list item. A table whose cells hold paragraphs, or whose columns stay mostly empty, is a list forced into a grid.

*Detour*: a "Done" list of (a) classify the pattern, (b) catalogue the axes, (c) extract parameters from (b), (d) write up the above. a→b→c is a pipeline. d covers them all. *Direct*: "Done" lists two independent end-states. The deliverable and the implicit pipeline live in their own sections.

### P3. Use concrete words

Every word carries meaning. Every load-bearing term — a term the claim depends on — comes from the reader's side.

- Name domain-specific actions. Abstract verbs ("process", "manage", "handle", "apply") give a sentence its shape without content. The substitution test finds them: swap the apex's main noun and verb for another domain. If the sentence still reads, it was empty.
- Use load-bearing terms the reader knows from their own side. Gloss or replace a term they know only from yours. Such a term makes the reader translate from your side to theirs.
- Speak the goal's vocabulary in success criteria, evidence, and support. Keep implementation-side terms in background.
- Cut every word the sentence survives without. Padding — throat-clearing, hedging, restated context — is a detour inside the sentence: length without meaning ("in order to" → "to"; "it is important to note that" → nothing).

### P4. Use technical writing, not narrative

Every sentence states a new claim: a fact, a rule, or a decision. Narrative sentences, the two kinds below, only lead on or restate. Cut them. A build-up's sentences carry facts. P1 moves them below the point.

| Narrative kind | What it is | Kept instead |
|---|---|---|
| Lead-in | A sentence whose only role is to lead to the next (a transition, a preamble) | A sentence naming a list's shared axis: it states a claim (P2) |
| Restatement | A sentence that re-argues or restates an earlier claim or reason without adding a fact. An expanded reason is the common case. | A needed reason, one sentence per fact, after its claim |

Each claim also gets its own sentence, stated affirmatively:

- A sentence joining two claims that could each stand alone splits at the conjunction. A claim and its reason are two claims, each in its own sentence. The test counts claims, not length.
- A claim is stated in positive form ("state claims affirmatively" over "avoid negation"). Negation stays in prohibitions, warnings, and contrasts naming the rejected alternative ("fewer words, not fewer facts"). Such a contrast keeps the claim unambiguous. Negations are never stacked ("not unlikely").

### P5. Mark the boundary

Name what a document or section excludes where its scope is ambiguous. The reader then stops speculating about scope. The claim also becomes easier to verify.

- Add a one-line "Out of scope" where scope ambiguity is likely. Tickets carry it as a standard field.
- Name the rejected alternative. It marks a decision's boundary by contrast.
- Skip the boundary statement when the title and apex make the scope obvious. Such a statement is a detour.

---

## How to Apply

### When writing

Top-down (P1) is the target shape, not the drafting order. Phase B iterates between bottom-up exploration and top-down restructuring.

1. Run A1–A3.
2. Pin the viewpoint (P0) in one sentence.
3. Write the apex: one sentence covering the content. Content that needs more holds more than one document. Split or narrow it.
4. Apply P1–P5 in order, iterating. The first apex is usually wrong. Sharpening it sharpens the body.
5. Re-read for viewpoint drift (P0) once the body has grown.
6. Self-review with docs-review when the output is substantive (run/skip criteria in SKILL.md). Before handing back, apply the smallest edit that turns each NG to OK.

### When reviewing

1. Rate the [checklist](checklist.md) rows in the order it sets.
2. On an A NG, ask the writer which reader anchors they identified. The NG may mean missing content (Phase A).
3. Propose V (P0) fixes before the other layers' fixes.
4. Propose the smallest edit that turns each NG to OK. Apply an edit only after the writer confirms it.
