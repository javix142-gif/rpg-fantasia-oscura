# Ceniza Salvaje v0.3 — Arquitectura estabilizada

## Entry point

`project.godot` ejecuta `main.tscn`; la escena instancia `v03.gd`. `v03.gd` es el bootstrap/orchestrator del vertical slice y coordina los módulos siguientes.

## Responsabilidades

- `core/game_state.gd`: crea y aplica snapshots de estado persistente. No escribe archivos.
- `world/world_generator.gd`: seed, ruido, biomas, coordenadas/chunks, contenido procedural y colores de terreno. El mundo base sigue siendo determinista.
- `world/spatial_index.gd`: índice `buildings_by_chunk` y consultas de construcciones cercanas. No es fuente de verdad; `buildings` sigue siendo la colección persistente.
- `systems/persistence/save_system.gd`: validación, migración v3→v4, primary/temp/backup y escritura segura.
- `systems/input/input_actions.gd`: acciones de teclado/InputMap. El touch continúa resuelto por el orchestrator para preservar el comportamiento móvil existente.
- `systems/interaction/interaction_system.gd`: selección de interactuables cercanos y contrato ligero de interacción.
- `systems/interaction/harvest_system.gd`: comienzo/cancelación/finalización de recolección y actualización de `chunk_mods`.
- `systems/combat/combat_system.gd`: ataque del jugador, timing windup/active/recovery, stamina y resolución de impactos.
- `systems/enemies/enemy_system.gd`: IA de lobo/acechador/saqueador, daño, muerte, separación y sidestep simple ante bloqueo.
- `systems/inventory/inventory_system.gd`: costes, crafting, equipamiento, comida, vendas y transferencias de cofre.
- `systems/building/building_system.gd`: selección, preview lógico, validación de placement, colocación y cancelación.
- `systems/environment/day_weather_system.gd`: ciclo temporal, clima, hambre y efecto de fogata.
- `ui/world_renderer.gd`: ordenación visual por Y de recursos, enemigos y construcciones usando los draw helpers existentes.

## Responsabilidades que permanecen en `v03.gd`

`v03.gd` conserva deliberadamente:

- bootstrap y coordinación del game loop;
- estado runtime compartido del vertical slice;
- carga/descarga de chunks activos;
- colisiones geométricas y helpers de mundo usados por varios sistemas;
- entrada touch y hit-testing de la UI móvil;
- dibujo procedural de terreno, jugador, HUD, minimapa/mapa, menús, FX y controles táctiles;
- audio procedural y mensajes/feedback;
- tutorial/onboarding;
- wrappers delgados hacia módulos.

No se siguió extrayendo UI/helpers sólo para reducir líneas: el objetivo de esta fase es estabilidad, no alcanzar una cifra artificial.

## Estado espacial

La fuente de verdad se mantiene compatible:

- `loaded_chunks`: sólo chunks activos;
- `chunk_mods`: diferencias persistentes contra el mundo determinista;
- `explored_chunks`: chunks visitados;
- `buildings`: lista persistente de construcciones/cofres;
- `buildings_by_chunk`: índice derivado para consultas locales.

Las consultas de recursos/enemigos trabajan sobre el chunk actual y vecinos cargados. Las consultas de construcciones cercanas usan `buildings_by_chunk` cuando corresponde.

## Límite arquitectónico futuro

La estructura permite evolucionar más adelante hacia `World → Biome → Zone/Chunk → Location → Vegetation/Spawn/Persistent Entities` sin cambiar en esta estabilización el worldgen ni introducir Locations.
