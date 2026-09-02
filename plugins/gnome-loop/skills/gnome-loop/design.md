# gnome-loop Design Doc

## Purpose

Run the dev-cycle method's stages 4–5 as an autonomous lap over loop-ready
tickets, so human deliberation (filing, design approval, plan agreement,
merge approval) and AI implementation proceed in parallel. The skill holds
only the operating procedure; everything project-specific is injected
through slots so the loop runs unchanged in any host that meets the
prerequisites.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Lease mechanics live in a script | Acquire (atomic mkdir), heartbeat (mtime), staleness, and release are machine-decidable operations. Mechanical prose executed by an LLM every lap is a failure class of its own — one wrong extraction or path destroys exclusivity silently. The skill only branches on exit codes; the script's rules are pinned by `tests/plugins/gnome-loop/run.sh`. |
| Stale leases are reported, never taken | A stale mtime is a crash *trace*, not proof the session died. Takeover destroys a live session's exclusivity if the guess is wrong, so the script exits 3 and the human confirms (`release --force` + `acquire`) — the loop starts with a human present. |
| verify / observe are project skills, values are one config file | The two injection points carry judgment (how to read a red, what evidence shows the change, how a human runs it) — placement rule "procedures and judgment criteria → skill". Paths, limits, and glob lists carry no judgment — one TOML. Splitting them keeps the config honest and the skills improvable per project without touching the plugin. |
| Lane discovery via frontmatter `metadata.lane` | Unknown top-level frontmatter keys hard-fail skill packaging; the `metadata` field is the documented free-form map, so lane skills mark themselves `metadata: { lane: pattern }` and the loop greps for it. Adding a lane never touches the plugin or a correspondence table. |
| The lane contract lives in lane-protocol.md | The Two lanes section used to enumerate what the lap consumes from a lane skill, and the lane-creation protocol document would have restated it — one rule in two homes. The document owns the contract (lane-author side and loop side together); the lap's steps name each item at the point they consume it. |
| implementer preloads dev-cycle via `skills:` | The agent needs the method (TDD, observation-first, business rules) without depending on any host CLAUDE.md content beyond authority rules. A failed `skills:` preload only logs a debug warning, so the agent's body guards: no dev-cycle in context at startup → stop and report, never implement without the method. |
| Tracker resolved from the task-tracker plugin at runtime | The cache path changes with every plugin version; a glob + `sort -V` picks the newest. Hosts with a different tracker supply a script with the same interface at the same resolution or adjust the config — the state machine's statuses are plain strings the tracker stores verbatim. |
| Loop statuses are loop-written | The first dry run (2026-08-15) stopped at the pick gate because a dialog-driven ticket sat in-flight: out-of-loop work using the loop's status vocabulary collides with the in-flight count and the crash-trace recovery rule. Ruling: in-flight / awaiting-human are written only by the loop for work it carries; out-of-loop work stays open with ticket-log progress. |
| Ticket-log appends use a guarded read-modify-write | The tracker's `-d` is a full replace; an empty extraction plus `-d` silently destroys the ticket body (observed 2026-08-14). The skill pins the exact extraction and the non-empty guard. The round-trip disappears entirely when the tracker grows an append operation — filed as a tracker improvement. |
| The lap ends turns instead of waiting | Long waits (implementation, verification) block the session's turn, which is where merge approvals and user input get processed. Dispatch to background, note the position on the ticket, end the turn; notifications resume the lap. Wakeups are fallbacks, not the primary signal. |
| Human-facing replies end the turn with no tool call after them | A turn ending with `ScheduleWakeup` shows no text — before the call hidden, after it never produced (2026-08-22, 2026-08-29; anthropics/claude-code #74184) — so both orders are out, 0.3.2's reply-first too. The harness's idle wakeup, its ScheduleWakeup ~20 min after a turn that neither armed nor stopped, carries the lap on (scheduled-tasks docs, 2026-08-29). |
| Lap-log format and classes live in dev-cycle (since 0.4.0) | The classes name quality nets the cycle owns, and dialog laps write the same log; rationale in the dev-cycle design doc. The loop keeps only what no dialog lap has: the pattern lane's rework equivalence (stops, warnings, expected-vs-actual reds) and the mid-run no-self-rewrite constraint. |
| English body | Marketplace-wide convention; hosts choose their conversation language in their own CLAUDE.md. |

## Data Flow

```
human (dialog session): file → approve designs / agree values or plan → loop-ready
  -> loop lap: lease → pick → lane decision
       pattern: run the lane skill in a worktree
       novel:   delegate to implementer (plan checklist as the prompt)
  -> code-review (loop session, requirements first) → verify skill
  -> observe skill evidence → commit on the branch
  -> awaiting-human report (state class on line 1)
  -> lap log: classified observations (format: dev-cycle) → improvement tickets
human: deviation check → "#N merge OK"
  -> merge (ff-only) → verify on main → close → rebase queue
```

## Constraints & Tradeoffs

- **One loop session at a time.** Tracker status updates are not atomic
  and the checkout is shared; the lease enforces the agreed single-session
  design. Parallelism lives inside the session as worktrees, capped by
  config.
- **The loop never rewrites its own procedure, templates, or skills
  mid-run.** Improvements are tickets; stability of the running lap beats
  immediacy of the fix.
- **Slot quality bounds loop quality.** A verify skill that misses a net
  or an observe skill that shows the wrong thing degrades every lap; the
  lap log exists to surface exactly that class for freezing.
- **The loop reads tickets, not minds.** Judgment work not finished before
  loop-ready (per the lane skill's list or the plan checklist) surfaces as
  blocked, by design.
- **A report turn arms no wakeup, so the next lap's pickup waits for the
  harness's idle wakeup (~20 min) instead of the 60 s the loop would have
  armed.** Report scenarios were already paced at 30 minutes, so the cost
  lands inside the old budget. Awaiting-human and merge turns leave no
  background work, so that idle wakeup is the only signal a report turn
  gets. Fix issue #74184 and a report turn may arm its own wakeup again.
