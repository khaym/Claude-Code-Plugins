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
| `add` | `task.sh add -s "Subject" [-c category] [-b blocked-by] [-r related] [-p parent] [-d "Details"]` | Add a new task |
| `list` | `task.sh list [--status <status>\|active\|all] [--category cat]` | List tasks (default: active = all but closed; any other value filters that exact status) |
| `show` | `task.sh show <id>` | Show task metadata + details |
| `update` | `task.sh update <id> [-s subject] [-c cat] [--status status] [-b blocked-by] [-r related] [-p parent] [-d details] [-a text]` | Update fields (`-d` replaces the entire details text; `-a`/`--append-details` appends to it, separated by a blank line — use this for progress notes) |
| `close` | `task.sh close <id> [-d "Comment"]` | Close a task |
| `delete` | `task.sh delete <id>` | Delete a task |

## Categories

Use standard categories to classify tasks:
- `bug` — Defects or broken behavior
- `improvement` — Enhancements to existing features
- `task` — General work items (default)

## Relations

Three optional columns let the `list` view convey structure and priority without opening each task:

- `BLOCKED_BY` (`-b`/`--blocked-by`) — IDs of tasks this one is waiting on. Stored in this single direction (not the inverse `blocks`) so a row shows what holds it back at a glance.
- `RELATED` (`-r`/`--related`) — IDs of loosely related tasks. A pointer between peers: it carries **no** parent/child meaning — use `PARENT` for that.
- `PARENT` (`-p`/`--parent`) — the single ID of the task this one belongs to (a child ticket split out of a larger story). The parent is read from the child's own row, like `BLOCKED_BY`; a task's children are found by scanning the `PARENT` column of `list`. `show` is a single-ticket view: it prints the ticket's own parent and does not list children.

`-b`/`-r` take comma-separated IDs (e.g. `-b "1,2"`); `-p` takes one ID. On `update` the value **replaces** the field — pass the full set. References are kept loose: IDs are not validated and dangling references after a `delete` are left as-is (they behave as memo notes, not enforced links).

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

## Writing the tracker files

- Change the index (`tasks.tsv`) and the counter (`.counter`) only through `task.sh` — `add`, `update`, `close`, `delete`. Reading the index directly with `grep` or `awk` is fine.
- Edit the details (`details/<id>.md`) by hand when that is easier than `update -d` or `-a`.
- The bundled hook refuses a Claude session's hand writes to the index and the counter, and names the `task.sh` subcommand to use instead. It is a guard rail, not a lock: it covers the common write shapes — Bash redirection, `tee`, `sed -i`, the `mv`/`cp` destination, and the Edit and Write tools. Other writers pass, and the next `add` catches a counter they leave behind.

## Error Handling

All commands exit with non-zero status and print an error message naming the cause on failure: correct the arguments, or follow the recovery it prints, and retry. Common cases:

- **Not initialized**: every command except `init` fails if `.tasks/` is missing under the current working directory — `cd` to the project root and retry (or run `task.sh init` for a new project)
- **Task not found**: `show`, `update`, `close`, `delete` fail if the ID does not exist
- **Missing required arguments**: `add` requires `-s`; `show`/`update`/`close`/`delete` require an ID
- **Already closed**: `close` fails if the task is already closed
- **Counter behind the index, missing, or not a number**: `add` fails, adds nothing, and prints an `echo <id> > <project>/.tasks/.counter` command (absolute path), with a note on deleted IDs when the counter is missing or not a number. Show the command and the note to the user, who runs it in their own terminal; then retry the `add`

## Data Storage

Tasks are stored in `.tasks/`, resolved relative to the **current working directory** — run commands from the project root. Only `init` creates the directory; every other command fails when it is missing, so a command run in the wrong directory cannot plant a stray `.tasks/`. The directory holds:

- `.tasks/tasks.tsv` — the index: tab-separated metadata (ID, STATUS, CATEGORY, SUBJECT, CREATED, UPDATED, BLOCKED_BY, RELATED, PARENT)
- `.tasks/.counter` — the counter: the last ID handed out; `add` takes the next number
- `.tasks/details/<id>.md` — the details: the description of each task

The index's TSV format allows efficient filtering with standard tools (`grep`, `awk`) without reading the entire file into context. Older TSV files (6 columns before the relation columns existed, 8 before `PARENT`) are migrated to 9 columns automatically on the next command, with every existing value kept. Rows narrower than the header are widened too, so rows appended by an older installed copy of the script are repaired on the next command.
