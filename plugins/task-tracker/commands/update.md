---
description: Update fields of an existing task
---

Update one or more fields of a task.

Parse `$ARGUMENTS` to extract the task ID and field updates. The first argument should be the task ID, followed by field flags.

Run:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/task.sh update <id> [flags]
```

Available flags:
- `-s "New subject"` — Update the subject
- `-c "category"` — Update the category
- `--status <status>` — Update the status. Values are free-form (e.g. `open`, `closed`, or workflow states like `loop-ready`); `closed` hides the task from the default `list`, and `active`/`all` are reserved as `list` filter keywords
- `-b "1,2"` / `--blocked-by` — Replace the blocked-by IDs (comma-separated; pass the full set)
- `-r "5"` / `--related` — Replace the related IDs (comma-separated; pass the full set)
- `-d "New details"` — Replace the details: the existing text is overwritten entirely, not merged. To keep any of the current details, include them in the new text

Examples:
- `/task-tracker:update 1 -s "New title"` → `task.sh update 1 -s "New title"`
- `/task-tracker:update 3 -c bug --status closed` → `task.sh update 3 -c bug --status closed`
- `/task-tracker:update 2 -b "1,4"` → `task.sh update 2 -b "1,4"`

Show the output to the user.
