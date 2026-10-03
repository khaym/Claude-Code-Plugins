# Design Doc Authoring Guidelines

Derive the rules from the purpose before any code exists, so the requester can judge the goal in prose and the implementation receives only decided rules.

This is the thinking behind the three design documents — Design Doc, Data Dictionary, Business Rules — for the writer about to produce them. The writing procedure (the six stages and what the requester judges at each) is in SKILL.md; this file says why the documents have the shape they have.

- [Why design before code](#why-design-before-code) — four ideas the shape follows from
- [The one question](#the-one-question) — flow, rule, or procedure
- [Three documents](#three-documents) — what each holds, who reads it, which way references point
- [Design Doc items](#design-doc-items) — ten items in writing order
- [Data Dictionary entry](#data-dictionary-entry) — six items per record
- [Business Rules](#business-rules) — the unit handed to implementation
- [Two indexes](#two-indexes) — undecided and provisional
- [Present tense only](#present-tense-only) — decisions, facts, and what leaves the document

## Why design before code

A story whose goal is vague gets its gaps filled from the code when implementation starts first. The code is the most readable thing in reach, so judgments are made in its vocabulary and surface only after the fact, as review round-trips and rework. The later a wrong judgment is found, the more work it undoes. The documents exist so that the judgments are made earlier, in prose, by the person who owns the goal — the requester. Four ideas give them their shape.

### Design derives rules from the purpose

A rule the writer cannot trace to who gains what is not a design decision. It is a guess, or a description of what the code happens to do. Descriptions lifted from code are facts (the result of an investigation) and are kept apart from decisions in the document, so the requester judges only what was actually decided. A document reverse-engineered from code can pass every structural check and still be wrong, because its spine is the code, not the purpose.

### The documents hold the flow and the rules; code holds the procedure

The flow is how components line up and what records pass between them, including the keys that join those records. A rule is the intent connecting purpose and specification, written as a state a record must satisfy or an order the system must impose ([Business Rules](#business-rules) has the full form). A procedure is how a component does its work inside — branches, ordering, the attributes of a cookie. Flow and rules are written because contradictions appear there. Procedure in prose goes stale without serving any purpose, and code and tests own it. A record or key that passes between components is written even though it is a means.

### Each stage is judged before the next opens

One stage answers one question. The requester judges it before the next stage opens. A later stage that would overturn an earlier judgment reopens it as an undecided item instead of silently rewriting it. The stages (six of them, listed in SKILL.md) run from the outside in, then by strength of constraint — three ordering groups, not the stage list:

- the purpose and the flow first, because the goal is judged from the user's side
- the records and their keys next, because they are the hardest to change
- the rules last, because they ride on the records they bind

Anything the purpose cannot settle is raised at the stage where it appears and collected in one index ([Two indexes](#two-indexes)), so the requester answers from a list, not from scattered remarks.

### Contradictions show in a walkthrough, not in a list

A list of rules can be read end to end with every rule looking right, and still two of them fight when one concrete case passes through. Walking one representative case through the flow, using only the Design Doc, is the inspection that finds them before implementation. If the walkthrough cannot proceed without opening the Data Dictionary or Business Rules, the Design Doc is missing an essential — a rule's intent at the level the walkthrough needs ([Design Doc items](#design-doc-items)).

## The one question

Every statement the writer is about to put down is sorted with one question: is it saying what passes between components, what state a record must satisfy, or how a component does it inside?

| The statement says | Kind | Home |
|---|---|---|
| Which component writes this record; where it is placed and under what name; which field joins it to which other record; what its lifetime is tied to | Flow | Data Dictionary (the record's entry), with the picture across records in the Design Doc |
| How many times and when it is written; whether overwrite is allowed; that two cannot share one location; that a key is unique and immutable; what a cleanup may and may not delete; the condition under which a record must not be deleted | Rule | Business Rules, binding the record by name |
| How the write is made atomic, how the directory is created, how the hash is computed, in what order a cleanup walks | Procedure | Not written — code and tests |

The question is asked per statement, not per topic: "lifetime" yields a flow statement (tied to the run), a rule (must survive until the parent closes), and a procedure (how archiving is done), and only the first two are written.

## Three documents

Everything the requester needs in order to judge sits in the Design Doc; what only the implementation side reads goes to two supplements beside it.

| Document | Holds | Read by |
|---|---|---|
| Design Doc | The whole picture: purpose, facts, flow, the list of records and the keys joining them, the essentials of the rules by purpose, decisions with their rejected alternatives, the walkthrough, the boundary, the indexes | The requester judging each stage; anyone needing the whole picture |
| Data Dictionary | One entry per record: fields and their definitions, who writes it, where it is placed, its keys, its lifetime | Whoever plans the code that writes, finds, or deletes a record |
| Business Rules | The full text of every rule, each with an identifier | Implementation, tests, and review, citing a rule by identifier |

The walkthrough test decides what leaves the Design Doc for a supplement: can the walkthrough still be run on the Design Doc alone? If yes, the detail is a supplement's; if no, it is an essential and stays.

References point one way, opposite to the writing order: Business Rules → Data Dictionary → Design Doc. A document written earlier is complete without the later ones. When two disagree, the upstream one is right. The Data Dictionary never cites Business Rules; a rule names the record it binds, so the writer looking for a record's rules searches Business Rules for the record's name. The Design Doc's supplement list registers each supplement by name and the question it answers, and that is the only downstream pointer: it says a supplement exists and never cites its content.

A project may add supplements, with the same test — same lifetime as the system, read by the code side rather than the requester — and each is registered in the Design Doc's supplement list with the question it answers.

## Design Doc items

The items in the order they appear as headings in the document. The stage that writes each is in SKILL.md; the indexes fill from the first stage on, and the Boundary's story list is written at close.

| Item | What it answers |
|---|---|
| Purpose | Who gains what, and who is deliberately not served. Nothing else — the means come later |
| Facts | The premises that cannot be moved, summarized here with their source (observation record, real data, real code). Marked apart from decisions; a provisional premise is marked as such |
| Flow | How the components line up and which records pass between them, seen from the user's side |
| Records | Every record the system manages, with its role, where it lives, and its lifetime — including records written outside this system that it only reads, since the walkthrough cannot run without them |
| Keys | Which fields join which records |
| Essentials | For each purpose: purpose → intent → the states records must satisfy, in present tense. The intent is what the requester approves or rejects; the walkthrough runs on these |
| Decisions | Numbered: the adopted option, its reason, the rejected options and their reasons. Kept separate from the essentials — a decision records why, an essential states what holds — and holding no history |
| Walkthrough | One representative case passed through the flow using the essentials alone: the steps, the undecided items and contradictions found, and what they changed |
| Boundary | What this system does not do; the line to neighboring systems; if the work is cut into several stories, which stories and which decisions each implements |
| Indexes | The undecided and provisional indexes (below), followed by the supplement list: each supplement with the question it answers |

## Data Dictionary entry

One entry per record, as labeled lines under the record's heading. The comparison across records is the Design Doc's record list.

| Item | What it answers | Without it |
|---|---|---|
| Record name | The same name as in the Design Doc's record list | The entry cannot be matched to the list |
| Fields and definitions | One line per field with its meaning. A machine-readable schema (JSON Schema, DDL) that already exists is the home; the entry points to it | Writer and reader read a field differently |
| Writer | The component that writes it — the name only; when and how often is a rule | Two writers collide |
| Location | Where, under what name, and what else can appear there | The reader cannot find it; a cleanup deletes what is not its own |
| Keys | The fields that join it to other records | Joins fail |
| Lifetime | What it lives as long as, and whether it survives the end state; the condition under which it must not be deleted is a rule | Something is deleted that must stay, or kept forever |

An entry has no "identity" item: what identity would say splits into field definitions, keys, and a rule stating when a record may be reused.

## Business Rules

A business rule is the intent connecting purpose and specification — given this purpose, why this spec. It is the unit the design hands to implementation: tests express it, review checks the code against it, and both cite it by identifier. A specification without the intent is a copy of the code; an intent without a specification is a wish.

One rule has four items:

| Item | Form |
|---|---|
| Identifier | Lowercase letters, digits, hyphens; two to four words naming the state the rule establishes or the order it imposes; no chapter numbers, so the identifier survives restructuring |
| Statement | One sentence: "so that <who> can <what>, <this state holds / this order is kept>". The intent is inside the sentence; there is no separate reason line |
| Bound record | The record (or document) the rule constrains, by its name in the Data Dictionary |
| Grounds | The purpose it serves, the decision it rests on, and the fact behind it. Never another rule, and never an undecided item: a rule grounded in a rule leads nowhere, and an undecided item cannot ground anything |

The statement is written once, in Business Rules, and nowhere else in the documents. The Design Doc holds the essentials — the same intent at the level the walkthrough needs — and the Data Dictionary points at records, not at rules. A rule restated in two places drifts, and the drift is where contradictions enter.

Rules are grouped by the purpose they serve, in the order the Design Doc lists its purposes, so the reader of a purpose finds its rules together.

## Two indexes

Both live in the Design Doc, because whoever meets a line takes a different action on each. The requester answers the undecided index before the design is cut into tickets; an implementer who still meets an undecided item stops and asks instead of filling it. A provisional value is used as it stands.

| Index | The implementer's action | Each line holds |
|---|---|---|
| Undecided — implementation does not fill these | Stop and ask. The index must be empty before the design is cut into tickets | The question, the stage where it arose, two options, the recommended one and why, and the requester's words verbatim while the answer is pending. A decided line leaves the index: the decision goes to the Decisions item, the quote to the commit and the ticket |
| Provisional — observe and correct | Use the value and move on, knowing where it came from | The value (including "done by hand" or "no mechanism yet" as a value), where it was decided, and the observation that will trigger revising it |

An item waiting on an observation is provisional, not undecided: the implementer proceeds with the current form, and the index does not block ticketing. The undecided index keeps only questions the requester can answer now, from two options.

Whether the undecided index is empty is judged after the walkthrough, because the walkthrough is where the last items surface.

## Present tense only

The Design Doc states the design as it is now. Two kinds of text are kept out of it, each with a home of its own:

| Kept out | Home | The test |
|---|---|---|
| History — when, from what, and on whose word something changed | The commit message of that change, and the ticket | Does the line say "when / from what / who said"? |
| Story order, dependencies, and work content | The tracker (parent, blocked-by) and the ticket body | Is this what the tracker already carries? |

A decision stays — adopted option, reason, rejected alternatives — because without it the next session proposes the same rejected option again. Facts stay, marked as facts. What goes is the trail of how the document got here: a reader judging the design in one pass should meet only the design.
