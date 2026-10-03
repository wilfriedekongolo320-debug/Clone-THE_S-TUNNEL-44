
#!/bin/bash
clear
echo -e "\e[36m====================================================\e[0m"
echo -e "\e[36m    DÉMARRAGE DE L'INSTALLATION: THE_S TUNNEL VPN   \e[0m"
echo -e "\e[36m====================================================\e[0m"

# 1. Préparation des outils vitaux
apt-get update -y >/dev/null 2>&1
apt-get install -y wget curl >/dev/null 2>&1

# 2. Correction réseau (Forçage IPv4 pour la stabilité)
echo "[+] Optimisation des routes réseau..."
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1

# 3. Téléchargement du Lanceur Principal depuis JOELTOM VPN
SERVER_HOST="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main""
echo "[+] Connexion au dépôt autonome JOELTOM..."
wget -qO /root/joeltom.sh "$SERVER_HOST/joeltom.sh"

# 4. Exécution Sécurisée
if [ -f /root/joeltom.sh ]; then
    echo "[+] Fichier noyau intercepté avec succès. Lancement..."
    chmod +x /root/joeltom.sh
    # Toujours lire les choix interactifs depuis le terminal réel.
    # Cela évite le EOF lorsque autoinstall.sh est lancé avec:
    # curl ... | sudo bash
    if [ -r /dev/tty ]; then
        exec bash /root/joeltom.sh </dev/tty
    else
        exec bash /root/joeltom.sh
    fi
else
    echo "[-] ERREUR FATALE: Impossible d'atteindre le dépôt GitHub."
    exit 1
fi
