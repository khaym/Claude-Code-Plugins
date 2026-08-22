# Pattern-Lane Protocol

The rules and procedure for adding a pattern lane to a host project: the
gate that decides whether a ticket class may become a lane, the contract
every lane skill provides to the loop, and the steps that build one.
Adding a lane never touches this plugin — the lap discovers lane skills
by their frontmatter declaration (the contract's opening).

- [The gate (when a ticket class may become a lane)](#the-gate-when-a-ticket-class-may-become-a-lane)
- [The contract](#the-contract)
- [The script / skill split](#the-script--skill-split)
- [Building a lane](#building-a-lane)
- [Out of scope](#out-of-scope)

## The gate (when a ticket class may become a lane)

A lane serves a ticket class, never a single ticket. Build one only when
all three conditions hold; a class failing any one stays in the novel
lane:

1. The class recurs. The same-shape ticket has arrived at least
   twice and more are expected. A lane for a one-off costs more than it
   saves.
2. The work is schema-interior. Every artifact is a deterministic
   function of values agreed on the ticket before the loop starts — an
   approved design, agreed numbers, a policy for each predicted
   consequence. The test: could a script write every file given only
   the ticket's agreed values? A class where an artifact needs a
   judgment call mid-implementation is novel-lane work, as is anything
   that moves the schema itself.
3. Standing nets already verify the result. The repository holds
   automated nets that judge any instance of the class without
   per-instance edits (manifest-walking invariants, registries,
   snapshot suites). Nets come first, the generator second: a generator
   without standing nets shifts verification onto per-addition
   hand-written checks — the class of work the lane exists to remove.
   File missing nets as novel-lane tickets and land them before
   building the lane.

## The contract

A lane skill is a host project skill under `.claude/skills/` whose
frontmatter carries `metadata: { lane: pattern }` — the marker the lap
greps for. It sits inside `metadata` because unknown top-level
frontmatter keys hard-fail skill packaging; `metadata` is the
documented free-form map.

The *red prediction* below is the script's printed forecast of which
standing tests go red for a given input — its fifth duty
([next section](#the-script--skill-split)).

The lane skill is the truth source for six things, each consumed at a
named point of the [gnome-loop procedure](SKILL.md) — the first by the
human granting loop-ready, the rest by the lap:

| # | Item | The lane skill provides | Consumed at |
|---|---|---|---|
| 1 | Loop-ready agreements | The full list of pre-filing agreements a ticket of this class must carry: approved designs, agreed values, and a policy for every conditional consequence the red prediction can name | the loop-ready grant — a human checks the ticket against this list before the loop ever sees it |
| 2 | Input home and format | Where the input file lives and its schema | lap step 5 — the loop session writes the input per the skill |
| 3 | Steps and stop conditions | The ordered procedure and a stops table (signal / meaning / do) | lap step 5 — hitting a stop turns the ticket blocked, with the stopping fact in the ticket log |
| 4 | Verification commands and expected reds | The verification command list and the static expected-red rule, with the answer each predicted red takes | lap step 6 — review compares actual reds against the prediction |
| 5 | Rebase / conflict rule | How mechanical, append-shaped conflicts in its generated artifacts resolve under rebase | lap step 6 and merge step 5 |
| 6 | Untracked-asset verification | Its own checks for gitignored assets it owns (e.g. generator smoke checks) | merge step 2, after a merge touches them |

Three rules run through every item:

- **Verbatim transcription.** Input values copy from the ticket
  verbatim. The lane re-derives nothing except values the script
  explicitly solves. A ticket-agreed value always wins over a solved
  one: the lane takes it as given, and the standing nets judge it at
  verification. Re-derivation
  reintroduces the transcription-error class the lane exists to remove
  and moves a judgment off the ticket. The input file records the
  ticket's agreement; the generated artifacts are the repo-facing
  record.
- **Stops route judgment, never absorb it.** Every stop returns a
  decision to the ticket. A lane never blesses a snapshot, raises a
  cap, weakens an expectation, or bends an agreed value. Even a
  predicted red whose answer is a transcription (append the ticket's
  agreed row to a frozen registry) stays an edit outside the generator,
  so the change gets read rather than silently written.
- **The class boundary is declared.** The skill's opening names both
  the class of work the lane covers and what it never does — the lap's
  lane decision and the skill's own stop table need this edge to be
  decidable. Every never-list includes at least:
  - choose a design
  - agree a value
  - change what an existing test asserts
  - extend the schema

## The script / skill split

Everything machine-decidable lives in the script; the skill holds only
the order of operations and the stop conditions. Judgment-free work
re-executed by a model every lap reintroduces the variance the lane
exists to remove. The script's five duties:

- **validation** — refuse mechanically decidable violations before any
  file is written, in the input's vocabulary, with the ways out printed
- **derivation** — solve anything solvable from agreed values plus
  frozen repository constants; parse inventories from the tree at run
  time, so no number lives in two places
- **emission** — write the artifacts
- **overwrite refusal** — never write over existing artifacts; print
  the recovery map (files to delete, files to check out), derived from
  the same list the writer uses so it cannot drift
- **red prediction** — print the static expected-red list for this
  input, derived from the tree

Three layers govern where each check lands:

1. Mechanically decidable violations are refused before generation
   (validation).
2. Consequences needing human judgment are forecast by the red
   prediction; the policy lives on the ticket, and a missing policy is
   a stop, never a guess.
3. The standing nets stay the last line. A diff between the prediction
   and an actual red is generator-improvement input — reported, never
   patched around.

## Building a lane

Run these steps once the gate passes. Each step names the contract item
its output lands in. The steps carry a running example: a host app that
ships color themes, where the third "add one theme" ticket has just
arrived — palettes are approved by humans on candidate screenshots,
every artifact is derivable from the approved values, and a
theme-registry test plus a rendering snapshot suite already stand.

### 1. Agree the class

Collect and agree with a human — this list is what every future ticket
of the class gets checked against (contract item 1), and the boundary
becomes the skill's opening:

- **class boundary** — what the lane covers, and its never-list (the
  four common nevers plus any class-specific ones)
- **agreement set** — every value a ticket must carry: which design
  approvals, which agreed values, and which values the script solves
  instead (named as solved)
- **red policies** — for each red the prediction can name that needs
  judgment (a moved snapshot, a raised cap): the ticket carries the
  policy, the lane carries the stop

*Example: the theme lane covers "ship one new color theme" and never
restyles an existing theme; a ticket carries the approved palette, the
agreed theme name, and — when the prediction names a moved golden
image — its update policy.*

### 2. Design the input schema

Pick the input file's home and write its schema in the ticket's
vocabulary — one key per agreed value (contract item 2; the
transcription rules live in [the contract](#the-contract)). Skeleton:

```toml
# work/<lane>-inputs/<name>.toml — values copied from the ticket verbatim
[<class>]
name = "<agreed name>"
# one key per value in the agreement set;
# a script-solved value is optional and commented as solved:
# output = 6            # optional: omitted, the script solves it
```

*Example: `work/theme-inputs/<name>.toml` holding the agreed name and
the approved palette's hex values.*

### 3. Build the script

Implement the five duties, placing each check by the three layers.
Recommended interface — pin it unambiguously, whatever shape you pick:

- `--check`: validate only. A violation exits 2 and lists every
  violation in the input's vocabulary with the ways out; success exits
  0 and prints the expected-red list and any solved values.
- generation: the same validations, then emit. Print the artifacts
  written, the expected-red list, and the verification commands.
- overwrite: refuse, and print the recovery map (files to delete,
  files to check out).

Bring-up verification, standalone, before the skill exists:

- run each refusal path once (a malformed value, a collision, an
  overwrite)
- run one real generation and compare the printed prediction against
  the actual test reds — a diff is a script defect to fix now, not a
  forecast to adjust later

*Example: `themegen.py --check` refuses a malformed hex value or a
name collision before writing anything; generation emits the theme
definition and prints the one predicted red — the theme registry,
answered by transcribing the ticket's agreed row.*

### 4. Write the lane skill

Frontmatter carries the marker and the trigger phrases:

```yaml
---
name: add-<class>-kind
description: <third person: what the lane adds, from what agreements>
  ... The <class> pattern lane. Use when you hear ...
metadata:
  lane: pattern
---
```

Two sections' content comes from the script you just built:

- **rebase rule** — for each generated artifact that appends to a
  shared file (a registry row, a manifest word), state how a
  mechanical, append-shaped conflict resolves (keep both sides, rerun
  the lane's verification); any other conflict shape is a stop
- **untracked-asset checks** — name the gitignored assets the lane
  owns (its input directory, at minimum) and the command that verifies
  them (the script's `--check` over the stored inputs is usually
  enough)

The body is one section per contract item; the steps section stays
thin — order of operations and stop references only (the split rule):

| Section | Satisfies |
|---|---|
| Opening: class boundary and never-list (step 1) | the lap's lane decision |
| Prerequisites: the agreement set and red policies (step 1) | contract item 1 |
| Input file: home and schema (step 2) | contract item 2 |
| Steps: the order of operations | contract item 3 |
| When it stops: a stops table (signal / meaning / do) | contract item 3 |
| Verification: commands and each predicted red's answer (step 3) | contract item 4 |
| Rebase rule: append-shaped conflict resolution (above) | contract item 5 |
| Untracked assets: the owned files and their checks (above) | contract item 6 |

A host with a skill-authoring toolchain runs its create workflow and
review gate here; this table supplies the lane-specific sections.

*Example: the theme lane's stops table carries "unexpected red → stop,
report prediction vs reality" and "predicted golden-image red, no
policy on the ticket → stop"; its rebase rule keeps both registry rows
and reruns the registry test; its untracked-asset check runs
`themegen.py --check` over every stored input.*

### 5. Quality check

Run the host's skill-review gate if one exists. Either way, check by
reading the skill alone:

- every contract row is answerable from the skill, without opening the
  script
- the steps section holds no judgment — each judgment is a stop row
- every stop row names the decision that goes back to the ticket

### 6. Prove the lane

Run the next ticket of the class through the lane end-to-end — in a
dialog session or a loop lap — and verify:

- the input matches the ticket's values verbatim
- stops land where the stops table says
- actual reds match the printed prediction, and the lane's
  verification commands end green

A clean pass opens the class for loop-ready grants. A prediction-vs-red
diff is script-improvement input before the lane takes its next ticket.

## Out of scope

A generic generator. Emission is domain-specific — a project may reuse
its existing generation tooling as parts, but the script belongs to the
lane, not to this plugin.
