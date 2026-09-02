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
