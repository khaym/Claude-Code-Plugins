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
| implementer preloads dev-cycle via `skills:` | The agent needs the method (TDD, observation-first, business rules) without depending on any host CLAUDE.md content beyond authority rules. A failed `skills:` preload only logs a debug warning, so the agent's body guards: no dev-cycle in context at startup → stop and report, never implement without the method. |
| Tracker resolved from the task-tracker plugin at runtime | The cache path changes with every plugin version; a glob + `sort -V` picks the newest. Hosts with a different tracker supply a script with the same interface at the same resolution or adjust the config — the state machine's statuses are plain strings the tracker stores verbatim. |
| Loop statuses are loop-written | The first dry run (2026-08-15) stopped at the pick gate because a dialog-driven ticket sat in-flight: out-of-loop work using the loop's status vocabulary collides with the in-flight count and the crash-trace recovery rule. Ruling: in-flight / awaiting-human are written only by the loop for work it carries; out-of-loop work stays open with ticket-log progress. |
| Ticket-log appends use a guarded read-modify-write | The tracker's `-d` is a full replace; an empty extraction plus `-d` silently destroys the ticket body (observed 2026-08-14). The skill pins the exact extraction and the non-empty guard. The round-trip disappears entirely when the tracker grows an append operation — filed as a tracker improvement. |
| The lap ends turns instead of waiting | Long waits (implementation, verification) block the session's turn, which is where merge approvals and user input get processed. Dispatch to background, note the position on the ticket, end the turn; notifications resume the lap. Wakeups are fallbacks, not the primary signal. |
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
human: deviation check → "#N merge OK"
  -> merge (ff-only) → verify on main → close → rebase queue
  -> lap log: net-gap / net-miss / judgment / noise → improvement tickets
```

## Constraints & Tradeoffs

- **One loop session at a time.** Tracker status updates are not atomic
  and the checkout is shared; the lease enforces the agreed single-session
  design. Parallelism lives inside the session as worktrees, capped by
  config.
- **The loop never edits its own procedure mid-run.** Improvements are
  tickets; stability of the running lap beats immediacy of the fix.
- **Slot quality bounds loop quality.** A verify skill that misses a net
  or an observe skill that shows the wrong thing degrades every lap; the
  lap log exists to surface exactly that class for freezing.
- **The loop reads tickets, not minds.** Judgment work not finished before
  loop-ready (per the lane skill's list or the plan checklist) surfaces as
  blocked, by design.
