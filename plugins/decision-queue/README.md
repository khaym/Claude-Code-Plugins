# decision-queue

Keeps every judgment awaiting the user visible in the statusline: Claude
appends a line to a per-session queue file when a decision starts waiting on
you and deletes it when you answer; the bundled renderer shows the whole list
under the input box, and stays silent while nothing is pending.

## Prerequisites

- `jq` on PATH (both the hooks and the renderer parse their stdin JSON with it)

## Setup (one-time)

Claude Code plugins cannot ship a `statusLine` setting, so register it once:

1. Install and enable the plugin.
2. Start one session — the SessionStart hook creates the stable path
   `~/.claude/decision-queue/statusline.sh`.
3. Add to a settings file (e.g. `~/.claude/settings.json`):

   ```json
   "statusLine": {
     "type": "command",
     "command": "~/.claude/decision-queue/statusline.sh"
   }
   ```

Register the stable path, never the versioned plugin cache path. The hook
re-links it to the installed plugin version at every session start, so after
a plugin update the registration heals at the next session start (a session
already running when the old version's files disappear shows a blank
statusline until then).

`statusLine` holds a single command — if you already run a statusline,
registering this one replaces it. To keep both, register a small wrapper that
feeds the same stdin to each:

```json
"statusLine": {
  "type": "command",
  "command": "bash -c 'in=$(cat); your-statusline <<<\"$in\"; ~/.claude/decision-queue/statusline.sh <<<\"$in\"'"
}
```

## Cleanup behavior

A session's queue file is deleted when that session ends (`/clear`, logout,
exit). Resuming a session keeps its session id, so its queue survives
`--resume` / `--continue`. Files from sessions that died without the
SessionEnd hook firing are deleted once untouched for over 30 days.

## Uninstall

1. Disable or uninstall the plugin first — while it is enabled, the
   SessionStart hook recreates the directory and symlink on every session.
2. Remove the `statusLine` key from your settings.
3. Delete `~/.claude/decision-queue/`.
