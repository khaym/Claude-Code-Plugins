---
name: observe
description: Produces the evidence a human reviews for a {project} change - {evidence summary, e.g. "screenshots of the changed pages, captured API responses"} - and supplies the run instructions for the awaiting-human report. The gnome loop's observe slot. Use when you hear "collect evidence", "証拠を集めて", or when the gnome loop reaches its evidence step.
---

# observe ({project}'s evidence and run instructions)

Input: the tree root and the ticket's target (the content or behavior to
show).

## Evidence

- How to produce it: {the command(s) that drive the change and capture
  its visible result}
- Where it lands: {path under the tree root, e.g. work/captures/<name>/}
- What the report includes: the evidence paths, and which part of the
  ticket's target each piece covers. If evidence cannot be produced,
  report that fact — never substitute stale or unrelated captures.

## Run instructions (include in every awaiting-human report)

How a human runs the built change safely — {sandboxing, test data,
flags that keep real data untouched}:

```bash
{run command}
```

{Notes the human needs: what state to expect on startup, how to reach the
ticket's target quickly, what is safe to discard afterwards.}
