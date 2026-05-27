# docs-authoring Design Doc

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

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| One skill covers both "writing" and "reviewing" | The underlying goal (reduce reader load) is identical. Splitting into two skills would itself violate "Less, but better". |
| Design docs and tickets share one guideline set | The structural problems (no apex, mixed abstraction, lost premises, viewpoint drift) appear in both formats. Format-specific shape lives in `references/`. |
| Principles-first, not lenses-first | Writing is a High freedom-level task (skill-authoring's Freedom Level Design). High freedom calls for text instructions plus examples, not branching diagnostic checklists. Principles teach the why; diagnostic-only lenses do not. |
| P0 (viewpoint) sits above the other principles | Viewpoint drift compounds across sections; local fixes leak when viewpoint slides. The other principles assume P0 is already satisfied. |
| P0 propagates to wording (P3 absorbs both substitution test and reader-vocabulary) | Once viewpoint is pinned, the right vocabulary is largely determined by the reader's side. "Concrete verbs" and "reader's vocabulary" were merged from two principles into one to reflect this. |
| P2 (sibling independence) absorbs "no overlap" + "no inter-item dependency" | Dependent items presented as siblings force the reader to reverse-engineer the pipeline. This is the same failure as restatement and umbrella-mixing — the reader has to reconstruct the list before reading the content. |
| "When writing" workflow described as bottom-up → top-down iteration | Top-down structure is the target shape, not the drafting process. Writers usually brainstorm bottom-up, abstract to find the apex, then restructure. Describing only the target shape would be a lie about the process. |
| Failure patterns kept as a small mapping table | Reviewers often start from a symptom ("this feels off"). The mapping table gives them a path back to the missed principle. |
| Verification extracted to checklist.md, removed from each principle | Per-principle Self-check sub-sections required reviewers to scan five separate spots and hold all principles in working memory. A consolidated binary checklist (modeled on skill-authoring/checklist.md) makes the application pass observable and complete, separating "understand the principle" from "verify each one". |
| Two-phase model: Process (Phase A) precedes Principles (Phase B) | The original five principles all describe what readable prose looks like, but assume the content has been chosen. A test (webwright adoption report) showed structural cleanness can quietly drop reader-relevant facts (e.g., "lightweight" framing and dependency footprint disappeared from the docs-authoring-applied version). Phase A makes content identification an explicit action step that precedes structural work; "useful trumps clean" sits in Phase A's A3 rather than being smuggled into a principle. |
| Process (A) framed as actions, not principles | The principles describe properties of readable prose (state-oriented). Content identification is action-oriented and sequential. Mixing the two collapses the writer's planning step into a structural rule, which obscures both. |
| Skill value scales with input messiness | Comparative rewrite tests showed that measurable improvements (apex placement, viewpoint unification, anchor explicitness) are clearly visible when the input is unstructured — AI-generated bloat, conversational notes, ambiguous viewpoint — and only marginally visible when the source is already well-edited technical material. The skill's trigger phrases ("make this clearer", "tighten this doc", "読みやすくしたい") and the Phase A → Phase B workflow target the messy-input case. |
| Main session, not SubAgent | Writing assistance is iterative — the user reacts to each suggestion. Context isolation would break the feedback loop. |
| Markdown is the only supported output format at v0.1 | Jira / Confluence / Notion-specific shapes are deferred. The principles apply regardless; only templates would differ. |

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
P1. Build top-down                     (apex first; support, premises, examples below)
P2. Keep sibling items independent     (MECE, same abstraction, no inter-item dependencies)
P3. Use concrete words from the         (substitution test + reader-side translation cost)
    reader's vocabulary
P4. Mark the boundary                  (out-of-scope; rejected alternatives;
                                        skip when scope is already obvious)
```

Failure patterns F1–F4 are surface symptoms; each maps back to a missed step or principle, giving reviewers a path from "feels off" to "fix here". F4 (missing decision-relevant facts) is the symptom that motivated Phase A's introduction.

## Constraints & Tradeoffs

- **Markdown-only output at v0.1.** Jira ADF, Confluence storage format, and Notion blocks are out of scope. The principles still apply but shaping rules would differ.
- **Phase B principle count is capped at five.** Adding more principles past this point turns the skill into the kind of document it is meant to fix. Phase A is action-oriented process and is counted separately.
- **No agents, no hooks at v0.1.** Only the skill, invoked from the main session.

## Composition

Standalone skill. Not consumed by other skills or agents at v0.1. If a future `docs-review` agent ships, it will preload this skill via the `skills:` frontmatter field (DI pattern).
