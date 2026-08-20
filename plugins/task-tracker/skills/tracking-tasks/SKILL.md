---
name: tracking-tasks
description: Manages project tasks using a TSV-based tracker. Use when discovering bugs, improvements, or issues during testing/development, or when asked to track, list, or update tasks.
---

# Task Tracker

A lightweight task/ticket tracker using TSV files for efficient context-aware task management.

## CLI Location

```
${CLAUDE_PLUGIN_ROOT}/scripts/task.sh <command> [options]
```

## Commands

| Command | Usage | Description |
|---------|-------|-------------|
| `init` | `task.sh init` | Initialize `.tasks/` in the current working directory (idempotent; the only command that creates it) |
| `add` | `task.sh add -s "Subject" [-c category] [-b blocked-by] [-r related] [-d "Details"]` | Add a new task |
| `list` | `task.sh list [--status <status>\|active\|all] [--category cat]` | List tasks (default: active = all but closed; any other value filters that exact status) |
| `show` | `task.sh show <id>` | Show task metadata + details |
| `update` | `task.sh update <id> [-s subject] [-c cat] [--status status] [-b blocked-by] [-r related] [-d details] [-a text]` | Update fields (`-d` replaces the entire details text; `-a`/`--append-details` appends to it, separated by a blank line — use this for progress notes) |
| `close` | `task.sh close <id> [-d "Comment"]` | Close a task |
| `delete` | `task.sh delete <id>` | Delete a task |

## Categories

Use standard categories to classify tasks:
- `bug` — Defects or broken behavior
- `improvement` — Enhancements to existing features
- `task` — General work items (default)

## Relations

Two optional columns let the `list` view convey priority without opening each task:

- `BLOCKED_BY` (`-b`/`--blocked-by`) — IDs of tasks this one is waiting on. Stored in this single direction (not the inverse `blocks`) so a row shows what holds it back at a glance.
- `RELATED` (`-r`/`--related`) — IDs of loosely related tasks.

Both take comma-separated IDs (e.g. `-b "1,2"`). On `update` the value **replaces** the field — pass the full set. References are kept loose: IDs are not validated and dangling references after a `delete` are left as-is (they behave as memo notes, not enforced links).

## Workflow

### When you discover an issue during testing or development:

1. **Add** the task:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/task.sh add -s "Button click handler not firing" -c bug -d "The onClick handler on the submit button in ContactForm.astro does not trigger. Likely a naming mismatch."
   ```

2. **List** open tasks to review:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/task.sh list
   ```

3. **Show** task details before working on it:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/task.sh show 1
   ```

4. **Close** after fixing:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/task.sh close 1 -d "Fixed: renamed handler to match the event attribute"
   ```

### When asked to review or manage tasks:

- List all tasks: `task.sh list --status all`
- Filter by category: `task.sh list --category bug`
- Update a task: `task.sh update 3 -s "Updated subject" -c improvement`

## Error Handling

All commands exit with non-zero status and print an error message on failure. Common cases:

- **Not initialized**: every command except `init` fails if `.tasks/` is missing under the current working directory — `cd` to the project root and retry (or run `task.sh init` for a new project)
- **Task not found**: `show`, `update`, `close`, `delete` fail if the ID does not exist
- **Missing required arguments**: `add` requires `-s`; `show`/`update`/`close`/`delete` require an ID
- **Already closed**: `close` fails if the task is already closed

No special recovery is needed — read the error message and retry with corrected arguments.

## Data Storage

Tasks are stored in `.tasks/`, resolved relative to the **current working directory** — run commands from the project root. Only `init` creates the directory; every other command fails when it is missing, so a command run in the wrong directory cannot plant a stray `.tasks/`. The directory holds:

- `.tasks/tasks.tsv` — Tab-separated metadata (ID, STATUS, CATEGORY, SUBJECT, CREATED, UPDATED, BLOCKED_BY, RELATED)
- `.tasks/details/<id>.md` — Detailed descriptions per task

The TSV format allows efficient filtering with standard tools (`grep`, `awk`) without reading the entire file into context. Older 6-column TSV files (created before the relation columns existed) are migrated to 8 columns automatically on the next command.
