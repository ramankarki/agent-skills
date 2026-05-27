#!/usr/bin/env bash
# Usage: ./scrape.sh <url>
# scrape.sh — fetch a dynamic page, extract main content as clean markdown, index it
# Goal: produce AI-friendly output (readable, stripped of boilerplate, clean markdown)
# Uses: lightpanda (fetch), Mozilla Readability (content extraction), turndown (HTML→MD)
# Called by: read-cache.sh (on miss), update-cache.sh (refresh all)

set -euo pipefail

# ── config ────────────────────────────────────────────────────────────────────
URL="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/pages"
INDEX_FILE="$SCRIPT_DIR/pages/index.json"

# ── validate ──────────────────────────────────────────────────────────────────
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

mkdir -p "$OUTPUT_DIR"

# ── ensure dependencies ────────────────────────────────────────────────────────
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
echo "[scrape] fetching: $URL" >&2
RAW_HTML=$(lightpanda fetch \
  --dump html \
  --strip-mode js \
  --wait-until networkidle \
  "$URL" 2>/dev/null) || {
  echo "Error: lightpanda fetch failed for $URL" >&2
  exit 1
}

# ── extract main content with Mozilla Readability ──────────────────────────────
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

CLEAN_MD=$(echo "$RAW_HTML" | NODE_PATH="$NODE_PATH" node "$EXTRACT_SCRIPT" "$URL" 2>/dev/null)
rm -f "$EXTRACT_SCRIPT"

if [[ -z "$CLEAN_MD" ]]; then
  echo "Error: Readability extraction failed for $URL" >&2
  exit 1
fi

# ── check for existing entry ─────────────────────────────────────────────────
EXISTING_FILENAME=""
if [[ -f "$INDEX_FILE" ]]; then
  EXISTING_FILENAME=$(jq -r --arg url "$URL" \
    '.[] | select(.url == $url) | .filename' "$INDEX_FILE" 2>/dev/null || echo "")
fi

# ── store (reuse existing filename or create new) ──────────────────────────────
if [[ -n "$EXISTING_FILENAME" ]]; then
  FILENAME="$EXISTING_FILENAME"
  FILEPATH="${OUTPUT_DIR}/${FILENAME}"
  echo "$CLEAN_MD" > "$FILEPATH"
  echo "[scrape] updated → $FILEPATH" >&2
else
  UUID=$(uuidgen | tr 'A-Z' 'a-z')
  FILENAME="${UUID}.md"
  FILEPATH="${OUTPUT_DIR}/${FILENAME}"
  echo "$CLEAN_MD" > "$FILEPATH"
  echo "[scrape] saved → $FILEPATH" >&2
fi

# ── update index ──────────────────────────────────────────────────────────────
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "[]" > "$INDEX_FILE"
fi

if [[ -n "$EXISTING_FILENAME" ]]; then
  jq --arg url "$URL" \
     --arg ts "$TIMESTAMP" \
     'map(if .url == $url then .updated_at = $ts else . end)' \
     "$INDEX_FILE" > "${INDEX_FILE}.tmp" && mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
  echo "[scrape] index: entry updated" >&2
else
  jq --arg url "$URL" \
     --arg fn "$FILENAME" \
     --arg ts "$TIMESTAMP" \
     '. += [{"url": $url, "filename": $fn, "updated_at": $ts}]' \
     "$INDEX_FILE" > "${INDEX_FILE}.tmp" && mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
  echo "[scrape] index: new entry added" >&2
fi

# ── output filepath for caller ────────────────────────────────────────────────
echo "$FILEPATH"
