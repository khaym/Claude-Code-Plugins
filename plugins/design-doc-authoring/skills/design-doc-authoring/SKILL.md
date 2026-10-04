---
name: design-doc-authoring
description: Guides writing the three design documents — Design Doc, Data Dictionary, Business Rules — from the purpose down to decided rules, one judged stage at a time, so the goal is settled in prose before implementation starts. Use when you hear "write a design doc", "design this story", "Data Dictionary", "Business Rules", "where does this statement go", or "設計書を書きたい". For read-only conformance audits of a written design, the design-doc-review agent is preferred.
---

# Design Doc Authoring

Write the design as three documents — Design Doc, Data Dictionary, Business Rules — one judged stage at a time, so the requester settles the goal in prose and the implementation receives only decided rules. This file is the procedure for the writer — a developer or a Claude session — working with the requester who owns the goal.

Read [guidelines.md](guidelines.md) for the thinking and the shapes — why a vague goal otherwise gets filled in from the code, and what the documents do about it:

- why design before code, and the four ideas the documents follow from
- the one question that sorts every statement — flow, rule, or procedure
- the three documents, their items, and which way references point
- what a business rule is and the form one takes
- the two indexes — undecided and provisional
- what never enters the Design Doc

[checklist.md](checklist.md) holds the binary checks (S/D/DD/BR), one per rule in guidelines.md — each a way a design can leave its implementer guessing. The `design-doc-review` Custom SubAgent scores them in an isolated context — a reader who knows only the documents — and returns a read-only findings report; it preloads this skill via the `skills:` field, so the criteria are shared. See the [audit pass](#audit-pass).

## Intent detection

| Intent | Example triggers | Action |
|---|---|---|
| Write or continue a design | "write a design doc", "design this story", "next stage" | Run the [writing flow](#writing-flow) from the first stage not yet judged |
| Sort one statement | "where does this go", "is this a rule or a procedure" | Answer with the one question in [guidelines.md](guidelines.md): flow, rule, or procedure, and the home each has |
| Shape lookup | "what goes in the Data Dictionary", "how is a business rule written" | Answer from [guidelines.md](guidelines.md) |
| Audit a design | "review this design doc", "design doc conformance check", "設計書をレビューしてほしい" | Run the [audit pass](#audit-pass) |

## Writing flow

The input is a story ticket with a purpose and a provisional Done. The output is a Design Doc whose undecided index is empty, with its two supplements and their locations registered in its supplement list. A ticket is ready for design when its purpose names who gains what; otherwise send it back to the requester (through the installed filing skill when one is installed) before stage 1.

Before drafting:

1. Load the installed writing skill (e.g. `docs-authoring`). Its writing model shapes the prose while drafting; applied afterwards it only patches. Skip only when no writing skill is installed.
2. Observe before writing. Facts come from the real thing — real data, real code, existing records of observation — and are put down with their source. A fact recalled rather than observed is a hypothesis and is marked as one.

Then write the six stages in order. Each stage ends with the requester's judgment; the next stage does not open before it.

| Stage | The question it answers | Written in | Raise as undecided when |
|---|---|---|---|
| 1 Purpose | Who gains what, and who is deliberately not served? What premises cannot be moved? | Design Doc: Purpose, Facts | The purpose cannot name who gains, or a premise is only assumed |
| 2 Flow | Seen from the user's side, how do the components line up and what passes between them? Where is the line to neighboring systems? | Design Doc: Flow, Boundary (what this system does not do, the line to its neighbors) | Two orderings of the components serve the purpose equally |
| 3 Records | What records pass between components, what keys join them, what is each one's lifetime? | Design Doc: Records, Keys; one Data Dictionary entry per record | A record's writer, location, or lifetime cannot be derived from the purpose |
| 4 Rules | For each purpose, what state must each record satisfy, what order must the system keep? | Design Doc: Essentials (purpose → intent → states); Business Rules (full text, one identifier each) | A rule's intent cannot be traced to a purpose, or two candidate rules serve it equally |
| 5 Decisions | For each undecided item raised so far, which two options are there, which is recommended, and why? Which items are waiting on an observation? | Design Doc: Indexes (each undecided line completed with its options; observation-waiting items moved to provisional); Decisions (adopted, reason, rejected) for what the requester settles here | — |
| 6 Walkthrough | Does one representative case pass through the flow on the Design Doc alone? | Design Doc: Walkthrough | A step needs a supplement to proceed (an essential is missing), or two essentials fight |

The undecided index exists from stage 1: each item is added at the stage where it appears, with that stage noted. Stage 5 completes the lines with options and a recommendation. An item raised in stage 6 gets its options the same way, as part of closing.

Within stage 3, decide in this order: which records exist and what role each plays, then the keys that join them, then each record's fields. Within stage 4, write the essentials in the Design Doc first and the full rules second; a rule with no essential behind it is a signal that the Design Doc is missing one.

At every stage:

- Sort each statement with the one question before writing it. Procedure is not written.
- Mark anything the purpose cannot settle at the stage where it appears, and add it to the undecided index with the stage noted. Do not fill it in.
- Keep facts, decisions, and the requester's pending words visibly apart (facts marked as facts; decisions as adopted / reason / rejected; pending judgments verbatim).
- Present the stage to the requester as its answer to the stage's question, not as the text that was written. The requester approves or rejects that answer.
- When the requester rejects, revise and present the same stage again. When the revision changes an earlier stage's answer, that answer goes back to the undecided index and its stage is presented again before continuing.

## Closing the design

1. Give each undecided item raised in the walkthrough its two options and a recommendation, put them to the requester, and record what the requester settles in Decisions (adopted, reason, rejected), as stage 5 does. Move items waiting on an observation to the provisional index with the value in use and the observation that will revise it.
2. Judge whether the undecided index is empty. An item still open sends the writer back to the stage it is marked with; repeat the walkthrough once the item is decided.
3. With the undecided index empty, add to the Design Doc's Boundary which stories the work is cut into and which decisions each implements, then cut the tickets with the installed filing skill (e.g. `ticket-authoring`). Order, dependencies, and work content go to the tracker and the ticket bodies. When no filing skill is installed, hand the Boundary's story list to the requester as the cut and say that the filing checks could not run.
4. Move verbatim judgments that became decisions out of the Design Doc into the commit message and the story ticket, leaving the decision and its reason.

## Audit pass

The `design-doc-review` agent (when installed via plugin, subagent type `design-doc-authoring:design-doc-review:design-doc-review`) reads the design as its implementer would: can the purpose and the intent behind each rule be understood, and the means chosen, without guessing? Its findings cite checklist.md. Contradictions in content are the walkthrough's to find. Its checks judge a design that has reached its close; on an earlier draft, expect the checks for the walkthrough and the undecided lines to fail.

1. **Invoke the agent** with one Design Doc path. It finds the supplements through the Design Doc's supplement list, so register their locations there first.
2. **Read the findings report.** Each NG cites a check ID and a direction; each N/A carries its reason. If the agent reports it could not read the Design Doc or its criteria, fix that and re-run — do not act on a partial audit.
3. **Apply the smallest edit that turns each NG into OK.** A fix that changes a stage's answer goes back to the requester as that stage does in the writing flow.
4. **Re-run after substantial rewrites**; a wording tweak does not need a second pass.

## Notes

- This skill owns what the three documents say and where each statement goes. Prose readability belongs to the writing skill; cutting and filing tickets belongs to the filing skill.
- The code-side handling of business rules — tests that pin a rule's behavior, which comments are worth writing — belongs to the project's development-cycle skill where one is installed. This skill defines what a business rule is and the form one takes.
- Writing runs in the main session with the requester; observation (Before drafting, step 2) may be delegated to a subagent when its scope folds into one prompt.
