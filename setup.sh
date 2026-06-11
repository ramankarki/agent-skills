#!/usr/bin/env bash

set -euo pipefail

# ── symlink skills ─────────────────────────────────────────────────────────────
echo "[setup] linking skills and global agent..."
ln -sf ~/agent-skills/skills/* ~/.pi/agent/skills/ 2>/dev/null || true
ln -sf ~/agent-skills/GLOBAL_AGENTS.md ~/.pi/agent/AGENTS.md
