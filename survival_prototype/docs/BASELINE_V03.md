# Baseline Ceniza Salvaje v0.3

## Fuente de verdad

- Rama base: `artifact/survival-v0.3-core-pass`
- Commit de gameplay usado como baseline: `bf205f11e77cd3e0c8c58cd92d323cb719517c82`
- Godot: `4.7.2.stable.official.ed1daf0bf`
- Escena principal: `res://main.tscn`
- Script activo: `res://v03.gd`
- Resolución lógica: `640×360`, landscape, GL Compatibility.
- Seed reproducible de pruebas: `424242`.

Los commits posteriores que sólo añadieron workflows de empaquetado/capturas no cambiaron el runtime de juego.

## Sistemas funcionales esperados

1. Mundo procedural determinista por seed y chunks 512×512.
2. Biomas bosque, pradera y cenizal.
3. Zona segura inicial sin spawn enemigo.
4. Recursos con HP, herramientas requeridas y `chunk_mods` persistentes.
5. Combate con stamina y estados windup/active/recovery.
6. Lobo, acechador y saqueador con patrones diferenciados.
7. Inventario, crafting, equipamiento, comida y vendajes.
8. Construcción de fogata, muro y cofre con preview/rotación.
9. Cofres con almacenamiento persistente.
10. Día/noche, clima y supervivencia.
11. Mapa/minimapa de chunks explorados.
12. Tutorial persistente.
13. Controles touch y teclado.
14. Save/load local.

## Controles baseline

### Touch

- Joystick izquierdo: movimiento; borde del joystick activa sprint.
- Botón espada: ataque.
- Botón mano: interacción/recolección/cofre.
- Botón mochila: inventario.
- Minimapa: mapa completo.
- Placement: confirmar, rotar, cancelar y drag del fantasma.

### Teclado

- WASD/flechas: mover.
- Shift: sprint.
- Espacio: atacar.
- E: interactuar.
- I/Tab: inventario.
- C: crafting.
- B: building.
- M: mapa.
- F: comer.
- H: vendaje.
- Escape: cerrar/cancelar.
- N: nuevo mundo en el baseline histórico; debe quedar protegido/deshabilitado durante estabilización.

## Smoke esperado

Al iniciar sin save debe crearse un mundo válido, verse el claro inicial, aceptar movimiento y mantener 5×5 chunks activos. Con seed de prueba `424242`, dos generaciones del mismo chunk deben producir la misma firma de recursos/enemigos.

## Evidencia visual baseline

Capturas automatizadas de la v0.3 anterior al refactor: release `ceniza-salvaje-v0.3-capturas`, con estados de gameplay, inventario, crafting, building, placement y mapa.

## Riesgo crítico conocido de baseline

El flujo histórico `save existe + _load_game() false -> _new_world() -> _save_game()` puede sobrescribir un save inválido. La suite de estabilización exige que el nuevo `SaveSystem` preserve el archivo primario inválido y utilice backup sólo si es válido.
