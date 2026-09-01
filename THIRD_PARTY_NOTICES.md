# THIRD_PARTY_NOTICES.md

## Godot Engine
- baseline: 4.7.2 stable
- licencia: MIT
- estado: requerido

## gda / godot-agent
- baseline Prompt 0: 0.12.0
- fuente: `aigengame/godot-agent`, commit revisado `e61c407ab6a134a33ccc62872534df3715228286`
- licencia declarada en PyPI: MIT
- Python 3.13+
- estado: requerido para tooling agent-first
- GDA Skill debe generarse desde el CLI instalado

## Android SDK Command-line Tools
- baseline Prompt 0: 15859902 (Linux)
- fuente: Android Developers
- licencia: Android Software Development Kit License Agreement
- estado: requerido para instalar platform-tools, API 36 y Build Tools 36.0.0 en Cloud

## Eclipse Temurin OpenJDK
- baseline Prompt 0: 17.0.20.1+1 (Linux x64)
- fuente: Eclipse Adoptium API / adoptium/temurin17-binaries
- licencia: GPL-2.0 with Classpath Exception
- estado: JDK aislado bajo `.tools/jdk17/`; reemplaza el runtime incompleto del contenedor

## uv-managed CPython
- baseline Prompt 0: CPython 3.13+ instalado por `uv`
- fuente: Astral uv Python distributions
- estado: requerido para ejecutar GDA en un entorno aislado bajo `.tools/`

## GD-Agentic-Skills
- fuente candidata: `thedivergentai/GD-Agentic-Skills`
- commit revisado: `6a36f189d9c9b53b8c6769fb5c2cce8bfa5ad35c`
- licencia indicada por el proyecto: LGPL-3.0
- estado: no vendorizado/activado en este ZIP
- política: skills específicas, project-scoped, revisadas y registradas

## GUT
- candidato: 9.7.1 para Godot 4.7.x
- no instalado en Prompt 0

## Dialogue Manager
- candidato: 3.10.5 para Godot 4.7
- no instalado en Prompt 0

## Referencias visuales
`references/**` fue aportado por el usuario como referencia.
Estado: `REFERENCE_ONLY`.
No incluir en builds ni tratar como asset redistribuible.
