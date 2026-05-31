#!/usr/bin/env bash
# Usage: ./read-url.sh <url>
# Output cached markdown content for URL, scrape if miss

# Cron-friendly PATH: lightpanda, node, npm, jq
export PATH="/Users/raman/.local/bin:/Users/raman/.nvm/versions/node/v24.15.0/bin:/usr/bin:/bin"

set -euo pipefail

# ── config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/pages"
INDEX_FILE="$SCRIPT_DIR/pages/index.json"
SCRAPE_SCRIPT="$SCRIPT_DIR/scrape-url.sh"

# Source shared functions
source "$SCRIPT_DIR/lib.sh"

# ── validate ──────────────────────────────────────────────────────────────────
URL="${1:-}"
if [[ -z "$URL" ]]; then
  echo "Usage: $0 <url>" >&2
  exit 1
fi

NORMALIZED_URL=$(normalize_url "$URL")

# ── check cache ───────────────────────────────────────────────────────────────
if [[ -f "$INDEX_FILE" ]]; then
  CACHED_FILENAME=$(get_cached_filename "$INDEX_FILE" "$NORMALIZED_URL")

  if [[ -n "$CACHED_FILENAME" && -f "${OUTPUT_DIR}/${CACHED_FILENAME}" ]]; then
    cat "${OUTPUT_DIR}/${CACHED_FILENAME}"
    exit 0
  fi
fi

# ── cache miss — scrape ───────────────────────────────────────────────────────
FILEPATH=$("$SCRAPE_SCRIPT" "$NORMALIZED_URL")
cat "$FILEPATH"
