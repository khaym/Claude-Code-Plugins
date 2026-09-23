# Ticket Premise Checklist

Binary premise checks used by the authoring audit pass and the `ticket-review` agent.
Rate each item as **OK / NG / N/A**, judging as the outside reader — someone who knows nothing about the code that prompted the ticket. For each NG, consult the matching section in [guidelines.md](guidelines.md).

These checks detect *code-anchoring* — a ticket whose means have taken charge of its purpose. Prose readability is not judged here (a general writing concern).

For a ticket with a `parent`, read the parent ticket too. Score T1 and T2 on the parent, in their own rows; when the parent cannot be obtained, rate both N/A with the reason "parent unavailable" rather than scoring the child alone. The child's own trace to the parent sits in T3.

| # | Check item |
|---|-----------|
| T1 | **Discrimination test** — reading only the Subject and the first sentence of Purpose, an outside reader can tell who gains what, and the reviewer can restate that value in one line of their own words |
| T2 | **Purpose anchoring** — the first line of Purpose is anchored to an external phenomenon (user-visible behavior, an upcoming release, a named person's work or rework); internal-convenience framings ("no convention exists", "docs are out of sync", "these disagree") appear only from the second sentence on, subordinated to the value they serve |
| T3 | **Done shape, viewpoint and parent trace** — Done opens with one prose sentence describing a behavior or state change visible to the user; each `- [ ]` item below it is a success criterion — a verifiable end-state in the outcome's vocabulary, independent of the other items and not a restatement of the opening sentence; implementation details (file, function, test names) appear only as parenthetical references, never as items; for a ticket with a `parent`, Subject names the child's own outcome, Purpose identifies which parent criterion it closes, and Done stays within that criterion |
| T4 | **Decision vocabulary** — every decision left to the human (options under consideration, open questions, notes in the ticket log) is phrased in the domain's outcome vocabulary; internal names (test names, coefficients, file paths) only appear alongside as parenthetical references, never alone |
| T5 | **Boundary and relations** — "related but not done here" items are explicit in Out of scope, and relations to other tickets sit in header metadata (`blocked-by` for prerequisites, `parent` for the one ticket a child belongs to, `related` for references that are neither), not restated in the body |
