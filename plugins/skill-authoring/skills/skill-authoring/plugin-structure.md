# Plugin Structure Reference

How to package skills and agents as a Claude Code plugin for distribution.

## Table of Contents

- [When to Use Plugins](#when-to-use-plugins)
- [Directory Structure](#directory-structure)
- [Plugin Manifest](#plugin-manifest)
- [Skills in Plugins](#skills-in-plugins)
- [Agents in Plugins](#agents-in-plugins)
- [Standalone to Plugin Conversion](#standalone-to-plugin-conversion)
- [Testing](#testing)
- [Distribution via Marketplace](#distribution-via-marketplace)

## When to Use Plugins

| Approach | Best for |
|----------|----------|
| Standalone (`.claude/`) | Personal workflows, project-specific, quick experiments |
| Plugin | Sharing with team/community, reusable across projects, versioned releases |

Start with standalone configuration, then convert to a plugin when ready to share.

## Directory Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest (required)
├── skills/               # Agent Skills (SKILL.md per skill)
│   └── my-skill/
│       ├── SKILL.md
│       └── design.md
├── agents/               # Custom SubAgents (agent.md per agent)
│   └── my-agent/
│       ├── agent.md
│       └── helper.sh
├── commands/             # Slash commands (Markdown files)
├── hooks/                # Event handlers (hooks.json)
├── .mcp.json             # MCP server configurations
├── .lsp.json             # LSP server configurations
└── settings.json         # Default settings
```

**Warning**: Do not place `skills/`, `agents/`, `commands/`, or `hooks/` inside `.claude-plugin/`. Only `plugin.json` goes inside `.claude-plugin/`.

## Plugin Manifest

`.claude-plugin/plugin.json`:

```json
{
  "name": "my-plugin",
  "description": "What this plugin does",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier and skill namespace prefix |
| `description` | Yes | Shown in plugin manager |
| `version` | Yes | Semantic versioning (major.minor.patch) |
| `author` | No | Attribution |

The `name` becomes the namespace prefix for skills: `/my-plugin:my-skill`.

## Skills in Plugins

Same structure as standalone `.claude/skills/`, placed at `<plugin-root>/skills/`.

```
my-plugin/skills/my-skill/SKILL.md
```

After installation, invoke as `/my-plugin:my-skill`.

## Agents in Plugins

Same structure as standalone `.claude/agents/`, placed at `<plugin-root>/agents/`.

```
my-plugin/agents/my-agent/agent.md
```

After installation, available via the Agent tool with subagent_type `my-plugin:my-agent:my-agent`.

**Note on context: fork**: The `context: fork` frontmatter in SKILL.md may not work reliably in plugins. Use Custom SubAgents for context isolation in plugins instead.

## Standalone to Plugin Conversion

1. Create `<plugin-dir>/.claude-plugin/plugin.json`
2. Copy `.claude/skills/` to `<plugin-dir>/skills/`
3. Copy `.claude/agents/` to `<plugin-dir>/agents/`
4. Copy hooks from `settings.json` to `<plugin-dir>/hooks/hooks.json`
5. Test with `claude --plugin-dir ./<plugin-dir>`

## Testing

Load locally without installation:

```bash
claude --plugin-dir ./my-plugin
```

Verify:
- Skills appear in `/help` under the plugin namespace
- Agents appear in `/agents`
- Hooks trigger as expected

## Distribution via Marketplace

### Marketplace manifest

`.claude-plugin/marketplace.json` at the repository root:

```json
{
  "name": "my-marketplace",
  "owner": { "name": "your-name" },
  "metadata": { "description": "Description" },
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./plugins/my-plugin",
      "description": "What it does",
      "version": "1.0.0"
    }
  ]
}
```

### Installation commands

```
/plugin marketplace add owner/repo-name
/plugin install my-plugin@repo-name
/plugin marketplace update repo-name
```

### Version Updates

1. Update `version` in both `plugin.json` and `marketplace.json`
2. Commit and push
3. Users run `/plugin marketplace update` to get the new version

Details: https://code.claude.com/docs/en/plugins
