#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/codex/env.sh"

[[ -x "$GODOT_BIN" ]] || { echo "Godot is not installed. Run scripts/codex/setup_cloud.sh first." >&2; exit 1; }
[[ -x "$GDA_BIN" ]] || { echo "GDA is not installed. Run scripts/codex/setup_cloud.sh first." >&2; exit 1; }

"$ROOT/scripts/asset_pipeline/process_assets.sh"
"$ROOT/scripts/asset_pipeline/validate_assets.sh"

# P1.3 is still the same offline Stage 1 slice: the checks below guard its
# platform contract and make the new reusable scene layers explicit.
grep -F 'handheld/orientation=0' "$ROOT/game/project.godot" >/dev/null
grep -F 'size/viewport_width=640' "$ROOT/game/project.godot" >/dev/null
grep -F 'size/viewport_height=360' "$ROOT/game/project.godot" >/dev/null
grep -F 'stretch/aspect="expand"' "$ROOT/game/project.godot" >/dev/null
grep -F 'screen/orientation=0' "$ROOT/game/export_presets.cfg" >/dev/null
grep -F 'renderer/rendering_method="gl_compatibility"' "$ROOT/game/project.godot" >/dev/null
grep -F 'class_name Stage1Theme' "$ROOT/game/ui/stage1_theme.gd" >/dev/null
grep -F 'class_name QuestMarker' "$ROOT/game/world/quest_marker.gd" >/dev/null
grep -F 'class_name LiriaAmbientFx' "$ROOT/game/world/ambient_fx.gd" >/dev/null
grep -F 'name = "WorldCollision"' "$ROOT/game/world/village_world.gd" >/dev/null
grep -F 'name = "AuthoredBackground"' "$ROOT/game/world/village_world.gd" >/dev/null
grep -F 'name = "Foreground"' "$ROOT/game/world/village_world.gd" >/dev/null
grep -F 'fade_from_black' "$ROOT/game/main.gd" >/dev/null
grep -F 'Controles táctiles activos' "$ROOT/game/main.gd" >/dev/null
grep -F 'RemoveItem' "$ROOT/game/data/dialogue_service.gd" >/dev/null
grep -F 'alpha_binary' "$ROOT/art/ASSET_MANIFEST.json" >/dev/null
grep -F 'clear_transparent_rgb' "$ROOT/art/ASSET_MANIFEST.json" >/dev/null
if grep -E 'draw_(rect|circle|line|colored_polygon)' "$ROOT/game/world/village_world.gd" >/dev/null; then
  echo "WORLD_PROCEDURAL_VISUALS=FAIL" >&2
  exit 1
fi

# Populate Godot's global class cache before GDA and the typed contracts.
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

"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p13_player_visual_contract.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p13_world_physics_contract.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p13_ambient_life_contract.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p13_quest_guidance_contract.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p13_quest_flow_contract.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p13_ui_contract.gd -- --size=640x360
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p13_ui_contract.gd -- --size=800x360
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p13_transition_contract.gd

# P1/P1.1/P1.2 regression coverage remains part of the P1.3 cloud gate.
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/stage1_e2e.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p12_player_contract.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p12_collision_contract.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p12_ui_quest_contract.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p12_visual_capture.gd
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p11_layout_contract.gd -- --size=640x360
"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p11_layout_contract.gd -- --size=800x360
"$ROOT/scripts/test_headless.sh"

"$GODOT_BIN" --headless --path "$ROOT/game" --script res://tests/p13_evidence_generator.gd
for evidence in \
  "$ROOT/art/debug/p13_player_contact_sheet.png" \
  "$ROOT/art/debug/p13_collision_map.png" \
  "$ROOT/art/debug/p13_player_contact_sheet.svg" \
  "$ROOT/art/debug/p13_ui_mockups.svg"; do
  [[ -s "$evidence" ]] || { echo "EVIDENCE_MISSING=$evidence" >&2; exit 1; }
done

apk="$ROOT/builds/android/rpg_stage1_liria_p13.apk"
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
echo "P13_STAGE1_VALIDATION=PASS"
