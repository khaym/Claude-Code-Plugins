---
name: skill-authoring
description: Assists with creating and reviewing Claude Code Agent Skills. Use when you hear "create a skill", "new skill", "improve this skill", or "automate this as a skill". For read-only audits, the skill-review agent is preferred.
---

# Skill Authoring

Create and review skills using standardized processes.

## Intent Detection

Select the appropriate workflow based on user intent:

| Intent | Example triggers | Reference |
|--------|-----------------|-----------|
| **New creation** | "create a skill", "new skill", "automate this" | [create-workflow.md](create-workflow.md) |
| **Review / improve** | "review skill", "quality check", "improve this skill" | [Review Flow](#review-flow) below |
| **Rule lookup** | "skill rules", "guidelines" | [guidelines.md](guidelines.md) |

Ask the user to clarify if intent is ambiguous.

## Review Flow

The audit belongs to the `skill-review` Custom SubAgent (isolated context, preloads this skill via its `skills:` field); the main session consumes its findings report and implements improvements.

**Review goal**: a session that loads the reviewed skill receives steps built on the context design principles and works as intended — which includes being loaded when it is needed. Each NG finding is judged against this goal, per finding rather than per check ID:

- **Blocking** — one sentence can state how the finding breaks the goal: in which situation a session that loads the skill does the wrong thing, or why the skill is not loaded when it is needed. Blocking findings keep the review going. **Critical** marks a blocking finding that makes the skill fail to load or run, or exposes a credential.
- **Note** — the check is violated, but no such sentence can be written. Notes never extend the review.

1. **Invoke the `skill-review` agent** (when installed via plugin, subagent type `skill-authoring:skill-review:skill-review`) with the skill directory path (and the MEMORY.md path if memory integrity should be checked; omitted, the M checks rate N/A). If the agent reports it could not read the target, resolve the path with the user — do not continue with a partial audit.
2. **Present the findings report to the user.** Lead with the verdict line and the blocking findings; keep the agent's judgment of blocking and notes, do not re-triage silently.
3. **Agree on improvements.** Each finding names a proposed direction; where a direction allows multiple concrete fixes, confirm the choice before writing. Fixing a note is the user's choice. The user may also judge a blocking finding not blocking; keep that judgment for the later rounds.
4. **Implement approved fixes in the main session.** Rewrite affected sections rather than patching — see "Coherence after updates" in [guidelines.md](guidelines.md).
5. **Re-review until nothing blocks the review goal.** Re-run `skill-review` on the whole skill and return to step 2. Stop when no blocking finding remains, counting as a note any blocking finding the user judged not blocking at step 3, even when the agent reports it again. The limit is three rounds — the first review and two re-reviews. When the third report still has blocking findings, do not implement them: stop the review, report to the user the remaining blocking findings and the blocking count per round, and ask how to proceed.

## Reference Files

| File | Content | When to reference |
|------|---------|-------------------|
| [guidelines.md](guidelines.md) | Shared guidelines (standard rules + recommended practices) | Both creation and review |
| [create-workflow.md](create-workflow.md) | 8-step creation process | New skill creation |
| [checklist.md](checklist.md) | Quality checklist (standard rules + recommended practices) | Final check in creation, evaluation in review |
| [custom-subagent.md](custom-subagent.md) | Custom SubAgent definition reference | When creating or evaluating Custom SubAgents |
| [plugin-structure.md](plugin-structure.md) | Plugin packaging and distribution | When packaging skills/agents as a plugin |
