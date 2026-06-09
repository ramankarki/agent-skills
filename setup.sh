#!/usr/bin/env bash

set -euo pipefail

# ── symlink skills ─────────────────────────────────────────────────────────────
echo "[setup] linking skills and global agent..."
# ln -sf "$SCRIPT_DIR/skills"/* ~/.pi/agent/skills/ 2>/dev/null || true
ln -sf "$SCRIPT_DIR/GLOBAL_AGENTS.md" ~/.pi/agent/AGENTS.md
