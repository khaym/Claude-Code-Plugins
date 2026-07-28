---
description: List tasks from the tracker
---

List tasks using the task tracker CLI.

Parse `$ARGUMENTS` to determine the filter:
- Empty or no arguments → no flag (default: every status except closed)
- Any status value (e.g. `open`, `closed`, `loop-ready`) or `all` → `--status <value>`
- A category name can be passed with `--category`

Run:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/task.sh list $ARGUMENTS_PARSED
```

Examples:
- `/task-tracker:list` → `task.sh list`
- `/task-tracker:list all` → `task.sh list --status all`
- `/task-tracker:list closed` → `task.sh list --status closed`
- `/task-tracker:list --category bug` → `task.sh list --category bug`

Show the output to the user.
