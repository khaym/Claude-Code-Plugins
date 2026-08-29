---
name: gnome-loop
description: Runs one lap of the gnome pipeline - picks a loop-ready ticket from the tracker, drives worktree implementation (a pattern-lane skill's generator for pattern tickets, the bundled implementer agent for novel ones), reviews, collects evidence, and parks the ticket awaiting-human; also processes merge approvals and rebase queues. Use when you hear "gnome loop", "run the loop", "run a lap", "ループを回して", "チケットを消化して", or as the iteration body of "/loop /gnome-loop:gnome-loop".
---

# gnome-loop (one lap of the pipeline)

- [Host prerequisites](#host-prerequisites)
- [Two lanes](#two-lanes)
- [State machine and tracker commands](#state-machine-and-tracker-commands)
- [Session exclusion (lease)](#session-exclusion-lease)
- [Execution model (dispatch and end the turn)](#execution-model-dispatch-and-end-the-turn)
- [One lap](#one-lap)
- [Merge procedure (only on a human approval reply)](#merge-procedure-only-on-a-human-approval-reply)
- [On failure](#on-failure)
- [Ending the turn and pacing](#ending-the-turn-and-pacing)
- [Related files](#related-files)

One lap carries one loop-ready ticket from pickup through worktree
implementation → code review → evidence → awaiting-human. Merging happens
only on an explicit human approval reply. The lap is the dev-cycle skill's
development cycle projected onto a state machine: stages 4–5 run inside the
loop; stages 1–3 (filing, observation, plan agreement) and stage 6 (audit,
merge approval) stay with humans and dialog sessions. Rationale lives in
[design.md](design.md); this file is the operating procedure.

All paths run from the repository root. Ticket operations always run from
the root, never from a worktree.

## Host prerequisites

The lap reads these at start; a missing one stops the lap **by name** —
never proceed as if a gate had fired:

| Prerequisite | Home |
|---|---|
| Config | `.claude/gnome-loop.toml` — schema and comments in [config.example.toml](config.example.toml) |
| Tracker | task-tracker plugin (or a script with the same interface). Resolve: `TASK_SH=$(ls ~/.claude/plugins/cache/*/task-tracker/*/scripts/task.sh \| sort -V \| tail -1)` |
| `verify` skill | `.claude/skills/verify/` — the project's verification suite (contract at lap step 6) |
| `observe` skill | `.claude/skills/observe/` — evidence capture and run instructions (contract at lap step 7) |
| dev-cycle | This plugin — the method the lap projects; its trigger line sits in the host CLAUDE.md. Loaded on invoke like any skill, so step 0 invokes it when it is not already in context |
| `implementer` agent | This plugin (`agents/implementer/`) — the novel lane's delegation target (step 5). Verify it resolves to this plugin's definition, not a same-named local agent |

## Two lanes

- **Pattern lane** — the ticket's work is covered by a project lane skill:
  a skill under the host's `.claude/skills/` whose frontmatter carries
  `metadata: { lane: pattern }` and whose class of work matches the ticket.
  The loop session runs that skill's procedure itself in the worktree — no
  spec, no delegation. The lane skill is the truth source for everything
  the lap consumes from it; the contract — and the protocol for adding a
  lane to a host — lives in [lane-protocol.md](lane-protocol.md).
- **Novel lane** — everything else. Delegate implementation to the bundled
  `implementer` agent with the plan checklist agreed on the ticket.
- Reviewer and implementer stay separate: the loop session gates
  code-review and merges; it never reviews its own novel-lane
  implementation (that is the implementer's), and lane-generator output is
  reviewed against the ticket, not regenerated to taste.
- Humans own both ends: before filing (ideas, design approvals, agreed
  values, granting loop-ready) and after the lap (deviation check, merge
  approval). The loop carries only the middle.

## State machine and tracker commands

| Transition | Command | Actor |
|---|---|---|
| open → loop-ready | (granted by a human in a dialog session; conditions below) | human |
| loop-ready → in-flight | `task.sh update <id> --status in-flight` + append branch name and start time to the ticket log | loop |
| in-flight → awaiting-human | `task.sh update <id> --status awaiting-human` + append verify results, evidence paths, branch | loop |
| any → blocked | `task.sh update <id> --status blocked` + append the facts; **line 1 of the append names the decision needed** (so `task.sh list --status blocked` reads as the human's decision queue) | loop |
| blocked → loop-ready / open | (human resolves and returns it) | human |
| awaiting-human → closed | last step of the merge procedure: `task.sh close <id>` | loop |

The in-flight and awaiting-human statuses are written only by the loop,
for work the loop carries. A session working a ticket outside the loop
leaves it open (progress goes to the ticket log) — the pick gate's
in-flight count and the crash-trace rule (On failure) read these statuses
literally.

loop-ready means the judgment work is finished before the loop starts:

- Pattern: a matching lane skill exists, and every pre-filing agreement
  that skill requires (designs, agreed values, conditional policies) is on
  the ticket. The lane skill is the truth source for the full list.
- Novel: the plan checklist (success criteria) is agreed on the ticket.
- Common: all `blocked-by` resolved. A ticket that changes DSL or API
  vocabulary (rename or addition) has grepped the host's `.claude/skills`
  for the old, new, and parent words and names in its body every skill
  document that quotes them — only named documents may be updated inside
  the lap (step 4's untracked-assets rule).

Appending to a ticket log: fetch the current body with
`task.sh show <id> | sed -n '/── Details ──/,$p' | tail -n +2`, **stop if
the extraction is empty** (a wrong extraction plus `-d` full-replace
silently destroys the body), append, write back with `-d`.

## Session exclusion (lease)

One loop session at a time. The mechanics live in
[scripts/lease.sh](scripts/lease.sh) — the lap only branches on exit codes.
Session id: a stable identifier for this session (e.g. the scratchpad
path's UUID). Lease dir: config `paths.lease`.

| Call | When | Exit → action |
|---|---|---|
| `lease.sh acquire <dir> <id>` | lap start (prereq step 0) | 0 → proceed. 2 (held, fresh) → do no write-phase work; if the user handed you approvals or loop instructions, find the holding session via ListAgents and forward with SendMessage when identifiable, else report the holder and ask the user to feed the holding session directly. 3 (stale) → crash trace: show the holder lines, get the human's confirmation, then `release --force` + `acquire` — never take over automatically |
| `lease.sh heartbeat <dir> <id>` | first thing every turn while holding | 0 → continue. 2/4 → the lease is not yours anymore: stop write-phase work and re-acquire at the next lap start |
| `lease.sh release <dir> <id>` | stopping the loop, or finishing a one-shot lap | 0 always (idempotent) |

## Execution model (dispatch and end the turn)

Long waits (implementer runs, verify suites, evidence capture) are not
awaited synchronously: dispatch to the background and end the turn.
Completion notifications resume the lap. User input (merge approvals,
questions, side work) gets processed at turn boundaries.

- Subagents stay on their default background launch; command verification
  goes out with `run_in_background`.
- After delegating to the implementer, append one line to the ticket log
  (the delegated agent's name) before ending the turn — if the
  notification is lost, the ticket plus the worktree reconstruct the
  position. Verification commands need no note (lost = rerun).
- On resume, handle interruptions (merge approvals, user instructions)
  with step 1's priority before continuing the lap.
- Recommend a parallel session for large side work — while this session's
  turns are occupied, lap resumption waits behind them.

## One lap

### 0. Prerequisites

- cwd is the repository root; config read; every [host
  prerequisite](#host-prerequisites) present.
- dev-cycle is in context — invoke it now if it is not (skill bodies load
  on invoke, not at plugin install; the lap reviews and implements by its
  method).
- Lease acquired (table above). Not acquired → no lap.
- The main working tree is clean. Dirty means a parallel session is
  mid-work — do not merge, do not pick; wait out the whole lap.

### 1. Merge queue first

A human reply approving "#N merge OK" is processed (merge procedure below)
before any new pickup.

### 2. Pick

One ticket from `task.sh list --status loop-ready`, subject to:

- in-flight count below config `loop.parallel_limit`
- tickets matching config `serial.globs` are not picked while another
  in-flight ticket matches them (print `serial.note` when this defers)

Transition to in-flight immediately on picking (exclusivity). Nothing to
pick → idle pacing (below).

### 3. Lane decision

Discover lane skills: `grep -l 'lane: pattern'` over the host's
`.claude/skills/*/SKILL.md` frontmatter (`metadata` field). A lane skill
whose work class matches the ticket → pattern lane; none → novel lane.

### 4. Worktree

```bash
git worktree add "<config paths.worktrees>/<repo>-wt-<id>" -b <branch_prefix><id>-<slug> main
```

If `-b` fails with already-exists: a branch identical to main is debris
from a failed add — `git branch -D` and retry. A branch with commits main
lacks is work in progress — blocked.

Config `untracked_assets.paths` are gitignored and therefore absent from
worktrees: read them (inputs, observation files, skills) from the main
checkout by absolute path. Editing them lands on the shared main copy
immediately and outside the branch — do it only when the ticket names the
file, and record the landing in the ticket log and the awaiting-human
report (step 8).

### 5. Implement

**Pattern lane**: the loop session runs the lane skill's procedure in the
worktree (inputs written per that skill; pass the worktree as its repo
root). Hitting one of the skill's stop conditions → blocked, with the
stopping fact in the ticket log.

**Novel lane**: delegate to the `implementer` agent (this plugin's; model
per its frontmatter, override at invocation when the ticket calls for it).
The agent's own delegation contract governs scope, commits, and the report
fields; the loop-specific pieces of the prompt are:

- the worktree path as the working tree, and the ticket's plan checklist
  pasted in full (the worktree has no tracker access — never have the
  agent run task.sh)
- shared assets, if any: exactly the untracked assets the ticket names
  (step 4's rule)
- run the observe skill's evidence capture to completion inside the
  implementation loop (evidence lands under the worktree; locations per
  the observe skill)
- avoid order-dependent references in tests (resolve content by name, not
  by index — rebases shift order)

### 6. code-review (loop session)

The verify skill runs here and again at merge step 2 (lane skills may also
call it inside their own procedures). Its contract: given a tree root
(worktree or main checkout), it runs the project's full verification suite
and reports green, or each failing net's name with its output — it never
weakens an expectation to pass, and never interprets a red (interpretation
belongs to lane skills and the ticket).

First, if the worktree is behind main: `git rebase main`, then rerun the
verify skill (a rebase deferred from merge step 5 is picked up here;
conflict rules per the owning lane skill). Then review the diff,
requirements first, correctness second:

- **Vocabulary sweep (both lanes)**: if the diff changes DSL or API
  vocabulary (rename or addition), grep the host's `.claude/skills` for
  old, new, and parent words; check that quoting documents followed. Hits
  in documents the ticket did not name are not hand-fixed — they go into
  the awaiting-human report as decisions (step 8).
- **Pattern**: check generated artifacts against the ticket's approved
  design and agreed values, and that expected-red policies were applied as
  written on the ticket; rerun the verify skill in the worktree. Defects
  in generated artifacts are generator defects — never hand-patch; blocked
  plus an improvement ticket.
- **Novel**: review against the ticket's plan checklist; rerun the verify
  skill; return findings to the same implementer agent via SendMessage
  (keeps the delegation context; re-delegate if the agent is gone). Not
  converged after two round trips → blocked. Record round-trip count in
  the lap log.

### 7. Evidence and commit

The observe skill's contract (it also runs inside step 5's implementation
loop and supplies step 8's run instructions): given a tree root and the
ticket's target, it produces the evidence a human reviews (captures,
screenshots, transcripts) under that tree, reports their paths, and
supplies the run/playtest instructions the awaiting-human report includes.

- Copy the observe skill's evidence from the worktree to the main checkout
  (locations per the observe skill).
- Commit on the branch, in the repository's voice and trailer conventions.

### 8. To awaiting-human (shared with blocked)

Transition, append verify results, evidence paths, and branch to the
ticket log. The session reply **declares the state class on line 1**:

- `✅ #<id> done — check only`: all success criteria met; the human's work
  is deviation check and merge approval
- `⚠️ #<id> done — <N> decisions`: implemented and verified, but answers
  are needed before merge approval (net updates, accepted compromises)
- `⛔ #<id> blocked — <the decision, in one phrase>`

Body order: "what the human does" (numbered; only items needing answers) →
"reference" (verify results, branch, evidence paths — nothing needing an
answer). Run/playtest instructions come from the observe skill and are
included every time. If the lap edited untracked assets, the reference
names the files and the fact they live on the shared main copy.

### 9. Lap log (every lap, lightweight)

Classify review findings and the implementer's self-reported rework into
four classes and append one line each to config `paths.lap_log`, one line
per observation:

```
- <YYYY-MM-DD> #<ticket> <class>[<topic-slug>] <the fact, one line> → <disposition>
```

The topic-slug is the recurrence key — grep past lines and reuse the slug
for the same phenomenon. If the file does not exist, create it with a
one-line header pointing here for the format and classes. In the pattern
lane, the lane skill's stops, warnings, and expected-vs-actual red gaps
are the "rework" equivalent.

- **net-gap** (a defect class no net covers) → file an improvement ticket
  now, purpose anchored in the developer's rework
- **net-miss** (a net exists but let it through) → record; second same
  topic → improvement ticket
- **judgment** (a design decision) → blocked or ticketed (should already
  be handled by step 6)
- **noise** (one-off) → record only

Improvement tickets are proposals. **The loop never rewrites its own
procedure, templates, or skills mid-run.** Per-lap overhead stays at
classify + one line + (conditionally) one ticket.

## Merge procedure (only on a human approval reply)

1. At the root: `git merge --ff-only <branch>` (history stays linear). If
   ff is impossible: rebase in the worktree first → rerun verify and the
   observe evidence → no re-approval needed, but record it in the ticket
   log.
2. Run the verify skill on main (post-merge check). If the lap edited
   untracked assets, additionally run the owning lane skill's own
   verification for them (e.g. its generator smoke checks) on main.
3. `git worktree remove` and `git branch -d` — **immediately**.
4. `task.sh close <id>`.
5. Rebase each remaining in-flight / awaiting-human branch on main → rerun
   the verify skill and the observe skill's evidence. Mechanical, append-shaped conflicts
   are resolved per the owning lane skill's rebase rule; green → restore
   state and record the rebase; red → blocked. Skip in-flight branches
   with a running background implementation — that lap's review step 6
   picks them up.
6. Reply to the human with the merge report: the merged commit, the
   post-merge verify outcome (step 2), and which branches were rebased
   (step 5).

## On failure

- **Unexpected test red**: never blessed away, never fixed by bending
  agreed values. Facts to the ticket log, blocked.
- **Subagent crash or timeout**: retry once; still failing → blocked.
- **Completion notification never arrived** (the 1800 s fallback wakeup
  resumed you): check whether the background task is alive. Dead → retry
  once as above; still running → re-arm the 1800 s fallback and wait.
- **Nothing resumed you after a report turn** (the harness's idle wakeup
  did not fire): the human's next message re-enters the loop, and the lap
  position is on the ticket.
- **in-flight ticket with no branch** (crash trace): return it to
  loop-ready. Branch exists → assess its state, continue or blocked.

## Ending the turn and pacing

Under self-paced `/loop`, arm a wakeup (a `ScheduleWakeup` call) matching
the state each time the turn ends, except the two turns below that arm
none:

- Waiting on background work (delegation, verification): the completion
  notification is the primary signal; arm a 1800 s fallback wakeup
- Only awaiting-human / blocked: recheck every 30 minutes
- Nothing at all: every 30 minutes

A turn that carries a human-facing reply — the step 8 report, the merge
report (merge step 6) — arms nothing:

1. Finish the step's tool work: ticket-log append, lap log, evidence copy.
2. Write the reply as the turn's last output.
3. Call nothing after it, `ScheduleWakeup` included.

The loop resumes on the harness's idle wakeup (about 20 minutes later), a
completion notification, or the human's reply; that turn arms the pacing
again and, when loop-ready tickets remain, picks the next one at once.
The ticket log stays the durable copy of every report.

A turn that stops the loop arms nothing and releases the lease.

One-shot runs (outside `/loop`) arm no wakeups; the reply rule applies
unchanged, and the resume signals are the completion notification and the
present human (rationale for all of the above in [design.md](design.md)).

## Related files

| File | Role |
|---|---|
| [config.example.toml](config.example.toml) | host config schema (values only) |
| [lane-protocol.md](lane-protocol.md) | the lane test, the lane-skill contract, and the script/skill split — how a host adds a pattern lane |
| [scripts/lease.sh](scripts/lease.sh) | session-exclusion mechanics (exit codes above) |
| [design.md](design.md) | decisions and rationale behind this procedure |
| dev-cycle skill (this plugin) | the development cycle the lap projects |
