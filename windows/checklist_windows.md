# Checklist de Hardening — Windows (20 puntos)

> Marca `[x]` cada punto completado. Base: CIS Windows Benchmarks / directrices de Microsoft.

## Cuentas y autenticación
- [ ] Desactivar la cuenta Administrador integrada o renombrarla con nombre no trivial
- [ ] Cuentas locales con contraseñas fuertes (15+ caracteres)
- [ ] **LAPS** (Local Administrator Password Solution) para contraseñas de admin local
- [ ] Desactivar invitados y cuentas deshabilitadas: `Get-LocalUser`
- [ ] MFA obligatorio (p. ej. Windows Hello, Microsoft Entra MFA)

## Protección del sistema
- [ ] Windows Defender activo + protección en tiempo real
- [ ] **Protección en la nube y envío automático de muestras** activados
- [ ] SmartScreen activado (apps y Edge)
- [ ] UAC al máximo: Panel → Cuentas → Configuración de control de cuentas
- [ ] Actualizaciones automáticas activadas (nunca "pausar")

## Red y protocolos
- [ ] Desactivar SMBv1: `Set-SmbServerConfiguration -EnableSMB1Protocol $false`
- [ ] Desactivar protocolos heredados (NetBIOS sobre TCP/IP si no hace falta)
- [ ] Firewall de Windows: perfiles `Domain/Private` = permitido solo lo necesario
- [ ] Segmentar: el equipo de administración nunca en la red de invitados

## Sistema de archivos y datos
- [ ] **BitLocker** en todas las unidades (TPM o arranque por clave)
- [ ] Cifrar copias de seguridad y verificar restauración
- [ ] NTFS: revisar ACLs de carpetas compartidas y "shared permissions"

## Visibilidad y auditoría
- [ ] Directivas de auditoría: logon, cambios de cuenta, ejecución de procesos (4688)
- [ ] Habilitar **PowerShell transcript/logging** (registro de script blocks — evento 4104)
- [ ] Conectar eventos al SIEM/Wazuh (repo `soc-blue-team`)
- [ ] Desinstalar software no usado y bloquear instalaciones con Elevation/MDM

---
**Fecha de auditoría:** _____ · **Host:** _____ · **Notas:**