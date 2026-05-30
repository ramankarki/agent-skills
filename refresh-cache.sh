#!/usr/bin/env bash
# update-cache.sh — re-scrape all indexed URLs
# Designed for cron: ./update-cache.sh [batch_size]
# Deps: scrape.sh

set -euo pipefail

# ── config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRAPE="$SCRIPT_DIR/scrape-url.sh"
INDEX_FILE="$SCRIPT_DIR/pages/index.json"
LOG_FILE="$SCRIPT_DIR/update.log"
BATCH_SIZE="${1:-5}"
LOCK_FILE="/tmp/scrape-update.lock"

# ── guard: prevent overlapping cron runs ─────────────────────────────────────
if [[ -e "$LOCK_FILE" ]]; then
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] [update] already running — skipping"
  exit 0
fi
trap 'rm -f "$LOCK_FILE"' EXIT
touch "$LOCK_FILE"

RUN_LOG=""

log() {
  local entry="[$(date +"%Y-%m-%d %H:%M:%S")] $*"
  echo "$entry"
  RUN_LOG="${RUN_LOG}${entry}
"
}

# ── validate ──────────────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  log "Error: jq not found in PATH"
  exit 1
fi

if [[ ! -x "$SCRAPE" ]]; then
  log "Error: scrape.sh not found or not executable at $SCRAPE"
  exit 1
fi

if [[ ! -f "$INDEX_FILE" ]]; then
  log "No index.json found — nothing to update"
  exit 0
fi

# ── read urls from index ──────────────────────────────────────────────────────
URLS=()
while IFS= read -r url; do
  URLS+=("$url")
done < <(jq -r '.[].url' "$INDEX_FILE")
TOTAL=${#URLS[@]}

if [[ "$TOTAL" -eq 0 ]]; then
  log "Index empty — nothing to update"
  exit 0
fi

log "Starting update: $TOTAL url(s), batch_size=$BATCH_SIZE"

# ── process in batches ────────────────────────────────────────────────────────
SUCCESS=0
FAIL=0

for (( i=0; i<TOTAL; i+=BATCH_SIZE )); do
  BATCH=("${URLS[@]:$i:$BATCH_SIZE}")
  log "Batch $((i/BATCH_SIZE + 1)): ${#BATCH[@]} url(s)"

  PIDS=()
  TMPFILES=()

  for url in "${BATCH[@]}"; do
    TMPF=$(mktemp)
    TMPFILES+=("$TMPF")
    URLS_IN_BATCH+=("$url")
    "$SCRAPE" "$url" > "$TMPF" 2>&1 &
    PIDS+=($!)
  done

  for j in "${!PIDS[@]}"; do
    wait "${PIDS[$j]}" && result=ok || result=fail
    if [[ "$result" == "ok" ]]; then
      log "  ✓ ${URLS_IN_BATCH[$j]}"
      (( SUCCESS++ )) || true
    else
      output=$(cat "${TMPFILES[$j]}")
      log "  ✗ ${URLS_IN_BATCH[$j]}"
      (( FAIL++ )) || true
    fi
    rm -f "${TMPFILES[$j]}"
  done
  URLS_IN_BATCH=()

  if (( i + BATCH_SIZE < TOTAL )); then
    sleep 2
  fi
done

log "Update complete: $SUCCESS succeeded, $FAIL failed"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# prepend entire run to log file (newest run first)
if [[ -n "$RUN_LOG" ]]; then
  tmp=$(mktemp)
  printf "%s" "$RUN_LOG" > "$tmp"
  [[ -f "$LOG_FILE" ]] && cat "$LOG_FILE" >> "$tmp"
  mv "$tmp" "$LOG_FILE"
fi
