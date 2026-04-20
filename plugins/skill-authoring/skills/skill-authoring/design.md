# skill-authoring Design Doc

## Purpose

Standardize skill quality by providing structured workflows for both creation and review. Prevents knowledge silos by encoding best practices into a reusable, auditable process.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Interactive skill (no SubAgent) | Both creation and review require file writes, making interactive main-session execution essential |
| `disable-model-invocation: false` (default) | Should auto-trigger on phrases like "create a skill" |
| SKILL.md as Navigation Hub | Progressive disclosure: detect intent first, then route to the appropriate workflow |
| guidelines.md as shared reference | Eliminates duplication between creation and review; single point of update when rules change |
| Standard rules vs. recommended practices separated | Distinguishes mandatory requirements from optional best practices; makes the skill portable across projects |
| Checklist with category grouping | Standard rules and recommended practices grouped by letter code ensure coverage while making applicability clear |
| plugin-structure.md added | Plugin packaging is a natural next step after skill/agent creation; guides standalone-to-plugin conversion and marketplace distribution |
| Interface clarity as Workflow Design principle | Ambiguous boundary values (SubAgent params, script args, return values) are a frequent failure source; explicit format/type specification prevents miscommunication |
| Memory Integrity as Recommended Practice | Skills must be self-contained — not rely on user auto-memory for correct execution; reconciliation workflow prevents silent coupling between skills and memory |

## Data Flow

```
User input ("create a skill" / "review skill")
  ↓
SKILL.md: Intent detection
  ↓
guidelines.md (load shared rules)
  ↓
[Create] create-workflow.md    [Review] review-workflow.md
  ↓                              ↓
Execute workflow                Execute workflow
  ↓                              ↓
checklist.md quality check      checklist.md evaluation
  ↓                              ↓
Output (new skill)              Review report + improvements
```

## Constraints & Tradeoffs

- Standard rules in guidelines.md are a snapshot of official documentation; manual updates are needed if official rules change. Source references:
  - https://code.claude.com/docs/en/skills
  - https://code.claude.com/docs/en/sub-agents
  - https://code.claude.com/docs/en/plugins
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Interactive-only — cannot be automated via SubAgent since user involvement is always required
- Checklist aims for "necessary and sufficient" — exhaustive coverage would make it impractical to use
