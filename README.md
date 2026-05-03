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

Context design framework for Claude Code [Agent Skills](https://code.claude.com/docs/en/skills). Claude's performance depends on the context it receives — this plugin provides principles and workflows for designing skills that give Claude the right information at the right time.

**Core principles:**
- **Context Design** — Control what enters, flows through, and exits each skill's context to maximize Claude's accuracy
- **Execution Pattern Selection** — Choose the optimal isolation level (main session, context:fork, Built-in/Custom SubAgent) for each task
- **Skill Composition** — When multiple agents share domain knowledge, use the `skills` field for Dependency Injection rather than duplicating content or creating fragile cross-references
- **Quality Checklist** — 28-item evaluation across 6 categories (Context Design, Structure, Frontmatter, Content, design.md, Scripts)

**Workflows:**
- **Creation**: Requirements → Pattern Selection → Design → Structure → Implementation → Quality Check → Test
- **Review**: Load → Compare Against Guidelines → Checklist Evaluation → Improvement Proposals → Report

**Usage:**

```
Create a new skill for checking Slack notifications
Review the task-tracker skill
What are the skill authoring guidelines?
```

### checking-oss-release

Checks open source projects for security leaks, privacy issues, and license compliance before release. Can also set up git pre-commit hooks.

**Features:**
- Three modes: Setup (install pre-commit hook), Quick (staged files check), Full (all files audit)
- Secret pattern detection (API keys, private keys, AWS credentials, GitHub tokens, etc.)
- Git email privacy check (noreply enforcement)
- .gitignore coverage validation
- Dependency license compatibility scan with license matrix
- THIRD_PARTY_LICENSES attribution check
- Bundled pre-commit hook script

**Usage:**

```
Run an OSS release check
Setup pre-commit hooks for security
Quick security check on staged files
Full pre-release audit
```

### designing-test-cases

Guides systematic test case design using established testing techniques. Works with any tech stack and is TDD-compatible (test-first, driven by specs and types rather than implementation).

**Features:**
- Two workflows: New test design and existing test review (gap analysis)
- Seven test design techniques: Equivalence Partitioning, Boundary Value Analysis, Null/Undefined Handling, Type Mismatch, State Transition, Combination/Interaction, Error/Exception
- Produces structured test case matrices (technique × input × expected result)
- Detailed technique reference with rules, checklists, and examples

**Usage:**

```
Design test cases for the login function
Are these tests enough? Review test coverage
What boundary values should I test?
```

### hardening-dev-environment

Layered defense for a development environment running Claude Code. Each layer addresses a distinct attack class — npm supply chain compromise, prompt-injection-driven scope escalation, credential exfiltration, persistence via config tampering, indirect injection from fetched content. Layers compose: static config prevents, runtime hooks catch known bypasses, the trust-boundary reminder shapes how fetched content is interpreted.

**Layered Defense Map:**

| # | Layer | Owner | Threats addressed |
|---|-------|-------|-------------------|
| 1 | Static `permissions.{deny, ask, allow}` rules | `hardening-claude-permissions` | Persistence (config writes), credential exfil (file reads), outbound exfil, plugin-authoring confirmation gate |
| 2 | Bundled runtime hooks (auto-active) | This plugin (`sensitive-bash-guard`, `package-json-scripts-guard`, `untrusted-content-reminder`) | Bash credential-read bypass, `package.json` `scripts` tampering, indirect prompt injection from `WebFetch` results |
| 3 | WebFetch trust discipline | `hardening-untrusted-content` | Indirect prompt injection — trust-boundary checklist + vendor allowlist that drives the PostToolUse hook |
| 4 | npm supply chain config | `hardening-pnpm-config` | Malicious package install / build-script execution / unpinned `npx` |
| 5 | Pre-commit secret scan | `checking-oss-release` plugin (sibling) | Plaintext secrets reaching commit-time |

Layer 2 hooks auto-activate when this plugin is enabled. The other layers are applied via their owner skill.

**Where to start:** ask Claude to *audit Claude Code hardening* — `hardening-overview` inspects the current state of each layer and recommends a setup order tailored to the project's plan tier and use case.

**Usage:**

```
Audit Claude Code hardening
```

### wsl-notify

Windows desktop notifications for Claude Code via [wsl-relay](https://github.com/khaym/wslconnector). Get notified when Claude finishes a task or needs permission — no more staring at the terminal.

**Features:**
- Auto-registered hooks — works immediately after install, no manual configuration
- **Stop** event → "Task completed" notification
- **Notification (permission_prompt)** event → "Permission required" notification
- Slash command: `/wsl-notify:test-notify` to verify connectivity
- Customizable via environment variables (`WSL_RELAY_HOST`, `WSL_RELAY_PORT`, message overrides)

**Prerequisites:**
- [wsl-relay](https://github.com/khaym/wslconnector) running on your Windows host

**Usage:**

```
/wsl-notify:test-notify
```

**Environment variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `WSL_RELAY_HOST` | `host.docker.internal` | wsl-relay host address |
| `WSL_RELAY_PORT` | `9400` | wsl-relay port |
| `WSL_NOTIFY_STOP_TITLE` | `Claude Code` | Stop notification title |
| `WSL_NOTIFY_STOP_BODY` | `Task completed` | Stop notification body |
| `WSL_NOTIFY_PERMISSION_TITLE` | `Claude Code` | Permission notification title |
| `WSL_NOTIFY_PERMISSION_BODY` | `Permission required` | Permission notification body |

## Installation

### Add the marketplace

```
# HTTPS (recommended — works without SSH key setup)
/plugin marketplace add https://github.com/khaym/Claude-Code-Plugins.git

# GitHub shorthand (requires SSH key configured for github.com)
/plugin marketplace add khaym/Claude-Code-Plugins
```

### Install a plugin

```
/plugin install task-tracker@khaym-claude-plugins
/plugin install skill-authoring@khaym-claude-plugins
/plugin install checking-oss-release@khaym-claude-plugins
/plugin install designing-test-cases@khaym-claude-plugins
/plugin install hardening-dev-environment@khaym-claude-plugins
/plugin install wsl-notify@khaym-claude-plugins
```

### Update

```
/plugin marketplace update khaym-claude-plugins
```


## Development setup

Contributing to this marketplace? After cloning, enable the bundled pre-commit hook:

```
git config core.hooksPath .githooks
```

This activates secret / git-email / .gitignore checks on every `git commit`, powered by the `checking-oss-release` plugin.


## License

MIT
