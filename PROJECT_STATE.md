# PROJECT_STATE.md

## Objetivo
RPG de fantasía oscura para Android en Godot.

Vertical slice:
**Liria → ataque → consecuencias → Camino Prohibido → Ceniza → primera ruina de Cyrion.**

## Estado actual
**PROMPT 0 COMPLETADO — PROMPT 1 COMPLETADO**

Canon, sistemas 1–14, dirección visual y plan de vertical slice están
definidos. La primera versión jugable de Liria normal está implementada sin
iniciar el ataque ni ningún sistema de P2.

Validado en Cloud:
- Godot 4.7.2 Standard y export templates 4.7.2;
- Eclipse Temurin JDK 17.0.20.1+1;
- Android SDK: command-line tools 15859902, platform-tools, API 36 y Build Tools 36.0.0;
- CPython 3.13.14, GDA 0.12.0 y GDA Skill project-scoped;
- proyecto smoke `game/`, validación headless y APK debug no vacío;
- pipeline visual P1 con fuentes seleccionadas, hashes y validación
  determinista;
- fundación `GameState`, definiciones tipadas, interacción, diálogo,
  MQ00_01, inventario y `SaveService` versionado;
- Liria compacta con jugador `CharacterBody2D`, ocho direcciones, joystick,
  cámara, NPC y HUD responsive;
- gate Stage 1 y APK `builds/android/rpg_stage1_liria.apk` validados.

Pendientes de validación manual: instalación/sensación en dispositivo
Android y aprobación visual del usuario. El personaje y el arte de P1 son
provisionales; no se declaran arte definitivo.

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
**P2 — Ataque de Liria + combate ARPG.** Requiere una autorización explícita
del usuario. No comenzar P2 automáticamente.

## Regla
P1 está superado; el ataque, el combate ARPG y los sistemas posteriores no
están implementados.
