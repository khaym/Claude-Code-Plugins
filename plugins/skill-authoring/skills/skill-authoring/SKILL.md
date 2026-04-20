---
name: skill-authoring
description: Assists with creating and reviewing Claude Code Agent Skills. Use when you hear "create a skill", "new skill", "review skill", "skill quality check", or "automate this as a skill".
---

# Skill Authoring

Create and review skills using standardized processes.

## Intent Detection

Select the appropriate workflow based on user intent:

| Intent | Example triggers | Reference |
|--------|-----------------|-----------|
| **New creation** | "create a skill", "new skill", "automate this" | [create-workflow.md](create-workflow.md) |
| **Review / improve** | "review skill", "quality check", "audit skill" | [review-workflow.md](review-workflow.md) |
| **Rule lookup** | "skill rules", "guidelines" | [guidelines.md](guidelines.md) |

Ask the user to clarify if intent is ambiguous.

## Reference Files

| File | Content | When to reference |
|------|---------|-------------------|
| [guidelines.md](guidelines.md) | Shared guidelines (standard rules + best practices) | Both creation and review |
| [create-workflow.md](create-workflow.md) | 8-step creation process | New skill creation |
| [review-workflow.md](review-workflow.md) | 6-step review process | Skill review |
| [checklist.md](checklist.md) | Quality checklist (standard rules + recommended practices) | Final check in creation, evaluation in review |
| [custom-subagent.md](custom-subagent.md) | Custom SubAgent definition reference | When creating or evaluating Custom SubAgents |
| [plugin-structure.md](plugin-structure.md) | Plugin packaging and distribution | When packaging skills/agents as a plugin |

## Notes

- Both creation and review require file writes, so this skill runs interactively in the main session (not delegated to a SubAgent)
- `guidelines.md` is the foundation for all workflows — always reference it before starting creation or review
