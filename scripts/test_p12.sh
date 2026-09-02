#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/codex/env.sh"

[[ -x "$GODOT_BIN" ]] || { echo "Godot is not installed. Run scripts/codex/setup_cloud.sh first." >&2; exit 1; }
[[ -x "$GDA_BIN" ]] || { echo "GDA is not installed. Run scripts/codex/setup_cloud.sh first." >&2; exit 1; }

"$ROOT/scripts/asset_pipeline/process_assets.sh"
"$ROOT/scripts/asset_pipeline/validate_assets.sh"

grep -F 'handheld/orientation=0' "$ROOT/game/project.godot" >/dev/null
grep -F 'stretch/aspect="expand"' "$ROOT/game/project.godot" >/dev/null
grep -F 'screen/orientation=0' "$ROOT/game/export_presets.cfg" >/dev/null
grep -F 'AnimatedSprite2D' "$ROOT/game/world/player_controller.gd" >/dev/null
grep -F 'collision_catalog' "$ROOT/game/world/village_world.gd" >/dev/null
grep -F 'QuestActive' "$ROOT/game/core/game_state.gd" >/dev/null
grep -F 'set_dialogue_mode' "$ROOT/game/main.gd" >/dev/null
if grep -E 'draw_(rect|circle|line|colored_polygon)' "$ROOT/game/world/village_world.gd" >/dev/null; then
  echo "WORLD_PROCEDURAL_VISUALS=FAIL" >&2
  exit 1
fi

# Populate Godot's global class cache before the per-script validator runs.
# This keeps the typed cross-script contracts valid on a clean checkout too.
"$GODOT_BIN" --headless --path "$ROOT/game" --editor --quit
validation_json="$($GDA_BIN script validate --all --project "$ROOT/game" --json)"
VALIDATION_JSON="$validation_json" python3 - <<'PY'
import json, os, sys
payload = json.loads(os.environ["VALIDATION_JSON"])
if not payload.get("valid", False):
    print("GDA_VALIDATION=FAIL")
    print(json.dumps(payload, ensure_ascii=False))
    sys.exit(1)
print("GDA_VALIDATION=PASS")
PY

"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/stage1_e2e.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p12_player_contract.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p12_collision_contract.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p12_ui_quest_contract.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p12_visual_capture.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p11_layout_contract.gd -- --size=640x360
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p11_layout_contract.gd -- --size=800x360
"$ROOT/scripts/test_headless.sh"

apk="$ROOT/builds/android/rpg_stage1_liria_p12.apk"
mkdir -p "$(dirname "$apk")"
rm -f "$apk"
"$GODOT_BIN" --headless --path "$ROOT/game" --export-debug "Android" "$apk"
[[ -s "$apk" ]] || { echo "ANDROID_APK=FAIL" >&2; exit 1; }
aapt="$ANDROID_SDK_ROOT/build-tools/36.0.0/aapt"
[[ -x "$aapt" ]] || { echo "AAPT=FAIL" >&2; exit 1; }
"$aapt" dump badging "$apk" | grep -F "targetSdkVersion:'36'" >/dev/null
"$aapt" dump xmltree "$apk" AndroidManifest.xml | grep -F 'android:screenOrientation' | grep -F '(type 0x10)0x0' >/dev/null
unzip -tq "$apk" >/dev/null
unzip -l "$apk" | grep -F 'assets/main.tscn.remap' >/dev/null
if unzip -l "$apk" | grep -E '(^|/)references/' >/dev/null; then
  echo "REFERENCE_ONLY content unexpectedly included in APK" >&2
  exit 1
fi
printf 'APK_PATH=%s\n' "$apk"
stat -c 'APK_SIZE=%s' "$apk"
echo "P12_STAGE1_VALIDATION=PASS"
