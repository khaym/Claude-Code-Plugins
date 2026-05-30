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

If the user mentioned dependencies or related tasks, record them with comma-separated IDs. `-b`/`--blocked-by` lists the tasks this one is waiting on; `-r`/`--related` lists loosely related tasks:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/task.sh add -s "Subject" -b "1,2" -r "5"
```

Show the output to the user after running.
