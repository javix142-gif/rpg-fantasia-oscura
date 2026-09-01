# Prompt 1 — Fundación + Liria + pipeline visual JIT

Estado de esta implementación: **P1 provisional**. El gate cloud automatizado
queda separado de la aprobación visual y de las pruebas en teléfono.

## Arquitectura

- `GameState` mantiene un estado serializable mínimo y estable (player, party,
  world, quests, factions, economy, corruption e inventory). `LIRIA` sólo puede
  estar en `NORMAL` en P1.
- `SaveService` escribe JSON versionado bajo `user://`, valida un temporal antes
  de reemplazar y conserva backup; no deserializa objetos arbitrarios.
- `SceneRouter` y `EventBus` son autoloads pequeños. Las definiciones de actor,
  item, quest y diálogo son Resources tipados; el catálogo de diálogo usa IDs,
  condiciones y efectos reutilizables.
- `PlayerController` es `CharacterBody2D`: teclado y `Stage1VirtualJoystick`
  alimentan el mismo `movement_input`, con ocho direcciones, diagonal
  normalizada, cámara con límites y colisión de pies.
- `VillageWorld` compone una Liria normal compacta con plaza/fuente,
  residencial, edificio de Halven, herrería, mercado, huertas, árboles,
  caminos, vallas, lámparas y seis vecinos ambientales. Mantiene un
  `TileMapLayer` para el futuro atlas y separa la composición visual de la
  colisión física.
- `Stage1Hud`, `DialoguePanel` y `Stage1SafeAreaContainer` son UI separada de
  la lógica. El diálogo demuestra choice, condition y effects. MQ00_01 avanza
  `NOT_STARTED → ACTIVE → item/stage 3 → COMPLETE` sin iniciar MQ00_02.

## Pipeline visual

`art/ART_STYLE.md` deriva la operación de las especificaciones visuales
protegidas. Las dos llamadas nativas de Image Generation de P1 produjeron el
master de personaje y la familia visual de Liria; se guardaron únicamente las
fuentes seleccionadas. `scripts/asset_pipeline/` usa Godot `Image` para
alpha/crop/canvas/nearest/hash/validación y actualiza `art/ASSET_MANIFEST.json`.
No se añadió Pillow, ImageMagick, ComfyUI, Stable Diffusion ni APIs externas.

El master se procesa a `game/assets/p1/player_master.png` (64×64) y a un
retrato (96×96); el kit propio de Liria se normaliza a 768×512. Los NPC,
props, suelo y UI restantes son placeholders procedurales deterministas con
IDs y pivots registrados. El walk de seis frames queda como deuda visual
controlada: P1 usa movimiento bob de un frame estable, sin falsear continuidad.

## Validación reproducible

```text
./scripts/codex/validate_repo.sh
./scripts/validate.sh
./scripts/asset_pipeline/validate_assets.sh
./scripts/test_stage1.sh
```

`tests/stage1_e2e.gd` ejecuta la progresión de diálogo/quest/inventario,
prueba movimiento runtime y verifica save/load, backup y save corrupto sin
crash. El APK se genera fuera de Git en
`builds/android/rpg_stage1_liria.apk`.

## Alcance y pendientes

P1 no implementa ataque, ARPG, combate táctico, Radan, enemigos, destrucción de
Liria, Ceniza ni Cyrion. `CHARACTER_MASTER_STATUS=P1_PROVISIONAL`: el usuario
debe aprobar visualmente el master y probar instalación, joystick, safe area,
background/resume, lectura y rendimiento en un dispositivo Android real.
