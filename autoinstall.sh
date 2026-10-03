#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo -e "\e[36m====================================================\e[0m"
echo -e "\e[36m    DÉMARRAGE DE L'INSTALLATION: THE_S🇨🇲TUNNEL PRO   \e[0m"
echo -e "\e[36m====================================================\e[0m"

if [ "$EUID" -ne 0 ]; then
    echo "[-] ERREUR: Ce script doit être exécuté en tant que root."
    exit 1
fi

apt-get update -y
apt-get install -y wget curl ca-certificates

echo "[+] Optimisation réseau..."
if ! grep -q "precedence ::ffff:0:0/96  100" /etc/gai.conf 2>/dev/null; then
    echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
fi
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1 || true
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1 || true

SERVER_HOST="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main"

rm -f /root/nexus.sh
curl -fsSL "${SERVER_HOST}/nexus.sh" -o /root/nexus.sh || {
    echo "[-] ERREUR: Impossible de télécharger nexus.sh depuis ${SERVER_HOST}"
    exit 1
}

chmod +x /root/nexus.sh
echo "[+] Téléchargement réussi. Lancement de nexus.sh..."
bash /root/nexus.sh
