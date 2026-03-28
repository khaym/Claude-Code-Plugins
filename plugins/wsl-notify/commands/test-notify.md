---
description: Sends a test notification to verify wsl-relay connectivity
---

Send a test notification via wsl-relay to confirm the connection is working.

Run:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh "wsl-notify" "Test notification — connection OK" "info"
```

If the command succeeds silently, tell the user: "Test notification sent. Check your Windows desktop for the notification."

If curl fails or wsl-relay is unreachable, suggest:
1. Verify wsl-relay is running on the Windows host
2. Check `WSL_RELAY_HOST` and `WSL_RELAY_PORT` environment variables
3. Test connectivity: `curl -s http://${WSL_RELAY_HOST:-host.docker.internal}:${WSL_RELAY_PORT:-9400}/api/v1/health`
