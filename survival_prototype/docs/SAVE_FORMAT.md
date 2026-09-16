# Ceniza Salvaje v0.3 — Save format

## Versión

`SAVE_VERSION = 4`.

La versión 3 del vertical slice se acepta como legacy y se migra en memoria a v4 antes de aplicarse. La migración actual no reescribe automáticamente un primary sólo por haber sido leído.

## Archivos

- primary: `user://ceniza_salvaje_v03_save.json`
- temporal: `user://ceniza_salvaje_v03_save.tmp`
- backup: `user://ceniza_salvaje_v03_save.bak`

## Escritura segura

Flujo de `save_state`:

1. duplicar snapshot y fijar `version = 4`;
2. validar estructura mínima;
3. serializar a JSON y volver a validar el payload;
4. escribir `.tmp`;
5. volver a leer/validar `.tmp`;
6. si existe primary, validarlo antes de tocarlo;
7. copiar el primary válido a `.bak` y validar el backup;
8. copiar `.tmp` al primary;
9. validar el primary final;
10. si la validación final falla y existía primary válido, restaurar sus bytes;
11. eliminar `.tmp` sólo al finalizar/abortar de forma controlada.

Un primary inválido nunca se usa como fuente para crear un backup ni se sobrescribe por un autosave normal.

## Lectura y corrupción

Orden:

1. primary válido → cargar primary;
2. primary inválido + backup válido → cargar backup y reportar el error del primary;
3. primary inválido + backup inválido/ausente → fallo de carga;
4. primary ausente + backup válido → cargar backup;
5. ninguno disponible → `save_missing`.

Si el runtime arranca con primary presente pero inválido, el juego protege el archivo y deja `save_blocked = true`. Puede mostrar una sesión temporal, pero no convierte silenciosamente ese error en un mundo nuevo guardado.

## Dirty state

`v03.gd` mantiene `save_dirty`. Los cambios persistentes llaman `_mark_dirty(reason)`. El autosave conserva su temporizador, pero `_save_game(false)` no serializa cuando el estado no cambió. Los saves explícitos pueden utilizar `force = true`, salvo que `save_blocked` esté activo.

## Datos persistidos

El snapshot v4 guarda:

- `version`;
- `seed`;
- posición de jugador y spawn;
- HP, hambre y stamina;
- reloj/día/clima;
- inventario;
- herramientas poseídas y herramienta/arma equipada;
- `chunk_mods` con diferencias del mundo base;
- construcciones con tipo, posición, rotación y contenido de cofre;
- `explored_chunks`;
- estado del tutorial.

## `chunk_mods`

Se conserva el modelo `mundo determinista + diferencias`. No se guarda el mapa completo. Las diferencias incluyen recursos eliminados, HP parcial de recursos y enemigos derrotados según el comportamiento actual del vertical slice.

## Política de migración

- Nunca reinterpretar silenciosamente una versión desconocida.
- Las migraciones deben ser explícitas, deterministas y cubiertas por regresión.
- Una versión no soportada debe fallar de forma segura antes de escribir.
- Toda futura modificación del schema debe mantener prueba roundtrip y prueba de corrupción/backup.
