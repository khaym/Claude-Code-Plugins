# Ticket Authoring Guidelines

Structure rules that keep a ticket's purpose in charge of its means: when code vocabulary takes the subject position, what to build, whose value it serves, and why drop out — the means becomes the end. Writing the ticket as a user story anchors it to value the code cannot invalidate.

Throughout these rules, the **outside reader** — someone who knows nothing about the code that prompted the ticket — is the detection instrument: if they can restate who gains what, the ticket is anchored to value, not code.

- [The unit: one ticket = one user story](#the-unit-one-ticket--one-user-story)
- [Value anchor](#value-anchor)
- [Subject](#subject)
- [Header metadata](#header-metadata)
- [Details layout](#details-layout)
- [Filing principles](#filing-principles)

## The unit: one ticket = one user story

One ticket = one capability a user gains. Apply the **discrimination test**: can the outside reader tell who gains what? If not, the ticket is cut wrong.

- Implementation steps have no standalone value — fold them into the Done checklist instead of filing them as tickets.
- Split out a child ticket only when a step has grown enough to need its own PR and review. The child points to its parent via `related` metadata and inherits the parent's purpose — do not restate it.

## Value anchor

Who "the user" is comes from the project's purpose statement (typically a purpose section in the repository's CLAUDE.md or README). Anchor every purpose to a phenomenon outside the codebase: behavior the user sees, an upcoming release, the work or rework of a named person.

Internal states — a missing convention, docs out of sync, an inconsistency — are never the purpose. They may support the purpose from the second sentence on, subordinated to the value they serve.

## Subject

One line in outcome vocabulary: name what the user can do or see afterwards, not the mechanism that makes it so.

## Header metadata

Relations between tickets live in tracker metadata, not the body: `blocked-by` for prerequisites, `related` for non-dependency references and child→parent links. Do not restate them in prose — a relation written twice drifts.

## Details layout

In this order:

1. **Purpose (Why)** — who, in what situation, gains what value. 1–3 lines, anchored per [Value anchor](#value-anchor).
2. **Done** — open with the change visible to the user, then list implementation steps as `- [ ]` items. Child tickets appear as `- [ ] #N ...`.
3. **Out of scope** — related things this ticket will not do; point follow-up work at its ticket ID.

Optional sections, in this order and only when the condition holds:

- **Options under consideration** — when the ticket must settle an approach choice.
- **Background** — when prior discussion or design context is needed to judge the ticket.

## Filing principles

- Cut tickets by value, not by what happens to be implementable next.
- Make dependencies explicit in `blocked-by` metadata.
- A defect against the current ticket's done criteria is fixed inside that ticket — fold it into the Done checklist. File a new ticket only when the fix changes the design or the promise itself.
- When the purpose, done criteria, or scope boundary is unclear, ask the ticket's requester — never fill the gap yourself.
- A proposal that cannot state its user value (hygiene or internal tidying only): default to not filing — record it in the project's development log instead.
