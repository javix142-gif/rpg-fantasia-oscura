# PROJECT_STATE.md

## Objetivo
RPG de fantasía oscura para Android en Godot.

Vertical slice:
**Liria → ataque → consecuencias → Camino Prohibido → Ceniza → primera ruina de Cyrion.**

## Estado actual
**PROMPT 0 COMPLETADO — PROMPT 1 COMPLETADO — P1.1 CLOUD COMPLETADO — P1.2 REPARACIÓN CLOUD COMPLETADA — P1.3 QUALITY FOUNDATION CLOUD COMPLETADA**

Canon, sistemas 1–14, dirección visual y plan de vertical slice están
definidos. La primera versión jugable de Liria normal está implementada. La
reparación P1.1 corrigió el gate cloud inicial y P1.2 añade reparaciones
acotadas de dispositivo, visual, física, UI y progresión sin iniciar el ataque
ni ningún sistema de P2. P1.3 homogeneiza la base visual y UX, añade guía de
quest, profundidad y vida ambiental de bajo coste, y conserva el alcance de
Liria sin iniciar el ataque.

Validado en Cloud:
- Godot 4.7.2 Standard y export templates 4.7.2;
- Eclipse Temurin JDK 17.0.20.1+1;
- Android SDK: command-line tools 15859902, platform-tools, API 36 y Build Tools 36.0.0;
- CPython 3.13.14, GDA 0.12.0 y GDA Skill project-scoped;
- proyecto smoke `game/`, validación headless y APK debug no vacío;
- pipeline visual P1 con fuentes seleccionadas, hashes y validación
  determinista;
- fundación `GameState`, definiciones tipadas, interacción, diálogo,
  MQ00_01, inventario y `SaveService` versionado;
- Liria compacta con jugador `CharacterBody2D`, ocho direcciones, joystick,
  cámara, NPC y HUD responsive;
- gate Stage 1 y APK `builds/android/rpg_stage1_liria.apk` validados.
- reparación P1.1: orientación Android landscape explícita, viewport expand y
  safe area responsive;
- escena authored de Liria, sprites NPC y hoja AnimatedSprite2D del jugador
  integrados mediante la pipeline determinista;
- interacción `Area2D` pública, E2E de MQ00_01 con botones de touch y layout
  comprobado en 16:9 y ratio ancho;
- APK P1.1 `builds/android/rpg_stage1_liria_p11.apk` validado con
  `screenOrientation=0` y `targetSdkVersion=36`.
- reparación P1.2: atlas del jugador remapeado de forma determinista, alpha e
  importación pixel-art saneadas, y contrato de 48 frames/direcciones validado;
- reparación P1.2: catálogo mantenible de footprints físicos para perímetro,
  casas, herrería, fuente, cercas, árboles y props principales;
- reparación P1.2: diálogo/HUD móvil dentro del contenido seguro, controles
  ocultos durante diálogo, reentrada de Iria y cierre verificable de MQ00_01;
- reparación P1.2: pantalla inicial responsive y pulido menor de jerarquía,
  márgenes, botones y paneles;
- contratos P1.2, E2E Stage 1, layouts 16:9/20:9, headless y export Android
  preparados para la validación integral reproducible.
- APK P1.2 `builds/android/rpg_stage1_liria_p12.apk` exportado y verificado:
  59,923,210 bytes, `targetSdkVersion=36`, `screenOrientation=0`.
- P1.3: tema compartido para portada, HUD y diálogo; transición reutilizable;
  marcadores de objetivo, guía offscreen y feedback de quest.
- P1.3: capas explícitas `Ground`, `AuthoredBackground`, `WorldProps`,
  `WorldCollision`, `Foreground`, `Interactables`, `NPC` y `AmbientFX`, con
  footprints de huertas y rutas críticas comprobables.
- P1.3: limpieza determinista de alpha/RGB transparente, escala común de
  player/NPC, profundidad selectiva, NPC ambientales y FX ligeros de fuente,
  herrería, humo, mercado y luciérnagas.
- P1.3: flujo de MQ00_01 probado de inicio a entrega, eliminación de linterna,
  cierre, feedback y persistencia save/load.
- P1.3: evidencias Cloud en `art/debug/` y suite reproducible
  `scripts/test_p13.sh` con regresión P1/P1.1/P1.2.
- APK P1.3 `builds/android/rpg_stage1_liria_p13.apk` exportado y verificado:
  59,958,175 bytes, `targetSdkVersion=36`, `screenOrientation=0`.

Pendientes de validación manual del APK P1.3: instalación/sensación en
dispositivo Android, safe area física, background/resume, colisiones observadas,
guía visual, vida ambiental, presentación y aprobación visual del usuario.
`DEVICE_QA=PENDING`, `USER_VISUAL_APPROVAL=PENDING` y
`PROMPT_1_REAL=PENDING`. El personaje y el arte de P1/P1.1 son provisionales;
no se declaran arte definitivo.

## Stack aprobado
- Godot 4.7.2 Standard.
- GDScript.
- Compatibility.
- Android landscape.
- 2D top-down/isométrico ligero.
- 640×360.
- GDA preferido.
- sin backend/login/ads.

## Prompt 0 activa
- Godot 4.7.2.
- export templates 4.7.2.
- JDK 17.
- Android SDK.
- GDA versionado.
- GDA Skill.
- skill propia `rpg-mobile-project-contract`.

## No activar todavía
- QuestSystem.
- LimboAI.
- State Charts.
- Phantom Camera.
- segundo MCP Godot.
- framework inventario.
- Aseprite Wizard.

## Candidatos posteriores
- GUT 9.7.1.
- Dialogue Manager 3.10.5.
- skills Godot específicas bajo demanda.

## Próximo gate
Completar la prueba física y la aprobación visual de P1.3. Sólo después de
esa aceptación y de una autorización explícita podrá abrirse **P2 — Ataque de
Liria + combate ARPG**. No comenzar P2 automáticamente.

## Regla
P1 cloud y P1.1/P1.2/P1.3 cloud están superados; el gate real de dispositivo
sigue pendiente. El ataque, el combate ARPG y los sistemas posteriores no
están implementados. `LISTO_PARA_PROMPT_2=NO`.

---

## Subproyecto independiente — Ceniza Salvaje v0.3-stable (cierre 2026-09-16)

Esta sección registra exclusivamente `survival_prototype/`; las etapas P1/P1.3 del RPG descritas arriba pertenecen a otro subproyecto y se conservan sin modificación.

- Rama aislada: `artifact/survival-v0.3-stabilization`. `main` no se fusionó ni modificó.
- Estado definitivo: `PASS_WITH_WARNINGS`; candidato interno `v0.3-stable`, **sin tag/release nuevo ni despliegue automático**.
- Commit de código efectivamente validado: `a417530ef3ae1f4f988f91f6e7733ab19564a8c7`. Los commits posteriores de cierre contienen solamente documentación y empaquetado de revisión.
- Motor y entrypoint: Godot `4.7.2.stable.official.ed1daf0bf`; `survival_prototype/project.godot → main.tscn → v03.gd`.
- QA CI run `35047514437`: regresión 12/12, parse, smoke, recorrido funcional 25/25, save real entre procesos, preservación de primary corrupto, recuperación backup, export PCK filtrado y APK ARM64 verificado: PASS.
- Corrección crítica: `chunk_mods` normaliza IDs/HP después de JSON para que recursos eliminados o dañados y enemigos derrotados persistan al reabrir.
- Save v4 con validación, temporal, backup, protección contra overwrite de primary corrupto y migración v3→v4; ver `survival_prototype/docs/SAVE_FORMAT.md`.
- Runtime: `v03.gd` 1.629 líneas y 13 módulos; sin features nuevas en cierre formal.
- Evidencia: 7 PNG post-refactor (spawn, exploración, combate, inventario/crafting, building, mapa y save/load) y `QA_METADATA.txt` vinculados al run anterior. Capturas inspeccionadas visualmente: sin fallo gráfico grave evidente en los estados retratados; no prueban rendimiento ni toda la interacción táctil.
- APK debug validado: `Ceniza-Salvaje-v0.3-stabilization-arm64-debug.apk`, 80.188.628 bytes, SHA-256 `59bb2c39f917f8f50802b069d8b56f072fa7defc22b85e16775172e89552b21e`; package `org.cenizasalvaje.v03`, minSdk 24, targetSdk 35, ABI arm64-v8a, firma v2.
- `TOUCH_ANDROID_FISICO=NOT_VALIDATED` (se mantiene pendiente explícito).
- Navegación compleja/pathfinding pendiente; mitigación sidestep y alcance futuro en `survival_prototype/docs/NAVIGATION_FUTURE.md`.
- Archivos históricos/CI preservados. `export_presets.cfg` excluye tooling, tests, docs, payload, triggers y versiones obsoletas del APK; filtro validado sobre PCK real.
- No alterar código ni iniciar nueva fase hasta completar prueba táctil Android real y revisar navegación en una fase autorizada.

**Siguiente gate:** prueba física móvil acotada de controles touch, save/reapertura, construcción/cofre y rendimiento; registrar evidencia sin habilitar automáticamente otra fase.
