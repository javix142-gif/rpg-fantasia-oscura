# P1 asset pipeline

La pipeline es determinista y no añade dependencias. Las fuentes seleccionadas
viven en `art/source/p1/selected/`; el runner de Godot usa `Image` para cargar
PNG, preservar alpha, recortar el rectángulo usado del personaje, normalizar
canvas, redimensionar con `INTERPOLATE_NEAREST`, guardar PNG y actualizar los
hashes del manifiesto. La imagen de Liria se conserva como familia visual
procesada; la composición jugable combina esa procedencia con módulos propios
dibujados por Godot.

No se corrigen anatomía, manos, armas ni perspectiva mediante algoritmos. Si un
asset falla la inspección visual, se reemplaza por otro intento o placeholder y
se registra deuda, nunca se oculta el fallo alterando píxeles automáticamente.

```bash
./scripts/asset_pipeline/process_assets.sh
./scripts/asset_pipeline/validate_assets.sh
```

`validate_assets.sh` verifica JSON, IDs, fuentes, hashes, salidas, dimensiones,
canvas, pivots, procedencia y que ninguna entrada use `references/**`.
