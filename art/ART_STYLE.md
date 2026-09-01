# ART_STYLE — Operacional P1

**Estado:** provisional, derivado de `docs/visual/ART_DIRECTION.md`,
`SPRITE_TECH_SPEC.md` y `UI_VISUAL_SPEC.md`. No es arte definitivo.

## Lenguaje visual

- Perspectiva 3/4 top-down con isometría ligera, control legible y Y-sort por
  la base de los pies.
- Pixel art moderno de lectura 16/32-bit: siluetas adultas claras, arma y
  peinado reconocibles; evitar chibi extremo y prerender 3D.
- Liria es cálida, acogedora, colorida y densa: madera, piedra, teja,
  vegetación, flores, huertas, plaza y puestos pequeños.
- Iluminación de tarde consistente; la oscuridad dramática queda reservada
  para etapas posteriores y no vuelve gris todo el mundo.

## Escala y procesamiento

- Actor: celda de atlas **64×64 px**, altura visible aproximada 36–46 px.
- Pivot lógico: centro entre los pies, 8–12 px sobre el borde inferior; las
  colisiones representan sólo el volumen físico de los pies/tronco.
- Módulos ambientales: 32×32 o 64×64 px; casas 160–224 px, herrería
  192–256 px, árboles 80–128 px de altura, puertas 32–40×56–72 px.
- Pipeline: alpha preservado, recorte sólo cuando corresponde, canvas estable,
  resize nearest-neighbor, sin antialiasing ni interpolación posterior.
- Outline oscuro cálido coherente cuando la silueta lo necesite; no aplicar
  contorno automático para corregir errores anatómicos.

## `P1_PALETTE_V1`

Paleta abierta pero controlada, con IDs estables para refinar en P5:

| Familia | Guía |
|---|---|
| Verde natural | hierba, hojas y huertas, saturación media |
| Marrón cálido | madera, tierra, cuero y troncos |
| Piedra | beige/gris con sombras azuladas suaves |
| Teja roja | tejados y pequeños acentos arquitectónicos |
| Azul pizarra | telas y sombras apagadas |
| Dorado cálido | luz, herrajes y foco narrativo |
| Floral | pocos acentos amarillo, blanco, rojo o azul |

No usar neón, bloom excesivo ni cinco estilos incompatibles. Mantener contraste
de luminancia entre personaje, suelo y props.

## UI móvil

Panel carbón cálido con borde bronce/oro apagado, tipografía renderizada por
Godot y botones de pulgar grandes. HUD a 640×360 en landscape, con safe-area:
retrato/nombre/HP/MP arriba a la izquierda, quest en el centro, menú arriba a
la derecha, joystick abajo a la izquierda, interacción abajo a la derecha y
diálogo en panel inferior central. No rasterizar texto generado, no cubrir
controles bajo cutouts y no usar UI gacha plana.

## Prohibiciones P1

No copiar, trazar, recortar o recolorear `references/**`; no mezclar sus
imágenes con el build. No producir aún ataque, dodge, hurt, KO, VFX, Radan,
MOR, Centinela, Ceniza o Cyrion. Los placeholders pueden carecer de detalle,
pero nunca de escala, pivot, orientación, hitbox o composición prevista.

## Integración visual P1.1

La reparación de dispositivo usa tres fuentes propias seleccionadas en
`art/source/p1_1/selected/`: una escena completa de Liria, una hoja de
animación del jugador y una familia de NPC. La pipeline las convierte a
salidas RGBA8 nearest en `game/assets/p1_1/`; el juego consume esas salidas,
nunca la hoja de preview completa ni material de `references/**`.

- `player_sheet.png`: 8 filas direccionales × 6 frames en celdas 64×64;
  idle usa dos frames y walk cuatro frames por dirección.
- `npc_sheet.png`: cinco variantes de 64×64 para Iria, Halven, herrero,
  comerciante y amigo; los aldeanos reutilizan la última variante.
- `liria_scene.png`: escena authored de 960×640, escalada con nearest y
  colocada detrás de capas técnicas; `TileMapLayer` conserva una base de
  césped real para extensión posterior.

Estado de aprobación: fuentes y salidas fueron inspeccionadas visualmente en
Cloud; `CHARACTER_MASTER_STATUS=P1_PROVISIONAL` y la aprobación subjetiva en
dispositivo siguen pendientes. Estas piezas establecen identidad P1.1, no
arte final.
