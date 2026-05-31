#!/usr/bin/env bash
# setup.sh — symlink skills to pi and install cron job
# Usage: ./setup.sh <cron-expression>
# Example: ./setup.sh '0 */6 * * *'

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UPDATE_SCRIPT="$SCRIPT_DIR/refresh-cache.sh"
LOG_FILE="$SCRIPT_DIR/update.log"
CRON_MARKER="# agent-skills-update"
CRON_SCHEDULE="${1:-}"

# ── install deps ───────────────────────────────────────────────────────────────
echo "[setup] installing npm deps..."
cd "$SCRIPT_DIR"
if command -v bun &>/dev/null; then
  bun install --silent
elif command -v pnpm &>/dev/null; then
  pnpm install --silent
else
  npm install --silent
fi

# ── symlink skills ─────────────────────────────────────────────────────────────
echo "[setup] linking skills..."
ln -sf "$SCRIPT_DIR/skills"/* ~/.pi/agent/skills/ 2>/dev/null || true
ln -sf "$SCRIPT_DIR/AGENTS.md" ~/.pi/agent/AGENTS.md

# ── validate ──────────────────────────────────────────────────────────────────
if [[ -z "$CRON_SCHEDULE" ]]; then
  echo "Usage: $0 <cron-expression>" >&2
  echo "Example: $0 '0 */6 * * *'" >&2
  exit 1
fi

if [[ ! -x "$UPDATE_SCRIPT" ]]; then
  echo "Error: refresh-cache.sh not found or not executable" >&2
  exit 1
fi

if ! command -v crontab &>/dev/null; then
  echo "Error: crontab not available" >&2
  exit 1
fi

# ── install crontab (idempotent) ──────────────────────────────────────────────
# Remove any existing cron entry for refresh-cache.sh, then add new one
CRON_LINE="$CRON_SCHEDULE $UPDATE_SCRIPT $CRON_MARKER"

(crontab -l 2>/dev/null | grep -v 'refresh-cache.sh' || true; echo "$CRON_LINE") | crontab -

echo "[setup] cron installed: $CRON_LINE"
echo "[setup] verify: crontab -l"
echo "[setup] logs: $LOG_FILE"
