#!/bin/bash
clear
echo -e "\e[36m====================================================\e[0m"
echo -e "\e[36m    DÉMARRAGE DE L'INSTALLATION: NEXUS TUNNEL PRO   \e[0m"
echo -e "\e[36m====================================================\e[0m"

# 1. Préparation des outils vitaux
apt-get update -y >/dev/null 2>&1
apt-get install -y wget curl >/dev/null 2>&1

# 2. Correction réseau (Forçage IPv4 pour la stabilité)
echo "[+] Optimisation des routes réseau..."
if ! grep -q "precedence ::ffff:0:0/96  100" /etc/gai.conf 2>/dev/null; then
    echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
fi
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1 || true
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1 || true

# 3. Téléchargement du Lanceur Principal depuis ton dépôt principal
SERVER_HOST="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main"
echo "[+] Connexion au dépôt autonome Nexus..."

rm -f /root/nexus.sh
wget -qO /root/nexus.sh "$SERVER_HOST/nexus.sh"

# 4. Exécution Sécurisée
if [ -s /root/nexus.sh ]; then
    echo "[+] Fichier noyau intercepté avec succès. Lancement..."
    chmod +x /root/nexus.sh
    bash /root/nexus.sh
else
    echo "[-] ERREUR FATALE: Le fichier nexus.sh n'a pas pu être téléchargé depuis $SERVER_HOST."
    exit 1
fi
