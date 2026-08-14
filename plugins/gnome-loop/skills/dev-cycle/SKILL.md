---
name: dev-cycle
description: Carries the development skeleton - Swiss Cheese quality layers, the six-stage development cycle from filing to close, and the business-rule conventions for tests and comments. Invoke BEFORE starting any work that changes code in a project wired to this plugin, and when filing a ticket or shaping a plan. Use when you hear "dev cycle", "development cycle", "how do we develop here", "開発サイクル", or at the start of any coding task.
---

# Development Cycle (dev-cycle)

- [When to invoke](#when-to-invoke)
- [Host bindings](#host-bindings)
- [Swiss Cheese Model](#swiss-cheese-model)
- [The development cycle (1 user story = 1 lap)](#the-development-cycle-1-user-story--1-lap)
- [Business rules (the shared unit of tests and comments)](#business-rules-the-shared-unit-of-tests-and-comments)
- [Host wiring (install)](#host-wiring-install)
- [What this skill never owns](#what-this-skill-never-owns)

The method for carrying one user story from filing to close — an antibody
against code-anchored development, where solutions, plans, and explanations
all start from the code while purpose and facts live outside it. The cycle
is run by any session, dialog-driven or autonomous. Rationale lives in
[design.md](design.md); this file is the method.

## When to invoke

Before starting any work that will change code, and when filing a ticket or
shaping a plan. Invoking after implementation has started defeats the
shift-left gates — stages 1–3 are where this skill earns its cost.

## Host bindings

The frame below is invariant; these project-bound inputs come from the host:

| Binding | What the host declares | Home |
|---|---|---|
| Immovable facts | The external realities that cannot be negotiated (data formats, API output, real rendering behavior) — stage 2 observes these | Host CLAUDE.md |
| Domain quality nets | Project-specific automated layers (snapshot regressions, invariant suites) added to the automated layer below | Host CLAUDE.md |
| Story-list source of truth | Where user stories live and how they are referenced by ID | Host CLAUDE.md task-registration rules |
| Development log | The file that receives proposals that cannot state user value (filed nowhere else) | Host CLAUDE.md |
| Toolchain | Tracker / writing / filing / review stack. Defaults: task-tracker, docs-authoring, ticket-authoring (with ticket-review), code-review | Host CLAUDE.md |

When a binding or a named sibling tool is missing at the moment its gate
should fire, surface the gap to the user and name the gate that cannot fire
— never skip silently and proceed as if it had fired. A missing tracker,
review agent, or domain-net declaration degrades one gate; an unreported
skip breaks the lap's promise.

## Swiss Cheese Model

The model's value is that when a problem class recurs, a permanent net can be
inserted into a layer **afterwards**. Defenses are split into layers so
quality rises while the system keeps changing. The frame is invariant; the
layers are domain-specific (host binding above).

- Automated layer: linter / hooks / unit tests / E2E tests, plus the host's
  domain nets
- Non-automated layers:
  - docs-authoring — applied when filing tickets and writing documents (skip
    conditions live in that skill).
  - ticket-review — fires immediately before filing a new ticket and before
    handing a ticket to an autonomous pipeline (ticket-authoring plugin).
    Audits premise validity — user-anchored purpose, outcome vocabulary for
    decisions — as a reader with no project knowledge, in an isolated
    context (one-pass readability belongs to docs-review).
  - code-review — runs without being asked once a code change is complete.
    **Verifying the diff against the ticket's success criteria comes first**
    — do not shrink it to bug-hunting (requirements validity → correctness).
    Findings are limited to correctness / requirement gaps / duplicated
    statements of a business rule (defined below); style is optional
    (chasing it is over-engineering). Apply and report before moving on.
    Docs- or ticket-only changes take docs-review instead.
  - Human Audit — closing happens only after the user confirms: summarize
    the outcome → get agreement → close. Even under "just wrap it up", keep
    that order. The authority behind this gate stays in the host CLAUDE.md
    (see [What this skill never owns](#what-this-skill-never-owns)).

Place gates as early in the spine as possible (**shift-left**). code-review
is a late net at the code stage: if code-anchored thinking is the root, much
of what it catches is the symptom of *picking means before observing facts*
— catch that earlier and cheaper with the fact-stage and plan-stage gates
(cycle stages 2–3).

These layers, fired along one user story's timeline, form the development
cycle below (Swiss Cheese viewed on a time axis). Layers are the concept;
the cycle is their firing order.

## The development cycle (1 user story = 1 lap)

The standard lap from filing to close. Each gate may be collapsed when
trivial (proportional to task size and speed) — but the collapse threshold
differs per gate, and **fact observation (2) is in principle never
collapsed**. Stages 2–3 are the shift-left gates that cut code-anchored
thinking before code is touched. Each stage is productive work or the firing
of a layer above:

| Stage | Layers fired (kind) |
|---|---|
| 1 File | docs-authoring, ticket-review (non-automated) |
| 2 Observe facts [shift-left] | fact-observation gate (the most upstream layer) |
| 3 Plan shape [shift-left] | plan-shape gate (cut by value?) |
| 4 TDD implementation | linter/hooks, unit tests (automated) |
| 5 code-review | code-review (non-automated), E2E (automated) |
| 6 Confirm & close | Human Audit (non-automated) |

1. **File** — file the work as a user story and confirm purpose, success
   criteria, and out-of-scope (load docs-authoring and ticket-authoring
   *before* drafting → register in the tracker; reviewing after drafting
   only patches existing text). Gate: the discrimination test (does the
   value reach the reader?) — ticket-review audits independently.
2. **Observe facts** — before touching code, observe external reality (the
   host's immovable facts: data, API output, real behavior) with the real
   thing, and put it in shared form. **Do not skip.** A wrong premise
   derails everything after it. Observation is Claude's strength and the
   human's load is only confirming presented facts — high value, low cost,
   always on. Gate: does the search for means start from *observed facts*,
   not from *the current state of the code*?
3. **Plan shape** — drop the implementation into a checklist of success
   criteria (→ register it). Plan depth is proportional to uncertainty: if
   one sentence of the requirements shows the approach / single file /
   known code, agree on the goal and implement; if not — multiple files,
   unfamiliar code — harden the plan first (plan mode). If skipping this
   stage repeatedly produces requirement-level findings in code-review, the
   collapse threshold is too loose. Gate: are steps and tickets cut by
   value, not by means? On the observed facts, do the chosen means serve
   the purpose?
4. **TDD implementation** — write the test that expresses the business rule
   first, then the code. The test's purpose is changeability: business
   rules made explicit.
5. **code-review** — fires without being asked (definition above).
   Verifying against requirements comes first.
6. **Confirm & close** — Human Audit fires (definition above).

Subagent delegation: tasks whose goal and context fold into a single
delegation prompt — stage 2 observation, research, mechanical work — may be
delegated to a cheaper-model subagent (general-purpose). Judge by "does the
context fold into one prompt", not by task kind. Requirements alignment,
planning, and review stay in the main conversation.

## Business rules (the shared unit of tests and comments)

A business rule is the intent connecting purpose and specification — "given
this purpose, why this spec". Tests pin the behavior; comments carry only
the "why" that cannot be reconstructed from code and tests. Consistency
(one simple solution per system rule) is kept by writing the chosen
solution down in this form.

- Discrimination test: if the next maintainer could reconstruct the same
  judgment from code and tests after the comment is deleted, it is
  redundant — do not write it. If they could not, it is a business rule
  (e.g., a spec choice that exploits an asymmetric-change-cost structure
  [save formats, frozen compatibility boundaries], or a rejected
  alternative and its reason).
- Single home (the same principle as information placement): a business
  rule is written in exactly one place that owns it (the parameter's,
  function's, or type's home) and never restated elsewhere. Duplicated
  statements produce full-sweep rewrites and missed-copy drift — grep is an
  impact-analysis signal only when it hits the home.
- Reviewing comments is refactoring, same as code: consolidating duplicated
  statements of one rule may be done in a batch when the need is observed —
  staleness survives longest in untouched homes, so change-triggered
  cleanup alone cannot catch it. Simple redundancy is trimmed
  directionally when a change touches it.

## Host wiring (install)

Add one MUST-form trigger line to the host project's CLAUDE.md — the
always-resident dispatch surface this skill depends on:

> Development method: before starting any work that changes code, you MUST
> invoke the `dev-cycle` skill (gnome-loop plugin) and follow its cycle
> from filing to close.

Keep the host side to this line, the host bindings above, and the authority
rules below; this skill body is the single home of the method itself.
Translate the line into the host's CLAUDE.md language if that language is
not English; keep the MUST form.

## What this skill never owns

Authority rules — grants of human authority, not procedure — stay resident
in the host CLAUDE.md and never depend on this skill being invoked:

- Committing, pushing, or opening PRs (typical host rules: no commits
  without an explicit request; confirm before push/PR)
- Closing without the user's confirmation (the authority behind Human Audit)
- The host's purpose statement, spine (purpose → facts → means), and
  language rules — the resident layer from which this skill is invoked
