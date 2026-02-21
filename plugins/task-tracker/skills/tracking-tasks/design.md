# tracking-tasks Design Doc

## Purpose

Provide a human-readable, project-scoped task tracker that both Claude and humans can operate on directly. The built-in Task List (`Ctrl+T`) manages work steps internally and can persist across sessions via `CLAUDE_CODE_TASK_LIST_ID`. task-tracker complements it by storing tasks in TSV and Markdown files that humans can read, edit, and process with standard shell tools (`grep`, `awk`).

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| TSV + Markdown format | TSV for metadata (fast filtering with `awk`/`grep`); Markdown for details (human-friendly, no parsing overhead) |
| Shell script CLI | Zero dependencies; runs anywhere Bash is available; keeps data processing out of LLM context |
| Main session execution | Task tracking happens inline during development; requires access to the conversation flow to decide what to track |
| Skill + Commands separation | Skill (`tracking-tasks`) enables proactive auto-tracking; Commands (`add`, `list`, etc.) give users direct control via slash commands |
| `.tasks/` in project root | Tasks are project-scoped and co-located with code; gitignored by default |
| Auto-init on first use | `ensure_init` removes setup friction; users don't need to run `init` explicitly |

## Data Flow

```
User or Claude (discovers issue / invokes command)
  ↓
Slash command (commands/*.md) or Skill (SKILL.md)
  ↓
task.sh (shell script)
  ├── Read/write .tasks/tasks.tsv (metadata)
  └── Read/write .tasks/details/<id>.md (details)
  ↓
Plain-text output → displayed to user / consumed by Claude
```

## Constraints & Tradeoffs

- **No concurrent access handling** — TSV read-modify-write is not atomic; safe for single-user CLI use but not for parallel processes
- **Flat ID namespace** — Monotonic counter; no support for hierarchical or cross-project references
- **gitignored by default** — Tasks don't travel with the repo; this is intentional (project-local scratchpad) but means tasks are lost if `.tasks/` is deleted
- **No search/full-text** — Finding tasks requires `list` with filters or `show` by ID; sufficient for small-to-medium task counts
