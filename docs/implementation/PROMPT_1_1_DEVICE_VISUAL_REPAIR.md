# P1.1 — Reparación de dispositivo y visual de Prompt 1

Estado: reparación en curso sobre `work/p1.1-device-visual-repair`. Este
documento registra el diagnóstico y el alcance de la corrección; no inicia
P2 ni convierte el arte provisional en arte final.

## Diagnóstico de P1

| Área | Causa observada | Corrección aplicada |
|---|---|---|
| Android | El preset no expresaba de forma inequívoca el contrato landscape y el proyecto no fijaba la orientación handheld. | `screen/orientation=0`, `handheld/orientation=0` y una confirmación runtime con `DisplayServer.SCREEN_LANDSCAPE`; el export sigue usando 640×360. |
| Viewport | El layout dependía de coordenadas absolutas y no expandía el canvas en ratios anchos. | `stretch/aspect=expand`, `SafeAreaContainer` con márgenes derivados del área segura y HUD anclado a contenedores relativos. |
| Touch | El flujo de prueba consultaba el NPC más cercano y podía exigir una superposición poco natural. | `InteractionSensor` como `Area2D`, selección estable por distancia, prompt contextual y botón público `request_interaction()`. |
| Player | Un único `Sprite2D` se desplazaba verticalmente para simular walk. | `AnimatedSprite2D` con `SpriteFrames` idle (2) y walk (4) para ocho filas direccionales; el movimiento conserva `CharacterBody2D`. |
| Liria | La apariencia principal provenía de `draw_*` y de figuras de depuración. | Escena authored procesada (`liria_scene.png`) detrás de capas técnicas, `TileMapLayer` de césped real y colisiones separadas. |
| NPC | Iria, Halven y aldeanos eran primitivas geométricas y mostraban etiquetas internas. | Hoja de cinco variantes coherentes, `Sprite2D` por rol, sombras discretas y nombres sólo en el diálogo. |
| HUD | Texto de estados/IDs y paneles sobredimensionados invadían la pantalla. | Objetivos narrativos legibles, menú para save/load, inventario contextual, joystick 90 px lógicos y paneles anclados. |

## Pipeline y provenance

P1.1 usa únicamente la capacidad nativa de Image Generation, con tres
llamadas: escena de Liria, hoja animada del jugador y familia de NPC. Las
fuentes seleccionadas viven en `art/source/p1_1/selected/` y las salidas
deterministas en `game/assets/p1_1/`.

`scripts/asset_pipeline/process_assets.sh` ejecuta las operaciones Godot
`Image` de alpha/crop/canvas/nearest y actualiza hashes del manifest.
`validate_assets.sh` comprueba JSON, fuentes, salidas, dimensiones, alpha,
pivots, frame count y hashes. No se instaló ninguna dependencia de arte ni se
tocó `references/**`.

## Validación y límites

`scripts/test_stage1.sh` agrupa el contrato de orientación, viewport, assets
authored, GDA, headless, E2E de MQ00_01 y exportación Android. Además ejecuta
`p11_layout_contract.gd` con 640×360 (16:9) y 800×360 (ratio ancho 20:9
aproximado), comprobando anclajes y límites dentro del contenido seguro. El renderer
headless disponible no expone textura de viewport para screenshots; se intentó
la captura en `game/tests/p11_visual_capture.gd` y se informa como
`SKIP_NO_RENDERER` cuando corresponde. Las salidas PNG procesadas sí fueron
inspeccionadas visualmente en Cloud.

La reparación puede cerrar `P1.1_CLOUD` sólo después de que todas las
validaciones reproducibles pasen. Aun entonces quedan explícitamente:

```text
DEVICE_QA=PENDING
USER_VISUAL_APPROVAL=PENDING
PROMPT_1_REAL=PENDING
LISTO_PARA_PROMPT_2=NO
```

El APK de esta reparación se genera fuera del historial Git como
`builds/android/rpg_stage1_liria_p11.apk`.
