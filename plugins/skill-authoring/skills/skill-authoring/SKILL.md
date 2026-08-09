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

The audit belongs to the `skill-review` Custom SubAgent (isolated context, preloads this skill via its `skills:` field); the main session consumes its findings report and implements improvements:

1. **Invoke the `skill-review` agent** (when installed via plugin, subagent type `skill-authoring:skill-review:skill-review`) with the skill directory path (and the MEMORY.md path if memory integrity should be checked; omitted, the M checks rate N/A). If the agent reports it could not read the target, resolve the path with the user — do not continue with a partial audit.
2. **Present the findings report to the user.** Lead with the verdict line and the Critical findings; keep the agent's priorities, do not re-triage silently.
3. **Agree on improvements.** Each finding names a proposed direction; where a direction allows multiple concrete fixes, confirm the choice before writing.
4. **Implement approved fixes in the main session.** Rewrite affected sections rather than patching — see "Coherence after updates" in [guidelines.md](guidelines.md).
5. **Re-verify.** Re-run `skill-review` and confirm the addressed NG items now rate OK. Report any remaining or newly surfaced findings.

## Reference Files

| File | Content | When to reference |
|------|---------|-------------------|
| [guidelines.md](guidelines.md) | Shared guidelines (standard rules + recommended practices) | Both creation and review |
| [create-workflow.md](create-workflow.md) | 8-step creation process | New skill creation |
| [checklist.md](checklist.md) | Quality checklist (standard rules + recommended practices) | Final check in creation, evaluation in review |
| [custom-subagent.md](custom-subagent.md) | Custom SubAgent definition reference | When creating or evaluating Custom SubAgents |
| [plugin-structure.md](plugin-structure.md) | Plugin packaging and distribution | When packaging skills/agents as a plugin |
