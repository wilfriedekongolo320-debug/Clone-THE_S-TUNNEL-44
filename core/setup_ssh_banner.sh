#!/bin/bash

set -e

BANNER_FILE="/etc/ssh/banner"
BANNER_URL="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main/issue.net"
SSHD_CONFIG="/etc/ssh/sshd_config"

mkdir -p /etc/ssh

echo "[*] Téléchargement de la bannière SSH..."
if ! wget -q -O "$BANNER_FILE" "$BANNER_URL"; then
    echo "[-] Impossible de télécharger la bannière, création d'une bannière locale par défaut"
    cat > "$BANNER_FILE" <<'EOF'
╔════════════════════════════════════════════════════════════════╗
║              🜲 THE_S TUNNEL PRO - SSH ACCESS                  ║
╚════════════════════════════════════════════════════════════════╝

Welcome to THE_S Tunnel Pro SSH Service
All activities are monitored and logged
Unauthorized access is prohibited
EOF
fi

chmod 644 "$BANNER_FILE"
if [ -f "${SSHD_CONFIG}.backup" ]; then
    cp "${SSHD_CONFIG}.backup" "$SSHD_CONFIG"
fi
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.backup" 2>/dev/null || true

sed -i '/^Banner/d' "$SSHD_CONFIG"
if ! grep -q "^Banner " "$SSHD_CONFIG"; then
    printf '\nBanner %s\n' "$BANNER_FILE" >> "$SSHD_CONFIG"
fi

if sshd -t >/dev/null 2>&1; then
    systemctl restart ssh >/dev/null 2>&1 || service ssh restart >/dev/null 2>&1 || true
    echo "[+] Bannière SSH configurée"
else
    echo "[-] Configuration SSH invalide, restauration de la sauvegarde"
    cp "${SSHD_CONFIG}.backup" "$SSHD_CONFIG"
    exit 1
fi
