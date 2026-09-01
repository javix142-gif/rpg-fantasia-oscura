#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/codex/env.sh"

"$ROOT/scripts/codex/validate_repo.sh"
"$ROOT/scripts/codex/verify_environment.sh"
"$ROOT/scripts/test_headless.sh"
"$GDA_BIN" info --json
"$GDA_BIN" script validate res://smoke_bootstrap.gd --project "$GDA_PROJECT" --json
"$ROOT/scripts/build_android_debug.sh"
[[ -s "$ROOT/builds/android/rpg_prompt0_smoke.apk" ]]
aapt="$ANDROID_SDK_ROOT/build-tools/36.0.0/aapt"
[[ -x "$aapt" ]] || { echo "Android Build Tools 36.0.0 are unavailable." >&2; exit 1; }
"$aapt" dump badging "$ROOT/builds/android/rpg_prompt0_smoke.apk" | grep -F "targetSdkVersion:'36'" >/dev/null
echo "PROMPT_0_VALIDATION=PASS"
