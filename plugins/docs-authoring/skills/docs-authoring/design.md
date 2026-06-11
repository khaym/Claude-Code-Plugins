# docs-authoring Design Doc

## Table of Contents

- [Purpose](#purpose)
- [Core Concept](#core-concept)
- [Target Failure Patterns](#target-failure-patterns)
- [Design Decisions](#design-decisions)
- [Data Flow](#data-flow)
- [Writing Model](#writing-model)
- [Constraints & Tradeoffs](#constraints--tradeoffs)
- [Composition](#composition)

## Purpose

Help users produce design documents, tickets, and similar engineering prose that a reader can understand in one pass. The skill applies a shared writing model — content-identification process (Phase A) plus structural principles (Phase B) — whether the user is drafting from scratch or rewriting an existing document.

## Core Concept

**Identify what the reader came for, then choose the shortest path to it.**

Writing has two phases. The first decides what to convey (the reader's questions or decisions). The second structures that content into a path the reader can follow in one pass.

"Less, but better" (Dieter Rams) applies to both phases: every fact and every word should serve a function. Cutting for cleanness — dropping facts the reader needs because they don't fit the structure — is the failure mode the skill is built to prevent.

## Target Failure Patterns

LLM-generated and human-written engineering prose tends to fail in recurring ways. The skill is calibrated to surface and fix each one.

| # | Failure | Reader's experience |
|---|---------|---------------------|
| F1 | Repetition / verbosity | Same point restated with different wording |
| F2 | Flat surface, no point of issue | Cannot tell which sentence carries the claim |
| F3 | Broken logical thread | Must re-read prior sections to follow the current one |
| F4 | Missing decision-relevant facts | Reads cleanly but does not tell the reader what they need to decide |
| F5 | Bold-saturated surface | Everything is highlighted, so nothing is — no resting place, no priority |

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| One skill covers both "writing" and "reviewing" | The underlying goal (reduce reader load) is identical. Splitting into two skills would itself violate "Less, but better". |
| Design docs and tickets share one guideline set | The structural problems (no apex, mixed abstraction, lost premises, viewpoint drift) appear in both formats. Format-specific shape lives in `references/`. |
| Principles-first, not lenses-first | Writing is a High freedom-level task (skill-authoring's Freedom Level Design). High freedom calls for text instructions plus examples, not branching diagnostic checklists. Principles teach the why; diagnostic-only lenses do not. |
| P0 (viewpoint) sits above the other principles | Viewpoint drift compounds across sections; local fixes leak when viewpoint slides. The other principles assume P0 is already satisfied. |
| P0 propagates to wording (P3 absorbs both substitution test and reader-vocabulary) | Once viewpoint is pinned, the right vocabulary is largely determined by the reader's side. "Concrete verbs" and "reader's vocabulary" were merged from two principles into one to reflect this. |
| Sentence-level concision folded into P3 + Core Concept, not added as a new principle | The output-length complaint ("generated docs run long") traced to an asymmetry: the model warned against dropping facts (A3, F4) five times but had no pressure to cut *words*. Fix splits "Less, but better" explicitly into facts (keep — relocate, don't delete) vs words (cut filler), states *fewer words, not fewer facts* in Core Concept, and extends P3 from word *choice* to word *count* (the `Filler` bullet, checklist W4). Folded into P3 rather than a new P5 to respect the five-principle cap — a sixth principle would itself bloat the model it polices. F1 (verbosity) now maps to P2 (list-level) **and** P3 (prose-level). |
| Guidelines explain the skill-specific, not the generally-known | Compaction (189→127 lines) cut self-evident justification and kept only what removes 認識齟齬: skill-specific vocabulary, non-obvious calibrations (P0 compounds, fact/word split), and Detour/Direct examples for the easy-to-misread principles only (P0, P2 — dropped for P1/P3/P4). A skill directs attention; it does not re-teach what the reader already knows. |
| P2 (sibling independence) absorbs "no overlap" + "no inter-item dependency" | Dependent items presented as siblings force the reader to reverse-engineer the pipeline. This is the same failure as restatement and umbrella-mixing — the reader has to reconstruct the list before reading the content. |
| "When writing" workflow described as bottom-up → top-down iteration | Top-down structure is the target shape, not the drafting process. Writers usually brainstorm bottom-up, abstract to find the apex, then restructure. Describing only the target shape would be a lie about the process. |
| Failure patterns kept as a small mapping table | Reviewers often start from a symptom ("this feels off"). The mapping table gives them a path back to the missed principle. |
| Verification extracted to checklist.md, removed from each principle | Per-principle Self-check sub-sections required reviewers to scan five separate spots and hold all principles in working memory. A consolidated binary checklist (modeled on skill-authoring/checklist.md) makes the application pass observable and complete, separating "understand the principle" from "verify each one". |
| Two-phase model: Process (Phase A) precedes Principles (Phase B) | The original five principles all describe what readable prose looks like, but assume the content has been chosen. A test (webwright adoption report) showed structural cleanness can quietly drop reader-relevant facts (e.g., "lightweight" framing and dependency footprint disappeared from the docs-authoring-applied version). Phase A makes content identification an explicit action step that precedes structural work; "useful trumps clean" sits in Phase A's A3 rather than being smuggled into a principle. |
| Process (A) framed as actions, not principles | The principles describe properties of readable prose (state-oriented). Content identification is action-oriented and sequential. Mixing the two collapses the writer's planning step into a structural rule, which obscures both. |
| Skill value scales with input messiness | Comparative rewrite tests showed that measurable improvements (apex placement, viewpoint unification, anchor explicitness) are clearly visible when the input is unstructured — AI-generated bloat, conversational notes, ambiguous viewpoint — and only marginally visible when the source is already well-edited technical material. The skill's trigger phrases ("make this clearer", "tighten this doc", "読みやすくしたい") and the Phase A → Phase B workflow target the messy-input case. Later validated end-to-end on two contrasting external inputs: an AI-inflated article (human-sketched points, LLM-expanded) compressed to a one-pass summary with every reader anchor retained, whereas a well-edited reference doc yielded mainly contradiction- and completeness-catching rather than compression — both ends of the calibration confirmed. |
| Main session, not SubAgent | Writing assistance is iterative — the user reacts to each suggestion. Context isolation would break the feedback loop. |
| Markdown is the only supported output format at v0.1 | Jira / Confluence / Notion-specific shapes are deferred. The principles apply regardless; only templates would differ. |
| Principle definitions are language-independent; English-specific tactics demoted to realizations | Two definitions encoded an English syntactic feature as the rule itself: P1/T1 said the apex is "verb-first" (impossible in SOV languages like Japanese; in SVO Chinese the verb isn't fronted either), and P0/V2 keyed viewpoint to the "grammatical subject" (routinely elided in pro-drop languages — Japanese, Chinese, Spanish). Both let the means (English grammar) hijack the end (assert the action / hold one stance). Reworded to the language-independent intent — apex *names the action or outcome, not the topic*; viewpoint keeps *the stance's subject* consistent — since the skill triggers on non-English authoring ("読みやすくしたい"). Illustrative examples (English filler, abstract-verb list in P3) were left as-is: examples illustrate, they don't define, and abstracting them would cost the concreteness that makes them useful. |
| Sentence/paragraph granularity absorbed into P1/P2/P3; bold demoted to a symptom (F5) | The model covered document (P0/P1), list (P2), word (P3), and scope (P4) granularity, but nothing between word and section. Cybozu's "テクニカルライティングの基本 2023" (Steps 3–4) fills the gap: one topic per paragraph with the claim first (P1/T6), parallel form for parallel content (P2/S5–S6), one claim per sentence and positive form (P3/W5–W6). Bold overuse is treated as the *symptom* that appears when these structural rules are violated — so detection (strip test W7, bold budget W8, F5) points back to P1/P2/P3, not to a styling rule. "One claim per sentence" replaces "keep sentences short" because claim count is binary-checkable while length is only a symptom (the source deck itself notes length ≠ clarity). No new P5, respecting the five-principle cap. |
| Self-review pass is cost-gated, not blanket-mandatory | The writing workflow chains into docs-review **for substantive output** (design docs, RFCs, postmortems, multi-paragraph tickets) and skips it for trivial cases (one-line subjects, comments, few-line fixes). Reason: the agent's load (guidelines.md + checklist.md + draft in isolated context) only pays off when the writing model has surface to bite on. A blanket "always run" would impose SubAgent dispatch cost on outputs where the full checklist sweep yields little. The criteria live in SKILL.md; this design decision records the principle (cost proportional to value). |

## Data Flow

```
User intent (write | review | look up rules)
        │
        ▼
SKILL.md  ── routes by intent ──┬─▶ guidelines.md (concept + Process A + Principles P0–P4 + how-to)
                                └─▶ checklist.md  (A + V/T/S/W/B binary checks)
                                        │
                                        ▼
                              references/{design-doc, ticket}.md
                                  (format-specific shapes, future)
                                        │
                                        ▼
                              Edits to the user's document
```

The user holds the document; the skill supplies principles and recipes. No external data, no scripts.

## Writing Model

Two phases — Process (actions) then Principles (properties):

```
Apex: identify what the reader came for, then choose the shortest path to it

Phase A — Process (content identification, action-oriented):
A1. Identify the reader                (specific naming; segment if diverse)
A2. Identify what the reader came for  (questions/decisions; ask if unclear)
A3. Select content by usefulness       (useful trumps clean; relocate, don't delete)

Phase B — Principles (properties of readable prose):
P0. Hold one viewpoint throughout      (Foundational — subject stance, abstraction level,
                                        role declaration, argument frame)
P1. Build top-down                     (apex first; support, premises, examples below;
                                        one topic per paragraph, claim first)
P2. Keep sibling items independent     (MECE, same abstraction, no inter-item
                                        dependencies, parallel form)
P3. Use concrete words, only the         (substitution test + reader-side translation cost
    ones that carry the claim              + cut filler + split test — fewer words,
                                           not fewer facts; bold is a last resort)
P4. Mark the boundary                  (out-of-scope; rejected alternatives;
                                        skip when scope is already obvious)
```

Failure patterns F1–F5 are surface symptoms; each maps back to a missed step or principle, giving reviewers a path from "feels off" to "fix here". F4 (missing decision-relevant facts) is the symptom that motivated Phase A's introduction; F1 (repetition / verbosity) maps to both P2 (list-level redundancy) and P3 (prose-level padding); F5 (bold-saturated surface) appears when paragraph-head claims (P1) or parallel form (P2) are missing and typography compensates.

## Constraints & Tradeoffs

- **Markdown-only output at v0.1.** Jira ADF, Confluence storage format, and Notion blocks are out of scope. The principles still apply but shaping rules would differ.
- **Phase B principle count is capped at five.** Adding more principles past this point turns the skill into the kind of document it is meant to fix. Phase A is action-oriented process and is counted separately.
- **No hooks.** The plugin ships the skill and the read-only `docs-review` agent (see Composition); nothing runs automatically.

## Composition

The skill is the single source of truth for the writing model (guidelines.md + checklist.md) and has two consumers:

| Consumer | Mode | Loads via |
|----------|------|-----------|
| Main session | Writing / tightening (iterative, edits the document) | Skill auto-loaded by trigger phrases |
| `docs-review` agent | Audit (one-shot, isolated context, read-only findings report) | `skills: docs-authoring` frontmatter (DI) |

Trigger phrases are partitioned so the two consumers do not compete: writing/tightening verbs route to the skill; audit verbs route to the agent. The skill remains self-contained — no cross-references into the agent.
