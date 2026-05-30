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
| Relations as TSV columns (not a separate edge table) | Keeps the "one index conveys the whole picture" property: `list` shows what blocks each task without opening details. A normalized `relations.tsv` would be cleaner for graph queries but splits the at-a-glance view |
| Store `BLOCKED_BY`, not `blocks` | The prioritization question is "what is this waiting on?", answerable from the row itself. The inverse (`blocks`) would force a full-table scan per row, defeating the at-a-glance goal |
| Single direction, loose integrity | Storing both directions would double the bookkeeping; relations are memo-style notes, so they are not validated or kept referentially consistent (see Constraints) |
| Append relation columns at the end | Keeps existing column indices (1–6) stable so the field accessors and pre-relation TSV files keep working; `migrate_schema` pads older files to 8 columns on next use |

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
- **Flat ID namespace** — Monotonic counter; no cross-project references
- **Relations are loose, single-direction notes** — `BLOCKED_BY`/`RELATED` are unvalidated comma-separated IDs; the inverse direction is not derived or displayed, and dangling references after a `delete` are not cleaned up
- **gitignored by default** — Tasks don't travel with the repo; this is intentional (project-local scratchpad) but means tasks are lost if `.tasks/` is deleted
- **No search/full-text** — Finding tasks requires `list` with filters or `show` by ID; sufficient for small-to-medium task counts
