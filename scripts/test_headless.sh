#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/codex/env.sh"

[[ -x "$GODOT_BIN" ]] || { echo "Godot is not installed. Run scripts/codex/setup_cloud.sh first." >&2; exit 1; }
[[ -f "$GDA_PROJECT/project.godot" ]] || { echo "Smoke project is missing." >&2; exit 1; }

# Godot probes Android tooling during editor startup. A local ADB server removes
# a non-fatal device-discovery warning when no server has been started yet.
if command -v adb >/dev/null 2>&1; then
  adb start-server >/dev/null 2>&1 || true
fi

"$GODOT_BIN" --headless --path "$GDA_PROJECT" --editor --quit
"$GODOT_BIN" --headless --path "$GDA_PROJECT" --quit-after 5
