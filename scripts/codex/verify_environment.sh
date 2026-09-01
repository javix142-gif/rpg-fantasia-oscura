#!/usr/bin/env bash
set -u
echo "== system =="; uname -a || true
echo "== python =="; python3 --version || true
echo "== uv =="; uv --version || true
echo "== java =="; java -version || true
echo "== android =="; adb --version || true; sdkmanager --version || true
echo "== godot =="
if command -v godot >/dev/null 2>&1; then godot --version || true
elif [[ -n "${GDA_GODOT:-}" && -x "${GDA_GODOT}" ]]; then "${GDA_GODOT}" --version || true
else echo "Godot not found"; fi
echo "== gda =="; gda --version || true
printf 'GDA_GODOT=%s\n' "${GDA_GODOT:-<unset>}"
printf 'GDA_PROJECT=%s\n' "${GDA_PROJECT:-<unset>}"
