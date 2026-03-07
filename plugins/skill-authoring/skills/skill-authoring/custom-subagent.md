# Custom SubAgent Reference

How to define dedicated agents when Built-in SubAgents are insufficient.

## Comparison with Built-in SubAgents

| Aspect | Built-in SubAgent | Custom SubAgent |
|--------|-------------------|-----------------|
| Definition | Not needed (delegate via Task tool) | Markdown file in `.claude/agents/` |
| Tool restriction | Not possible (depends on agent type) | Fine-grained control via `tools` / `disallowedTools` |
| Model selection | Not possible (inherit or type-fixed) | Specify `haiku` / `sonnet` / `opus` via `model` |
| System prompt | Only the Task tool's `prompt` parameter | Full Markdown body serves as system prompt |
| Persistent memory | None | `memory` for cross-session knowledge |
| MCP servers | Not possible | Specify via `mcpServers` |
| Permission mode | Inherits from parent | Custom via `permissionMode` |
| Lifecycle hooks | None | `hooks` for pre/post tool validation |

**When to consider Custom SubAgents**:
- Need to restrict available tools (e.g., read-only agents)
- A low-cost, fast model is sufficient for routine tasks
- Domain knowledge should be embedded in the system prompt
- Cross-session learning is needed (`memory`)

## Directory Structure

Custom SubAgents use a **subdirectory pattern**. Keep scripts, output files, and other resources alongside the agent definition.

```
.claude/agents/<agent-name>/
├── agent.md          # Agent definition + procedure (required)
├── design.md         # Design document
├── fetch.py          # Script (if needed)
├── report.md         # Output file (if needed)
└── cache.json        # Cache etc. (if needed)
```

Placement scopes:
- `.claude/agents/` — Project scope (shareable with team)
- `~/.claude/agents/` — User scope (available across all projects)
- `<plugin-root>/agents/` — Plugin scope (distributed via marketplace). See [plugin-structure.md](plugin-structure.md)

**Warning: Do not place `.venv` inside the agent directory.** Markdown files inside Python packages (licenses, etc.) interfere with agent discovery and can prevent the agent from being recognized. If a venv is needed, place it at `.claude/venvs/<agent-name>/` instead.

### Skill vs SubAgent Decision

| Condition | Approach |
|-----------|----------|
| Agent has only one procedure | **Embed directly in agent.md** (no skill needed) |
| Agent uses multiple interchangeable procedures | Separate into skills in `.claude/skills/` and reference via `skills` field |

**Why not create a skill for single-procedure agents:** Embedding the procedure directly in agent.md is simpler (fewer files to manage) and ensures the procedure is included as part of the system prompt. A separate SKILL.md adds file management overhead and is only warranted when the agent needs multiple interchangeable procedures.

**Multiple skills example**: A `developer` agent that has `coding-skill` and `testing-skill`, switching between them based on the task. In this case, separate them as skills without frontmatter (agent-exclusive) and place in `.claude/skills/`.

## Agent Definition File

```markdown
---
name: my-agent
description: Agent description (used by Claude for delegation decisions)
tools: Read, Bash, Grep, Glob
model: haiku
maxTurns: 10
---

System prompt and procedure go here.
```

## Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier (lowercase hyphen-separated) |
| `description` | Yes | Description used by Claude for delegation decisions |
| `tools` | No | List of allowed tools (inherits all if omitted) |
| `disallowedTools` | No | List of prohibited tools |
| `model` | No | `sonnet` / `opus` / `haiku` / `inherit` (default: `inherit`) |
| `permissionMode` | No | `default` / `acceptEdits` / `dontAsk` / `bypassPermissions` / `plan` |
| `maxTurns` | No | Maximum turns (prevents runaway execution) |
| `skills` | No | Skill names to preload at startup |
| `mcpServers` | No | MCP servers to use |
| `memory` | No | Persistent memory scope (`user` / `project` / `local`) |
| `hooks` | No | Lifecycle hooks (PreToolUse, PostToolUse, Stop) |

Details: https://code.claude.com/docs/en/sub-agents
