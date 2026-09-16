# Navegación futura — Ceniza Salvaje

## Limitación actual

Los enemigos usan movimiento directo y colisión geométrica local. Esto es suficiente para el vertical slice, pero no garantiza encontrar una ruta alrededor de estructuras complejas, corredores, cercos extensos o agrupaciones densas de construcciones.

## Mitigación actual

`enemy_system.gd` aplica una evitación simple: cuando el avance propuesto queda casi completamente bloqueado, intenta un paso lateral determinista. Esto reduce atascos triviales sin introducir un sistema de navegación nuevo.

## Problema futuro

Con bases grandes puede aparecer:

- enemigo oscilando frente a un muro;
- rutas locales sin salida;
- ataques que no encuentran una aproximación válida;
- acumulación de enemigos en cuellos de botella.

El sidestep no debe ampliarse indefinidamente hasta convertirse en un pathfinder improvisado.

## Alternativas recomendadas para una fase específica

Evaluar, con benchmark móvil antes de decidir:

1. navegación por grid/chunks con A* limitado al entorno activo;
2. grafo local generado alrededor de construcciones persistentes;
3. navegación jerárquica: ruta gruesa por chunk + evitación local;
4. steering/local avoidance combinado con una ruta discreta de baja frecuencia.

La solución futura debe respetar mundo procedural, carga por chunks, modificaciones persistentes y presupuesto Android. No se implementa pathfinding en la estabilización v0.3.
