# design-doc-authoring Design Doc

## Purpose

A story whose goal is vague, run with LLM assistance, gets its gaps filled from the code: the code is the most readable thing in reach, so judgments are made in its vocabulary and surface only after implementation, as review round-trips and rework concentrated on the one rule nobody had decided. Writing a design document does not by itself help — a document whose skeleton mirrors the code passes structural review and is still rejected, because its spine is the code, not the purpose. This skill makes the design a staged derivation from the purpose: the requester judges each stage in prose, undecided items are collected rather than filled in, one representative case is walked through before anything is cut into tickets, and the implementation receives only decided rules.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Three documents: one Design Doc for judgment, two supplements (Data Dictionary, Business Rules) for the code side | Everything the requester judges must fit one reading; detail the walkthrough does not need pushes the whole picture out of view and inflates what an LLM session reads. The split test is a single question — can the walkthrough still run on the Design Doc alone — so the line does not depend on taste. A flat set of peer documents (system design, data contract, per-story design notes) was rejected: no single place holds the whole picture, and a story's implementation session reads on the order of a thousand lines |
| Write flow and rules, never procedure | Flow (records and keys passing between components) and rules (states a record must satisfy) are where contradictions appear; procedure (how a component works inside) in prose goes stale and is owned by code and tests. Observed in a host project: per-story design notes reached 150–300 lines each, and the bulk was procedure |
| Six judged stages, outside-in then by strength of constraint | The goal is judged from the user's side, so purpose and flow come first; records are harder to change than rules, so they are fixed before the rules that bind them. Judging per stage keeps a later stage from silently overturning an earlier judgment — it must reopen it as an undecided item |
| Undecided items go to one index with two options and a recommendation; implementation never fills them | The cost observed was not slow decisions but decisions that were never raised as questions: one undecided rule produced four review round-trips. A list the requester answers in one pass replaces scattered remarks. Items waiting on an observation are provisional, not undecided, so the index can actually empty |
| Walkthrough on the Design Doc alone, as a required stage | Contradictions do not show in a list of rules; they show when one case passes through. Needing a supplement to proceed is the signal that an essential is missing from the Design Doc |
| Business rule = the intent connecting purpose and specification; one sentence, one identifier, grounded in purpose/decision/fact, one home | The implementation cites a rule by identifier, so the sentence must carry the intent itself (no separate reason line to drift) and the grounds must lead back to a purpose (a rule grounded in another rule leads nowhere). This skill is the home of the definition; the development-cycle skill keeps the code-side handling (tests, comments) and points here |
| Present tense only; history, verbatim quotes of decided items, and story order leave the document | A document that accumulates its own trail stops being judgeable in one pass; git log and the tracker already carry that trail. A verbatim quote stays only while its item is undecided, as the record of a pending judgment |
| Writing skill loads before drafting; filing skill takes over at close | Same shape as the sibling ticket-authoring skill: the writing model is drafting input, not a post-hoc check; cutting the design into tickets is the filing skill's domain |
| No checklist file and no inspection items in this skill | The writer needs the thinking and the shapes, not a conformance list. Whether a review agent needs stable IDs to cite is decided with that agent, in the shape its findings report takes |

## Data Flow

Story ticket (purpose, provisional Done) → observed facts → six stages, each judged by the requester, writing into Design Doc / Data Dictionary / Business Rules → walkthrough → undecided index judged empty → tickets cut by the filing skill; order and dependencies to the tracker.

## Constraints & Tradeoffs

- The format was derived on, and tried against, systems that pass records between components (files, tracker rows, documents). A story with little record state has not been walked through it.
- The skill does not decide at which development stage a design task is inserted, or who inspects conformance; those belong to the project's development-cycle wiring.
- Sorting a statement as flow / rule / procedure is a judgment, not a mechanical test; the examples in guidelines.md calibrate it but do not replace it.
