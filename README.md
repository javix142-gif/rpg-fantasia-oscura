# RPG Fantasía Oscura

Repositorio base para desarrollar el RPG móvil con Codex Cloud + Godot.

## Estado
**P1.1 CLOUD COMPLETADO / QA DE DISPOSITIVO PENDIENTE**

El gate Cloud de Prompt 0, Prompt 1 y su reparación P1.1 están validados.
Prompt 2 (ataque de Liria + combate ARPG) aún no ha comenzado y permanece
bloqueado hasta la prueba física y aprobación visual.

## Gates completados
Prompt 0 preparó y validó:
1. organizar/normalizar el repo;
2. preparar Godot 4.7.2;
3. preparar export templates;
4. preparar JDK 17 + Android SDK;
5. preparar GDA;
6. instalar GDA Skill project-scoped;
7. crear un proyecto Godot smoke bajo `game/`;
8. validar headless;
9. exportar una APK debug mínima.

Prompt 1 añadió la fundación jugable, Liria normal, MQ00_01, inventario,
save/load y el pipeline visual JIT. La validación reproducible de Stage 1 es:

```bash
./scripts/test_stage1.sh
```

P1.1 reparó la orientación Android landscape, safe area, interacción táctil,
animación real del jugador y la integración visual de Liria/NPC. El APK de
esta corrección es `builds/android/rpg_stage1_liria_p11.apk` (ignorado por
Git). `DEVICE_QA=PENDING`, `USER_VISUAL_APPROVAL=PENDING` y
`PROMPT_1_REAL=PENDING`.

La preparación se reproduce desde un checkout limpio con:

```bash
./scripts/codex/setup_cloud.sh
./scripts/validate.sh
```

Las dependencias se instalan de forma aislada bajo `.tools/` (ignorado por
Git). Para ejecuciones separadas:

```bash
./scripts/test_headless.sh
./scripts/build_android_debug.sh
```

El proyecto Godot se encuentra en `game/`. Prompt 0 genera
`builds/android/rpg_prompt0_smoke.apk`; Prompt 1 genera
`builds/android/rpg_stage1_liria.apk`; P1.1 genera
`builds/android/rpg_stage1_liria_p11.apk` (artefactos ignorados por Git).

## Fuente de verdad
- `docs/canon/`: canon narrativo.
- `docs/design/`: sistemas y alcance.
- `docs/visual/`: dirección artística.
- `docs/implementation/`: plan por etapas.
- `docs/tooling/`: tooling Cloud.
- `references/`: `REFERENCE_ONLY`, nunca assets del juego.
- `assets/`: assets propios.
- `game/`: proyecto Godot real.
