# PROJECT_STATE.md

## Objetivo
RPG de fantasía oscura para Android en Godot.

Vertical slice:
**Liria → ataque → consecuencias → Camino Prohibido → Ceniza → primera ruina de Cyrion.**

## Estado actual
**PROMPT 0 COMPLETADO**

Canon, sistemas 1–14, dirección visual y plan de vertical slice están
definidos. El gate Cloud se cerró sin iniciar gameplay.

Validado en Cloud:
- Godot 4.7.2 Standard y export templates 4.7.2;
- Eclipse Temurin JDK 17.0.20.1+1;
- Android SDK: command-line tools 15859902, platform-tools, API 36 y Build Tools 36.0.0;
- CPython 3.13.14, GDA 0.12.0 y GDA Skill project-scoped;
- proyecto smoke `game/`, validación headless y APK debug no vacío.

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
Esperar autorización explícita para iniciar la **Etapa 1**. No crear sistemas,
escenas de gameplay, quests ni assets finales antes de esa autorización.

## Regla
Prompt 0 está superado; no comenzar Etapa 1 sin autorización explícita.
