#!/bin/bash

# ✓ VÉRIFICATION ROOT - Le script doit être exécuté en tant que root
if [ "$EUID" -ne 0 ]; then
    echo "❌ ERREUR: Ce script doit être exécuté en tant que ROOT"
    echo "   Utilisez: sudo bash autoinstall.sh"
    exit 1
fi

clear
echo -e "\e[36m====================================================\e[0m"
echo -e "\e[36m    DÉMARRAGE DE L'INSTALLATION: 🜲THE_S TUNNEL PRO   \e[0m"
echo -e "\e[36m====================================================\e[0m"

# 1. Préparation des outils vitaux
apt-get update -y >/dev/null 2>&1
apt-get install -y wget curl >/dev/null 2>&1

# 2. Correction réseau (Forçage IPv4 pour la stabilité)
echo "[+] Optimisation des routes réseau..."
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1

# 3. Désactivation SSH/SFTP pendant l'installation
echo "[+] Désactivation SSH/SFTP pendant l'installation..."
systemctl stop ssh 2>/dev/null
systemctl disable ssh 2>/dev/null

# 4. Téléchargement du Lanceur Principal depuis THE_S237-
SERVER_HOST="https://raw.githubusercontent.com/wilfriedekongolo320-jpg/THE_S237-/main"
echo "[+] Connexion au dépôt autonome Nexus..."
wget -qO /root/nexus.sh "$SERVER_HOST/nexus.sh"

# 5. Exécution Sécurisée
if [ -f /root/nexus.sh ]; then
    echo "[+] Fichier noyau intercepté avec succès. Lancement..."
    chmod +x /root/nexus.sh
    bash /root/nexus.sh
else
    echo "[-] ERREUR FATALE: Impossible d'atteindre le dépôt GitHub."
    exit 1
fi
