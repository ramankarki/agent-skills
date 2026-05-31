#!/usr/bin/env bash
# Usage: ./scrape-url.sh <url>
# Fetch dynamic page, extract main content as markdown, index it

# Cron-friendly PATH: lightpanda, node, npm, jq
export PATH="/Users/raman/.local/bin:/Users/raman/.nvm/versions/node/v24.15.0/bin:/usr/bin:/bin"

set -euo pipefail

# ── config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/pages"
INDEX_FILE="$SCRIPT_DIR/pages/index.json"

# Source shared functions
source "$SCRIPT_DIR/lib.sh"

# ── validate ──────────────────────────────────────────────────────────────────
URL="${1:-}"
if [[ -z "$URL" ]]; then
  echo "Usage: $0 <url>" >&2
  exit 1
fi

for dep in lightpanda jq node; do
  if ! command -v "$dep" &>/dev/null; then
    echo "Error: '$dep' not found in PATH" >&2
    exit 1
  fi
done

NORMALIZED_URL=$(normalize_url "$URL")
mkdir -p "$OUTPUT_DIR"

# ── ensure node dependencies ──────────────────────────────────────────────────
NODE_PATH=""
if [[ -d "$SCRIPT_DIR/node_modules" ]]; then
  NODE_PATH="$SCRIPT_DIR/node_modules"
else
  echo "[scrape] installing @mozilla/readability..." >&2
  cd "$SCRIPT_DIR"
  npm install --silent @mozilla/readability jsdom turndown 2>/dev/null
  NODE_PATH="$SCRIPT_DIR/node_modules"
fi

# ── fetch with lightpanda ─────────────────────────────────────────────────────
RAW_HTML=$(lightpanda fetch \
  --dump html \
  --strip-mode js \
  --wait-until networkidle \
  "$NORMALIZED_URL" 2>/dev/null) || {
  echo "Error: lightpanda fetch failed for $NORMALIZED_URL" >&2
  exit 1
}

# ── extract content with Mozilla Readability ───────────────────────────────────
EXTRACT_SCRIPT=$(mktemp)
cat > "$EXTRACT_SCRIPT" << 'ENDOFSCRIPT'
const { Readability } = require('@mozilla/readability');
const { JSDOM } = require('jsdom');
const fs = require('fs');
const TurndownService = require('turndown');

const html = fs.readFileSync('/dev/stdin', 'utf8');
const doc = new JSDOM(html, { url: process.argv[2] || 'about:blank' });
const reader = new Readability(doc.window.document);
const article = reader.parse();

if (!article) {
  console.error('Error: Could not extract article content');
  process.exit(1);
}

const turndown = new TurndownService({ headingStyle: 'atx', bulletListMarker: '-' });
console.log('# ' + article.title + '\n');
console.log(turndown.turndown(article.content));
ENDOFSCRIPT

CLEAN_MD=$(echo "$RAW_HTML" | NODE_PATH="$NODE_PATH" node "$EXTRACT_SCRIPT" "$NORMALIZED_URL" 2>/dev/null)
rm -f "$EXTRACT_SCRIPT"

if [[ -z "$CLEAN_MD" ]]; then
  echo "Error: Readability extraction failed for $NORMALIZED_URL" >&2
  exit 1
fi

# ── check for existing entry ─────────────────────────────────────────────────
EXISTING_FILENAME=""
if [[ -f "$INDEX_FILE" ]]; then
  EXISTING_FILENAME=$(get_cached_filename "$INDEX_FILE" "$NORMALIZED_URL")
fi

# ── store ─────────────────────────────────────────────────────────────────────
if [[ -n "$EXISTING_FILENAME" ]]; then
  FILENAME="$EXISTING_FILENAME"
else
  FILENAME="$(uuidgen | tr 'A-Z' 'a-z').md"
fi
FILEPATH="${OUTPUT_DIR}/${FILENAME}"
echo "$CLEAN_MD" > "$FILEPATH"

# ── update index ──────────────────────────────────────────────────────────────
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ensure_index "$INDEX_FILE"
update_index "$INDEX_FILE" "$NORMALIZED_URL" "$FILENAME" "$TIMESTAMP" "$EXISTING_FILENAME"

# ── output filepath for caller ────────────────────────────────────────────────
echo "$FILEPATH"
