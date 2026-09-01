#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/codex/env.sh"
[[ -x "$GODOT_BIN" ]] || { echo "Godot is not installed. Run scripts/codex/setup_cloud.sh first." >&2; exit 1; }
[[ -x "$GDA_BIN" ]] || { echo "GDA is not installed. Run scripts/codex/setup_cloud.sh first." >&2; exit 1; }

"$ROOT/scripts/asset_pipeline/process_assets.sh"
"$ROOT/scripts/asset_pipeline/validate_assets.sh"

# P1.1 contract checks are intentionally source-level and deterministic: they
# guard the Android orientation, logical viewport and the authored visual path
# without pretending that a headless renderer is a physical-device test.
grep -F 'handheld/orientation=0' "$ROOT/game/project.godot" >/dev/null
grep -F 'stretch/aspect="expand"' "$ROOT/game/project.godot" >/dev/null
grep -F 'size/viewport_width=640' "$ROOT/game/project.godot" >/dev/null
grep -F 'size/viewport_height=360' "$ROOT/game/project.godot" >/dev/null
grep -F 'screen/orientation=0' "$ROOT/game/export_presets.cfg" >/dev/null
grep -F 'AnimatedSprite2D' "$ROOT/game/world/player_controller.gd" >/dev/null
grep -F 'InteractionSensor' "$ROOT/game/world/player_controller.gd" >/dev/null
grep -F 'TileMapLayer' "$ROOT/game/world/village_world.gd" >/dev/null
grep -F 'LiriaAuthoredScene' "$ROOT/game/world/village_world.gd" >/dev/null
if grep -E 'draw_(rect|circle|line|colored_polygon)' "$ROOT/game/world/village_world.gd" >/dev/null; then
  echo "WORLD_PROCEDURAL_VISUALS=FAIL" >&2
  exit 1
fi
if grep -E '\.text\s*=\s*"(MQ00_01|NOT_STARTED|ACTIVE|COMPLETE)' "$ROOT/game/ui/hud.gd" >/dev/null; then
  echo "HUD_DEBUG_IDS=FAIL" >&2
  exit 1
fi
echo "P11_ORIENTATION=PASS"
echo "P11_VIEWPORT=PASS"
echo "P11_VISUAL_CONTRACT=PASS"

validation_json="$($GDA_BIN script validate --all --project "$ROOT/game" --json)"
VALIDATION_JSON="$validation_json" python3 - <<'PY'
import json, os, sys
payload = json.loads(os.environ["VALIDATION_JSON"])
if payload.get("project_root") and not payload.get("valid", False):
    print("GDA_VALIDATION=FAIL")
    print(json.dumps(payload, ensure_ascii=False))
    sys.exit(1)
if not payload.get("valid", False):
    print("GDA_VALIDATION=FAIL")
    sys.exit(1)
print("GDA_VALIDATION=PASS")
PY

"$GODOT_BIN" --headless --path "$ROOT/game" --editor --quit
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/stage1_e2e.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p11_visual_capture.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p11_layout_contract.gd -- --size=640x360
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p11_layout_contract.gd -- --size=800x360
"$ROOT/scripts/test_headless.sh"

apk="$ROOT/builds/android/rpg_stage1_liria_p11.apk"
mkdir -p "$(dirname "$apk")"
"$GODOT_BIN" --headless --path "$ROOT/game" --export-debug "Android" "$apk"
[[ -s "$apk" ]] || { echo "ANDROID_APK=FAIL" >&2; exit 1; }
aapt="$ANDROID_SDK_ROOT/build-tools/36.0.0/aapt"
"$aapt" dump badging "$apk" | grep -F "targetSdkVersion:'36'" >/dev/null
# Android orientation enum 0 is landscape in Godot's Android exporter. The
# manifest check catches a preset/project mismatch even when the desktop run
# is correct.
"$aapt" dump xmltree "$apk" AndroidManifest.xml | grep -F 'android:screenOrientation' | grep -F '(type 0x10)0x0' >/dev/null
unzip -tq "$apk" >/dev/null
if ! unzip -l "$apk" | grep -F 'assets/main.tscn.remap' >/dev/null; then
  echo "MAIN_SCENE_MISSING=FAIL" >&2
  exit 1
fi
if unzip -l "$apk" | grep -E '(^|/)references/' >/dev/null; then
  echo "REFERENCE_ONLY content unexpectedly included in APK" >&2
  exit 1
fi
printf 'APK_PATH=%s\n' "$apk"
stat -c 'APK_SIZE=%s' "$apk"
echo "P11_STAGE1_VALIDATION=PASS"
