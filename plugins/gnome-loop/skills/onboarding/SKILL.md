---
name: onboarding
description: Wires the gnome-loop pipeline into a host project in one conversation - audits the host against the loop's prerequisites, generates the verify/observe skill skeletons and the config while asking for the project's real commands, and proposes the dev-cycle trigger line for the host CLAUDE.md. Use when you hear "onboard gnome-loop", "wire this project for the loop", "gnome-loop を導入", "導入監査", or "set up the gnome pipeline".
---

# onboarding (wire a host project for the gnome pipeline)

- [When to invoke](#when-to-invoke)
- [1. Audit](#1-audit)
- [2. Audit report (one screen)](#2-audit-report-one-screen)
- [3. Fill the gaps (interactive)](#3-fill-the-gaps-interactive)
- [4. Trigger line](#4-trigger-line)
- [5. Final report (one screen)](#5-final-report-one-screen)
- [Related files](#related-files)

One conversation takes a host project from unwired to "minimal laps can
start": audit → skeleton generation → trigger line → report. Minimal means
the novel lane only — pattern lanes are assembled later, when a ticket
class recurs (step 5). Rationale lives in [design.md](design.md); this
file is the procedure.

## When to invoke

On a project that should run the gnome loop but is not wired yet. An
already-wired host may re-run it any time to re-audit — same procedure,
same one-screen report; steps 3–4 simply find nothing to generate.

## 1. Audit

Run the mechanical half against the host repository root:

```bash
bash <this skill's base dir>/scripts/audit.sh <host repo root>
# item list, statuses, and exit codes are documented in its header
```

Then make the three checks that need reading, and only those three — the
script's items are not otherwise re-judged:

- **Net inventory** — read the project's test and CI configuration and
  list the automated nets that exist (unit, lint, type check, E2E, domain
  nets). The audit reports stock; building nets is out of scope.
- **verify / observe conformance** — when a slot file exists, existence is
  not proof the slot is filled: Claude Code's built-in `/verify`
  auto-creates a build-and-drive recipe at `.claude/skills/verify/SKILL.md`
  when that file is missing — same home, different shape. Check each
  existing slot file against its skeleton's contract-bound sections
  ([verify-skeleton.md](verify-skeleton.md): report shape and "No
  judgment"; [observe-skeleton.md](observe-skeleton.md): evidence and run
  instructions). A file that does not meet them is raw material for
  step 3, not a filled slot.
- **Trigger-line form** — when CLAUDE.md mentions dev-cycle, check the
  line is step 4's MUST-form wording (translated is fine). A weaker
  mention is reported as such and upgraded through step 4.

## 2. Audit report (one screen)

Line 1 is the verdict, then the findings, then what happens next — one
screen total:

```
gnome-loop onboarding audit — <project>
verdict: ready for minimal laps | not ready — <N> gaps

<audit.sh output verbatim>
nets in stock: <inventory from step 1, one line>
verify slot:   <conforms | raw material (non-conforming recipe) | missing>
observe slot:  <conforms | raw material (non-conforming recipe) | missing>
trigger line:  <canonical | weak (upgrade in step 4) | missing>

next: <the step-3/4 pieces to generate, in order | "run the first lap">
```

Stop here and confirm the gap list with the user before generating
anything — the audit may have misread a project-specific arrangement.

## 3. Fill the gaps (interactive)

Generate each missing piece **while asking for the host's real commands —
never invent them**. Ask, write, then show the result for confirmation.

| Gap | Action |
|---|---|
| verify skill | Copy [verify-skeleton.md](verify-skeleton.md) to `.claude/skills/verify/SKILL.md` and fill every `{placeholder}` by asking: the verification commands, each net's green condition, what a red summary must keep. A non-conforming existing file is rewritten into this shape, keeping its working commands. Keep the "No judgment" section as written — it is the contract's edge. |
| observe skill | Copy [observe-skeleton.md](observe-skeleton.md) to `.claude/skills/observe/SKILL.md` and fill by asking: what evidence a human reviews, how to produce it, where it lands, how a human runs the change safely. |
| config | Copy `../gnome-loop/config.example.toml` (sibling-file resolution: Related files) to `.claude/gnome-loop.toml` and fill by asking; its comments name each value's meaning. |
| tracker | Point at the task-tracker plugin (install, then `task.sh init` at the repo root) — its own docs are the truth source. A host with a different tracker supplies a same-interface script instead. |
| slot files gitignored | Add them to config `untracked_assets.paths` and say the consequence out loud: worktrees will not see them, the loop reads them from the main checkout. |

## 4. Trigger line

The canonical wording (translate into the host CLAUDE.md's language if it
is not English; keep the MUST form):

> Development method: before starting any work that changes code, you MUST
> invoke the `dev-cycle` skill (gnome-loop plugin) and follow its cycle
> from filing to close.

Propose it with the insertion point in the host CLAUDE.md. **Write it only
after the human confirms** — this line changes how every future session
behaves, and the host CLAUDE.md is the human's document.

## 5. Final report (one screen)

Same shape as step 2, current state after generation:

- verdict line: what can start now (minimal laps / still blocked, by what)
- what was generated and what the human should review in each file
- how to run the first lap: grant a ticket loop-ready, then invoke the
  gnome-loop skill
- pattern lanes: not assembled at onboarding. When the same ticket class
  recurs, the lane test and protocol live in the gnome-loop skill's
  lane-protocol.md — name that trigger and stop.

## Related files

| File | Role |
|---|---|
| [scripts/audit.sh](scripts/audit.sh) | mechanical audit items, statuses, exit codes |
| [verify-skeleton.md](verify-skeleton.md) | template for the host's verify slot |
| [observe-skeleton.md](observe-skeleton.md) | template for the host's observe slot |
| [design.md](design.md) | decisions and rationale behind this procedure |
| gnome-loop skill (this plugin) | the loop the wiring serves; owns the slot contracts, `config.example.toml`, and `lane-protocol.md`. Sibling-skill files resolve as `../gnome-loop/` from this skill's base directory — the plugin ships and versions its skills together |
| dev-cycle skill (this plugin) | the method the trigger line dispatches to; owns the host bindings the audit's judgment checks read against |
