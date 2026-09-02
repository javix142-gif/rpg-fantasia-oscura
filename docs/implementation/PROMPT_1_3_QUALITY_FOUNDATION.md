# Prompt 1.3 — Quality Foundation

## Alcance

P1.3 parte de `f91ea49ee5fee6781ed83d6e67369b558bffa0f2` y mantiene el slice
de Liria, Android landscape, touch, save/load y el flujo MQ00_01. No inicia
P2 ni agrega combate, enemigos, nuevas zonas o sistemas de alcance mayor.

## Diagnóstico breve

- El player dependía de un remapeo de atlas y una envolvente visual que hacía
  más evidente la diferencia de escala/perspectiva frente a los NPC; la
  limpieza anterior no comprobaba todo el contrato de alpha por frame.
- El mundo ya tenía colliders nombrados, pero faltaba una separación explícita
  entre capas visuales, físicas, foreground e interactuables, además de rutas
  de recorrido que evidenciaran accesos libres.
- HUD, portada y diálogo construían estilos localmente y no tenían un lenguaje
  común; la quest tenía estado, pero no un marcador/feedback suficiente para
  comunicar el siguiente destino.
- Liria carecía de movimiento ambiental y las transiciones de estado eran
  instantáneas.

## Trabajo realizado

- Se reforzó la pipeline del player/NPC con una envolvente común, alpha
  determinista, RGB transparente limpiado y contrato de 8 direcciones sin
  mirroring en runtime.
- Se creó `Stage1Theme` para paneles, botones, colores, márgenes y tipografía;
  se rehízo el diálogo móvil con retrato, choices compactas y typewriter
  configurable; el HUD incorpora tracker accionable, marcador, guía offscreen y
  feedback de objetivo/completado.
- Se organizaron las capas de Liria (`Ground`, `AuthoredBackground`,
  `WorldProps`, `WorldCollision`, `Foreground`, `Interactables`, `NPC`,
  `AmbientFX`), se añadieron footprints de huertas y profundidad selectiva.
- Se añadió vida ambiental de bajo coste: ciclo controlado para aldeanos y
  FX dibujados para fuente, herrería, humo, mercado y luciérnagas.
- Se añadió `Stage1TransitionLayer` para fades, entrada de Liria y salida de
  diálogo; la pantalla inicial usa el fondo authored a pantalla completa con
  velo de legibilidad y controles táctiles en Android.
- Se ajustó el diálogo de Bram para no competir con el objetivo de la linterna
  y se verificó el cierre completo de MQ00_01, incluida la eliminación del item.

## Evidencia y validación

La suite reproducible es `scripts/test_p13.sh`. Incluye pipeline/asset QA,
GDA, contratos P1.3, E2E de Stage 1, regresión P1.2, layouts 640×360 y
800×360, headless, generación determinista de evidencia y export Android.

Evidencias:

- `art/debug/p13_player_contact_sheet.png`
- `art/debug/p13_player_contact_sheet.svg`
- `art/debug/p13_collision_map.png`
- `art/debug/p13_ui_mockups.svg`

APK generado: `builds/android/rpg_stage1_liria_p13.apk`, 59,958,175 bytes,
`targetSdkVersion=36`, `screenOrientation=0`.

Image Generation P1.3: 0 llamadas.

## Estado de cierre

Cloud: PASS. El gate real de dispositivo y la aprobación visual humana quedan
pendientes. P2 sigue bloqueado.
