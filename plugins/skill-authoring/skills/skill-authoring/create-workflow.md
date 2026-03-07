# Skill Creation Workflow

Step-by-step process for creating a new skill.
See [guidelines.md](guidelines.md) for shared rules.

---

## Table of Contents

1. [Requirements Gathering](#1-requirements-gathering)
2. [Execution Pattern Selection](#2-execution-pattern-selection)
3. [Create design.md](#3-create-designmd)
4. [Structure Design](#4-structure-design)
5. [Write SKILL.md](#5-write-skillmd)
6. [Script Implementation](#6-script-implementation)
7. [Quality Check](#7-quality-check)
8. [Test & Report](#8-test--report)

---

## 1. Requirements Gathering

Collect the following from the user:

- **Purpose**: What to automate or assist with
- **Triggers**: How they want to invoke it (→ trigger phrases for `description`)
- **Input**: What's needed (API keys, config values, user input, `$ARGUMENTS`)
- **Output**: What to return (report, files, interactive response)
- **Frequency**: How often it will be used (→ informs execution pattern selection)
- **Expected behavior**: What should happen in normal and error cases (→ becomes test criteria)

If information is missing, present choices and confirm with the user.

## 2. Execution Pattern Selection

Follow the selection flow in [guidelines.md](guidelines.md) to determine the optimal execution pattern:

1. **Main session**: Interactive back-and-forth is central (e.g., skill-authoring itself)
2. **Skill (context: fork)**: Independent work while referencing main context
3. **Built-in SubAgent**: One-off research or data retrieval
4. **Custom SubAgent**: Repeatedly executed specialized tasks (e.g., slack-check, jira-check)

If Custom SubAgent is selected:
- Refer to [custom-subagent.md](custom-subagent.md) to consider design options (tool restrictions, model selection, memory, etc.)
- **Determine whether to separate skills**: If the agent has only one procedure, embed it directly in agent.md (no skill needed). Only create separate skills when the agent uses multiple interchangeable procedures
- If Custom SubAgent is chosen, read the remaining steps with these adjustments:
  - Step 3: Create design.md inside the agent directory
  - Step 4: Design the agent subdirectory structure
  - Step 5: If no skill is needed, write the procedure directly in agent.md

## 3. Create design.md

Solidify the design before writing structure or code. Create `design.md` first.

```markdown
# {skill-name} Design Doc

## Purpose
[1-2 sentences describing the problem this skill solves]

## Design Decisions
| Decision | Rationale |
|----------|-----------|
| [Decision 1] | [Rationale 1] |
| [Decision 2] | [Rationale 2] |

## Data Flow
[Describe the input → processing → output flow]

## Constraints & Tradeoffs
- [Constraint 1]
- [Constraint 2]
```

### Patterns to Consider During Design

Evaluate whether these patterns apply and record decisions in design.md.

**Token optimization** (for skills that fetch external data and generate reports):

When fetching external data to generate reports, having Claude read all raw data wastes context. Perform filtering and format conversion in scripts wherever possible, passing only minimal data to Claude. When responding to the main session, avoid returning full datasets — minimize context waste.

Key techniques:
- Generate Markdown reports in scripts; SubAgent reads only the report
- Don't use LLMs for data formatting (handle it in scripts)
- Direct API calls are more token-efficient than MCP for data retrieval

**Credential file placement** (for skills using external APIs):

To prevent credential leaks (git inclusion, AI training data exposure), store credentials outside the skill directory:
- Location: `~/.<name>_token` or `~/.<name>_credentials.json`
- Permissions: `chmod 600`
- Never hardcode credentials in the skill

Share the design with the user and get alignment before proceeding.

## 4. Structure Design

Based on design.md's data flow and decisions, determine the directory structure.

### A. Custom SubAgent (subdirectory pattern)

```
.claude/agents/{agent-name}/
├── agent.md      # Agent definition + procedure (required)
├── design.md     # Design document
├── fetch.py      # Script (if needed)
└── report.md     # Output file (if needed)
```

For plugin distribution, use `<plugin-root>/agents/` instead of `.claude/agents/`. See [plugin-structure.md](plugin-structure.md).

- Write the system prompt and procedure directly in agent.md
- Place scripts and output files in the same directory as the agent
- Only separate skills into `.claude/skills/` when the agent uses multiple interchangeable procedures

### B. Skill (main session / context: fork)

```
.claude/skills/{skill-name}/
├── SKILL.md      # Entry point (required)
└── design.md     # Design document (recommended)
```

### Additional files as needed

| Type | When to add | Example |
|------|-------------|---------|
| Reference `.md` | When SKILL.md gets too long; separate workflows, guidelines | `guidelines.md`, `workflow.md` |
| Script `.py` / `.sh` | External API calls, data processing, validation | `{prefix}_fetch.py`, `validate.sh` |
| Template | When output format should be fixed | `report_template.md` |

References from SKILL.md are limited to 1 level. If files proliferate, organize with subdirectories like `scripts/`.

### Considerations

- **Content patterns**: Refer to "Freedom Level Design" in guidelines.md and choose the appropriate pattern
- **Dynamic context injection**: If runtime external data is needed, consider using `` `!`command` `` syntax

### Naming

- Directory names: Follow naming rules in guidelines.md
- `name` value should match the directory name

## 5. Write SKILL.md

### Frontmatter

```yaml
---
name: {skill-name}
description: {Third-person description + trigger phrases}
---
```

Description tips:
- Describe functionality in third person ("Checks...", "Generates...", "Assists with...")
- Include phrases users might say to invoke the skill
- Max 1024 characters

**Note**: If the skill is exclusively for a Custom SubAgent, do not add frontmatter (see [guidelines.md](guidelines.md) frontmatter section).

### Body structure

1. Skill name and overview
2. Add elements as needed:

| Element | When to add |
|---------|-------------|
| Execution steps (numbered) | When the skill involves scripts or commands |
| Intent detection rules | When routing to multiple workflows |
| Reference file list | When auxiliary files exist |
| Setup instructions | When first-time setup (credentials, etc.) is needed |
| Troubleshooting | When common errors are anticipated |

## 6. Script Implementation

> Skip this step if the skill doesn't need scripts.

Implement according to the design decisions from Step 3. Script roles vary by skill (data retrieval, transformation, validation, etc.). Follow the context design principles and minimize data volume passed to Claude.

## 7. Quality Check

Evaluate all items in [checklist.md](checklist.md).

- Rate each item as OK / NG / N/A
- Fix all NG items before proceeding to the next step
- Consult the user if a rating is unclear

## 8. Test & Report

### Verification

- Compare against expected behaviors defined in Step 1 (normal and error cases)
- If scripts exist, run them standalone to verify no errors
- Confirm the skill triggers on expected phrases
- Confirm it works correctly in the selected execution pattern
- If a Custom SubAgent specifies a model, verify behavior on that model
- Confirm context consumption is not excessive

### Report to user

Upon completion, report:
- List of created files
- How to invoke the skill (trigger phrases)
- Setup steps if applicable
