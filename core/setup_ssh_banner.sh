#!/bin/bash

# Script de configuration de la bannière SSH depuis le dépôt Clone-THE_S-TUNNEL-44
# Cette bannière s'affiche lors de la connexion SSH/SlowDNS

SERVER_HOST="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main"
BANNER_FILE="/etc/ssh/banner.issue.net"

echo "[*] Téléchargement de la bannière SSH depuis le dépôt officiel..."

# Créer le répertoire si nécessaire
mkdir -p /etc/ssh

# Télécharger UNIQUEMENT la bannière depuis le dépôt Clone-THE_S-TUNNEL-44
wget -q -O "$BANNER_FILE" "$SERVER_HOST/issue.net"

if [ -f "$BANNER_FILE" ]; then
    echo "[+] Bannière téléchargée avec succès"
    
    # Configurer SSH pour afficher la bannière
    sed -i '/^#Banner/c\Banner \/etc\/ssh\/banner.issue.net' /etc/ssh/sshd_config
    sed -i '/^Banner/c\Banner \/etc\/ssh\/banner.issue.net' /etc/ssh/sshd_config
    
    # S'assurer que la configuration existe
    if ! grep -q "Banner /etc/ssh/banner.issue.net" /etc/ssh/sshd_config; then
        echo "Banner /etc/ssh/banner.issue.net" >> /etc/ssh/sshd_config
    fi
    
    # Permissions appropriées
    chmod 644 "$BANNER_FILE"
    
    # Redémarrer SSH
    systemctl restart ssh
    
    echo "[+] Bannière SSH configurée et activée"
else
    echo "[-] ERREUR: Impossible de télécharger la bannière depuis $SERVER_HOST/issue.net"
    exit 1
fi
