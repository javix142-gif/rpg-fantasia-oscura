# Ceniza Salvaje v0.3 — acta de cierre formal

- Fecha: 2026-09-16.
- Estado: `PASS_WITH_WARNINGS`.
- Rama: `artifact/survival-v0.3-stabilization` (sin merge ni tag/release nuevo).
- Revisión de gameplay verificada: `a417530ef3ae1f4f988f91f6e7733ab19564a8c7`. El cierre posterior actualiza sólo docs/tooling de empaquetado.
- Godot: `4.7.2.stable.official.ed1daf0bf`.
- QA reproducible: https://github.com/javix142-gif/rpg-fantasia-oscura/actions/runs/35047514437

## Gates comprobados

| Gate | Resultado |
|---|---|
| Regression | 12/12 PASS |
| Godot parse / headless smoke | PASS / PASS |
| Recorrido integral | 25/25 PASS |
| Save real en procesos separados | PASS |
| Primary corrupto preservado, backup válido y bloqueo de escritura | PASS |
| Capturas post-refactor | 7/7 generadas e inspeccionadas; no muestran regresión visual grave obvia en esos estados |
| Filtro PCK real | PASS |
| APK build/firma v2/manifest/ABI/ZIP/zipalign | PASS |
| Touch Android físico | NOT_VALIDATED |

## APK validado (entregado por separado)

- Archivo: `Ceniza-Salvaje-v0.3-stabilization-arm64-debug.apk`.
- Tamaño: `80188628` bytes.
- SHA-256: `59bb2c39f917f8f50802b069d8b56f072fa7defc22b85e16775172e89552b21e`.
- Paquete: `org.cenizasalvaje.v03`; minSdk `24`, targetSdk `35`, ABI `arm64-v8a`.
- Evidencia publicada antes de este cierre: https://github.com/javix142-gif/rpg-fantasia-oscura/releases/tag/ceniza-salvaje-v0.3-stabilization-closure

## Capturas existentes

`01_spawn.png`, `02_exploration.png`, `03_combat.png`, `04_inventory_crafting.png`, `05_building.png`, `06_map.png` y `07_save_load.png`. Su ZIP se adjunta como evidencia dentro del paquete de revisión. Las imágenes fueron capturadas bajo Xvfb/renderer Compatibility: no validan touch físico, audio real ni FPS Android.

## Diff/limpieza

Revisión contra commit base `6c2d49a978ef6c1edcce8e41b4b2d931eefe590d`: cambio de runtime acotado a estabilización, 13 módulos, siete scripts QA y cinco workflows históricos/CI nuevos, triggers y herramientas de estabilización. No hubo borrados de historia, cambio de motor, addons, instalaciones ni nuevas features. `git diff --check`, comprobación de ámbito y búsqueda de claves/rutas absolutas: PASS. Tooling histórico se mantiene en árbol fuente pero se excluye del PCK; su reubicación se difiere deliberadamente.

## Pendientes deliberados

1. `TOUCH_ANDROID_FISICO=NOT_VALIDATED`: probar joystick, botones, menús, drag de construcción, cofre, background/resume y save en el dispositivo.
2. Navegación compleja: sidestep local no resuelve laberintos ni bases grandes; ver `NAVIGATION_FUTURE.md`.

**Siguiente paso único:** QA física acotada de Android y registrar resultados, sin iniciar funcionalidades ni fusionar ramas automáticamente.
