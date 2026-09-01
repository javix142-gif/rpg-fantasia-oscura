#!/usr/bin/env bash
set -euo pipefail
test -f AGENTS.md
test -f PROJECT_STATE.md
test -f VERSIONS.lock.json
test -f docs/design/PREPRODUCCION_PUNTOS_01_14_CANON_v1.md
test -d docs/canon
test -d references
test -d game
python3 - <<'PY'
import json
from pathlib import Path
json.loads(Path("VERSIONS.lock.json").read_text(encoding="utf-8"))
print("VERSIONS.lock.json: OK")
PY
echo "Repository skeleton: OK"
