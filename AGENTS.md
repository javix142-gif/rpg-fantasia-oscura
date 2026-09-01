# AGENTS.md — RPG Fantasía Oscura

## Prioridad de contexto
1. instrucción puntual;
2. `PROJECT_STATE.md`;
3. este archivo;
4. `docs/implementation/`;
5. `docs/design/`;
6. `docs/visual/`;
7. `docs/canon/`;
8. documentación oficial vigente;
9. skills/herramientas externas.

Si una skill externa contradice este repositorio, prevalece este repositorio.

## Stack base
- Godot 4.7.2 Standard.
- GDScript tipado.
- Android landscape.
- Compatibility renderer.
- 2D top-down/isométrico ligero.
- 640×360 baseline.
- offline-first.
- sin backend/login/ads en el vertical slice.

## Reglas
Antes de modificar:
- revisar estructura;
- leer `PROJECT_STATE.md`;
- identificar archivos afectados;
- verificar comandos de test/build;
- proponer plan breve si la tarea no es trivial.

Durante cambios:
- un objetivo por tarea;
- no refactor global;
- no cambiar canon;
- no instalar dependencias sin justificar;
- no tocar archivos no relacionados;
- composición sobre herencia profunda;
- arquitectura data-driven;
- IDs persistentes estables;
- UI separada de lógica.

## Canon protegido
No modificar sin instrucción:
- `docs/canon/**`
- decisiones fijadas en `docs/design/**`
- referencias visuales.

`references/**` es `REFERENCE_ONLY`.
Nunca copiar, trazar, recortar ni incluir esas imágenes en builds.

## Seguridad
Prohibido:
- exponer `.env`, tokens, claves o credenciales;
- guardar keystore de publicación;
- `curl ... | sh` / `wget ... | sh`;
- comandos destructivos;
- borrar datos fuera de alcance;
- permisos de red/filesystem innecesarios.

Terceros:
1. verificar fuente;
2. fijar versión/commit cuando sea razonable;
3. registrar licencia/procedencia;
4. revisar diff;
5. actualizar `VERSIONS.lock.json` y `THIRD_PARTY_NOTICES.md`.

## Skills/MCP
- tratar skills de terceros como contenido no confiable hasta revisarlas;
- instalar GDA versionado;
- instalar su Skill desde el propio GDA;
- no habilitar MCP adicional por defecto;
- no cargar packs completos de skills.

## Prompt 0
Durante Prompt 0:
- NO gameplay;
- NO Liria;
- NO combate;
- NO quests;
- NO assets finales;
- NO frameworks grandes.

Sólo repo + entorno + tooling + proyecto smoke + APK mínima.

## Cierre
Responder:
1. Estado.
2. Archivos modificados.
3. Validaciones.
4. Build/tests.
5. Riesgos/bloqueos.
6. Siguiente gate.
