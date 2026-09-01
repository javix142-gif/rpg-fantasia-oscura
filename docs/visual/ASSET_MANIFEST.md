# ASSET_MANIFEST.md
## RPG Fantasía Oscura — Manifiesto de assets del vertical slice

Estados:

- `REFERENCE_ONLY`: imagen de inspiración; nunca usar directamente en build.
- `PLACEHOLDER_REQUIRED`: crear antes/durante el vertical slice.
- `PLACEHOLDER_OK`: puede ser muy simple.
- `FINAL_LATER`: no bloquear el slice.
- `FINAL_REQUIRED_BEFORE_RELEASE`: deberá reemplazarse antes de una release pública.

---

# 1. Referencias recibidas

Todas las imágenes dentro de `references/` son:

**REFERENCE_ONLY**

No:
- copiar;
- recortar sprites;
- reutilizar UI;
- trazar;
- incluir en APK.

---

# 2. Protagonista

| ID | Asset | Slice | Estado |
|---|---|---:|---|
| ASSET_PLAYER_BASE | cuerpo protagonista 8-dir | sí | PLACEHOLDER_REQUIRED |
| ASSET_PLAYER_SWORD | espada temporal | sí | PLACEHOLDER_REQUIRED |
| ASSET_PLAYER_IDLE | idle | sí | PLACEHOLDER_REQUIRED |
| ASSET_PLAYER_WALK | walk | sí | PLACEHOLDER_REQUIRED |
| ASSET_PLAYER_ATTACK | attack | Etapa 2 | PLACEHOLDER_REQUIRED |
| ASSET_PLAYER_DODGE | dodge | Etapa 2 | PLACEHOLDER_REQUIRED |
| ASSET_PLAYER_HURT | hurt | Etapa 2 | PLACEHOLDER_OK |
| ASSET_PLAYER_KO | KO | Etapa 2 | PLACEHOLDER_OK |
| PORTRAIT_PLAYER | retrato protagonista | sí | PLACEHOLDER_REQUIRED |

---

# 3. Personajes Liria

| ID | Asset | Estado |
|---|---|---|
| CHR_IRIA | sprite Iria | PLACEHOLDER_REQUIRED |
| PORTRAIT_IRIA | retrato Iria | PLACEHOLDER_REQUIRED |
| CHR_HALVEN | sprite Halven | PLACEHOLDER_REQUIRED |
| PORTRAIT_HALVEN | retrato Halven | PLACEHOLDER_REQUIRED |
| CHR_SMITH | herrero | PLACEHOLDER_REQUIRED |
| CHR_MERCHANT | comerciante | PLACEHOLDER_REQUIRED |
| CHR_VILLAGER_A | aldeano A | PLACEHOLDER_OK |
| CHR_VILLAGER_B | aldeano B | PLACEHOLDER_OK |
| CHR_VILLAGER_C | aldeano C | PLACEHOLDER_OK |
| CHR_VILLAGER_D | aldeano D | PLACEHOLDER_OK |

---

# 4. Enemigos

| ID | Asset | Estado |
|---|---|---|
| ENEMY_MERC_MELEE | mercenario melee | PLACEHOLDER_REQUIRED |
| ENEMY_MERC_ARCHER | mercenario arquero | PLACEHOLDER_REQUIRED |
| ENEMY_MOR_FEBRILE | Febril MOR | PLACEHOLDER_REQUIRED |
| ENEMY_RADAN_P1 | Radan fase 1 | PLACEHOLDER_REQUIRED |
| ENEMY_RADAN_P2_OVERLAY | corrupción Radan | PLACEHOLDER_REQUIRED |
| ENEMY_SENTINEL | Centinela imperial | Etapa 3 / PLACEHOLDER_REQUIRED |

---

# 5. Liria environment

## Ground

| ID | Estado |
|---|---|
| TILE_GRASS_A | PLACEHOLDER_REQUIRED |
| TILE_DIRT_A | PLACEHOLDER_REQUIRED |
| TILE_COBBLE_A | PLACEHOLDER_REQUIRED |
| TILE_COBBLE_EDGE | PLACEHOLDER_REQUIRED |
| TILE_FLOWERS_A | PLACEHOLDER_OK |

## Architecture

| ID | Estado |
|---|---|
| ENV_HOUSE_A | PLACEHOLDER_REQUIRED |
| ENV_HOUSE_B | PLACEHOLDER_REQUIRED |
| ENV_SMITHY | PLACEHOLDER_REQUIRED |
| ENV_HALVEN_BUILDING | PLACEHOLDER_REQUIRED |
| ENV_MARKET_STALL | PLACEHOLDER_REQUIRED |
| ENV_FENCE | PLACEHOLDER_REQUIRED |
| ENV_WALL_LOW | PLACEHOLDER_REQUIRED |

## Vegetation

| ID | Estado |
|---|---|
| ENV_TREE_OAK_A | PLACEHOLDER_REQUIRED |
| ENV_TREE_OAK_B | PLACEHOLDER_OK |
| ENV_BUSH_A | PLACEHOLDER_REQUIRED |
| ENV_FLOWER_PATCH | PLACEHOLDER_OK |

## Props

| ID | Estado |
|---|---|
| PROP_BARREL | PLACEHOLDER_OK |
| PROP_CRATE | PLACEHOLDER_OK |
| PROP_BENCH | PLACEHOLDER_OK |
| PROP_LAMP | PLACEHOLDER_REQUIRED |
| PROP_FOUNTAIN | PLACEHOLDER_REQUIRED |
| PROP_SMITH_ANVIL | PLACEHOLDER_REQUIRED |
| PROP_FRUIT_STALL | PLACEHOLDER_OK |

---

# 6. Liria ataque

Variantes:

| ID | Estado |
|---|---|
| VFX_FIRE_SMALL | PLACEHOLDER_REQUIRED |
| VFX_FIRE_LARGE | PLACEHOLDER_REQUIRED |
| VFX_SMOKE | PLACEHOLDER_REQUIRED |
| ENV_HOUSE_DAMAGE_OVERLAY | PLACEHOLDER_REQUIRED |
| PROP_DEBRIS_A | PLACEHOLDER_REQUIRED |
| PROP_BROKEN_CART | PLACEHOLDER_OK |
| PROP_BLOOD_SUBTLE | PLACEHOLDER_OK |

La escena debe reutilizar la mayor cantidad posible del Liria normal.

---

# 7. Camino Prohibido

| ID | Estado |
|---|---|
| TILE_OLD_IMPERIAL_ROAD | PLACEHOLDER_REQUIRED |
| PROP_IMPERIAL_MARKER | PLACEHOLDER_REQUIRED |
| ENV_RUIN_WALL_A | PLACEHOLDER_REQUIRED |
| ENV_RUIN_GATE | PLACEHOLDER_REQUIRED |
| VFX_RESONANCE_SYMBOL | PLACEHOLDER_REQUIRED |

---

# 8. Ceniza

Sólo distrito de entrada.

| ID | Estado |
|---|---|
| ENV_ASH_GATE | PLACEHOLDER_REQUIRED |
| ENV_ASH_MARKET | PLACEHOLDER_REQUIRED |
| ENV_CUSTODIA_POST | PLACEHOLDER_REQUIRED |
| CHR_MAEL_VAROS | PLACEHOLDER_REQUIRED |
| PORTRAIT_MAEL_VAROS | PLACEHOLDER_REQUIRED |
| CHR_CUSTODIA_GUARD | PLACEHOLDER_REQUIRED |
| CHR_RUINSEEKER | PLACEHOLDER_OK |

---

# 9. Cyrion Ruin 01

| ID | Estado |
|---|---|
| TILE_ILYRION_WHITE_STONE | PLACEHOLDER_REQUIRED |
| TILE_ILYRION_BLACK_METAL | PLACEHOLDER_REQUIRED |
| PROP_ILYRION_CRYSTAL | PLACEHOLDER_REQUIRED |
| PROP_FIVE_SLOT_TERMINAL | PLACEHOLDER_REQUIRED |
| VFX_ILYRION_LIGHT | PLACEHOLDER_REQUIRED |
| VFX_COLLAR_RESPONSE | PLACEHOLDER_REQUIRED |

---

# 10. UI

## HUD

| ID | Estado |
|---|---|
| UI_PANEL_STATUS | PLACEHOLDER_REQUIRED |
| UI_FRAME_PORTRAIT | PLACEHOLDER_REQUIRED |
| UI_BAR_HP | PLACEHOLDER_REQUIRED |
| UI_BAR_MP | PLACEHOLDER_REQUIRED |
| UI_PANEL_QUEST | PLACEHOLDER_REQUIRED |
| UI_PANEL_RESOURCE | PLACEHOLDER_REQUIRED |
| UI_MINIMAP_FRAME | PLACEHOLDER_REQUIRED |
| UI_JOYSTICK | PLACEHOLDER_REQUIRED |
| UI_BTN_ATTACK | PLACEHOLDER_REQUIRED |
| UI_BTN_DODGE | PLACEHOLDER_REQUIRED |
| UI_BTN_INTERACT | PLACEHOLDER_REQUIRED |
| UI_BTN_SKILL | PLACEHOLDER_REQUIRED |
| UI_BTN_ITEM | PLACEHOLDER_REQUIRED |
| UI_ICON_CORRUPTION | PLACEHOLDER_REQUIRED |

## Dialogue

| ID | Estado |
|---|---|
| UI_DIALOGUE_PANEL | PLACEHOLDER_REQUIRED |
| UI_DIALOGUE_CHOICE | PLACEHOLDER_REQUIRED |
| UI_DIALOGUE_ARROW | PLACEHOLDER_OK |

## Tactical

| ID | Estado |
|---|---|
| UI_TIMELINE_PANEL | PLACEHOLDER_REQUIRED |
| UI_GRID_MOVE | PLACEHOLDER_REQUIRED |
| UI_GRID_ATTACK | PLACEHOLDER_REQUIRED |
| UI_TACTICAL_ACTIONS | PLACEHOLDER_REQUIRED |
| UI_DAMAGE_PREVIEW | PLACEHOLDER_REQUIRED |

---

# 11. Icons

Crear un set temporal coherente:

- sword;
- bow;
- magic;
- heal;
- dodge;
- hand/interact;
- potion;
- quest;
- shop;
- smith;
- corruption;
- map;
- menu.

Todos originales/simples.

---

# 12. Arte que NO bloquea Etapa 1

Puede seguir como PLACEHOLDER_OK:

- VFX avanzados;
- animaciones ambientales;
- retratos emocionales adicionales;
- decoración secundaria;
- particles complejos;
- portraits de NPC menores;
- variantes estacionales.

---

# 13. Regla de producción

Antes de crear un asset nuevo preguntar:

1. ¿aparece en el vertical slice?
2. ¿afecta escala/hitbox/UI?
3. ¿puede reutilizar un asset existente?
4. ¿necesita ser final o sólo funcional?

No producir assets del juego completo antes de validar el slice.
