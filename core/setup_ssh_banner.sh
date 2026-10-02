#!/bin/bash

# ================================================================================
# Script de Configuration de la Bannière SSH
# THE_S TUNNEL PRO - SSH Banner Setup
# ================================================================================

set -e

BANNER_FILE="/etc/ssh/banner"
BANNER_URL="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main/issue.net"
SSHD_CONFIG="/etc/ssh/sshd_config"

echo "[*] Configuration de la bannière SSH..."

# 1. Créer le répertoire SSH s'il n'existe pas
mkdir -p /etc/ssh

# 2. Télécharger la bannière depuis le dépôt
echo "[*] Téléchargement de la bannière..."
if ! wget -q -O "$BANNER_FILE" "$BANNER_URL"; then
    echo "[-] ERREUR: Impossible de télécharger la bannière depuis $BANNER_URL"
    echo "[-] Création d'une bannière locale par défaut..."
    cat > "$BANNER_FILE" << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║              🜲 THE_S TUNNEL PRO - SSH ACCESS                  ║
╚════════════════════════════════════════════════════════════════╝

Welcome to THE_S Tunnel Pro SSH Service
All activities are monitored and logged
Unauthorized access is prohibited

For support, contact: @WILLY_NET_OFFICIEL
EOF
fi

# 3. Définir les permissions correctes
chmod 644 "$BANNER_FILE"
echo "[+] Bannière trouvée/créée : $BANNER_FILE"

# 4. Sauvegarder une copie de sshd_config
if [ ! -f "${SSHD_CONFIG}.backup" ]; then
    cp "$SSHD_CONFIG" "${SSHD_CONFIG}.backup"
    echo "[+] Sauvegarde de sshd_config créée"
fi

# 5. Supprimer TOUTES les anciennes configurations de bannière
sed -i '/^Banner/d' "$SSHD_CONFIG"
sed -i '/^#Banner/d' "$SSHD_CONFIG"

# 6. Ajouter la nouvelle configuration de bannière
# (Au début du fichier pour la priorité)
sed -i "1i Banner $BANNER_FILE" "$SSHD_CONFIG"

echo "[+] Configuration SSH mise à jour"

# 7. Vérifier la syntaxe de sshd_config
if sshd -t >/dev/null 2>&1; then
    echo "[+] Configuration SSH valide"
else
    echo "[-] ERREUR: Configuration SSH invalide!"
    echo "[-] Restauration de la sauvegarde..."
    cp "${SSHD_CONFIG}.backup" "$SSHD_CONFIG"
    exit 1
fi

# 8. Redémarrer le service SSH
echo "[*] Redémarrage du service SSH..."
if systemctl restart ssh >/dev/null 2>&1; then
    echo "[+] Service SSH redémarré avec succès"
else
    echo "[-] ERREUR: Impossible de redémarrer SSH"
    exit 1
fi

# 9. Vérifier que le service est actif
if systemctl is-active --quiet ssh; then
    echo "[+] Service SSH actif et en cours d'exécution"
else
    echo "[-] ERREUR: Le service SSH n'est pas actif"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  ✅ Bannière SSH configurée avec succès                        ║"
echo "║  Fichier   : $BANNER_FILE"
echo "║  Affichée  : lors de la connexion SSH                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# 10. Test optionnel (affiche la bannière)
echo "[*] Test: Affichage de la bannière..."
echo ""
cat "$BANNER_FILE"
echo ""
echo "[+] Fin de la configuration"
