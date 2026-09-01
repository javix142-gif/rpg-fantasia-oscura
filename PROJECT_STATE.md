# PROJECT_STATE.md

## Objetivo
RPG de fantasía oscura para Android en Godot.

Vertical slice:
**Liria → ataque → consecuencias → Camino Prohibido → Ceniza → primera ruina de Cyrion.**

## Estado actual
**PRE-IMPLEMENTACIÓN**

Canon, sistemas 1–14, dirección visual y plan de vertical slice están definidos.

Aún no está validado:
- entorno Godot en Codex Cloud;
- Android toolchain;
- GDA;
- export APK.

## Stack aprobado
- Godot 4.7.2 Standard.
- GDScript.
- Compatibility.
- Android landscape.
- 2D top-down/isométrico ligero.
- 640×360.
- GDA preferido.
- sin backend/login/ads.

## Prompt 0 activa
- Godot 4.7.2.
- export templates 4.7.2.
- JDK 17.
- Android SDK.
- GDA versionado.
- GDA Skill.
- skill propia `rpg-mobile-project-contract`.

## No activar todavía
- QuestSystem.
- LimboAI.
- State Charts.
- Phantom Camera.
- segundo MCP Godot.
- framework inventario.
- Aseprite Wizard.

## Candidatos posteriores
- GUT 9.7.1.
- Dialogue Manager 3.10.5.
- skills Godot específicas bajo demanda.

## Próximo gate
Ejecutar `PROMPT_0_CODEX_CLOUD.md`.

Debe terminar con:
- repo organizado;
- Godot headless;
- GDA;
- Android;
- APK smoke.

## Regla
No comenzar Etapa 1 antes de superar Prompt 0.
