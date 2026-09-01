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
La aprobación visual del usuario sigue pendiente para `CHARACTER_MASTER` y
para la composición móvil completa.

## Estados de trazabilidad

Cada entrada del manifest puede avanzar por estos estados, sin confundir
existencia de un PNG con integración jugable:

1. `GENERATED`: fuente creada mediante la capacidad nativa de Image
   Generation y conservada en `art/source/**/selected/`.
2. `PROCESSED`: salida determinista generada por la pipeline, con hash,
   canvas, alpha y filtrado registrados.
3. `INTEGRATED_IN_GAME`: una escena o script del proyecto carga la salida.
4. `VISUALLY_VALIDATED`: inspección visual de la salida integrada realizada.

En P1.1, `ASSET_P11_LIRIA_SCENE`, `ASSET_P11_PLAYER_SHEET` y
`ASSET_P11_NPC_SHEET` están `INTEGRATED_IN_GAME` y
`VISUALLY_VALIDATED`; las fuentes permanecen separadas de las salidas. La
captura de pantalla runtime se intentó con el renderer headless disponible,
pero ese renderer no expone una textura de viewport; por ello la aprobación
de dispositivo no se infiere de esta checklist.
