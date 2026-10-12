---
name: dev-cycle
description: Carries the development skeleton - the quality layers (Swiss Cheese) and the six-stage development cycle from filing to close, including when a story gets a design before implementation and where the code-side discipline is read. Invoke BEFORE starting any work that changes code in a project wired to this plugin, and when filing a ticket or shaping a plan. Use when you hear "dev cycle", "development cycle", "how do we develop here", "開発サイクル", or at the start of any coding task.
---

# Development Cycle (dev-cycle)

- [Host bindings](#host-bindings)
- [Quality layers (Swiss Cheese)](#quality-layers-swiss-cheese)
- [The development cycle (1 user story = 1 lap)](#the-development-cycle-1-user-story--1-lap)
  - [Who runs which stage](#who-runs-which-stage)
  - [Lap log (every lap, lightweight)](#lap-log-every-lap-lightweight)
- [What this skill never owns](#what-this-skill-never-owns)

The method for carrying one user story from filing to close. It is the
antibody against code-anchored development, where solutions, plans, and
explanations start from the code alone. Any session runs it, dialog-driven
or autonomous. Invoked after implementation has started, it can no longer
fire the gates of stages 2–3. Rationale lives in [design.md](design.md).

## Host bindings

The frame below is invariant; these project-bound inputs come from the host:

| Binding | What the host declares | Home |
|---|---|---|
| Immovable facts | The external realities that cannot be negotiated (data formats, API output, real rendering behavior) — stage 2 observes these | Host CLAUDE.md |
| Domain quality nets | Project-specific automated layers (snapshot regressions, invariant suites) | Host CLAUDE.md, or the project's `verify` skill where the gnome loop is wired (its contract lives in the gnome-loop skill) |
| Story-list source of truth | Where user stories live and how they are referenced by ID | Host CLAUDE.md task-registration rules |
| Development log | The file that receives proposals that cannot state user value | Host CLAUDE.md |
| Lap log | The file that receives each lap's observations, classified per stage 6 below — a separate file from the development log | Host CLAUDE.md, or the loop config's `paths.lap_log` where the gnome loop is wired |
| Toolchain | Tracker / writing / filing / design / coding / review stack. Defaults: task-tracker, docs-authoring, ticket-authoring (with ticket-review), design-doc-authoring (with design-doc-review), coding-guideline, code-review | Host CLAUDE.md |

When a binding or a named sibling tool is missing at the moment its gate
should fire, surface the gap to the user and name the gate that cannot
fire, rather than proceeding as if it had fired. (Wiring a host — the
trigger line and its wording — is this plugin's onboarding skill.)

## Quality layers (Swiss Cheese)

When each layer fires is the stage table's last column.

| Layer | What it judges | Home |
|---|---|---|
| Automated nets — linter, hooks, unit tests, E2E tests, the host's domain nets | What a machine can check | Host |
| docs-authoring | One-pass readability, applied while writing (skip conditions live in the skill) | docs-authoring plugin |
| ticket-review | Premise validity — a user-anchored purpose, outcome vocabulary for decisions — read with no project knowledge, in an isolated context | ticket-authoring plugin |
| docs-review | One-pass readability, read in an isolated context | docs-authoring plugin |
| design-doc-review | Whether the design lets its implementer understand the purpose and the intent behind each rule without guessing | design-doc-authoring plugin |
| coding-guideline | Whether tests, code, and comments are built from what the design or the ticket decided and stay changeable | coding-guideline plugin |
| code-review | The diff against the success criteria first, then correctness; style is optional | Toolchain binding (default: Claude Code's built-in skill) |
| Human Audit | Whether the user confirms the outcome | Host CLAUDE.md |

The `[shift-left]` tag in the stage table marks the gates that catch what
would otherwise reach code-review.

## The development cycle (1 user story = 1 lap)

Each stage is productive work closed by a gate, the question answered
before the next stage opens.

A gate may be skipped or shortened when the task is trivial, with one
exception: stage 2 is never skipped. When a shortened gate repeatedly lets
requirement-level findings reach code-review, it is being shortened too
often.

| Stage | Work | Gate | Layers fired |
|---|---|---|---|
| 1 File | The story filed; a design recommended when the success criteria name a data contract, and agreed or declined | Does the value reach a reader with no project knowledge? | docs-authoring, ticket-review, docs-review |
| 2 Observe facts [shift-left] | The external reality observed first, then the code as it is | Does the search for means start from observed facts, the code counted among them — not from the code alone, as remembered? | — |
| 3 Plan shape [shift-left] | The success criteria dropped into a checklist on the ticket; with an agreed design, the design written first and the criteria finalized at the design child's closing | On the observed facts, do the steps — cut by value, not by means — serve the purpose? | design-doc-review before the design child closes |
| 4 TDD implementation | The change written through the author's pass, tests before code | Did the author's pass finish without a stop (its halt on a defective input), with the automated nets green and none weakened? | coding-guideline (author's pass), automated nets |
| 5 code-review | The diff reviewed | Did the reviewer's pass finish without a stop, with the findings applied and reported? | code-review; coding-guideline (reviewer's pass, run by the session that runs code-review); automated nets; docs-review in place of code-review on a docs- or ticket-only change |
| 6 Confirm & close | The lap log written; the outcome summarized for the user | Has the user confirmed? | Human Audit |

1. File — load docs-authoring and ticket-authoring before drafting.
   Register the story in the tracker and confirm with the user:
   - its purpose
   - its success criteria
   - its out-of-scope

   The design recommendation fires when the success criteria, or a
   document they cite, state a data contract — any of:
   - what a record holds
   - where it lives and the keys that name it
   - how long it lives

   When the user agrees to a design, open a child ticket of the story,
   the design child, to hold it. The story's success criteria stay
   provisional until the design child closes at stage 3.
2. Observe facts — before choosing means, observe with the real thing
   and put the result in shared form. The external reality is the host's
   immovable facts. The code as it is means the scope of the change: what
   will be touched and what depends on it, counted (a grep, a listing)
   rather than recalled. Repeat whenever a later stage writes a new claim
   about that scope — a delegation prompt, a rework instruction, a
   report.
3. Plan shape — plan depth is proportional to uncertainty, on one
   scale:
   - the approach fits in one sentence of the requirements (a single
     file, known code): agree on the goal and implement
   - it needs more (multiple files, unfamiliar code): harden the
     checklist with the user before implementing
   - the approach needs the design agreed at stage 1 (a data contract):
     write it with design-doc-authoring from stage 2's facts, under the
     design child

   The design child closes after the design's close (its undecided index
   empty) and the design child's design-doc-review audit. The success
   criteria are final when it closes. When the design's close cuts the
   implementation into child tickets of the story, each child runs the
   cycle from its own stage 3 with its own checklist; otherwise the story
   carries the checklist itself (whether a parent ticket can enter the
   gnome loop is the gnome-loop skill's rule).
4. TDD implementation — a stop in the author's pass returns the story
   to the stage that settled the defective input: stage 1 for the ticket,
   stage 3 for the design.
5. code-review — fires without being asked once the change is
   complete. A stop in the reviewer's pass returns the story as a stop in
   stage 4 does.
   A gap outside the change, found by either pass, is not fixed in this
   lap: file it as a ticket when it can state user value, otherwise record
   it in the development log.
6. Confirm & close — the lap log's format and classes are below.

### Who runs which stage

Requirements alignment (1), planning (3), and review (5) stay in the main
conversation. Work whose goal and context fold into a single delegation
prompt (e.g. stage 2 observation, research, mechanical work) may be
delegated to a cheaper-model subagent (general-purpose). Stage 4 of a
ticket past stage 3 delegates to this plugin's bundled `implementer`
agent, whose definition owns the delegation contract — what the prompt
must carry; the method and the guideline are not among it, the agent
preloads them.

### Lap log (every lap, lightweight)

An observation is one review finding or one piece of implementation
rework — the implementer's self-reported rework, or the session's own when
it implemented directly. Classify each into one of the four classes below
and append one line per observation to the host's lap log (binding
above). Never invent a path for it (a missing binding, above). A declared
file that does not exist yet is created with a one-line header pointing
here for the format and classes.

```
- <YYYY-MM-DD> #<ticket> <class>[<topic-slug>] <the observation, one line> → <disposition>
```

- `<class>` — the class token
- `<topic-slug>` — a kebab-case recurrence key; grep past lines and reuse
  the slug for the same phenomenon
- `<disposition>` — what was done with it, one phrase: `filed as #N`,
  `recorded`, `settled with the user`

Classes:

- `net-gap` (a defect class no net covers) → file an improvement ticket
  now, its purpose anchored in the observed rework
- `net-miss` (a net exists but let it through) → record; the second same
  slug → file an improvement ticket
- `judgment` (a design decision) → settle it with the user, or file it (a
  dialog lap usually has already; an autonomous lap leaves it for the
  user in the tracker)
- `noise` (one-off) → record

Improvement tickets are proposals, filed for the user to pick up.

## What this skill never owns

These rules stay resident in the host CLAUDE.md and never depend on this
skill being invoked:

- who may commit, push, or open a PR (typical host rules: no commits
  without an explicit request; confirm before push/PR)
- who may close, and in what order (the authority behind Human Audit:
  summarize, get agreement, then close)
- the host's purpose statement, its order of thought (purpose → facts →
  means), and its language rules
