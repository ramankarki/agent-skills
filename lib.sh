#!/usr/bin/env bash
# lib.sh — shared functions for URL scraping scripts

# ── url normalization ─────────────────────────────────────────────────────────
# Normalize URL: strip trailing slash from path (but keep query params intact)
# https://react.dev/ -> https://react.dev
# https://react.dev/?a=1 -> https://react.dev?a=1
normalize_url() {
  local url="$1"
  echo "$url" | sed -E 's|/\?|?|' | sed -E 's|/$||'
}

# ── index operations ─────────────────────────────────────────────────────────
# Ensure index file exists and is valid JSON
ensure_index() {
  local index_file="$1"
  if [[ ! -f "$index_file" ]] || [[ ! -s "$index_file" ]]; then
    echo "[]" > "$index_file"
  fi
}

# Get cached filename for URL (returns empty string if not found)
get_cached_filename() {
  local index_file="$1"
  local url="$2"
  jq -r --arg url "$url" \
    '.[] | select(.url == $url) | .filename' \
    "$index_file" 2>/dev/null || echo ""
}

# Add or update entry in index
update_index() {
  local index_file="$1"
  local url="$2"
  local filename="$3"
  local timestamp="$4"
  local existing="$5"

  if [[ -n "$existing" ]]; then
    jq --arg url "$url" \
       --arg ts "$timestamp" \
       'map(if .url == $url then .updated_at = $ts else . end)' \
       "$index_file" > "${index_file}.tmp" && mv "${index_file}.tmp" "$index_file"
  else
    jq --arg url "$url" \
       --arg fn "$filename" \
       --arg ts "$timestamp" \
       '. += [{"url": $url, "filename": $fn, "updated_at": $ts}]' \
       "$index_file" > "${index_file}.tmp" && mv "${index_file}.tmp" "$index_file"
  fi
}
