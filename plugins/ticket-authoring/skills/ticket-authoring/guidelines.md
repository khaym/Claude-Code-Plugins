# Ticket Authoring Guidelines

Structure rules that keep a ticket's purpose in charge of its means: when code vocabulary takes the subject position, what to build, whose value it serves, and why drop out — the means becomes the end. Writing the ticket as a user story anchors it to value the code cannot invalidate.

Throughout these rules, the **outside reader** — someone who knows nothing about the code that prompted the ticket — is the detection instrument: if they can restate who gains what, the ticket is anchored to value, not code.

- [The unit: one ticket = one user story](#the-unit-one-ticket--one-user-story)
- [Value anchor](#value-anchor)
- [Subject](#subject)
- [Done](#done)
- [What the tracker carries](#what-the-tracker-carries)
- [Details layout](#details-layout)
- [Filing principles](#filing-principles)

## The unit: one ticket = one user story

One ticket = one capability a user gains. Apply the **discrimination test**: can the outside reader tell who gains what? If not, the ticket is cut wrong.

- Implementation steps are never tickets: they have no standalone value, and Done carries the success criteria they serve.
- Split out a child ticket only when the work behind one criterion has grown enough to need its own PR and review. The child points to its parent via `related` metadata and inherits the parent's purpose — do not restate it.

## Value anchor

Who "the user" is comes from the project's purpose statement (typically a purpose section in the repository's CLAUDE.md or README). Anchor every purpose to a phenomenon outside the codebase: behavior the user sees, an upcoming release, the work or rework of a named person.

Internal states — a missing convention, docs out of sync, an inconsistency — are never the purpose. They may support the purpose from the second sentence on, subordinated to the value they serve.

## Subject

One line in outcome vocabulary: name what the user can do or see afterwards, not the mechanism that makes it so.

## Done

One prose sentence stating the change visible to the user, then `- [ ]` items — each a **success criterion**: a verifiable end-state the implementation must reach, written in the outcome's vocabulary and independent of the others, so that no item is a stage toward another. The criteria are the states that prove that sentence.

Implementation steps are not listed here. An ordering constraint the implementer cannot derive from the criteria is a premise — put it in Background.

Child tickets appear as `- [ ] #N ...`, the end-state being "#N is closed".

## What the tracker carries

Relations between tickets live in header metadata, not the body: `blocked-by` for prerequisites, `related` for non-dependency references and child→parent links. Do not restate them in prose — a relation written twice drifts.

The reader is carried the same way: the status says who is reading — the implementer, or the owner deciding among Options — so the body declares no reader, and the writing skill's reader- and role-declaration checks are not judged for tickets.

Revision history goes to the ticket log — the tracker's appended lines — for the same reason: withdrawn options, who found what, what was demoted belong there, never in the body. A rejected alternative's reason is not history: history records that the change happened, while the reason bears on the choice that now stands, so it stays with that decision.

## Details layout

In this order; a section not marked optional is always present, an optional one only when its condition holds. Two constraints fix Background's and Evidence's slots: premises go above what depends on them, so Background precedes Done; records go below the claim they serve, so Evidence comes last.

1. **Purpose (Why)** — who, in what situation, gains what value. 1–3 lines, anchored per [Value anchor](#value-anchor).
2. **Background** — optional: the premises Done depends on (facts, constraints, prior decisions the plan assumes).
3. **Done** — the outcome sentence and its success criteria, per [Done](#done).
4. **Out of scope** — related things this ticket will not do; point follow-up work at its ticket ID.
5. **Options under consideration** — optional: when the ticket must settle an approach choice.
6. **Evidence** — optional: observations, command output, and measurements that back claims made above.

## Filing principles

- Cut tickets by value, not by what happens to be implementable next.
- Make dependencies explicit in `blocked-by` metadata.
- A defect against the current ticket's success criteria is fixed inside that ticket — add or sharpen a criterion in Done. File a new ticket only when the fix changes the design or the promise itself.
- When the purpose, success criteria, or scope boundary is unclear, ask the ticket's requester — never fill the gap yourself.
- A proposal that cannot state its user value (hygiene or internal tidying only): default to not filing — record it in the project's development log instead.
