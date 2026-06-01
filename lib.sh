#!/usr/bin/env bash
# lib.sh — shared functions for URL scraping scripts

# ── url normalization ─────────────────────────────────────────────────────────
# Normalize URL: strip trailing slash from path EXCEPT for root URLs
# https://react.dev/ -> https://react.dev/  (keep slash for root - lightpanda bug)
# https://react.dev/learn/ -> https://react.dev/learn
# https://react.dev/?a=1 -> https://react.dev/?a=1
normalize_url() {
  local url="$1"
  # Goal: path always ends with slash, query params preserved
  # https://react.dev -> https://react.dev/
  # https://react.dev/learn -> https://react.dev/learn/
  # https://react.dev/learn?a=123 -> https://react.dev/learn/?a=123
  # https://react.dev?a=123 -> https://react.dev/?a=123

  if [[ "$url" =~ ^([^?]+)(\?.*)?$ ]]; then
    local path="${BASH_REMATCH[1]}"
    local query="${BASH_REMATCH[2]}"
    # Ensure path ends with slash
    if [[ ! "$path" =~ /$ ]]; then
      path="$path/"
    fi
    echo "${path}${query}"
  else
    echo "$url"
  fi
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

# Add or update entry in index (with file locking for concurrent access)
update_index() {
  local index_file="$1"
  local url="$2"
  local filename="$3"
  local timestamp="$4"
  local existing="$5"
  local lock_dir="${index_file}.lock.d"

  # Acquire exclusive lock using mkdir (atomic, works on macOS)
  local waited=0
  while ! mkdir "$lock_dir" 2>/dev/null; do
    if [[ $waited -ge 30 ]]; then
      echo "Error: Could not acquire lock for $index_file" >&2
      return 1
    fi
    sleep 1
    ((waited++)) || true
  done

  # Ensure lock is released on exit
  trap 'rmdir "$lock_dir" 2>/dev/null' RETURN

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
