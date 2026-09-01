# SPRITE_TECH_SPEC.md
## RPG Fantasía Oscura — Especificación técnica de sprites temporales

**Objetivo:** crear placeholders que puedan ser reemplazados por arte final sin rehacer lógica, hitboxes o mapas.

---

# 1. Protagonista temporal

## Celda de atlas

Baseline:

**64 × 64 px por frame**

El personaje visible ocupa aproximadamente:

- 36–46 px de altura corporal;
- espacio adicional para arma/capa;
- pies centrados cerca de la zona inferior de la celda.

Esto no significa que todos los píxeles deban estar ocupados.

## Pivot

Punto lógico:
- centro entre los pies;
- ~8–12 px por encima del borde inferior.

Toda colisión y Y-sort dependen de los pies, no de la cabeza.

---

# 2. Proporción

Objetivo:
- adulto joven;
- cabeza moderadamente ampliada para lectura;
- torso y piernas claramente distinguibles;
- no chibi extremo.

El arma debe ser reconocible desde zoom de juego.

---

# 3. Dirección

Se exportan 8 direcciones:

```text
N
NE
E
SE
S
SW
W
NW
```

Para producción puede investigarse mirroring de E/W si no genera errores de mano/arma.

El placeholder debe contener las ocho direcciones de forma explícita para probar orientación.

---

# 4. Animaciones mínimas del protagonista

## Etapa 1

### Idle
- 2–4 frames × 8 dirs.

### Walk
- 6 frames × 8 dirs.

## Etapa 2

### Attack basic
- 6–8 frames × 8 dirs.

### Dodge
- 4–6 frames × 8 dirs.

### Hurt
- 2–3 frames × 8 dirs.

### KO
- 5–7 frames; puede usar menos variantes direccionales.

### Skill/Cast
- 4–6 frames × direcciones necesarias.

---

# 5. FPS de animación

Baseline:

- idle: 4–6 FPS;
- walk: 8–10 FPS;
- attack: 10–14 FPS;
- dodge: 12–16 FPS.

No interpolación suave de sprites.

---

# 6. Protagonista placeholder — identidad

El placeholder debe mostrar:

- cabello oscuro/castaño genérico;
- ropa de aventurero azul/gris;
- botas;
- cinturón;
- arma claramente visible.

Para la primera clase de prueba:
- espada de una mano.

Cuando se prueben otras clases:
- arma cambia;
- skeleton/celda permanecen compatibles.

No bloquear todavía apariencia definitiva del protagonista configurable.

---

# 7. Variantes de clase

Baseline temporal:

```text
Warrior    → sword/shield
Swordsman  → sword
Archer     → bow
Sorcerer   → staff/focus
Cleric     → mace/staff
```

El cuerpo base puede reutilizarse inicialmente.

---

# 8. NPC

NPC estándar:

- misma escala del protagonista;
- celda 64×64;
- idle 2–4;
- walk 6 si se desplaza.

NPC ambientales pueden usar:
- 4 direcciones temporalmente.

NPC reclutables/principales:
- 8 direcciones completas.

---

# 9. Iria

Placeholder:
- misma escala;
- arco visible;
- cabello/silueta diferenciados;
- tonos tierra/verde o rojo cálido;
- 8 direcciones;
- idle/walk;
- attack bow durante Etapa 2.

---

# 10. Halven

Placeholder:
- anciano;
- bastón/llaves/libro o elemento visual;
- escala ligeramente menor/encorvada;
- idle principal;
- 4 direcciones suficientes para slice.

---

# 11. Radan Korr

Placeholder:
- humano adulto robusto;
- armadura mercenaria;
- espada;
- corrupción visible sólo en fase 2.

Fase 2:
- overlay violeta/rojo;
- ojos;
- brazo/venas;
- VFX.

No crear aún un sprite completamente nuevo si un overlay permite validar el sistema.

---

# 12. Enemigos slice

## Mercenario melee
- rig humano base.

## Mercenario archer
- rig humano base.

## MOR Febril
- rig humano alterado.

## Centinela imperial
- rig propio constructo.

Objetivo:
validar pipelines, no producir el bestiario completo.

---

# 13. Hitboxes

La hitbox nunca cubre todo el sprite.

Baseline actor:
- cápsula/rectángulo centrado en pies;
- ancho aproximado 18–24 px;
- alto 12–20 px.

Attack hitboxes:
- independientes del sprite;
- activadas por frames/eventos.

---

# 14. Liria — tiles/props temporales

Aunque el escenario no sea estrictamente isométrico, mantener una grilla modular de producción.

Baseline:
- módulos de 32 px o 64 px;
- edificios compuestos en piezas;
- props separados.

Familias:
- ground;
- cobblestone;
- dirt;
- grass;
- flowers;
- walls;
- roof;
- doors/windows;
- fences;
- vegetation;
- marketplace;
- smithy;
- lamps;
- fountain/statue;
- debris/fire variants.

---

# 15. Escala de edificios

Casa pequeña:
- ~160–224 px de ancho lógico visible.

Herrería:
- ~192–256 px.

Árbol maduro:
- 80–128 px de alto visual.

Puerta:
- 32–40 px ancho;
- 56–72 px alto visual.

Estos valores se validan con personaje en escena.

---

# 16. Separación visual y colisión

Un árbol puede ocupar 120 px visualmente, pero su colisión sólo representa:
- tronco/base.

Edificios:
- colliders en paredes/base;
- techos/foreground en capas superiores.

---

# 17. Import settings Godot

Para pixel art:
- texture filtering: nearest;
- mipmaps: off salvo excepción;
- repeat sólo donde corresponda;
- compresión sin artefactos visibles.

---

# 18. Nomenclatura

Ejemplos:

```text
chr_player_temp_idle_s.png
chr_player_temp_walk_ne.png

chr_iria_temp_walk_w.png

env_liria_house_a.png
env_liria_tree_oak_a.png

enemy_radan_temp_phase1.png
enemy_radan_temp_phase2_overlay.png

ui_btn_attack_temp.png
```

En atlas final puede cambiar la organización, pero los IDs deben permanecer estables.

---

# 19. Criterio de aprobación del protagonista temporal

Debe poder:

- verse claramente en 640×360;
- orientarse en 8 direcciones;
- caminar sin jitter;
- mostrar espada;
- entrar por puertas sin parecer demasiado grande;
- moverse entre NPC sin perder lectura;
- reemplazarse sin cambiar hitbox/pivot.
