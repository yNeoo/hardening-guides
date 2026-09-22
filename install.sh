#!/bin/bash
# yNeoo Hardening Guides · instalador de la herramienta de auditoría (Lynis)
set -e

echo "[+] Instalando Lynis (auditor de hardening)..."
sudo apt update && sudo apt install -y lynis

echo ""
echo "[✔] Listo. Auditoria rapida:"
echo "    sudo lynis audit system --quick"
echo "    sudo lynis report --view-cat warnings"
echo ""
echo "    Checklist incluidos:"
echo "      - linux/checklist_linux.md"
echo "      - windows/checklist_windows.md"