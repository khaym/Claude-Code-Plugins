# onboarding Design Doc

## Purpose

Wiring gnome-loop into a new host by hand means reverse-engineering the
loop's prerequisites (tracker, verify/observe slots, config, trigger line)
from the loop skill and the two reference hosts — a setup cost that eats
the value of the laps. This skill turns the install into one conversation:
audit → skeleton generation → trigger line → a host that can start
minimal (novel-lane-only) laps the same day.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Mechanical audit is a script, judgment stays in the skill | The script/skill split (same principle as lane-protocol.md): file existence, tracker resolution, gitignore status, and trigger-line presence are machine-decidable — `scripts/audit.sh` reports them with fixed item names, statuses, and exit codes, and the bash test harness pins them. Net inventory and verify-contract conformance require reading and interpreting content, so they stay in the SKILL.md procedure. |
| The verify slot is audited for contract conformance, not existence | Claude Code's built-in `/verify` designates the same home (`.claude/skills/verify/SKILL.md`) and auto-creates a build-and-drive recipe there when the file is missing. Existence is therefore not proof the slot is filled; the skill checks the file against the loop's verify contract and treats a non-conforming file as raw material. Keeping the slot name `verify` (instead of renaming to dodge the collision) is deliberate: the project skill shadows the built-in in name resolution, the built-in commit-time nudge then reinforces the loop's verify gate, and a renamed slot would make the built-in create a second, duplicate recipe. (Observed on Claude Code 2.1.239, 2026-08-22.) |
| Skeletons are placeholder templates filled by dialog | The skill never invents host commands — every `{placeholder}` is asked. The templates pre-shape the contract-bound sections (report shape, no-judgment rules) so a generated skill conforms to the loop's contracts by construction, and the host only supplies facts. |
| The trigger line's canonical wording lives here | dev-cycle's Host wiring section was the interim home (a v0.1.0 deferred decision, recorded in dev-cycle's design.md): installers needed the wording before this skill existed. Now installers consume it through this skill, and dev-cycle keeps a one-line pointer — one rule, one home. |
| Minimal configuration is novel-lane only | A pattern lane requires a recurring ticket class and standing nets (the lane test in lane-protocol.md) — a fresh host has neither. Onboarding names the protocol and stops; assembling lanes here would pull judgment work into the install. |
| Re-audit uses the same entry point | An already-wired host re-runs the same audit and gets the same one-screen report — no separate "health check" procedure to drift from the install path. |
| Sibling-skill files are referenced plugin-relative | This skill consumes the gnome-loop skill's `config.example.toml` and `lane-protocol.md`. The skills ship and version together in one plugin, so `../gnome-loop/` from this skill's base directory is a stable resolution, stated once in Related files. The coupling is intra-plugin only; a sibling rename is a plugin-versioned change its own review catches. |

## Data Flow

Host repo root → `scripts/audit.sh` (mechanical items) + skill-side
judgment checks (net inventory, verify conformance) → one-screen audit
report → interactive generation of missing pieces (verify/observe skeletons,
config) → trigger-line proposal (written only after human confirmation) →
final one-screen report (what is in place, what remains, how to run the
first lap).

## Constraints & Tradeoffs

- The skeletons restate, in template form, the slot contracts the
  gnome-loop skill owns at its lap steps — an intentional copy so a
  generated slot conforms by construction and the audit can check
  conformance against an in-skill home. A contract change must edit both
  homes; they ship in one plugin version, and plugin review is the net.
- The audit checks presence and shape, not quality: a generated verify
  skill is only as good as the commands the host names. The first laps are
  the real test, and the host refines its own slot skills afterwards (the
  improvement flow stays project-side by design).
- `implementer` resolution (plugin definition vs a same-named local agent)
  is not machine-checked here; the loop's prerequisite step owns that check
  at lap time.
- `audit.sh --cache-dir` exists for hermetic tests; real runs use the
  default plugin cache location.
