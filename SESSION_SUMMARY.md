# SESSION_SUMMARY.md

## Estado
P1.3 Quality Foundation cerrado internamente en Cloud: se homogeneizaron
player/NPC/UI, se reforzaron footprints y rutas físicas de Liria, se añadió
profundidad selectiva y vida ambiental, se incorporó guía explícita de
MQ00_01, feedback/transiciones y una portada integrada. El gate reproducible y
el APK Android debug quedan validados por script; la aceptación física y
visual del usuario siguen pendientes.

## Próximo paso
Probar el APK P1.3 en un dispositivo Android y registrar la aprobación visual.
Mantener `P1_DEVICE=PENDING`, `P1_REAL=PENDING` y no iniciar Prompt 2
automáticamente.

## Contexto mínimo
- canon: `docs/canon/`
- preproducción: `docs/design/`
- visual: `docs/visual/`
- implementación: `docs/implementation/`
- tooling: `docs/tooling/`

P1 deja Liria en estado `NORMAL`; MQ00_01, inventario y save/load son reales.
El ataque, ARPG, Radan, Ceniza y Cyrion siguen fuera de alcance.

## Validación Prompt 0
- `./scripts/validate.sh` finalizó con `PROMPT_0_VALIDATION=PASS`.
- APK debug: `builds/android/rpg_prompt0_smoke.apk` (57,603,021 bytes en la validación).
- Herramientas reproducibles: `scripts/codex/setup_cloud.sh`,
  `scripts/test_headless.sh` y `scripts/build_android_debug.sh`.

## Validación Prompt 1
- `./scripts/codex/validate_repo.sh`: PASS.
- `./scripts/asset_pipeline/validate_assets.sh`: PASS.
- `./scripts/test_stage1.sh`: `STAGE1_VALIDATION=PASS`.
- APK Stage 1: `builds/android/rpg_stage1_liria.apk` (58,430,221 bytes en la
  validación final, `targetSdkVersion=36`).
- E2E headless: nueva partida → nombre/clase → Liria → Iria → Halven →
  objeto → inventario → MQ00_01 completa → guardar → alterar → cargar y
  restaurar.
- Image Generation: 2 invocaciones; `CHARACTER_MASTER_STATUS=P1_PROVISIONAL`.
- Pendiente: prueba física Android y aprobación visual del usuario.

## Validación P1.1
- Rama de trabajo: `work/p1.1-device-visual-repair`.
- `./scripts/codex/validate_repo.sh`: PASS.
- `./scripts/validate.sh`: `PROMPT_0_VALIDATION=PASS`.
- `./scripts/asset_pipeline/validate_assets.sh`: `ASSET_PIPELINE_VALIDATION=PASS`.
- `./scripts/test_stage1.sh`: `P11_STAGE1_VALIDATION=PASS`.
- E2E: movimiento a rango, botón público, elecciones de diálogo,
  MQ00_01, inventario y save/load: PASS.
- Layout: 640×360 (16:9) y 800×360 (ratio ancho 20:9 aproximado): PASS.
- GDA: todos los scripts válidos; headless: PASS.
- APK: `builds/android/rpg_stage1_liria_p11.apk`, 59,938,731 bytes,
  `targetSdkVersion=36`, `screenOrientation=0` (landscape).
- Image Generation nativa: 3 llamadas P1.1; fuentes seleccionadas y hashes
  registrados en `art/ASSET_MANIFEST.json`.
- Captura runtime: intentada; renderer dummy no expone textura
  (`P11_VISUAL_CAPTURE=SKIP_NO_RENDERER`). Las salidas de arte procesadas se
  inspeccionaron visualmente en Cloud.
- Estado: `DEVICE_QA=PENDING`, `USER_VISUAL_APPROVAL=PENDING`,
  `PROMPT_1_REAL=PENDING`, `LISTO_PARA_PROMPT_2=NO`.

## Validación P1.2
- Atlas del jugador: 48 celdas RGBA8 no vacías, con alpha binaria, canvas de
  pies común y ocho filas estables de idle/walk: `P12_PLAYER_CONTRACT=PASS`.
- Colisiones: catálogo de 31 footprints nombrados y prueba física de fuente,
  casas, herrería, cercas, árboles y props: `P12_COLLISION_CONTRACT=PASS`.
- UI/quest: pantalla inicial, contenido seguro, diálogo, controles, inicio de
  MQ00_01 y restauración de HUD: `P12_UI_QUEST_CONTRACT=PASS`.
- E2E Stage 1: movimiento multidireccional, Iria/Halven, linterna,
  inventario y save/load: `STAGE1_E2E=PASS`.
- GDA, editor headless, validación de layouts 640×360/800×360 y smoke
  headless: PASS.
- Captura runtime intentada; el renderer dummy de este entorno no expone
  texturas, por lo que `P12_VISUAL_CAPTURE=SKIP_NO_RENDERER`. El atlas
  procesado sí fue inspeccionado en Cloud.
- APK P1.2: `builds/android/rpg_stage1_liria_p12.apk`, 59,923,210 bytes,
  `targetSdkVersion=36`, `screenOrientation=0`, ZIP íntegro.
- Estado: `P1_DEVICE=PENDING`, `P1_REAL=PENDING`, `P2_AUTORIZADO=NO`.

## Validación P1.3
- Base de trabajo: commit remoto `f91ea49ee5fee6781ed83d6e67369b558bffa0f2`.
- Player: 8 direcciones explícitas, idle/walk con canvas y pivote estables,
  sin flip runtime; `PLAYER_ALPHA_ARTIFACT_PIXELS=0`.
- Mundo: 35 footprints nombrados, capas físicas/visuales explícitas y 6 rutas
  críticas libres; fuente, edificios, cercas, árboles, huertas y props
  principales cubiertos por contrato.
- Vida: aldeano con ciclo idle/look/short walk y FX deterministas de fuente,
  herrería, humo, mercado y luciérnagas.
- Quest: tracker accionable, marcador `!/?`, guía offscreen, toast de objetivo
  y cierre completo de MQ00_01 con eliminación de la linterna.
- UI: tema compartido, diálogo con retrato y choices compactas, HUD/portada y
  transiciones verificadas en 640×360 y 800×360.
- GDA, headless, regresión P1/P1.1/P1.2, contratos P1.3, evidencia estática y
  export Android: PASS mediante `./scripts/test_p13.sh`.
- Evidencias: `art/debug/p13_player_contact_sheet.png`,
  `art/debug/p13_collision_map.png`, `art/debug/p13_player_contact_sheet.svg`
  y `art/debug/p13_ui_mockups.svg`.
- APK P1.3: `builds/android/rpg_stage1_liria_p13.apk`, 59,958,175 bytes,
  `targetSdkVersion=36`, `screenOrientation=0`.
- Image Generation P1.3: 0 llamadas; las evidencias se generaron de forma
  determinista a partir de assets existentes.
- Estado: `P1_DEVICE=PENDING`, `USER_VISUAL_APPROVAL=PENDING`,
  `P1_REAL=PENDING`, `P2_AUTORIZADO=NO`.

---

## Continuidad del subproyecto Ceniza Salvaje — cierre formal v0.3 (2026-09-16)

Este bloque es independiente del RPG/Liria relatado arriba. Rama: `artifact/survival-v0.3-stabilization`; no merge a `main`, no nuevo release/tag. Candidato interno `v0.3-stable`, estado `PASS_WITH_WARNINGS`.

**Fuente de verdad:** `survival_prototype/README.md`, `docs/ARCHITECTURE.md`, `docs/SAVE_FORMAT.md`, `docs/NAVIGATION_FUTURE.md` y `docs/FINAL_CLOSURE.md`.

**Código validado:** commit `a417530ef3ae1f4f988f91f6e7733ab19564a8c7`, Godot 4.7.2; posteriores cambios de cierre limitados a docs/workflow de empaquetado. `v03.gd` 1.629 líneas, 13 módulos. Se corrigió normalización JSON de `chunk_mods` tras detectar fallo real de persistencia entre procesos.

**QA run 35047514437:** regresión 12/12, parse, smoke, E2E 25/25, save/load real, corrupción/backup/escritura bloqueada y filtro PCK: PASS; 7 capturas post-refactor generadas. Inspección visual de las 7: sin regresión grave observable en fotogramas; no equivale a QA física/táctil. APK debug ARM64 verificado 80.188.628 bytes; SHA-256 `59bb2c39f917f8f50802b069d8b56f072fa7defc22b85e16775172e89552b21e`. Artefactos y metadatos en el run/release de evidencia previo; cierre formal no crea release nuevo.

**Pendientes:** `TOUCH_ANDROID_FISICO=NOT_VALIDATED`; navegación compleja/pathfinding requiere fase posterior. El sidestep actual sólo trata bloqueos locales. No iniciar features automáticamente.

**Continuar:** validar táctil/instalación/save en un Android real contra el APK comprobado y registrar incidencias concretas; no modificar worldgen ni ejecutar refactor adicional sin evidencia.
