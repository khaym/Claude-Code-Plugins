#!/bin/bash
# Fetch clipboard image from wsl-relay and save as PNG
# Usage: clipboard.sh [output_dir]
#
# Environment variables:
#   WSL_RELAY_HOST  - wsl-relay host (default: host.docker.internal)
#   WSL_RELAY_PORT  - wsl-relay port (default: 9400)

RELAY_HOST="${WSL_RELAY_HOST:-host.docker.internal}"
RELAY_PORT="${WSL_RELAY_PORT:-9400}"
OUTPUT_DIR="${1:-/tmp/wsl-clipboard}"

mkdir -p "$OUTPUT_DIR"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_FILE="${OUTPUT_DIR}/clipboard_${TIMESTAMP}.png"

HTTP_CODE=$(curl -s --connect-timeout 5 -o "$OUTPUT_FILE" -w "%{http_code}" \
  "http://${RELAY_HOST}:${RELAY_PORT}/api/v1/clipboard/image")

if [ "$HTTP_CODE" != "200" ]; then
  rm -f "$OUTPUT_FILE"
  echo "ERROR: Failed to fetch clipboard image (HTTP ${HTTP_CODE})" >&2
  exit 1
fi

# Verify it's actually a PNG (check bytes 1-3 for "PNG")
PNG_SIG=$(od -A n -t x1 -N 4 "$OUTPUT_FILE" 2>/dev/null | tr -d ' \n')
if [ "$PNG_SIG" != "89504e47" ]; then
  rm -f "$OUTPUT_FILE"
  echo "ERROR: Response is not a valid PNG image" >&2
  exit 1
fi

echo "$OUTPUT_FILE"
