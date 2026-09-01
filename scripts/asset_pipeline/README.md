# P1/P1.1 asset pipeline

La pipeline es determinista y no añade dependencias. Las fuentes seleccionadas
viven en `art/source/p1/selected/` y `art/source/p1_1/selected/`; el runner de
Godot usa `Image` para cargar PNG, preservar alpha, recortar el rectángulo
usado, normalizar canvas, redimensionar con `INTERPOLATE_NEAREST`, guardar
salidas y actualizar los hashes del manifiesto. P1.1 procesa la escena authored
de Liria, la hoja animada del jugador y la familia de NPC en
`game/assets/p1_1/`; esas salidas son las que consumen las escenas del juego.

No se corrigen anatomía, manos, armas ni perspectiva mediante algoritmos. Si un
asset falla la inspección visual, se reemplaza por otro intento o placeholder y
se registra deuda, nunca se oculta el fallo alterando píxeles automáticamente.

```bash
./scripts/asset_pipeline/process_assets.sh
./scripts/asset_pipeline/validate_assets.sh
```

`validate_assets.sh` verifica JSON, IDs, fuentes, hashes, salidas, dimensiones,
canvas, alpha, pivots, procedencia y que ninguna entrada use `references/**`.
