# Política de ahorro de tokens para desarrollo con IA

## Principio central

No se ahorran tokens haciendo prompts vagos. Se ahorran tokens entregando el contexto correcto y eliminando ruido.

## Reglas prácticas

### 1. Separar contexto estable de contexto variable

Contexto estable:

- arquitectura;
- comandos;
- reglas;
- convenciones;
- estructura de carpetas;
- definición de terminado.

Debe ir en archivos persistentes como AGENTS.md, CLAUDE.md, reglas de Cursor, instrucciones de Copilot u OpenCode rules.

Contexto variable:

- tarea puntual;
- bug puntual;
- log recortado;
- archivo afectado;
- criterio de aceptación específico.

Debe ir en el prompt de la tarea.

### 2. Usar resúmenes de continuidad

Al terminar una sesión larga, pedir:

> Resume el estado para continuar en otra sesión con mínimo contexto.

Guardar ese resumen como `PROJECT_STATE.md` o `SESSION_SUMMARY.md`.

### 3. Evitar pegar todo

No pegar:

- archivos completos si solo importan 30 líneas;
- logs de miles de líneas;
- conversaciones enteras;
- documentación histórica sin marcar;
- duplicados.

Sí pegar:

- error exacto;
- stack trace relevante;
- función afectada;
- contrato esperado;
- ejemplo de entrada/salida;
- restricciones.

### 4. Mantener prompts modulares

Malo:

> Haz toda la app completa, revisa todo, mejora todo, optimiza todo y deja perfecto.

Bueno:

> Revisa solo el módulo de autenticación. Identifica causa del error X. Propón plan. No modifiques archivos.

### 5. Usar fases

- explorar;
- planificar;
- implementar;
- probar;
- revisar;
- documentar.

Cada fase consume menos que una instrucción gigante mal delimitada.

### 6. Controlar salida

Pedir salidas breves cuando no se necesita explicación extensa:

- “máximo 10 puntos”;
- “solo tabla”;
- “solo archivos modificados y pruebas”;
- “no repitas contexto”.

### 7. Usar caché cuando exista

En API, mantener prefijos estables:

- system prompt fijo;
- reglas estables arriba;
- documentación estable antes del prompt variable;
- datos dinámicos al final.

Esto mejora probabilidad de cache hit en sistemas con prompt caching.

### 8. Evitar razonamiento excesivo en tareas simples

Usar modelos/ajustes más baratos o rápidos para:

- formato;
- documentación simple;
- renombrar variables;
- pruebas simples;
- explicación de código.

Reservar modelos de mayor razonamiento para:

- arquitectura;
- bugs complejos;
- migraciones;
- refactors grandes;
- seguridad;
- concurrencia;
- bases de datos;
- cambios con alto riesgo.

### 9. Mantener documentación viva

Cuando el agente se equivoque dos veces en lo mismo, actualizar reglas persistentes.

Ejemplo:

- “No usar pandas si la planilla supera X filas sin justificar.”
- “No cambiar formato de Excel salvo instrucción explícita.”
- “No tocar base operativa; trabajar sobre copia.”

### 10. Presupuesto antes de tarea grande

Antes de una tarea grande, pedir:

> Divide esto en subtareas pequeñas ordenadas por impacto y dependencia, optimizadas para consumir menos tokens y reducir riesgo.
