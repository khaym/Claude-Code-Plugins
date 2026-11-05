# tracking-tasks Design Doc

## Purpose

Provide a human-readable, project-scoped task tracker that both Claude and humans can operate on directly. The built-in Task List (`Ctrl+T`) manages work steps internally and can persist across sessions via `CLAUDE_CODE_TASK_LIST_ID`. task-tracker complements it by storing tasks in TSV and Markdown files that humans can read directly and process with standard shell tools (`grep`, `awk`). The index and counter change only through `task.sh`; the details stay hand-editable.

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
| Append relation columns at the end | Keeps existing column indices (1–6) stable so the field accessors and pre-relation TSV files keep working; `migrate_schema` pads older files to the current 9 columns on next use |
| `PARENT` as a single-ID column, children derived by scanning it | The question a child's row must answer is "what does this belong to?", read from its own row like `BLOCKED_BY`. A `CHILDREN` column would hold the inverse and force the full-table scan that the `BLOCKED_BY` decision above avoids; scanning the `PARENT` column of `list` recovers the children when they are actually wanted |
| `migrate_schema` triggers on any short line, not the header | An older *installed* copy of the script can run against the same file and keeps appending rows of its own width after the header is already current; a header-only check would leave those rows short forever |
| `task.sh` is the sole writer of the index (`tasks.tsv`) and the counter (`.counter`) | It keeps IDs, the column count, and `UPDATED` consistent, and only `add` advances the counter. A row added by hand leaves the counter behind, and the next `add` hands out an ID a row already has (observed: a hand-appended row led to two tickets with one ID) |
| Details (`details/<id>.md`) stay hand-editable | They are free prose, and `update -d` only replaces the whole text, so a partial rewrite is safer as a direct edit. A hand edit of the details does not bump the row's `UPDATED` |
| A bundled PreToolUse hook as a guard rail, not a lock | It refuses a Claude session's writes to the index and counter in the common write shapes (Edit/Write; Bash redirection, `tee`, `sed -i`, the `mv`/`cp` destination) and names the `task.sh` subcommand to use instead. Bash is judged by write shapes, never by a file name appearing, so reads and `task.sh` calls pass. Other writers pass by design and a hook that cannot parse its input allows the call: the next `add` catches what slips through. Parsing details live in the hook script's docstring |
| No `if` filter on the hook handler | Observed in a real session (Claude Code 2.1.318): a `Bash(*tasks.tsv*)` `if` pattern does not see redirect targets, so `printf ... >> tasks.tsv` (the shape of the observed incident) never starts the hook, and `Edit(**/.tasks/.counter)` did not match a Write to `.counter`. Filtering would skip exactly the writes the hook exists for; the hook runs on every Edit, Write, and Bash call instead (about 30 ms each) |
| `add` refuses a lagging counter rather than repairing it | Numbering trusts the counter. A counter behind the highest ID in the index, missing while the index has rows, or not a number means something wrote outside `task.sh`; `add` writes nothing, so the filer learns of it before a duplicate ID exists. The fix is a human's: the error prints the `echo <id> > <project>/.tasks/.counter` command (absolute path) for their own terminal, since the hook blocks it from a Claude session. For a missing or unreadable counter the highest index ID is only a lower bound (tickets above it may have been deleted), so the error adds that the last ID handed out is the value to use then |

## Data Flow

```
User or Claude (discovers issue / invokes command)
  ↓
Slash command (commands/*.md) or Skill (SKILL.md)
  ↓
task.sh (shell script)
  ├── Read/write .tasks/tasks.tsv (index: metadata)
  ├── Read/write .tasks/.counter (counter: checked against the index before add writes)
  └── Read/write .tasks/details/<id>.md (details)
  ↓
Plain-text output → displayed to user / consumed by Claude

Claude session's own Edit / Write / Bash call
  ↓
PreToolUse hook (hooks/hooks.json → tracker-write-guard.py)
  ├── index or counter written in a common write shape → denied, task.sh subcommand named
  └── anything else → allowed
```

## Constraints & Tradeoffs

- **No concurrent access handling** — TSV read-modify-write is not atomic; safe for single-user CLI use but not for parallel processes
- **Hand writes are caught, not prevented** — the hook covers a Claude session's common write shapes only; human edits and other writers pass, and the counter they leave behind is detected at the next `add`, which a human then fixes
- **Flat ID namespace** — Monotonic counter; no cross-project references
- **Relations are loose, single-direction notes** — `BLOCKED_BY`/`RELATED` (comma-separated) and `PARENT` (single ID) are unvalidated; the inverse direction (`blocks`, children) is not derived or displayed, cycles are not detected, and dangling references after a `delete` are not cleaned up
- **gitignored by default** — Tasks don't travel with the repo; this is intentional (project-local scratchpad) but means tasks are lost if `.tasks/` is deleted
- **No search/full-text** — Finding tasks requires `list` with filters or `show` by ID; sufficient for small-to-medium task counts
