# decision-queue

Keeps every judgment awaiting the user visible in the statusline: Claude
appends a line to a per-session queue file when a decision starts waiting on
you and deletes it when you answer; the bundled renderer shows the whole list
under the input box, and stays silent while nothing is pending.

## Prerequisites

- `jq` on PATH (both the hooks and the renderer parse their stdin JSON with it)

## Setup (one-time)

Two settings, both in your user settings file (`~/.claude/settings.json`).
A Claude Code plugin can ship only the `agent` and `subagentStatusLine`
settings keys — never `permissions`, `sandbox`, or `statusLine` — so these
stay yours to add, once, and they take effect at the next session start.

### 1. Allow writes to the queue directory

```json
"permissions": {
  "allow": ["Edit(~/.claude/decision-queue/**)"]
}
```

Without it, every queue update stops and asks: with the Bash sandbox on,
appending a line fails with `Read-only file system` and Claude has to ask
you to run it unsandboxed; the file-editing tools prompt each time under
`acceptEdits`. This one rule opens both paths — it permits Edit / Write on
the directory outright, and `~/.claude/decision-queue` joins the Bash
sandbox's write-allow list (check it with `/sandbox`). The queue lives
under your home rather than in a project, so the rule belongs in user
settings, not a project's.

### 2. Register the statusline

1. Install and enable the plugin.
2. Start one session — the SessionStart hook creates the stable path
   `~/.claude/decision-queue/statusline.sh`.
3. Add to the same settings file:

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
2. Remove the `statusLine` key and the `Edit(~/.claude/decision-queue/**)`
   allow rule from your settings.
3. Delete `~/.claude/decision-queue/`.
