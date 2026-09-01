# ASSET_QA — checklist reusable

Para cada asset producido:

- [ ] ID válido y único
- [ ] fuente registrada
- [ ] hash de fuente y salida registrado
- [ ] dimensiones correctas
- [ ] alpha válido
- [ ] fondo transparente cuando corresponde
- [ ] canvas consistente
- [ ] nearest-neighbor
- [ ] no se introdujo antialiasing
- [ ] paleta válida cuando aplique (`P1_PALETTE_V1`)
- [ ] pivot válido
- [ ] sin clipping
- [ ] frame count correcto
- [ ] direcciones correctas
- [ ] mirroring documentado
- [ ] spritesheet válido
- [ ] importación Godot correcta
- [ ] texture filtering nearest
- [ ] inspección visual realizada
- [ ] no proviene de `references/**`
- [ ] no contiene material externo no autorizado

La validación automática es `./scripts/asset_pipeline/validate_assets.sh`.
La aprobación visual del usuario sigue pendiente para `CHARACTER_MASTER`.
