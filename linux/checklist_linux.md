# Checklist de Hardening — Linux (24 puntos)

> Ejecuta en orden. Marca `[x]` cada punto completado. Base: CIS Benchmarks / NSA hardening.

## Sistema y actualizaciones
- [ ] `apt update && apt upgrade -y` (o tu gestor de paquetes)
- [ ] Configurar actualizaciones automáticas de seguridad (unattended-upgrades)
- [ ] Revisar paquetes instalados: eliminar los que no se usan

## Usuarios y permisos
- [ ] Desactivar root remoto: `PermitRootLogin no` en `/etc/ssh/sshd_config`
- [ ] Usar **claves SSH** en lugar de contraseñas: `PasswordAuthentication no`
- [ ] Revisar cuentas sin contraseña: `awk -F: '($2==""){print}' /etc/shadow`
- [ ] Revisar cuentas con UID 0 que no deberían ser root
- [ ] Asegurar permisos: `chmod 600 /etc/shadow` · `chmod 644 /etc/passwd`
- [ ] Sudores mínimos: revisar `/etc/sudoers` y `/etc/sudoers.d/`

## Firewall y red
- [ ] `ufw default deny incoming && ufw enable` (o firewalld)
- [ ] Cerrar puertos no necesarios: `ss -tulpn` y auditar cada uno
- [ ] Desactivar IPv6 si no se usa o configurarlo igual de estricto
- [ ] SSH en puerto no estándar SOLO si aporta algo (no lo uses como seguridad)

## Kernel y sysctl (`/etc/sysctl.d/99-hardening.conf`)
- [ ] `net.ipv4.conf.all.rp_filter = 1` (anti-spoofing)
- [ ] `net.ipv4.conf.default.rp_filter = 1`
- [ ] `net.ipv4.tcp_syncookies = 1` (protección SYN flood)
- [ ] `kernel.randomize_va_space = 2` (ASLR)
- [ ] `kernel.kptr_restrict = 1` · `kernel.dmesg_restrict = 1`
- [ ] `net.ipv6.conf.all.accept_redirects = 0` (si usas IPv6)

## Servicios y seguridad perimetral
- [ ] Fail2ban: `apt install fail2ban && systemctl enable --now fail2ban`
- [ ] Desactivar servicios innecesarios: `systemctl list-units --type=service --state=running`
- [ ] Eliminar paquetes tipo `telnet`, `rsh`, `ftp` sin cifrar
- [ ] Cron/AT: revisar `ls -la /etc/cron*` y `/var/spool/cron` (persistencia maliciosa)

## Auditoría y logs
- [ ] Instalar y ejecutar: `sudo lynis audit system`
- [ ] Revisar el informe y anotar el **Hardening Index**
- [ ] Logs en remoto (rsyslog/cliente Wazuh) — ver repo `soc-blue-team`
- [ ] Backups probados (3-2-1) y cifrados

---
**Fecha de auditoría:** _____ · **Host:** _____ · **Resultado Lynis:** ____%