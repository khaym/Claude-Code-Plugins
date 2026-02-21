---
description: Close a task
---

Close a task by setting its status to closed.

Parse `$ARGUMENTS` to extract the task ID and optional closing comment.

Run:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/task.sh close <id> [-d "comment"]
```

Examples:
- `/task-tracker:close 1` → `task.sh close 1`
- `/task-tracker:close 3 Fixed by updating the config` → `task.sh close 3 -d "Fixed by updating the config"`

If the user provides text after the ID, treat it as a closing comment and pass it with `-d`.

Show the output to the user.
