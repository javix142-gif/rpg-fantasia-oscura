#!/usr/bin/env bash
# Installs only the Prompt 0 Cloud dependencies below the ignored .tools/ directory.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TOOLS="$ROOT/.tools"
DOWNLOADS="$TOOLS/downloads"
GODOT_VERSION="4.7.2"
GODOT_SHA256="cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4"
TEMPLATES_SHA256="f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011"
ANDROID_TOOLS_VERSION="15859902"
ANDROID_TOOLS_SHA256="4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583"
JDK_SHA256="3808d1d15e3ec6bd5b84057fb5d84c33d8a1536a258146bcea2e603fc726e08e"
GODOT_URL="https://downloads.godotengine.org/?flavor=stable&platform=linux.64&slug=linux.x86_64.zip&version=$GODOT_VERSION"
TEMPLATES_URL="https://downloads.godotengine.org/?flavor=stable&platform=templates&slug=export_templates.tpz&version=$GODOT_VERSION"
ANDROID_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_TOOLS_VERSION}_latest.zip"
JDK_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.20.1%2B1/OpenJDK17U-jdk_x64_linux_hotspot_17.0.20.1_1.tar.gz"

require_command() {
  command -v "$1" >/dev/null 2>&1 || { echo "Required command not found: $1" >&2; exit 1; }
}

download_and_verify() {
  local url="$1"
  local expected_sha="$2"
  local destination="$3"
  local actual_sha

  if [[ ! -f "$destination" ]]; then
    local temporary="${destination}.partial"
    rm -f "$temporary"
    wget --quiet --https-only --output-document="$temporary" "$url"
    mv "$temporary" "$destination"
  fi
  actual_sha="$(sha256sum "$destination" | awk '{print $1}')"
  if [[ "$actual_sha" != "$expected_sha" ]]; then
    echo "Checksum mismatch for $destination" >&2
    echo "Expected: $expected_sha" >&2
    echo "Actual:   $actual_sha" >&2
    exit 1
  fi
}

require_command uv
require_command wget
require_command unzip
require_command tar

export XDG_DATA_HOME="$TOOLS/xdg-data"
export XDG_CONFIG_HOME="$TOOLS/xdg-config"

mkdir -p "$DOWNLOADS" "$TOOLS/godot" "$TOOLS/android-sdk/cmdline-tools" \
  "$XDG_DATA_HOME/godot/export_templates" "$XDG_CONFIG_HOME"

godot_archive="$DOWNLOADS/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
templates_archive="$DOWNLOADS/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
android_archive="$DOWNLOADS/commandlinetools-linux-${ANDROID_TOOLS_VERSION}_latest.zip"
jdk_archive="$DOWNLOADS/OpenJDK17U-jdk_x64_linux_hotspot_17.0.20.1_1.tar.gz"

download_and_verify "$GODOT_URL" "$GODOT_SHA256" "$godot_archive"
download_and_verify "$TEMPLATES_URL" "$TEMPLATES_SHA256" "$templates_archive"
download_and_verify "$ANDROID_TOOLS_URL" "$ANDROID_TOOLS_SHA256" "$android_archive"
download_and_verify "$JDK_URL" "$JDK_SHA256" "$jdk_archive"

if [[ ! -x "$TOOLS/jdk17/bin/javac" ]]; then
  mkdir -p "$TOOLS/jdk17"
  tar -xzf "$jdk_archive" --strip-components=1 -C "$TOOLS/jdk17"
fi
export JAVA_HOME="$TOOLS/jdk17"
export PATH="$JAVA_HOME/bin:$PATH"
java_major="$(java -version 2>&1 | sed -n 's/.*version "\([0-9][0-9]*\).*/\1/p' | head -n 1)"
[[ "$java_major" == "17" ]] || { echo "OpenJDK 17 is required; found major ${java_major:-unknown}" >&2; exit 1; }
command -v javac >/dev/null 2>&1 || { echo "JDK compiler is unavailable" >&2; exit 1; }

if [[ ! -x "$TOOLS/godot/godot" ]]; then
  unzip -p "$godot_archive" "Godot_v${GODOT_VERSION}-stable_linux.x86_64" > "$TOOLS/godot/godot"
  chmod 755 "$TOOLS/godot/godot"
fi

templates_dir="$XDG_DATA_HOME/godot/export_templates/${GODOT_VERSION}.stable"
if [[ ! -f "$templates_dir/android_debug.apk" ]]; then
  template_stage="$TOOLS/godot-template-stage"
  mkdir -p "$template_stage" "$templates_dir"
  unzip -qo "$templates_archive" -d "$template_stage"
  cp -a "$template_stage/templates/." "$templates_dir/"
fi

sdkmanager="$TOOLS/android-sdk/cmdline-tools/latest/bin/sdkmanager"
if [[ ! -x "$sdkmanager" ]]; then
  temporary_extract="$TOOLS/android-commandline-tools-extract"
  mkdir -p "$temporary_extract"
  unzip -q "$android_archive" -d "$temporary_extract"
  mv "$temporary_extract/cmdline-tools" "$TOOLS/android-sdk/cmdline-tools/latest"
  rmdir "$temporary_extract"
fi

set +o pipefail
yes | "$sdkmanager" --sdk_root="$TOOLS/android-sdk" --no_https --licenses >/dev/null
sdkmanager_license_status=${PIPESTATUS[1]}
set -o pipefail
[[ "$sdkmanager_license_status" -eq 0 ]] || exit "$sdkmanager_license_status"
"$sdkmanager" --sdk_root="$TOOLS/android-sdk" --no_https \
  "platform-tools" \
  "platforms;android-36" \
  "build-tools;36.0.0"

# Android's current command-line tools package nests platform-tools one level down.
# Godot expects the conventional SDK path, so expose only the required adb binary.
if [[ ! -e "$TOOLS/android-sdk/platform-tools/adb" ]]; then
  ln -s "platform-tools/adb" "$TOOLS/android-sdk/platform-tools/adb"
fi

# Generate the Godot settings file before setting the Android paths, then update
# those settings idempotently. The values are repository-local and contain no keys.
"$TOOLS/godot/godot" --headless --editor --quit >/dev/null
editor_settings="$XDG_CONFIG_HOME/godot/editor_settings-4.7.tres"
set_editor_path() {
  local key="$1"
  local value="$2"
  if grep -q "^${key} =" "$editor_settings"; then
    sed -i "s|^${key} =.*|${key} = \"${value}\"|" "$editor_settings"
  else
    printf '%s = "%s"\n' "$key" "$value" >> "$editor_settings"
  fi
}
set_editor_path "export/android/android_sdk_path" "$TOOLS/android-sdk"
set_editor_path "export/android/java_sdk_path" "$TOOLS/jdk17"

export UV_PYTHON_INSTALL_DIR="$TOOLS/python"
uv python install 3.13
python_bin="$(uv python find --managed-python --no-project 3.13)"
if [[ ! -x "$TOOLS/gda-venv/bin/python" ]]; then
  uv venv "$TOOLS/gda-venv" --python "$python_bin"
fi
uv pip install --python "$TOOLS/gda-venv/bin/python" "gda==0.12.0"

source "$ROOT/scripts/codex/env.sh"
"$GDA_BIN" skill --install --provider codex --scope project
"$GODOT_BIN" --version
"$GDA_BIN" --version
adb --version
"$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" --version
