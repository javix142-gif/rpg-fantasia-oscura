#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/codex/env.sh"

[[ -x "$GODOT_BIN" ]] || { echo "Godot is not installed. Run scripts/codex/setup_cloud.sh first." >&2; exit 1; }
[[ -f "$GDA_PROJECT/export_presets.cfg" ]] || { echo "Android export preset is missing." >&2; exit 1; }

output="$ROOT/builds/android/rpg_prompt0_smoke.apk"
mkdir -p "$(dirname "$output")"
rm -f "$output"
if command -v adb >/dev/null 2>&1; then
  adb start-server >/dev/null 2>&1 || true
fi
"$GODOT_BIN" --headless --path "$GDA_PROJECT" --export-debug "Android" "$output"
[[ -s "$output" ]] || { echo "APK export did not produce a non-empty file: $output" >&2; exit 1; }
printf 'APK_PATH=%s\n' "$output"
