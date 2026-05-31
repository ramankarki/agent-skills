#!/usr/bin/env bash
# Usage: ./read-url.sh <url>
# read-url.sh — output cached markdown content for URL, scrape if miss
# Always prints content to stdout

# Cron-friendly PATH: lightpanda, node, npm, jq
export PATH="/Users/raman/.local/bin:/Users/raman/.nvm/versions/node/v24.15.0/bin:/usr/bin:/bin"

set -euo pipefail

URL="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/pages"
INDEX_FILE="$SCRIPT_DIR/pages/index.json"
SCRAPE_SCRIPT="$SCRIPT_DIR/scrape-url.sh"

if [[ -z "$URL" ]]; then
  echo "Usage: $0 <url>" >&2
  exit 1
fi

# Check index for cached entry
if [[ -f "$INDEX_FILE" ]]; then
  CACHED_FILENAME=$(jq -r --arg url "$URL" \
    '.[] | select(.url == $url) | .filename' \
    "$INDEX_FILE" 2>/dev/null || echo "")

  if [[ -n "$CACHED_FILENAME" && -f "${OUTPUT_DIR}/${CACHED_FILENAME}" ]]; then
    cat "${OUTPUT_DIR}/${CACHED_FILENAME}"
    exit 0
  fi
fi

# Cache miss — scrape it
echo "[read-url] miss: $URL" >&2
FILEPATH=$("$SCRAPE_SCRIPT" "$URL")
cat "$FILEPATH"
