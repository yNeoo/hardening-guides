# Instalación — Hardening Guides

## Linux: Lynis (auditor de hardening)

```bash
# Debian/Ubuntu/Kali
sudo apt update && sudo apt install -y lynis
sudo lynis audit system --quick
```

O descarga la última versión:

```bash
wget https://downloads.cisofy.com/lynis/lynis-3.1.4.tar.gz
tar xzf lynis-3.1.4.tar.gz && cd lynis
sudo ./lynis audit system
```

## Uso de los checklist

```bash
# Imprime el checklist y aplícalo línea por línea
cat linux/checklist_linux.md
# o edítalo y marca los puntos
code linux/checklist_linux.md
```

## Windows

Los checklist de Windows se aplican desde PowerShell (admin) o `secpol.msc`. Copia el archivo y márcalo a medida que avanzas.

---

[⬅ Volver al inicio](README.md)