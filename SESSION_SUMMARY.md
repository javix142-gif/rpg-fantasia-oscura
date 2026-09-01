# SESSION_SUMMARY.md

## Estado
P1.1 Cloud cerrado: se repararon orientación Android, layout/safe area,
interacción táctil, animación real del jugador y la integración authored de
Liria/NPC. El gate reproducible y el APK Android debug están validados.
La aceptación física y visual del usuario siguen pendientes.

## Próximo paso
Probar el APK P1.1 en un dispositivo Android y registrar la aprobación visual.
Mantener `PROMPT_1_REAL=PENDING` y no iniciar Prompt 2 automáticamente.

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
