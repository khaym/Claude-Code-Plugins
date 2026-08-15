# implementer Design Doc

## Purpose

Run development-cycle stage 4 (TDD implementation) in an isolated context,
so planning and review stay in the delegating session and the
implementation loop's token cost stays off it. Bundled with the gnome-loop
plugin because the loop's novel lane depends on it; usable by any dialog
session delegating a planned ticket.

Method rationale is not restated here: the cycle and TDD discipline come
from the preloaded dev-cycle skill (see its design.md); the preload-guard
pattern's rationale lives in the gnome-loop skill's design.md.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| `model: opus` as the frontmatter default | Novel-lane work is the plugin's hardest implementation class; the default favors quality. Delegators downgrade or upgrade per ticket at invocation (`model` parameter) — the loop skill names this override explicitly. Note: a `CLAUDE_CODE_SUBAGENT_MODEL` env var silently overrides both. |
| Tools unrestricted | Stage 4 legitimately needs the full toolset (edit, run, search, background verification). Scope is bounded by the delegation contract (the tree, the checklist), not by tool denial. |
| Delegation contract in the agent body | The agent has two consumer classes — the loop's novel lane and ad-hoc dialog delegation. The loop skill's step 5 lists prompt requirements for its own laps, but dialog sessions never read that skill, so the agent itself names the minimum contract and asks for missing pieces instead of guessing. |
| An honest red is a valid completion | "Green before you report" alone pressures toward weakened expectations at an unattended gate. The stuck-exit (report red with observed facts, never weaken a net) keeps goal integrity when green is unreachable. |
| Report fields are a fixed contract | The delegator's review (stage 5) and the loop's lap log consume the report mechanically: checklist status for requirements-first review, verified-vs-hypothesis separation for trust, "rework during implementation" as lap-log input. |

## Data Flow

```
delegation prompt (tree path + goal & checklist + named verification)
  -> red → green → refactor inside the tree (method from dev-cycle preload)
  -> tests + lint + named verification
  -> completion report (files / checklist status / results / facts vs
     hypotheses / rework) → delegator reviews (stage 5)
```

## Constraints & Tradeoffs

- The agent never sees the tracker; the pasted checklist is its whole view
  of the ticket. Stale pastes are the delegator's responsibility.
- Review findings return via SendMessage to the same agent instance
  (context preserved); a dead agent means re-delegation with the same
  contract.
