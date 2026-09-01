# PROMPT 0 — PREPARAR CODEX CLOUD + GODOT + REPOSITORIO BASE

## Contexto

Este repositorio contiene el canon, diseño, dirección visual y plan de implementación de un RPG móvil Android.

Este prompt **NO implementa gameplay**.

Stack baseline:
- Godot 4.7.2 Standard.
- GDScript.
- Compatibility renderer.
- Android landscape.
- 2D top-down/isométrico ligero.
- target Android baseline API 36.
- GDA como interfaz agent-first preferida.
- sin backend/login/ads.

Lee `AGENTS.md` y `PROJECT_STATE.md` antes de cualquier cambio.

## Objetivo

Dejar el repositorio preparado para comenzar la Etapa 1 y demostrar el pipeline Cloud mediante una **APK Android mínima**.

Debes:
1. inspeccionar y normalizar la estructura;
2. verificar el entorno real de Codex Cloud;
3. preparar Godot 4.7.2 y export templates;
4. preparar JDK 17 + Android SDK;
5. preparar GDA versionado;
6. instalar GDA Skill project-scoped desde el propio CLI;
7. revisar skills Godot externas candidatas sin instalar packs completos;
8. crear un proyecto Godot smoke bajo `game/`;
9. configurar export debug Android;
10. validar headless;
11. exportar una APK mínima;
12. documentar setup/test/build reproducibles.

No continúes a gameplay.

## Archivos que debes leer

Obligatorios:
- `AGENTS.md`
- `PROJECT_STATE.md`
- `VERSIONS.lock.json`
- `README.md`
- `docs/tooling/CODEX_CLOUD_SETUP_SPEC.md`
- `docs/tooling/SELECTED_TOOLS_AND_SKILLS.md`
- `docs/implementation/PLAN_VERTICAL_SLICE_3_ETAPAS.md`
- `.agents/skills/rpg-mobile-project-contract/SKILL.md`

No leas todo el canon para esta tarea.

Sólo confirma que:
- `docs/canon/`
- `docs/design/`
- `docs/visual/`
- `references/`
están organizados y protegidos.

## Archivos que puedes modificar

- `README.md`
- `AGENTS.md` sólo para añadir comandos reales, sin relajar reglas
- `PROJECT_STATE.md`
- `SESSION_SUMMARY.md`
- `VERSIONS.lock.json` sólo con verificación/justificación
- `THIRD_PARTY_NOTICES.md`
- `.gitignore`
- `.agents/skills/**`
- `.codex/**` sin secretos ni rutas personales persistentes
- `docs/tooling/**`
- `docs/implementation/**` sólo información técnica
- `scripts/**`
- `game/**`
- `tests/**`
- `addons/**` sólo si se justifica explícitamente

Puedes mover archivos para normalizar la estructura, preservando contenido y referencias.

## Archivos que no debes modificar

- `docs/canon/**`
- `docs/design/PREPRODUCCION_PUNTOS_01_14_CANON_v1.md`
- `docs/visual/ART_DIRECTION.md`
- `docs/visual/UI_VISUAL_SPEC.md`
- `docs/visual/SPRITE_TECH_SPEC.md`
- `docs/visual/ASSET_MANIFEST.md`
- `references/**`

No usar `references/**` como assets.

## Restricciones

1. No implementar Liria.
2. No implementar player controller.
3. No crear combate.
4. No crear quests.
5. No crear inventario.
6. No crear assets finales.
7. No instalar QuestSystem, LimboAI, State Charts, Phantom Camera, segundo MCP Godot, framework inventario ni Aseprite Wizard.
8. No habilitar `gda-mcp` por defecto.
9. No instalar todas las skills de GD-Agentic-Skills.
10. No `curl | sh`, `wget | sh` ni scripts remotos ejecutados sin inspección.
11. No secretos ni keystore de publicación.
12. No ocultar fallos.
13. No cambiar Godot 4.7.2 sin motivo verificado.
14. No avanzar a Etapa 1.

## Procedimiento obligatorio

### Fase 1 — Exploración sin cambios

Ejecuta primero:

```bash
./scripts/codex/validate_repo.sh
./scripts/codex/verify_environment.sh
```

Después:
- inspecciona estructura;
- identifica herramientas presentes/ausentes;
- revisa `VERSIONS.lock.json`;
- propone internamente un plan breve.

No asumas Godot, Java, SDK, Python 3.13, uv ni GDA.

### Fase 2 — Normalizar repo

Debe quedar, como mínimo:

```text
/
├── AGENTS.md
├── PROJECT_STATE.md
├── README.md
├── VERSIONS.lock.json
├── THIRD_PARTY_NOTICES.md
├── .agents/
├── .codex/
├── docs/
│   ├── canon/
│   ├── design/
│   ├── visual/
│   ├── implementation/
│   ├── tooling/
│   └── process/
├── references/
├── assets/
├── addons/
├── scripts/
├── tests/
└── game/
```

No reorganices por gusto si ya coincide.

### Fase 3 — Godot / Android / GDA

#### Godot
- Standard 4.7.2.
- verificar versión y checksum.
- no .NET/C#.

#### Export templates
- misma versión exacta del motor.
- verificar checksum.

#### Java/Android
Verificar/preparar:
- OpenJDK 17;
- Android SDK;
- platform-tools;
- build-tools;
- plataforma necesaria para API 36.

Evitar Android Studio GUI si no hace falta.

#### GDA
1. prepara Python 3.13+ de forma controlada;
2. instala la versión fijada/verificada;
3. `gda --version`;
4. configura `GDA_GODOT`;
5. configura `GDA_PROJECT` hacia `game/`;
6. instala:

```bash
gda skill --install --provider codex --scope project
```

No copies manualmente la Skill de `main` si el CLI puede generarla.

### Fase 4 — Skills externas

Revisa upstream de GD-Agentic-Skills.

Sólo puedes considerar ahora:
- `godot-project-foundations`
- `godot-gdscript-mastery`
- `godot-platform-mobile`
- `godot-export-builds`

No es obligatorio instalar las cuatro.

Si instalas:
- project scope;
- revisa contenido;
- registra origen/commit;
- no `--all`;
- no skills de combate/RPG todavía.

### Fase 5 — Proyecto smoke

Bajo `game/` crea un Godot project mínimo:
- nombre provisional;
- Compatibility;
- landscape;
- 640×360;
- escena bootstrap;
- fondo simple propio por código/ColorRect;
- Label “Prompt 0 Smoke Build” o equivalente;
- sin assets externos;
- sin gameplay.

### Fase 6 — Android debug

Crear preset reproducible.

Salida objetivo:

```text
builds/android/rpg_prompt0_smoke.apk
```

Debug signing.
No release keystore.

### Fase 7 — Scripts reproducibles

Crear/validar:

```text
scripts/codex/setup_cloud.sh
scripts/test_headless.sh
scripts/build_android_debug.sh
scripts/validate.sh
```

Requisitos:
- `set -euo pipefail`;
- idempotentes donde aplique;
- sin secretos;
- errores claros;
- sin rutas personales.

### Fase 8 — Validar

Ejecutar como mínimo:
1. estructura repo;
2. Godot version;
3. import/parse headless;
4. smoke headless;
5. `gda info --json`;
6. una operación GDA simple;
7. export Android debug;
8. comprobar APK > 0 bytes;
9. revisar logs;
10. revisar diff.

No afirmes prueba en teléfono si no ocurrió.

### Fase 9 — Estado

Actualizar:
- `README.md`
- `PROJECT_STATE.md`
- `SESSION_SUMMARY.md`
- `VERSIONS.lock.json` si cambia algo
- `THIRD_PARTY_NOTICES.md` si se agrega tercero

Dejar:

```text
PROMPT_0=COMPLETADO | BLOQUEADO
GODOT=...
GDA=...
ANDROID_TOOLCHAIN=...
HEADLESS_TEST=PASS/FAIL
APK_EXPORT=PASS/FAIL
APK_PATH=...
LISTO_PARA_ETAPA_1=SI/NO
```

## Criterios de aceptación

Sólo COMPLETADO si:
- repo coherente;
- canon/referencias intactos;
- Godot 4.7.2 operativo;
- templates correctos;
- JDK/SDK operativo;
- GDA operativo;
- GDA Skill instalada;
- proyecto smoke válido;
- headless PASS;
- APK debug generada;
- scripts reproducibles;
- README con comandos reales;
- PROJECT_STATE actualizado;
- diff revisado;
- sin secretos.

Si el entorno impide APK, marca BLOQUEADO con evidencia y NO avances.

## Pruebas requeridas

Mínimo:

```bash
./scripts/codex/validate_repo.sh
./scripts/codex/verify_environment.sh
./scripts/test_headless.sh
./scripts/build_android_debug.sh
./scripts/validate.sh
```

## Formato de respuesta

### 1. Estado
```text
PROMPT_0=
GODOT=
GDA=
ANDROID=
APK=
LISTO_PARA_ETAPA_1=
```

### 2. Archivos creados/modificados
Lista breve.

### 3. Comandos ejecutados
Sólo relevantes.

### 4. Validaciones
PASS/FAIL por gate.

### 5. Riesgos/bloqueos
Sólo reales.

### 6. Siguiente paso
Una sola recomendación.

No repitas el canon.

## Prohibiciones

- No Etapa 1 automáticamente.
- No gameplay.
- No dependencias “por si acaso”.
- No modificar canon.
- No usar referencias como assets.
- No declarar éxito sin validaciones.
