---
name: rpg-mobile-project-contract
description: Reglas persistentes del RPG móvil Godot. Usar al organizar, implementar, revisar, probar o exportar este proyecto. Protege canon, alcance, mobile-first, arquitectura data-driven, seguridad y gates.
---

# RPG Mobile Project Contract

## Leer primero
1. `/AGENTS.md`
2. `/PROJECT_STATE.md`
3. sólo documentos pertinentes bajo `/docs/`

No precargar todo el canon.

## Contrato
- Godot 4.7.2 Standard.
- GDScript tipado.
- Android landscape.
- Compatibility.
- 2D top-down/isométrico ligero.
- 640×360.
- party 3.
- ARPG + táctico CT.
- offline-first.
- data-driven.
- no backend/login/ads en slice.

## Canon
No modificar `docs/canon/**`.
Si falta detalle, usar placeholder y registrar supuesto.

## Visual
`references/**` es `REFERENCE_ONLY`.
Nunca copiar, trazar, recortar ni incluir en build.

Placeholders propios deben respetar escala/pivot/hitbox/layout.

## Arquitectura
Preferir composición, Resources tipados, runtime separado de definition, IDs estables, Conditions/Effects reutilizables, señales tipadas y Autoloads pequeños.

## Workflow
Explorar → plan → cambio acotado → tests → build → review diff → PROJECT_STATE.

## Prompt 0
No gameplay. Sólo infraestructura, tooling, smoke project y APK mínima.
