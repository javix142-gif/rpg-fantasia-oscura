# UI_VISUAL_SPEC.md
## RPG Fantasía Oscura — UI temporal dirigida por referencias

**Plataforma:** Android landscape  
**Resolución lógica base:** 640×360  
**Objetivo:** que la UI placeholder tenga distribución muy cercana a la definitiva.

---

# 1. Layout de exploración

Distribución base:

```text
┌──────────────────────────────────────────────────────────────┐
│ [RETRATO][NOMBRE/NIVEL]   [QUEST ACTIVA]   [MONEDA][CORR]   │
│ [HP==================]                       [MINIMAPA][≡]    │
│ [MP==================]                                      │
│                                                              │
│                                                              │
│                       MUNDO                                  │
│                                                              │
│                                                              │
│ [JOYSTICK]                                  [SKILL] [SKILL]  │
│                                               [ATQ]           │
│                                      [DODGE] [USE] [ITEM]     │
└──────────────────────────────────────────────────────────────┘
```

---

# 2. Superior izquierda

Mostrar protagonista:

- retrato cuadrado;
- nombre;
- nivel;
- HP;
- MP/recurso.

Tamaño orientativo:
- bloque: 150–180 px lógicos de ancho;
- altura: 48–60 px;
- retrato: 40–48 px.

En party:
- compañeros se representan de forma más compacta debajo o mediante retratos pequeños.

No mostrar todas sus estadísticas.

---

# 3. Superior centro

Quest activa:

- icono pequeño;
- título;
- una línea de objetivo.

Ejemplo:

```text
LA CARRETERA PROHIBIDA
Investiga el acceso imperial al norte.
```

Máximo:
- 2 líneas.

Debe poder ocultarse.

Durante conversaciones largas:
- reducir opacidad o esconderse.

---

# 4. Superior derecha

Bloques separados:

## Recursos

- Marcos;
- recurso especial sólo cuando sea pertinente.

## Corrupción

Mostrar:
- porcentaje/estado;
- icono Resonancia.

No llamar “maldad”.

## Minimapa

Pequeño.

Funciones:
- orientación;
- quest;
- tiendas;
- salida;
- peligro.

Botón menú integrado.

---

# 5. Inferior izquierda

Joystick.

Baseline:
- diámetro 92–110 px lógicos visuales;
- área táctil algo mayor;
- opacidad 60–80%;
- opción fija/flotante;
- modo zurdo invierte la UI.

No impedir ver el escenario.

---

# 6. Inferior derecha

Cluster principal.

Prioridad de tamaño:

1. ataque;
2. skill principal;
3. dodge;
4. interacción;
5. skills secundarias;
6. consumible.

## Ataque

Botón mayor.

Diámetro visual:
~54–64 px.

## Skills

~42–50 px.

## Dodge

~42–48 px.

## Interacción

Icono de mano u objeto contextual.

Cuando no exista interacción válida:
- desaparecer o quedar muy tenue.

## Consumible

Botón pequeño con contador.

---

# 7. Comportamiento adaptativo

## Exploración tranquila

- botones de combate al 65–80% de opacidad.

## En combate

- 100% opacidad;
- cooldowns visibles;
- feedback de impacto.

## En diálogo

Ocultar/reducir:
- botones secundarios;
- quest;
- parte del HUD.

Mantener sólo lo indispensable.

---

# 8. Diálogo

Panel inferior central.

Debe dejar visible:
- personaje;
- entorno;
- speaker.

Layout:

```text
┌─[RETRATO]─────────────────────────────────────────┐
│ NOMBRE                                             │
│ Texto del diálogo...                               │
│                                                    │
│                                        [continuar] │
└────────────────────────────────────────────────────┘
```

Tamaño:
- 55–70% del ancho de pantalla;
- 23–30% de altura.

No ocupar toda la pantalla salvo escenas narrativas especiales.

---

# 9. Elecciones

Cuando haya choices:

```text
┌──────────────────────────────────┐
│ ¿Qué haces?                       │
│                                   │
│ > Defender la plaza               │
│ > Buscar a tu familia             │
│ > Perseguir a los atacantes       │
└──────────────────────────────────┘
```

Cada opción debe tener:
- área táctil grande;
- texto claro;
- scroll si es necesario.

No indicar siempre consecuencias exactas.

---

# 10. Combate táctico

Timeline:
- arriba;
- 8–10 turnos.

Grid:
- centro.

Barra inferior:
- MOVER;
- ATACAR;
- SKILL;
- ITEM;
- ESPERAR.

Preview al apuntar:
- daño;
- crítico;
- elemento;
- debilidad/resistencia;
- casillas afectadas.

Colores deben tener iconos/patrones adicionales para accesibilidad.

---

# 11. Menús

Landscape, 3 columnas cuando sea útil.

Inventario:

```text
[CATEGORÍAS] [LISTA] [DETALLE/COMPARACIÓN]
```

Skills:

```text
[ÁRBOL] [DESCRIPCIÓN] [LOADOUT]
```

Facciones:

```text
[REGIÓN] [FACCIÓN] [ESTADO / BENEFICIOS]
```

---

# 12. Dirección visual

Baseline:
- panel carbón/negro cálido;
- borde bronce/oro apagado;
- esquinas moderadamente ornamentadas;
- textura discreta;
- iconos pixel art;
- barra HP roja;
- MP azul;
- Resonancia violeta.

Evitar:
- borde enorme;
- textura que reduzca lectura;
- exceso de dorado;
- UI moderna plana sin identidad.

---

# 13. Placeholder UI

Antes de arte final, crear:

- paneles de 9-slice;
- iconos monocromáticos propios simples;
- portrait frames;
- barras HP/MP;
- botones redondos;
- joystick;
- minimapa temporal.

Todos deben conservar tamaños y anchors finales aproximados.

---

# 14. Safe Area

Todos los controles táctiles se alojan dentro de `SafeAreaContainer`.

No asumir bordes utilizables.

---

# 15. Criterios para aprobar la UI temporal

- playable con pulgares;
- nada crítico bajo cutout;
- botones no se superponen;
- texto legible en teléfono de ~6";
- HUD no cubre más mundo del necesario;
- modo diálogo despeja pantalla;
- modo zurdo funcional;
- 16:9 y 20:9 correctos.
