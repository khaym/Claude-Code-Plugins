---
name: verify
description: Runs {project}'s full verification suite on a tree (worktree or main checkout) - {net summary, e.g. "unit tests, lint, type check"} - and reports green, or each failing net's name with its output. The gnome loop's verify slot. Use when you hear "run the verification suite", "検証一式", or when the gnome loop reaches a verify step.
---

# verify ({project}'s verification suite)

Input: the tree root to verify (worktree or main checkout). Everything runs
from that root. If the root is not runnable as a {toolchain} project
({e.g. the build manifest is missing or the toolchain cannot start}),
report that fact **as a red, by name** — never as green.

The nets, run in order by name:

| Net | Command | Green condition |
|---|---|---|
| {net-name} | `{command}` | {e.g. exit 0} |

Report shape:

- Per net: `<net name>: green / red`.
- A red always keeps: the exit code, the failing test or check name, and
  the expected-vs-actual difference. Everything else may be summarized.

No judgment:

- Interpreting a red (expected? a policy to apply? a stop?) belongs to lane
  skills and the ticket. verify reports facts only.
- Never weaken an expectation, snapshot, or fixture to make a net pass.
