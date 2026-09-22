# yNeoo — Hardening Guides

Endurecimiento (**hardening**) de sistemas Linux y Windows: configuración segura, benchmarks CIS, auditoría con Lynis y checklist de verificación. El sello de "esto no es solo atacar" 🔒.

| Licencia | Estado | Visibilidad | Contenido |
|---|---|---|---|
| [MIT](LICENSE) | Activo | **Público** | Guías + checklist + Lynis |

```
hardening-guides/
├── linux/
│   └── checklist_linux.md     ← checklist de hardening Linux
├── windows/
│   └── checklist_windows.md   ← checklist de hardening Windows
├── INSTALL.md
├── install.sh
└── README.md
```

---

## 🔐 Principios básicos (aplica a todo)

1. **Superficie mínima**: menos paquetes, menos puertos, menos usuarios = menos riesgo
2. **Privilegio mínimo**: nadie con más permisos de los necesarios
3. **Defensa en profundidad**: firewall + AV/EDR + parches + segmentación
4. **Registra y audita**: si no hay logs, no existe

## 🐧 Linux — checklist rápido

| Acción | Comando |
|---|---|
| Actualizar sistema | `apt update && apt upgrade -y` |
| Configurar firewall | `ufw default deny incoming && ufw enable` |
| Fortalecer SSH | edita `/etc/ssh/sshd_config`: `PermitRootLogin no`, `PasswordAuthentication no` |
| SSH por clave | `ssh-keygen && ssh-copy-id usuario@host` |
| Fail2ban | `apt install fail2ban && systemctl enable --now fail2ban` |
| Auditoría con Lynis | `lynis audit system` |
| Parámetros kernel | edita `/etc/sysctl.d/99-hardening.conf` (ver checklist) |
| Asegurar permisos | `chmod 600 /etc/shadow` (por defecto ya lo está) |
| Servicios innecesarios | `systemctl list-units --type=service --state=running` → desactiva lo que no uses |

## 🪟 Windows — checklist rápido

| Acción | Dónde |
|---|---|
| Activar BitLocker | Configuración → Privacidad y seguridad |
| Defender + protección en la nube | Seguridad de Windows → Protección contra virus y amenazas |
| LAPS (contraseñas de administrador local) | Microsoft LAPS en Intune/AD |
| Desactivar SMBv1 y servicios viejos | PowerShell: `Disable-WindowsOptionalFeature` |
| Pausar actualizaciones: **no** | Mantén Windows Update al día |
| UAC al máximo | Panel → Cuentas de usuario → Configuración de control |
| Auditar logon/eventos | `secpol.msc` → directivas de auditoría |

## 🛡️ Lynis — la auditoría que se ve en un CV

```bash
sudo lynis audit system --quick        # análisis rápido
sudo lynis report --view-cat warnings  # ver hallazgos
# Consejo: alcanza un "Hardening Index" alto y documenta el informe
```

## 📊 Checklist incluidos

| Archivo | Contenido |
|---|---|
| `linux/checklist_linux.md` | 25+ puntos accionables con comandos (SSH, kernel, users, AV, backups) |
| `windows/checklist_windows.md` | 20+ puntos accionables (cuentas, Defender, LAPS, eventos, red) |

---

## Aviso

Las guías de **hardening** son material defensivo estándar (basado en prácticas CIS/NSA). Aplícalo donde tengas autorización. La responsabilidad del uso es del operador.

Documentación mantenida por [yNeoo](https://github.com/yNeoo).