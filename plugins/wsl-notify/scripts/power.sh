#!/bin/bash
# Control wsl-relay sleep inhibition
# Usage: power.sh inhibit|release
#
# `inhibit` acquires or renews the inhibit (idempotent POST); the relay
# auto-releases it when the TTL lapses, so a crashed session cannot keep
# the host awake. `release` ends it immediately.
#
# Environment variables:
#   WSL_RELAY_HOST           - wsl-relay host (default: host.docker.internal)
#   WSL_RELAY_PORT           - wsl-relay port (default: 9400)
#   WSL_NOTIFY_POWER_INHIBIT - set to "0" to disable sleep inhibition entirely
#   WSL_NOTIFY_POWER_TTL     - inhibit TTL in seconds (default: relay's default, 600)

[ "${WSL_NOTIFY_POWER_INHIBIT:-1}" = "0" ] && exit 0

RELAY_HOST="${WSL_RELAY_HOST:-host.docker.internal}"
RELAY_PORT="${WSL_RELAY_PORT:-9400}"
URL="http://${RELAY_HOST}:${RELAY_PORT}/api/v1/power/inhibit"

case "$1" in
  inhibit)
    if [ -n "${WSL_NOTIFY_POWER_TTL}" ]; then
      curl -s --connect-timeout 2 -X POST "$URL" \
        -H "Content-Type: application/json" \
        -d "{\"ttl_seconds\": ${WSL_NOTIFY_POWER_TTL}}" \
        >/dev/null 2>&1
    else
      curl -s --connect-timeout 2 -X POST "$URL" >/dev/null 2>&1
    fi
    ;;
  release)
    curl -s --connect-timeout 2 -X DELETE "$URL" >/dev/null 2>&1
    ;;
esac

exit 0
