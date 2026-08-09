# Ticket Premise Checklist

Binary premise checks used by the authoring audit pass and the `ticket-review` agent.
Rate each item as **OK / NG / N/A**, judging as the outside reader — someone who knows nothing about the code that prompted the ticket. For each NG, consult the matching section in [guidelines.md](guidelines.md).

These checks detect *code-anchoring* — a ticket whose means have taken charge of its purpose. Prose readability is out of scope here (a general writing concern).

| # | Check item |
|---|-----------|
| T1 | **Discrimination test** — reading only the Subject and the first sentence of Purpose, an outside reader can tell who gains what, and the reviewer can restate that value in one line of their own words |
| T2 | **Purpose anchoring** — the first line of Purpose is anchored to an external phenomenon (user-visible behavior, an upcoming release, a named person's work or rework); internal-convenience framings ("no convention exists", "docs are out of sync", "these disagree") appear only from the second sentence on, subordinated to the value they serve |
| T3 | **Done viewpoint** — the opening statement of Done describes a behavior or state change visible to the user; implementation steps (file, function, test names) appear only as checklist items below it, never as the statement itself |
| T4 | **Decision vocabulary** — every decision left to the human (options under consideration, open questions, notes in the ticket's log) is phrased in the domain's outcome vocabulary; internal names (test names, coefficients, file paths) only appear alongside as parenthetical references, never alone |
| T5 | **Boundary and dependencies** — "related but not done here" items are explicit in Out of scope, and dependencies on other tickets sit in header metadata (`blocked-by` / `related`), not restated in the body |
