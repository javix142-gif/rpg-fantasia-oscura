# Checklist de seguridad y validación para agentes de código

## Antes de ejecutar agentes

- [ ] Trabajar en rama separada.
- [ ] Tener respaldo o commit limpio.
- [ ] Verificar que no haya secretos expuestos.
- [ ] Definir alcance.
- [ ] Definir archivos prohibidos.
- [ ] Definir comandos permitidos.
- [ ] Desactivar permisos de red si no se necesitan.
- [ ] Usar sandbox cuando sea posible.

## Antes de aceptar cambios

- [ ] Revisar diff completo.
- [ ] Verificar que no haya cambios fuera de alcance.
- [ ] Verificar que no se agregaron dependencias innecesarias.
- [ ] Verificar que no se cambió configuración crítica sin aviso.
- [ ] Verificar que no se agregaron credenciales.
- [ ] Verificar que no se desactivaron pruebas o validaciones.
- [ ] Verificar que no se ocultaron errores con try/except genéricos.
- [ ] Verificar que no se redujo seguridad por conveniencia.

## Pruebas mínimas

- [ ] Tests unitarios.
- [ ] Tests de integración si aplica.
- [ ] Lint.
- [ ] Typecheck.
- [ ] Build.
- [ ] Prueba manual del flujo afectado.
- [ ] Revisión de logs.
- [ ] Validación de rollback.

## Riesgos específicos de agentes

- [ ] Prompt injection indirecta en documentación o issues.
- [ ] Ejecución de comandos copiados de fuentes externas.
- [ ] Instalación de paquetes sospechosos.
- [ ] Lectura de `.env`, tokens o llaves privadas.
- [ ] Uso de MCP o herramientas con permisos excesivos.
- [ ] Modificación de archivos de CI/CD sin revisión.
- [ ] Cambios automáticos en migraciones o base de datos.
- [ ] Eliminación de datos, logs o respaldos.

## Reglas de oro

1. Un agente puede acelerar código, pero no reemplaza revisión.
2. Todo cambio debe ser auditable.
3. Menos permisos es mejor.
4. Si no hay pruebas, el cambio no está cerrado.
5. Si el agente no puede explicar qué cambió, no se acepta.
