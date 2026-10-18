# Coding Guideline

The rules that keep a story's implementation on its purpose and changeable, and the method that builds it from the design's contract. The input — the design when the story has one, the ticket otherwise — is what has been decided toward the purpose: not a specification to transcribe, and not a procedure.

For the author and the reviewer; when each reads which part: SKILL.md.

- [Terms](#terms)
- [Input, output, freedom](#input-output-freedom)
- [Two ways off the purpose](#two-ways-off-the-purpose)
- [Correspondence rules](#correspondence-rules) — keep the purpose
- [From the contract to the code](#from-the-contract-to-the-code) — the method, and the structure rule each question leaves in the code; without a design
- [Comments](#comments)
- [Not here](#not-here)

## Terms

From the design documents, used unchanged:

- record — fields and definitions, writer, location, keys, lifetime (the Data Dictionary entry's items)
- Business Rule — identifier, bound record
- undecided index — the design's open questions; provisional value — a value the design's provisional index lists, used as it stands
- reuse condition — the Business Rule that states when a record may be reused and which fields make two records the same
- a record's invariants — what its field definitions and the Business Rules binding it require of every instance

Of this guideline:

- requester — whoever owns the story and receives its implementation
- author — whoever writes the change: a developer or a Claude session, including an implementer agent (the *writer*, in contrast, is the component that writes a record)
- reviewer — whoever checks the finished change
- rule, alone — a correspondence rule or a structure rule, one per row of their tables
- home — the module that keeps a record; entrance — where the record is read; exit — where its new state is written
- operation — what a Business Rule becomes in code (the operation question of [the method's table](#from-the-contract-to-the-code))
- degradation — completing what can be done and reporting what could not
- finding — a requirement of this guideline broken within what the change touches; gap — one broken outside it

## Input, output, freedom

| | |
|---|---|
| Input, with a design | Design Doc (purpose, flow, essentials, indexes), Data Dictionary (one entry per record), Business Rules (one per identifier, each binding a record) |
| Input, without a design | The ticket's purpose and success criteria. The author makes the decisions the documents would have carried ([Without a design](#without-a-design)) |
| Input that cannot be built from | Stops the work, and the story goes back to the requester: a ticket without success criteria, or with a criterion that names no observable outcome; a design the ticket names but that cannot be found; a design whose undecided index is not empty; a Business Rule that contradicts the purpose it is grounded in, or a criterion that cannot serve the purpose — neither transcribed nor worked around |
| Output | Tests, code, comments; without a design, the written decisions as well |
| Unit of correspondence | One Business Rule or one success criterion ↔ the tests that pin it and the code that realizes it |
| Freedom | The rules say what holds, not how to build. Modules, functions, types, algorithms, and the procedure inside a component are the author's, chosen for the purpose. [The method](#from-the-contract-to-the-code) gives data its shape and state change its place; the granularity is the author's |
| Existing code | A premise, not an input: read for where the records already have homes and what the change touches. Where it disagrees with the input, the purpose as the input states it wins and the code changes. The method shapes what the change creates; existing code the change touches is brought to the method's form only as far as the change's purpose needs, never swept |
| Scope of duty | What the change touches. Outside it, this guideline's requirements are the standard a gap is judged against. Gaps are recorded where the project keeps them, otherwise in the review report or the change's description |

## Two ways off the purpose

| Root | What it looks like | Effect | Kept out by |
|---|---|---|---|
| Wrong source — content taken from the code at hand instead of from what the input decided | A term renamed to an existing identifier; a Business Rule restated in the code's words; a reuse check on the fields the code happens to compare; a fixture shaped by the code's branches | Drifts from the purpose | [Correspondence rules](#correspondence-rules) |
| No structure — no rule for where data and behavior go | A Business Rule enforced in each caller; a record written from several modules; a value derived wherever it is used | Hard to change | The structure rules [the method](#from-the-contract-to-the-code) leaves in the code |

## Correspondence rules

Content and unit of the output come from the input, never from the code at hand. In this table and the method's, the last column is what a reviewer looks for.

| Rule | What holds | Rules out |
|---|---|---|
| Unit from the input | Every Business Rule or success criterion is pinned by tests. Every behavior the change adds — an effect the user or another component can observe — answers to one; a behavior the author cannot trace to one is a question for the requester: drop it, or add the statement. Code structure that serves a behavior needs no statement of its own | A behavior nothing asked for; a criterion nothing pins |
| Terms from the input | Identifiers, output labels, and test names use the input's words; the code coins no synonym | A term renamed to fit an existing identifier |
| Business Rules cited, not restated | A Business Rule's text lives in Business Rules; code and tests cite the identifier. Without a design, the pinning test states the criterion once and the code states it nowhere | One Business Rule written in several places |
| Identity as the input defines it | Matching or reusing a record compares every field the reuse condition names | A record reused on a partial match |
| Test premises from the record's definition | A fixture satisfies the record's invariants; branches are not bent to fit a fixture | A test passing on a state production never holds |

## From the contract to the code

The Data Dictionary is the contract: from it the author shapes the data and the interfaces between homes, and a Business Rule becomes an operation that transforms records under that contract. The method behind this is Data-Oriented Programming as Inside Java states it — "Data-Oriented Programming in Java — Version 1.1" (2024, https://inside.java/2024/05/23/dop-v1-1-introduction/) — stated here in language-neutral terms, with per-language forms left to the host project. Its four principles, verbatim:

- model data immutably and transparently
- model the data, the whole data, and nothing but the data
- make illegal states unrepresentable
- separate operations from data

The author answers the questions below in order, each from the input element named. What the author settles is the answer taken from that element; what holds is the structure rule the answer leaves in the code — the invariant the reviewer judges by, whatever means reached it.

The home question is answered before anything is written, by searching the code by name and by location (a renamed term misses by name) and counting the hits. One home: write there. None: create one. Several, or one whose home breaks a structure rule below (several writers, a Business Rule in callers): the change writes through one exit — the one that exists or the one it creates — and consolidates only what it touches (Existing code).

| Question, from | What the author settles | What holds (structure rule) | Rules out |
|---|---|---|---|
| Where is the home? — from the entry's writer, location, and lifetime, for each record and Business Rule the input names | The module that keeps the record and the exit that writes it, from the search above | One truth, one point of change — a record has one home, the writer's module, which alone produces, creates, and deletes it at its location; the state changes at the exit only; readers use the entrance, never the home's files or structure | A record written from outside its home; a second home beside the one that exists |
| What is the record? — from the entry's fields and definitions | An immutable record type with the entry's name and fields: readable by anyone, changed by no one, a new state a new value. An existing machine-readable schema is referenced, not copied | One derivation — the type carries what the entry defines and no cached derivation; a value is derived in one place, and a function returns what its callers need rather than callers re-deriving it | The same value derived twice; a derivation stored as a field |
| What is the operation? — from each Business Rule and the invariants it puts on its bound record | A pure function that takes the record and returns its new state; a caller states only its own need | Business Rule beside its mechanism — the Business Rule is enforced at the bound record's home, where the state it binds changes, or by the type where the language can express it (a closed set of alternatives with exhaustive branching, a field that cannot be absent); and in positive form: the operation says what it keeps or accepts, never what it excludes | A Business Rule enforced by each caller; a cleanup defined by what to delete |
| Where does the record cross? — from the Design Doc flow | Where the flow crosses a component boundary, the record crosses as a value; a home is referred to by the record's keys, never by its internal references. On the flow, the checks that can reject the record sit before the exit, where the one side effect — the write — happens | Check, then write — every check that can reject a record runs before it is written; one write is one whole record; what runs after the write is degradation, never a reason to unwind | A record persisted and then rejected, leaving an orphan |
| What happens when a record is rejected? — from the flow: which records come from the user, which from inside the system | The origin of each failure, from where the record came from | Failure judged by origin — a failure is handled by its origin alone, the same at every site: user-caused surfaces as an error, internal degrades. A record in a state the Business Rules do not admit is internal: reported, never silently rebuilt | Failure handling chosen per site; a record silently rebuilt |

A provisional value is used as it stands; its origin is written where [Comments](#comments) says.

### Without a design

The author designs for the purpose at the depth the story needs, and writes the decisions down where the reviewer reads them — the story's ticket where the project tracks stories, otherwise the change's description. The reviewer needs to find there what the questions above take from the documents:

- the records, with their fields, keys, invariants, and reuse condition, and for each its writer, location, lifetime, and origin (from the user, or from inside the system)
- the operations, which of them write at an exit, and where a record crosses between components

Correspondence then runs on the success criteria, and the questions above on these records. Decisions the reviewer cannot find there are a finding under this section.

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
| When review fires, who receives its report, and when a gap outside the change is fixed | The project's development-cycle skill |
