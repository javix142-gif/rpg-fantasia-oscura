#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/codex/env.sh"
[[ -x "$GODOT_BIN" ]] || { echo "Godot is not installed. Run scripts/codex/setup_cloud.sh first." >&2; exit 1; }
[[ -x "$GDA_BIN" ]] || { echo "GDA is not installed. Run scripts/codex/setup_cloud.sh first." >&2; exit 1; }

"$ROOT/scripts/asset_pipeline/process_assets.sh"
"$ROOT/scripts/asset_pipeline/validate_assets.sh"

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
"$ROOT/scripts/test_headless.sh"

apk="$ROOT/builds/android/rpg_stage1_liria.apk"
mkdir -p "$(dirname "$apk")"
"$GODOT_BIN" --headless --path "$ROOT/game" --export-debug "Android" "$apk"
[[ -s "$apk" ]] || { echo "ANDROID_APK=FAIL" >&2; exit 1; }
aapt="$ANDROID_SDK_ROOT/build-tools/36.0.0/aapt"
"$aapt" dump badging "$apk" | grep -F "targetSdkVersion:'36'" >/dev/null
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
echo "STAGE1_VALIDATION=PASS"
