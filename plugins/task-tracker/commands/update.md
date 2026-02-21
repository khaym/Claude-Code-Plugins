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
- `--status open|closed` — Update the status
- `-d "New details"` — Update/replace the details

Examples:
- `/task-tracker:update 1 -s "New title"` → `task.sh update 1 -s "New title"`
- `/task-tracker:update 3 -c bug --status closed` → `task.sh update 3 -c bug --status closed`

Show the output to the user.
