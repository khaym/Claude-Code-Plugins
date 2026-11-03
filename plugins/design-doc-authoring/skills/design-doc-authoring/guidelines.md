# Design Doc Authoring Guidelines

Derive the rules from the purpose before any code exists, so the requester judges the goal in prose and the implementation receives only decided rules.

This file defines the shape of the three design documents — Design Doc, Data Dictionary, Business Rules — and the reason for each shape, for the writer about to produce them. The writing procedure (the six stages and what the requester judges at each) is in SKILL.md.

- [Why design before code](#why-design-before-code)
- [The one question](#the-one-question)
- [Three documents](#three-documents)
- [Design Doc items](#design-doc-items)
- [Data Dictionary entry](#data-dictionary-entry)
- [Business Rules](#business-rules)
- [Two indexes](#two-indexes)
- [Designing against what exists](#designing-against-what-exists)
- [Present tense only](#present-tense-only)

## Why design before code

The documents move judgments ahead of the code, into prose, to the requester — the person who owns the goal. When implementation starts first, the code, the most readable thing in reach, fills the gaps in a vague goal: judgments are made in its vocabulary and surface only after the fact, as review round-trips and rework that grow the later they come.

The four subsections below are the ideas the documents' shape follows from.

### Design derives rules from the purpose

A design decision is a rule traced to who gains what. A rule without that trace is a guess, or a description of what the code does.

- A description lifted from code is a fact (the result of an investigation). The document keeps facts apart from decisions, so the requester judges only what was decided.
- A document reverse-engineered from code can pass every structural check and still be wrong: it is organized around the code, not the purpose.

### The documents hold the flow and the rules; code holds the procedure

| Kind | What it is | Written |
|---|---|---|
| Flow | How components line up, which records pass between them, and the keys that join those records | Yes — contradictions appear here |
| Rule | The intent connecting purpose and specification, written as a state a record must satisfy or an order the system must impose ([Business Rules](#business-rules)) | Yes — contradictions appear here |
| Procedure | How a component works inside — branches, ordering, the attributes of a cookie | No — code and tests own it; in prose it goes stale and serves no purpose |

A record or key that passes between components is written even though it is a means.

### Each stage is judged before the next opens

- One stage answers one question, and the requester judges it before the next opens.
- A later stage that would overturn an earlier judgment reopens it as an undecided item; it never rewrites the judgment silently.
- Anything the purpose cannot settle goes to one index ([Two indexes](#two-indexes)), so the requester answers from a list, not from scattered remarks.

The stages run from the outside in, then by strength of constraint — three ordering groups, not the stage list:

| Order | Group | Reason |
|---|---|---|
| 1 | The purpose and the flow | The goal is judged from the user's side |
| 2 | The records and their keys | They are the hardest to change |
| 3 | The rules | They ride on the records they bind |

### Contradictions show in a walkthrough, not in a list

The walkthrough — one representative case passed through the flow, using the Design Doc alone — finds contradictions before implementation. A list of rules cannot: two rules that each read right can fight when one concrete case passes through both. A walkthrough that needs the Data Dictionary or Business Rules to proceed shows a missing essential — a rule's intent at the level the walkthrough needs ([Design Doc items](#design-doc-items)).

## The one question

Sort every statement the writer is about to put down with one question: does it say what passes between components, what state a record must satisfy, or how a component does it inside?

| The statement says | Kind | Home |
|---|---|---|
| Which component writes this record; where it is placed and under what name; which field joins it to which other record; what its lifetime is tied to | Flow | Data Dictionary (the record's entry), with the picture across records in the Design Doc |
| How many times and when it is written; whether overwrite is allowed; that two cannot share one location; that a key is unique and immutable; what a cleanup may and may not delete; the condition under which a record must not be deleted | Rule | Business Rules, binding the record by name |
| How the write is made atomic, how the directory is created, how the hash is computed, in what order a cleanup walks | Procedure | Not written — code and tests |

Ask per statement, not per topic. "Lifetime" yields a flow statement (tied to the run), a rule (must survive until the parent closes), and a procedure (how archiving is done); only the first two are written.

## Three documents

The Design Doc holds everything the requester needs to judge. The two supplements — Data Dictionary and Business Rules — hold what only the implementation side reads. Supplements exist at two levels:

- The story's supplements — written for one story; they last until the story closes.
- The project's supplements — the project's one Data Dictionary and Business Rules, into which every story's supplements are merged ([Designing against what exists](#designing-against-what-exists)).

| Document | Holds | Read by |
|---|---|---|
| Design Doc | The whole picture ([Design Doc items](#design-doc-items)) | The requester judging each stage; anyone needing the whole picture |
| Data Dictionary | One entry per record ([Data Dictionary entry](#data-dictionary-entry)) | Whoever plans the code that writes, finds, or deletes a record |
| Business Rules | The full text of every rule, each with an identifier | Implementation, tests, and review, citing a rule by identifier |

The walkthrough test decides what leaves the Design Doc: can the walkthrough still run on the Design Doc alone? If yes, the detail goes to a supplement. If no, it is an essential and stays.

The supplement list, in the Design Doc, registers each supplement with:

- its name
- the question it answers
- its location — a path from the project root

The location lets the writer, the implementer, and a reviewer reach each supplement from the Design Doc — the same reason a Data Dictionary entry carries one. When the story closes, the list registers the project's supplements instead, named as such.

References point one way, opposite to the writing order: Business Rules → Data Dictionary → Design Doc.

- A document written earlier is complete without the later ones. When two disagree, the upstream one — nearer the Design Doc in this chain — is right.
- The Data Dictionary never cites Business Rules. A rule names the record it binds; the writer looking for a record's rules searches Business Rules for the record's name.
- The supplement list is the Design Doc's only downstream pointer: it says a supplement exists and never cites its content.
  - The Facts item naming the project's supplements is not such a pointer: it names what the design is designed against, as any fact names its source.

A project may add supplements by the same test — read by the code side rather than the requester. Each is registered in the supplement list and merged the same way.

## Design Doc items

The ten items, in the order they appear as headings in the document. The stage that writes each is in SKILL.md; the indexes fill from the first stage on, and the Boundary's story list is written at close.

| Item | What it answers |
|---|---|
| Purpose | Who gains what, and who is deliberately not served. Nothing else — the means come later |
| Facts | The premises that cannot be moved, summarized with their source (observation record, real data, real code). Marked apart from decisions; a provisional premise is marked as such. Includes what exists ([Designing against what exists](#designing-against-what-exists)) |
| Flow | How the components line up and which records pass between them, seen from the user's side. For an existing system, the whole [affected flow](#terms) |
| Records | Every record the system manages (for an existing system, of the affected flow): its role, where it lives, its lifetime. Includes records written outside this system that it only reads: the walkthrough needs them |
| Keys | Which fields join which records |
| Essentials | For each purpose: purpose → intent → the states records must satisfy, in present tense. The intent is what the requester approves or rejects; the walkthrough runs on these |
| Decisions | Numbered: the adopted option, its reason, the rejected options and their reasons. Kept separate from the essentials — a decision records why, an essential states what holds. Holds no history |
| Walkthrough | One representative case passed through the flow using the essentials alone: the steps, the undecided items and contradictions found, and what they changed |
| Boundary | What this system does not do; the line to neighboring systems; if the work is cut into several stories, which stories and which decisions each implements |
| Indexes | The undecided and provisional indexes ([Two indexes](#two-indexes)), followed by the supplement list ([Three documents](#three-documents)) |

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

An entry has no "identity" item. Identity splits into field definitions, keys, and a rule stating when a record may be reused.

## Business Rules

A business rule is the intent connecting purpose and specification — given this purpose, why this spec. It is the unit the design hands to implementation: tests express it, review checks the code against it, and both cite it by identifier. Both halves are required: a specification without the intent is a copy of the code, and an intent without a specification is a wish.

One rule has four items:

| Item | Form |
|---|---|
| Identifier | Lowercase letters, digits, hyphens; two to four words naming the state the rule establishes or the order it imposes. No chapter numbers, so the identifier survives restructuring |
| Statement | One sentence: "so that <who> can <what>, <this state holds / this order is kept>". The intent is inside the sentence; there is no separate reason line |
| Bound record | The records (or documents) the rule constrains, by their names in the Data Dictionary — or every record, for a general rule |
| Grounds | The purpose it serves, the decision it rests on, and the fact behind it. Never another rule — a rule grounded in a rule leads nowhere. Never an undecided item — it cannot ground anything. In the project's Business Rules, the grounds also name their Design Doc ([Designing against what exists](#designing-against-what-exists)) |

- The statement is written once, in Business Rules. The Design Doc holds the essentials — the same intent at the level the walkthrough needs — and the Data Dictionary points at records, not at rules. A rule restated in two places drifts, and contradictions enter through the drift.
- Rules are grouped by the purpose they serve, in the order the Design Doc lists its purposes, so the reader of a purpose finds its rules together. The project's Business Rules group them by the Design Doc their grounds name, then by its purposes.

## Two indexes

Both live in the Design Doc, because whoever meets a line — requester or implementer — takes a different action on each:

| Index | The implementer's action | Blocks ticketing |
|---|---|---|
| Undecided — implementation does not fill these | Stop and ask | Yes — the requester answers every line before the design is cut into tickets |
| Provisional — observe and correct | Use the value as it stands, knowing where it came from | No |

An undecided line holds:

- the question
- the stage where it arose
- two options, the recommended one, and why
- the requester's words verbatim, while the answer is pending

A decided line leaves the index: the decision goes to the Decisions item, the quote to the commit and the ticket.

A provisional line holds:

- the value — "done by hand" and "no mechanism yet" count as values
- where it was decided
- the observation that will trigger revising it

An item waiting on an observation is provisional, not undecided. The undecided index keeps only questions the requester can answer now, from two options. Whether it is empty is judged after the walkthrough, which surfaces the last items.

## Designing against what exists

A story is designed against what exists: a design that writes only the story's delta hides the steps around the change. Its supplements are merged into the project's supplements before implementation: kept apart, the two sets of rules meet first in implementation, where overlaps and contradictions then surface.

### Terms

- What exists — the project's supplements, the real code, or both; or nothing yet (a new system). Facts always states which, each with its location.
- The project's supplements — defined in [Three documents](#three-documents). A project without them gets them from its first merge, at a location it chooses; later designs name them in Facts.
- Affected flow — the user-side sequence the change belongs to (cart redesign → the purchase flow), not the whole system. Another flow enters only when the story's purpose spans it.
- Marks — unchanged, changed, new, retired, written beside the step, record name, or identifier. An item is marked against what exists for it: its entry or rule in the project's supplements, otherwise the real code.

### What is marked and copied in

| Item | Marked when | The story's documents hold |
|---|---|---|
| Flow steps, records in Records | Anything exists | Every step and record of the affected flow, unchanged ones included |
| Data Dictionary entries | The project's supplements exist | An entry for every record of the affected flow: copied from the project's supplements, or written from the code as facts where they hold none |
| Business Rules | The project's supplements exist | Every project rule bound to a record of the affected flow or to every record, copied with the project's grounds; and the story's own. Never a rule read off the code: it describes the code, it is not a decision |

### Marking conventions

| Case | Convention |
|---|---|
| A new record | A project rule may also bind it; a general rule binds it without naming it. Stage 3 asks which project rules also bind it (SKILL.md). Such a rule is copied in unchanged, or changed when its bound records must name the new one |
| Grounds of a rule | A rule marked new or changed traces to this Design Doc's purposes, decisions, and facts. A rule marked unchanged or retired keeps the project's grounds and sits in one group after the story's purpose groups |
| A retired entry or rule | Stays in the story's supplements, marked, so the implementer knows which code and tests to remove. A retired record absent from the project's supplements is shown only by its mark in Records |
| The Design Doc after close | Keeps its marks: they are its design, not its history |

### The merge

The merge runs before implementation. The requester audits the difference from the project's supplements, by record name and identifier.

| When | The project's supplements | The story's supplements |
|---|---|---|
| At the merge | New added, changed replaced, retired removed, unchanged left. An added or changed rule's grounds name this Design Doc by location. No marks — they state the system as designed | Merged, then kept |
| During implementation | Hold the text; code and tests cite identifiers | Read only — the list of what the story changes. A change reopens the design and is merged again |
| When the story closes | Registered in the supplement list, named as the project's supplements | Deleted; the merge's commit (SKILL.md, Closing step 6) records what changed |

## Present tense only

The Design Doc states the design as it is now. Two kinds of text stay out, each with its own home:

| Kept out | Home | The test |
|---|---|---|
| History — when, from what, and on whose word something changed | The commit message of that change, and the ticket | Does the line say "when / from what / who said"? |
| Story order, dependencies, and work content | The tracker (parent, blocked-by) and the ticket body | Is this what the tracker already carries? |

- Decisions stay — adopted option, reason, rejected alternatives. Without them, the next session proposes a rejected option again.
- Facts stay, marked as facts.
- The trail of how the document got here goes: a reader judging the design in one pass should meet only the design.
