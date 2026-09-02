# dev-cycle Design Doc

## Purpose

Carry the development skeleton — Swiss Cheese quality layers, the 6-stage
development cycle, and the business-rule conventions — as a plugin skill, so
any project's session loads the same method with one invoke instead of
hand-filling it into CLAUDE.md and hand-syncing improvements per project.
It is the base layer of the gnome-loop plugin: the loop
skill automates laps *over* this cycle, but the cycle stands on its own for
dialog-driven development — that is why it is a separate skill, not part of
the loop.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Main-session skill, no fork or SubAgent | The skeleton shapes how the *invoking* session files, observes, plans, implements, and reviews. Isolating it in a fork would leave the main session unchanged — the opposite of its job. |
| Separate skill from the loop skill | Stages 1–3 and 6 are run by dialog sessions (human + Claude), not by the loop; embedding the skeleton in the loop skill would leave dialog sessions no way to read it. The loop is a projection of this cycle onto a state machine, so the projection source stays its own unit. |
| Authority rules are excluded | Grants of human authority (around committing, pushing, closing) are not procedure and must never depend on a skill being invoked, so they stay resident in the host CLAUDE.md. The list itself has one home: SKILL.md's "What this skill never owns" section. |
| Host bindings replace the template's 【★】 slots | The template marked project-bound spots with fill-in slots. A skill cannot be filled in per project, so those spots become a bindings table: what the host declares (immovable facts, domain quality layers, story-list source of truth, dev-log home, lap-log home, toolchain) and where the skill reads it from. |
| The trigger line is the dispatch lifeline | Moving the skeleton out of CLAUDE.md makes gate-firing depend on the invoke. The always-resident surface — one MUST-form trigger line in the host CLAUDE.md plus this skill's `description` written as a firing condition — is the dispatch lifeline. If invoke-misses recur in practice, the escalation path is a hook (automation layer), not a longer trigger line. |
| Stage 4 names the bundled implementer (since 0.2.0) | Delegating stage 4 keeps planning and review in the main conversation while the implementation loop runs on the agent; the agent preloads this skill via `skills:`, so the method needs no host CLAUDE.md carriage. v0.1.0 deliberately kept the generic delegation guidance only — naming a not-yet-bundled agent would have dangled. |
| Host bindings may point at the verify skill (since 0.2.0) | Where the gnome loop is wired, the project's domain quality nets live in its `verify` skill (contract in the gnome-loop skill); hosts without the loop keep them in CLAUDE.md. v0.1.0 named only the CLAUDE.md home for the same no-dangling reason. |
| Lap log lives in the cycle, not the loop (since 0.4.0) | Its classes (net-gap / net-miss) name the quality nets this skill owns, and a dialog lap hits the same nets as a loop lap. While the procedure sat in the loop skill, dialog-lap observations landed as prose in the development log or nowhere, so recurrence — the trigger for inserting a net afterwards — went undetected. Per-lap overhead stays at classify + one line + (conditionally) one ticket. The loop skill keeps only its lane-specific rework equivalents and its no-self-rewrite constraint. |
| Lap log is a separate file from the development log (since 0.4.0) | The lap log holds one grep-able line per observation keyed by topic slug; the development log holds prose proposals that cannot state user value. Merging them would bury the recurrence key under prose. |
| Host wiring is a pointer (since 0.3.0) | The canonical trigger-line wording lives in the onboarding skill, which installers consume; SKILL.md's Host wiring section is a one-line pointer. v0.1.0–0.2.x carried the wording here as an interim home because installers needed it before the onboarding skill existed. |
| English body | Marketplace-wide convention: every plugin's documents are English; hosts pick their conversation language in their own CLAUDE.md. |

## Data Flow

```
host CLAUDE.md trigger line (MUST-form, resident)
  -> session invokes dev-cycle before code-changing work
  -> SKILL.md loads the skeleton: quality layers, 6-stage cycle, business rules
  -> session runs the lap; host bindings supply the project-specific inputs
       (facts to observe, domain nets, tracker, dev log, lap log)
  -> stage gates fire per the skeleton; authority rules stay with the host CLAUDE.md
```

## Constraints & Tradeoffs

- **Dispatch depends on the resident surface.** A session that never invokes
  the skill never sees the gates. Accepted cost of leaving CLAUDE.md thin;
  mitigations are the trigger line, the firing-condition description, and
  hook escalation on recurrence.
- **The skill assumes the sibling plugins** (docs-authoring, ticket-authoring
  with ticket-review, task-tracker or an equivalent tracker) for the layers
  it names. Missing siblings degrade specific gates, not the cycle's shape.
- **Improvements ship as plugin versions.** Project-specific deviations do
  not patch this skill — they live in the host's own CLAUDE.md or project
  skills; only stabilized general rules come back here.
