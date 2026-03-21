# Skill Creation & Review Guidelines

Shared reference for both the creation workflow and the review workflow.

## Table of Contents

- [Skill Design Principles](#skill-design-principles) — Why skill-ify / Context design / Composition
- [Agent Skills Standard Rules](#agent-skills-standard-rules) — Frontmatter / Naming / Structure / Content / Workflow
- [Recommended Practices](#recommended-practices) — design.md / File naming conventions

---

## Skill Design Principles

Understand these principles before diving into formatting rules. They guide the "purpose" and design criteria for good skills.

### Why Skill-ify

| Purpose | Description |
|---------|-------------|
| **Efficiency for repeated tasks** | Define procedures and decision criteria in a skill to eliminate per-invocation instruction cost |
| **Accuracy through context separation** | Use SubAgents or `context: fork` to limit context, keeping the agent focused on the task without extraneous information |
| **Main session longevity** | Offload skill execution context from the main session so the user can continue interacting with Claude |

If a task doesn't meet any of these three purposes, direct instructions are better than skill-ifying.

### Context Design

Skills and SubAgents are also **tools for designing context**. Keep these principles in mind:

**Control input context**: Minimize the information a skill reads
- The 500-line limit for SKILL.md and the 1-level reference depth rule stem from this principle
- Pass only necessary information to SubAgents

**Control in-process context**: Don't waste context on intermediate data
- Perform data fetching and transformation in scripts; pass only results to Claude
- Don't ask the LLM to format or reshape large datasets

**Control output context**: Be mindful of data volume returned to the main session
- SubAgent results should be reported concisely
- Return summaries, not raw data

### Execution Pattern Selection

There are several context separation methods. Choose the optimal pattern based on requirements:

| Pattern | Context | Mechanism | Best for |
|---------|---------|-----------|----------|
| **Main session** | Shared | Runs directly in the main conversation | Frequent interaction, iterative refinement, quick changes |
| **Skill (context: fork)** | Forked from main | Skill's `context: fork` for branched execution | Independent work while referencing main context |
| **Built-in SubAgent** | Fully isolated | Delegate to built-in agents via Task tool. No setup needed | One-off research or data retrieval |
| **Custom SubAgent** | Fully isolated + custom | Agent definition file in `.claude/agents/` or `<plugin>/agents/` | Repeatedly executed specialized tasks |

**Built-in SubAgent**: Claude Code's built-in agents (Explore, Plan, general-purpose, Bash, etc.). Instantly usable via the Task tool. However, delegation rules must be written in CLAUDE.md, consuming main session context.

**Custom SubAgent**: A dedicated agent defined as a YAML-frontmatter Markdown file in `.claude/agents/` (or `<plugin>/agents/` for plugin distribution). The `description` field handles delegation criteria, so no CLAUDE.md entry is needed. See [custom-subagent.md](custom-subagent.md) for details.

> **Plugin note**: `context: fork` may not work reliably in plugins. Use Custom SubAgents for context isolation in plugins. See [plugin-structure.md](plugin-structure.md).

**Selection flow**:

1. Does it require interactive back-and-forth with the user? → **Main session**
2. Need to reference main context while isolating context cost? → **context: fork**
3. Will it be executed repeatedly?
   - No → **Built-in SubAgent** (delegate to general-purpose etc. via Task tool)
   - Yes → **Custom SubAgent** (define in `.claude/agents/`. [Details](custom-subagent.md))

### Skill Composition

When multiple context-isolated agents share domain knowledge (design principles, review criteria, coding standards), two naive approaches create maintenance burden:

| Approach | Risk |
|---|---|
| **Duplication** | Content drift — copies diverge silently over time |
| **Cross-reference** (Skill B cites "Skill A Section 3") | Structural coupling — reorganization breaks dependents |

**Principle: Single Source of Truth + Dependency Injection**

- Shared knowledge is owned by **one skill** (the source of truth)
- Each agent declares which skills it needs via the `skills` frontmatter field
- The agent runtime preloads all declared skills at startup
- Skills remain **self-contained modules** with no inter-skill references

Skills are independently modifiable because no skill depends on another skill's internal structure. Agents are the composition layer.

---

## Agent Skills Standard Rules

Rules required for Claude to recognize and execute Agent Skills.

### Frontmatter

| Field | Rule |
|-------|------|
| `name` | Lowercase, hyphen-separated, max 64 characters |
| `description` | Max 1024 characters, written in third person, includes trigger phrases |
| Trigger phrases | Include multiple phrases a user might say to invoke the skill |

**Exception: Do not add frontmatter to skills used exclusively by Custom SubAgents.** When a Custom SubAgent references a skill as a procedure document (via Read), adding frontmatter would also register it as a user-facing Skill. This causes the `description` to compete with the agent's own description, potentially routing user instructions to the Skill (main session) instead of the SubAgent, breaking context separation.

### Naming

- Directory names and `name` values: kebab-case (lowercase hyphen-separated)
- Gerund form recommended: `processing-pdfs`, `checking-slack`
- Use specific, searchable names

### File Structure

| Rule | Details |
|------|---------|
| Entry point | `SKILL.md` (uppercase) |
| Line limit | SKILL.md must be **500 lines or fewer** |
| Reference depth | **1 level max** (SKILL.md → reference file; no further nesting) |
| Long files | Include a table of contents (TOC) at the top |
| Path notation | Use **relative paths** between files within a skill (`[guidelines.md](guidelines.md)`) |

### Content Principles

- **Conciseness**: Include only what's necessary. Avoid verbose explanations
- **Consistent terminology**: Use the same word for the same concept throughout (e.g., don't mix "report" and "summary" for the same output)
- **Avoid time-dependent language**: Don't use "latest", "current", etc. Use specific versions or dates instead
- **Narrow choices**: When multiple approaches exist, present one default and mention alternatives only for specific conditions
- **Self-contained**: Do not reference another skill's internal structure (section numbers, headings)

### Freedom Level Design

Calibrate how prescriptive each step should be based on the nature of the task:

| Level | Style | When to use | Example |
|-------|-------|-------------|---------|
| **High** | Text instructions only | Multiple valid approaches, context-dependent decisions | Code review procedures, writing guides |
| **Medium** | Pseudocode, parameterized templates | Recommended pattern exists but some variation is acceptable | Report generation templates, API call patterns |
| **Low** | Concrete scripts, fixed commands | Operations are fragile, consistency is essential, specific steps must be followed | DB migrations, deploy procedures |

**Rule of thumb**: The greater the impact of getting a step wrong, the lower the freedom level should be.

**Content patterns** to choose based on freedom level:
- **Template pattern**: Define output format (medium–low freedom)
- **Example pattern**: Show input/output pairs to demonstrate expected quality (high–medium)
- **Branching pattern**: Define decision flows for situational judgment (high)

### Workflow Design

- Use checklists to ensure quality
- Build in feedback loops (execute → verify → correct)
- Include error handling procedures
- **Goal integrity**: Even when a step fails, the skill must not act contrary to its purpose. Example: If data retrieval fails, don't generate a report with stale data that gives a false "all clear" — explicitly report the failure instead

---

## Recommended Practices

Best practices that improve skill quality. These are not mandatory but strongly encouraged.

### design.md

Creating a `design.md` alongside each skill is recommended. It documents design rationale and makes the skill easier to review and maintain.

Recommended sections:

| Section | Content |
|---------|---------|
| `## Purpose` | The problem this skill solves |
| `## Design Decisions` | Decisions and rationale in table format |
| `## Data Flow` | Input → Processing → Output flow |
| `## Constraints & Tradeoffs` | Known limitations and compromises |

### File Naming Conventions

Recommended naming patterns for scripts and output files:

| Type | Pattern | Example |
|------|---------|---------|
| Directory | kebab-case | `gmail-invoice-check/` |
| Result data | `{prefix}_result.json` | `slack_result.json` |
| Report | `{prefix}_report.md` | `jira_report.md` |
| Script | `{prefix}_{verb}.py` | `gmail_fetch.py` |
