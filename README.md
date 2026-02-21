# Claude Code Plugins

[日本語](README.ja.md)

A collection of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugins for development workflow.

## Plugins

### task-tracker

Lightweight task/ticket tracker using TSV files and shell scripts. While Claude Code's [built-in Task List](https://code.claude.com/docs/en/interactive-mode#task-list) automatically manages work steps internally, task-tracker stores tasks in TSV and Markdown files that humans can read and edit directly.

**Features:**
- Human-readable TSV + Markdown format (`.tasks/`)
- Slash commands: `/task-tracker:add`, `/task-tracker:list`, `/task-tracker:show`, `/task-tracker:update`, `/task-tracker:close`
- Categories: `bug`, `improvement`, `task`
- Includes a skill for Claude to automatically track issues found during development

**Usage:**

```
/task-tracker:add Fix login button not responding
/task-tracker:add bug: API returns 500 on empty payload
/task-tracker:list
/task-tracker:list all
/task-tracker:show 1
/task-tracker:update 1 -s "Updated title"
/task-tracker:close 1 Fixed by updating the handler
```

### skill-authoring

Guides creation and review of Claude Code [Agent Skills](https://code.claude.com/docs/en/skills) with standardized workflows and quality checklists.

**Features:**
- Intent-based routing: "create a skill" or "review skill" triggers the appropriate workflow
- 8-step creation workflow with execution pattern selection and token optimization guidance
- 6-step review workflow with checklist evaluation (27 items across 6 categories)
- Shared guidelines covering standard rules and recommended practices
- Custom SubAgent definition reference

**Usage:**

```
Create a new skill for checking Slack notifications
Review the task-tracker skill
What are the skill authoring guidelines?
```

## Installation

### Add the marketplace

```
/plugin marketplace add khaym/khaym-claude-plugins
```

### Install a plugin

```
/plugin install task-tracker@khaym-claude-plugins
/plugin install skill-authoring@khaym-claude-plugins
```

### Update

```
/plugin marketplace update khaym-claude-plugins
```


## License

MIT
