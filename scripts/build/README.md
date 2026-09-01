# Build scripts

Prompt 0 debe crear y validar:
- `scripts/codex/setup_cloud.sh`
- `scripts/test_headless.sh`
- `scripts/build_android_debug.sh`
- `scripts/validate.sh`

No se incluyen comandos ficticios antes de inspeccionar el entorno real.

Requisitos:
- `set -euo pipefail`;
- idempotencia cuando aplique;
- no secretos;
- errores claros;
- rutas portables.
