#!/bin/bash
# Send notification via wsl-relay HTTP API
# Usage: notify.sh <title> <body> <icon>
#
# Environment variables:
#   WSL_RELAY_HOST  - wsl-relay host (default: host.docker.internal)
#   WSL_RELAY_PORT  - wsl-relay port (default: 9400)

RELAY_HOST="${WSL_RELAY_HOST:-host.docker.internal}"
RELAY_PORT="${WSL_RELAY_PORT:-9400}"

TITLE="${1:-Claude Code}"
BODY="${2:-Notification}"
ICON="${3:-info}"

curl -s --connect-timeout 2 -X POST \
  "http://${RELAY_HOST}:${RELAY_PORT}/api/v1/notify" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg t "$TITLE" --arg b "$BODY" --arg i "$ICON" \
    '{title: $t, body: $b, icon: $i}')" \
  >/dev/null 2>&1

exit 0
