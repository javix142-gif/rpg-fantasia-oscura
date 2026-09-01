#!/usr/bin/env bash
# Shared, repository-relative environment for Prompt 0 tooling.
set -euo pipefail

CODEX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CODEX_TOOLS="$CODEX_ROOT/.tools"

export GODOT_BIN="$CODEX_TOOLS/godot/godot"
export GDA_GODOT="$GODOT_BIN"
# Keep Godot's user data and editor settings inside ignored repository-local tooling.
# Godot uses the XDG paths on Linux; GODOT_USER_PATH is not an editor environment
# variable and therefore cannot redirect export-template discovery.
export XDG_DATA_HOME="$CODEX_TOOLS/xdg-data"
export XDG_CONFIG_HOME="$CODEX_TOOLS/xdg-config"
export ANDROID_SDK_ROOT="$CODEX_TOOLS/android-sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
if [[ -x "$CODEX_TOOLS/jdk17/bin/java" ]]; then
  export JAVA_HOME="$CODEX_TOOLS/jdk17"
else
  export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
fi
export GDA_PROJECT="$CODEX_ROOT/game"
export GDA_BIN="$CODEX_TOOLS/gda-venv/bin/gda"
export PATH="$JAVA_HOME/bin:$CODEX_TOOLS/gda-venv/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/platform-tools/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
