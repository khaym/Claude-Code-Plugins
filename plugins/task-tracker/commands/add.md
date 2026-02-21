---
description: Add a new task to the tracker
---

Add a new task using the task tracker CLI.

Run:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/task.sh add -s "$ARGUMENTS"
```

If the user specified a category prefix (e.g., "bug: subject here" or "improvement: subject here"), parse it and use the `-c` flag:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/task.sh add -c "bug" -s "subject here"
```

If the user provided additional details beyond the subject line, use the `-d` flag:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/task.sh add -s "Subject" -c "category" -d "Detailed description"
```

Show the output to the user after running.
