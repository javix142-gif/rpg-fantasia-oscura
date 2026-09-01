# Flujo de desarrollo asistido por IA

## Fase 0: Preparación del contexto

Objetivo: evitar gasto innecesario de tokens y errores por falta de contexto.

Entregar al agente:

- objetivo concreto;
- carpeta o módulo afectado;
- archivos relevantes;
- ejemplo de comportamiento actual;
- ejemplo de comportamiento esperado;
- comandos de validación;
- restricciones.

No entregar al agente:

- todo el repositorio si solo cambia un módulo;
- logs largos sin recortar;
- conversaciones completas sin resumen;
- documentación antigua no marcada;
- datos sensibles.

## Fase 1: Exploración sin cambios

Prompt recomendado:

> Revisa el proyecto solo en modo lectura. Identifica estructura, archivos relevantes, flujo actual, riesgos y una propuesta de plan. No modifiques archivos.

Resultado esperado:

- mapa del módulo;
- archivos afectados;
- hipótesis de solución;
- riesgos;
- plan breve.

## Fase 2: Especificación

Antes de programar, exigir:

- requisito funcional;
- requisito no funcional;
- entrada;
- salida;
- errores esperados;
- casos borde;
- criterios de aceptación.

## Fase 3: Implementación controlada

Prompt recomendado:

> Implementa solo el punto 1 del plan. No hagas refactors globales. Mantén compatibilidad. Al terminar, muestra diff conceptual y pruebas necesarias.

Reglas:

- una tarea por prompt;
- cambios pequeños;
- evitar “ya que estamos”;
- no mezclar feature + refactor + cambio visual + migración.

## Fase 4: Pruebas

Pedir al agente:

- agregar pruebas si corresponde;
- ejecutar pruebas existentes;
- revisar errores;
- corregir solo lo relacionado;
- no ocultar fallas no resueltas.

## Fase 5: Revisión del diff

Prompt recomendado:

> Revisa el diff como revisor senior. Busca bugs, regresiones, problemas de seguridad, inconsistencias de estilo, duplicación y falta de pruebas. No modifiques archivos todavía.

## Fase 6: Documentación mínima

Documentar solo lo necesario:

- cómo ejecutar;
- cómo probar;
- qué cambió;
- qué no cambió;
- supuestos;
- limitaciones.

## Fase 7: Cierre

El cierre debe incluir:

- resumen;
- archivos modificados;
- pruebas ejecutadas;
- pendientes;
- riesgos;
- rollback sugerido si aplica.
