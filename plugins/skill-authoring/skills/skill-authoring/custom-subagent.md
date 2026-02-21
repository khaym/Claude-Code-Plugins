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

## Definition File Structure

Placement:
- `.claude/agents/` — Project scope (shareable with team)
- `~/.claude/agents/` — User scope (available across all projects)

```markdown
---
name: my-agent
description: Agent description (used by Claude for delegation decisions)
tools: Read, Bash, Grep, Glob
model: haiku
maxTurns: 10
---

System prompt content goes here.
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

Details: https://docs.claude.ai/en/docs/sub-agents
