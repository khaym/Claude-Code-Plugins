# Coding Guideline

The rules that keep a story's implementation on its purpose and changeable, and the default method for building it; the means stay the author's. The input — the design when the story has one, the ticket otherwise — is what has been decided toward the purpose, not a specification to transcribe.

For the author and the reviewer. Who they are, and when each reads which part: SKILL.md.

- [Input, output, freedom](#input-output-freedom) — including the terms
- [Two ways off the purpose](#two-ways-off-the-purpose)
- [Correspondence rules](#correspondence-rules) — keep the purpose
- [Structure rules](#structure-rules) — keep changeability
- [Find the home first](#find-the-home-first) — the one required step
- [The method](#the-method) — Data-Oriented Programming; input element in the code; without a design
- [Comments](#comments)
- [Not here](#not-here)

## Input, output, freedom

| | |
|---|---|
| Input, with a design | Design Doc (purpose, flow, essentials), Data Dictionary (one entry per record), Business Rules (one per identifier, each binding a record) |
| Input, without a design | The ticket's purpose and success criteria. The author makes the decisions the documents would have carried ([Without a design](#without-a-design)) |
| Output | Tests, code, comments; without a design, the written decisions as well |
| Unit of correspondence | One Business Rule or one success criterion ↔ the tests that pin it and the code that realizes it |
| Freedom | The rules say what holds, not how to build. Modules, functions, types, and algorithms are the author's, chosen for the purpose. The shape of data and the placement of state change follow [the method](#the-method) by default; an author who departs from it still meets the structure rules, and the reviewer judges by the rules, not by the method |
| Input against the purpose | A Business Rule that contradicts the purpose it is grounded in, or a criterion that cannot serve the purpose, goes back to the requester. It is neither transcribed nor worked around |
| Existing code | A premise, not an input: read for where the records already have homes and what the change touches. Where it disagrees with the input, the purpose as the input states it wins and the code changes |
| Scope of duty | What the change touches. Outside it, the rules are the standard a gap is judged against. Such a gap is an observation: recorded where the project keeps them, otherwise in the review report or the change's description. The development cycle decides when it is fixed |

Terms from the design documents, used unchanged:

- record — fields and definitions, writer, location, keys, lifetime (the Data Dictionary entry's items)
- Business Rule — identifier, bound record
- undecided index — the design's open questions; provisional value — a value used as it stands until an observation revises it
- reuse condition — the Business Rule that states when a record may be reused and which fields make two records the same
- a record's invariants — what its field definitions and the Business Rules binding it require of every instance

Terms of this guideline:

- requester — whoever owns the story and receives its implementation
- author — the person or session writing the code (the *writer*, in contrast, is the component that writes a record)
- rule, alone — one of this guideline's rules
- home — the one module that keeps a record; entrance — where the record is read; exit — where a new state is written. The exit is the only side effect on the record: reading at the entrance is not one, and the state changes nowhere else

## Two ways off the purpose

| Root | What it looks like | Effect | Kept out by |
|---|---|---|---|
| Wrong source — content taken from the code at hand instead of from what the input decided | A term renamed to an existing identifier; a Business Rule restated in the code's words; a reuse check on the fields the code happens to compare; a fixture shaped by the code's branches | Drifts from the purpose | [Correspondence rules](#correspondence-rules) |
| No structure — no rule for where data and behavior go | A Business Rule enforced in each caller; a record written from several modules; a value derived wherever it is used | Hard to change | [Structure rules](#structure-rules), built by [the method](#the-method) |

## Correspondence rules

Content and unit of the output come from the input. The last column is what a reviewer looks for.

| Rule | What holds | Rules out |
|---|---|---|
| Unit from the input | Every Business Rule or success criterion is pinned by tests. Every behavior the change adds — an effect the user or another component can observe — answers to one; a behavior the author cannot trace to one is a question for the requester: drop it, or add the statement. Code structure that serves a behavior needs no statement of its own | A behavior nothing asked for; a criterion nothing pins |
| Terms from the input | Identifiers, output labels, and test names use the input's words; the code coins no synonym | A term renamed to fit an existing identifier |
| Business Rules cited, not restated | A Business Rule's text lives in Business Rules; code and tests cite the identifier. Without a design, the pinning test states the criterion once and the code states it nowhere | One Business Rule written in several places |
| Identity as the input defines it | Matching or reusing a record compares every field the reuse condition names | A record reused on a partial match |
| Test premises from the record's definition | A fixture satisfies the record's invariants; branches are not bent to fit a fixture | A test passing on a state production never holds |

## Structure rules

Invariants that keep one change one change. They hold whatever method reached them.

| Rule | What holds | Rules out |
|---|---|---|
| One truth, one point of change | A record has one home; its state changes at the exit only; readers use the entrance and never reach into the home's files or structure | A record written from outside its home |
| One derivation | One question is answered in one place; a function returns what its callers need rather than callers re-deriving it | The same value derived twice |
| Business Rule beside its mechanism | A Business Rule is enforced where the state it binds changes — the home's operation — or expressed in the type; a caller states only its own need | A Business Rule enforced by each caller |
| Failure judged by origin | User-caused: surfaced as an error. Internal: absorbed as degradation (complete what can be done, report what could not). Judged by origin alone, the same at every site; a record in a state the Business Rules do not admit is reported, never silently rebuilt | Failure handling chosen per site |
| Check, then write | Every path that can reject a record runs before the record is written; what runs after the write is degradation, never a reason to unwind; one write is one whole record | A record persisted and then rejected, leaving an orphan |
| Business Rules in positive form | A Business Rule in code says what its operation acts on — what it keeps, what it accepts — never a list of what it excludes | A cleanup defined by what to delete |

## Find the home first

The one required step before writing. For each record and Business Rule the input names, search the code and count the hits, by name and by location (a renamed term misses by name). One home: write there. None: create one. Several: consolidate what the change touches; the rest is a gap outside the change.

## The method

Data-Oriented Programming as Inside Java states it — "Data-Oriented Programming in Java — Version 1.1" (2024, https://inside.java/2024/05/23/dop-v1-1-introduction/) — in language-neutral terms; per-language forms are the host project's. It is the default way to give data its shape and state change its place; it does not design modules or algorithms.

| Principle (verbatim) | Here | Rule it keeps |
|---|---|---|
| Model data immutably and transparently | A record is an immutable record type: named fields, readable by anyone, changed by no one; a new state is a new value | One truth, one point of change |
| Model the data, the whole data, and nothing but the data | The type carries what the input defines for the record and no cached derivation | One derivation |
| Make illegal states unrepresentable | What a Business Rule requires of a state goes into the type where the language can express it — a closed set of alternatives with exhaustive branching, a field that cannot be absent | Business Rule beside its mechanism; test premises from the record's definition |
| Separate operations from data | Operations are pure functions from records to records; side effects sit at the home's exit | Business Rule beside its mechanism; check, then write |

### Input element in the code

What still holds in the code for each element of the input, however the author shapes the modules and types.

| Input element | Holds in the code |
|---|---|
| Record | Its name and fields are the input's; an existing machine-readable schema is referenced, not copied |
| Writer | Only the writer's module produces its new states; that module is the home |
| Location | Only the home builds the path |
| Keys | What crosses homes is the keys, not the home's internal references |
| Lifetime | Creation and deletion live in the home |
| Business Rule | Placed as [Structure rules](#structure-rules) say |
| Design Doc flow | Where the flow crosses a component boundary, a record crosses a home |
| Provisional value | Used as it stands, marked at its one place with where it came from |

### Without a design

The author designs for the purpose at the depth the story needs, and writes the decisions down where the reviewer reads them — the story's ticket where the project tracks stories, otherwise the change's description. The reviewer needs to find there:

- the records, with their fields, invariants, and reuse condition
- the operations, and which of them have side effects

Correspondence then runs on the success criteria, and the structure rules on these records.

## Comments

A comment carries what only the author or the ticket knows — intent a reader of the committed code, tests, and design documents cannot reconstruct. Three kinds recur:

- the rejected alternative and why
- a constraint from an external fact the input omits
- why code that looks unnecessary stays

Other intent is written when it is otherwise unreadable. Intent that lives only in the ticket is always written, because a ticket is not committed.

Two references also live in comments: the Business Rule identifier at the check that enforces it, and the origin of a provisional value.

One intent, one place — on the parameter, function, or type it is about, never restated. A comment never restates the code: a function's inputs and outputs are read from the function, in any language, docstrings included.

## Not here

| Not in this guideline | Where it lives |
|---|---|
| Language-specific style | The project's formatter and linter |
| Test-design techniques | The project's test-design skill (designing-test-cases where installed) |
| The definition of a business rule and its text | The design skill (design-doc-authoring) and the story's Business Rules |
| When review fires, what it reports and to whom, and when a gap outside the change is fixed | The project's development-cycle skill. This file gives the rules; SKILL.md gives the pass that applies them |
