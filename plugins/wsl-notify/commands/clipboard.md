---
description: Captures clipboard image from Windows host via wsl-relay
---

Fetch the current clipboard image from the Windows host and display it.

Run the clipboard capture script:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/clipboard.sh
```

If the script succeeds, it prints the saved file path. Read that file using the Read tool to display the image to the user.

If the script fails:
- HTTP 403: clipboard operation may be disabled in wsl-relay config
- HTTP 500: no image data in clipboard — ask the user to copy an image first
- Connection refused: wsl-relay is not running — suggest starting it on the Windows host
