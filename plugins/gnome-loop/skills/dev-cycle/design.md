# dev-cycle Design Doc

## Purpose

Carry the development skeleton — the quality layers (Swiss Cheese) and the
6-stage development cycle — as a plugin skill, so
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
| Separate skill from the loop skill | Stages 1–3 and stage 6's audit and merge approval are run by dialog sessions (human + Claude), not by the loop; embedding the skeleton in the loop skill would leave dialog sessions no way to read it. The loop is a projection of this cycle onto a state machine, so the projection source stays its own unit. |
| Authority rules are excluded | Grants of human authority (around committing, pushing, closing) are not procedure and must never depend on a skill being invoked, so they stay resident in the host CLAUDE.md. The list itself has one home: SKILL.md's "What this skill never owns" section. |
| Host bindings replace the template's 【★】 slots | The template marked project-bound spots with fill-in slots. A skill cannot be filled in per project, so those spots become the Host bindings table: what the host declares and where the skill reads it from. |
| The trigger line is the dispatch lifeline | Moving the skeleton out of CLAUDE.md makes gate-firing depend on the invoke. The always-resident surface — one MUST-form trigger line in the host CLAUDE.md plus this skill's `description` written as a firing condition — is the dispatch lifeline. If invoke-misses recur in practice, the escalation path is a hook (automation layer), not a longer trigger line. |
| Layers are the Swiss Cheese model: a recurring problem class gets a permanent net inserted into one layer afterwards | Quality has to rise while the system keeps changing; a defense split into layers can take a new net without the others moving. The lap log exists to detect the recurrence that triggers the insertion. |
| Shift-left: stages 2–3 are the gates that matter | code-review is a late net at the code stage. When code-anchored thinking is the root, much of what it catches is the symptom of picking means before observing facts; the fact gate (2) and the plan gate (3) catch that earlier and cheaper, and what they catch never reaches code-review. Invoking after implementation has started defeats them, which is why the apex paragraph says so. |
| Stage 2 is never skipped | A wrong premise derails everything after it. Observation is the session's strength, and the user's load is only confirming presented facts — high value, low cost, so it stays always on. |
| Writing skills load before drafting (stage 1) | Reviewing after drafting only patches existing text; the writing model has to shape the draft. |
| Stage 4 names the bundled implementer (since 0.2.0) | Delegating stage 4 keeps planning and review in the main conversation while the implementation loop runs on the agent; the agent preloads this skill via `skills:`, so the method needs no host CLAUDE.md carriage. v0.1.0 deliberately kept the generic delegation guidance only — naming a not-yet-bundled agent would have dangled. |
| Host bindings may point at the verify skill (since 0.2.0) | Where the gnome loop is wired, the project's domain quality nets live in its `verify` skill (contract in the gnome-loop skill); hosts without the loop keep them in CLAUDE.md. v0.1.0 named only the CLAUDE.md home for the same no-dangling reason. |
| Lap log lives in the cycle, not the loop (since 0.4.0) | Its classes (net-gap / net-miss) name the quality nets this skill owns, and a dialog lap hits the same nets as a loop lap. While the procedure sat in the loop skill, dialog-lap observations landed as prose in the development log or nowhere, so recurrence — the trigger for inserting a net afterwards — went undetected. Per-lap overhead stays at classify + one line + (conditionally) one ticket. The loop skill keeps only its lane-specific rework equivalents and its no-self-rewrite constraint. |
| Lap log is a separate file from the development log (since 0.4.0) | The lap log holds one grep-able line per observation keyed by topic slug; the development log holds prose proposals that cannot state user value. Merging them would bury the recurrence key under prose. |
| Host wiring is a pointer (since 0.3.0; a sentence under Host bindings since 0.7.0) | The canonical trigger-line wording lives in the onboarding skill, which installers consume. v0.1.0–0.2.x carried the wording here as an interim home because installers needed it before the onboarding skill existed; the pointer had its own section until 0.7.0 folded it into Host bindings, the section an installer reads. |
| Stage 2 observes the scope of the change and repeats on every new scope claim (since 0.5.0) | In one host project's lap (2026-09-12), nine review findings were claims the main session had written from memory in delegation prompts and rework instructions — each countable with one grep beforehand. The repeat is stated inside stage 2 so the rule has one home; a sentence at each later point where such claims are written would restate it. |
| Stage 2 starts before choosing means and observes the external reality before the code (since 0.5.0) | The pathology is not reading the code but treating the code alone, unobserved, as the whole picture. So the boundary is at choosing means, the external reality comes first and the code as it actually is second, and the gate sets observed facts — the code counted among them — against the code alone as remembered. |
| Stage 1 recommends a design when the success criteria name a data contract (since 0.6.0) | A story whose goal is still vague gets its gaps filled from the code once implementation starts; design-doc-authoring settles them in prose from the purpose, but nothing in the cycle sent a story there. The trigger is one question at filing: do the success criteria name a data contract? The answer is a recommendation the user agrees to, not a mandatory step — the user knows when a design is worth its cost. The design child is the ticket that holds the design work, not a second cycle; the cycle runs design-doc-review before the child closes, because its checks judge a design that has reached its close. |
| The design is stage 3's deepest form (since 0.7.0) | design-doc-authoring's own "observe before writing" is stage 2, and the design's close — success criteria finalized, the implementation cut into child tickets when the story needs more than one — is stage 3's work of deciding what to build, by value, on the observed facts. So plan depth runs on one scale from a one-sentence goal to a full design. Up to 0.6.0 the whole design paragraph sat in stage 1, which read as writing the design before observing. A story with a design child is a parent ticket, and the gnome loop never picks a parent, so a loop-run story cuts at least one implementation child; a dialog session may implement the story directly. |
| Stage 3 names the plan's input, not plan mode (since 0.6.0) | Stage 3 named plan mode as the way to harden an uncertain plan; in the maintainer's observation (2026-10-07) it went practically unused. What the plan starts from — the success criteria, finalized by the design when the story has one — is what keeps the plan purpose-first; the tool used to hold it is not. |
| The business-rule definition lives in design-doc-authoring (since 0.6.0); the code-side discipline lives in coding-guideline, which stages 4 and 5 run (since 0.7.0) | design-doc-authoring is where rules are written and given their form, so it keeps the definition. The code-side handling — what the tests pin, where a rule lives in the code, what a comment carries, consolidating duplicates — sat in stages 4 and 5 as an interim home until a guideline existed (maintainer's decision, 2026-10-04); coding-guideline 0.1.0 is that home, so the stages run its author's and reviewer's passes and carry no rule of their own. The cycle keeps what the guideline leaves to it: when each pass fires, and when a gap outside the change is fixed — never in the lap that found it, because staleness survives longest in untouched code and change-triggered cleanup alone cannot catch it. |
| Each layer is defined once, firing points are recorded once, and every stage closes with a gate question (since 0.7.0) | Up to 0.6.0 the layer definitions and the stage bodies each carried part of a definition, shift-left was explained in three places, and stages 1–3 had gate questions while 4–6 had none — the residue of per-version patches. The layer table holds each layer's judgment and home; the stage table holds each stage's work, gate, and the layers it fires; the numbered list holds only detail a cell cannot. The reviewer's pass is coding-guideline's layer, run by whoever runs code-review, because the default code-review binding (Claude Code's built-in skill) does not know the guideline. Stage numbers and the section names Host bindings, Lap log, and What this skill never owns are cited by the gnome-loop skill, the implementer agent, the host template, and host CLAUDE.md files, so the restructure keeps them. |
| A stopped guideline pass returns the story to the stage that settled the defective input (since 0.7.0) | The pass's stops are all defects of the input. What changes is the input: the ticket, settled at stage 1, or the design, settled at stage 3. |
| A gap outside the change goes to the tracker or the development log, not the lap log (since 0.7.0) | The lap log's observation is a finding on this lap's change or rework; a gap elsewhere is a proposal for a later batch, which the existing bindings already place: a ticket when it states user value, the development log otherwise. |
| A missing binding or sibling is reported as the gate that cannot fire | A missing tool degrades one gate; a skip nobody reports breaks the lap's promise, because the user reads the lap as if every gate had fired. |
| English body | Marketplace-wide convention: every plugin's documents are English; hosts pick their conversation language in their own CLAUDE.md. |

## Data Flow

```
host CLAUDE.md trigger line (MUST-form, resident)
  -> session invokes dev-cycle before code-changing work
  -> SKILL.md loads the skeleton: quality layers, 6-stage cycle
       (the code-side discipline is read from the coding-guideline skill at stages 4–5)
  -> session runs the lap; the Host bindings table supplies the project-specific inputs
  -> stage gates fire per the skeleton; authority rules stay with the host CLAUDE.md
```

## Constraints & Tradeoffs

- **Dispatch depends on the resident surface.** A session that never invokes
  the skill never sees the gates. Accepted cost of leaving CLAUDE.md thin;
  mitigations are the trigger line, the firing-condition description, and
  hook escalation on recurrence.
- **The skill assumes the sibling plugins** named in the Toolchain binding
  for the layers it names. Missing siblings degrade specific gates, not the cycle's shape.
- **Improvements ship as plugin versions.** Project-specific deviations do
  not patch this skill — they live in the host's own CLAUDE.md or project
  skills; only stabilized general rules come back here.
