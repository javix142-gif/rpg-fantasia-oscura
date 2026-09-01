# CODEX_CLOUD_SETUP_SPEC

## Objetivo
Desarrollar y compilar desde Codex Cloud sin exigir Godot instalado en el PC del usuario.

## Baseline
- Godot 4.7.2 Standard.
- export templates 4.7.2.
- OpenJDK 17.
- Android target API 36.
- GDA 0.12.0 baseline / Python 3.13+.
- GDA Skill desde el propio CLI.
- GDA MCP no obligatorio inicialmente.

## Preflight
Antes de instalar:

```bash
uname -a
python3 --version || true
uv --version || true
java -version || true
adb --version || true
sdkmanager --version || true
godot --version || true
gda --version || true
```

No asumir herramientas.

## Seguridad
- no `curl | sh`;
- no scripts remotos sin inspección;
- no secretos;
- debug signing solamente;
- verificar checksums;
- registrar terceros.

## Resultado Prompt 0
- Godot headless válido;
- GDA válido;
- proyecto smoke;
- APK debug;
- scripts reproducibles;
- PROJECT_STATE actualizado.
