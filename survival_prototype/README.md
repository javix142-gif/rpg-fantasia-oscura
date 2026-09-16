# Ceniza Salvaje v0.3 — survival 2D procedural

Vertical slice Android autocontenido en Godot 4.7.2, 640×360 landscape y renderer Compatibility. La rama de estabilización conserva el gameplay de v0.3 y separa persistencia, worldgen, interacción, combate, IA, inventario, building, entorno, input e indexación espacial.

## Runtime activo

`project.godot → main.tscn → v03.gd`

`v03.gd` actúa como orchestrator. La arquitectura está descrita en `docs/ARCHITECTURE.md`.

## Sistemas existentes

- mundo determinista por seed y chunks;
- biomas bosque, pradera y cenizal;
- recursos y modificaciones persistentes por `chunk_mods`;
- fabricación de hacha, pico y vendas;
- construcción de fogata, muro y cofre funcional;
- lobo, acechador y saqueador;
- vida, hambre y stamina;
- combate con windup/active/recovery;
- inventario, equipamiento y cofres;
- ciclo día/noche y clima;
- minimapa/mapa explorado;
- tutorial/onboarding;
- controles táctiles y teclado de QA;
- save v4 con validación, `.tmp`, backup y migración v3→v4.

## Controles táctiles

- joystick izquierdo: mover/sprint por magnitud;
- A: atacar;
- E: interactuar/recolectar;
- botón de mochila: inventario/crafting/building;
- minimapa: abrir mapa;
- controles contextuales de paneles y placement se mantienen dentro del runtime.

## Teclado de QA

- WASD/flechas: movimiento;
- Shift: sprint;
- Espacio: ataque;
- E: interacción;
- I/Tab: inventario;
- C: crafting;
- B: building;
- M: mapa;
- F: comer;
- H: vendaje;
- Escape: cancelar/cerrar.

El antiguo atajo `N` para crear una seed nueva está deshabilitado en runtime estable para impedir sobrescrituras accidentales.

## Persistencia

El juego mantiene `mundo determinista + diferencias`; no serializa el mapa completo. Ver `docs/SAVE_FORMAT.md`.

Un primary corrupto no se reemplaza silenciosamente por una partida nueva. Se intenta backup válido y, cuando el primary inválido sigue presente, se bloquean escrituras automáticas hasta una recuperación explícita.

## Tests

La regresión headless vive en `tests/regression_runner.gd` y cubre determinismo, roundtrip, corrupción, backup, `chunk_mods`, building, chest, crafting y migración v3→v4.

Los tests y herramientas de QA se excluyen del APK mediante `export_presets.cfg`.

## Android

Preset `Android`:

- package: `org.cenizasalvaje.v03`;
- ARM64 únicamente;
- minSdk 24;
- targetSdk 35;
- landscape;
- debug APK para validación.

La prueba física de touch debe registrarse por separado; un smoke de CI no sustituye dispositivo real.

## Material histórico/tooling

`v02.gd`, `main.gd`, `v03_payload/`, `ci_*.py`, triggers y `tools/` se conservan para trazabilidad. No son entrypoints de v0.3 estabilizada y están excluidos del export Android. No se movieron durante el cierre para evitar romper referencias históricas/CI sin aportar valor al runtime.
