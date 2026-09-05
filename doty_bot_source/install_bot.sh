#!/bin/bash
# ==============================================================================
# Script d'installation corrigé - THE_S-TUNNEL-PRO- / NEXUS BOT
# Dépôt GitHub : https://github.com/thesnet320-source/THE_S-TUNNEL-PRO-.git
# 
# CORRECTIONS APPORTÉES:
# 1. Chemins unifiés: /etc/the_s_bot (au lieu de /etc/nexus_bot)
# 2. Fichier principal: bot/main.py (au lieu de nexus_bot.py)
# 3. Installation des modules manquants
# 4. Configuration correcte de systemd
# ==============================================================================

set -e

# Couleurs pour le terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/thesnet320-source/THE_S-TUNNEL-PRO-.git"
INSTALL_DIR="/opt/the_s_bot"
CONFIG_DIR="/etc/the_s_bot"
SERVICE_NAME="the_s_bot"

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}        INSTALLATION DU BOT TELEGRAM THE_S          ${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo -e ""

# 1. Vérification des droits ROOT
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[!] Erreur: Ce script doit être exécuté en tant que root${NC}"
  echo -e "${RED}    Commande: sudo bash install_bot.sh${NC}"
  exit 1
fi

# 2. Saisie interactive des identifiants (avec validation)
echo -e "${YELLOW}Ce module va relier votre serveur à Telegram.${NC}"
echo -e ""
read -rp " ➔ Entrez le TOKEN du Bot (ex: 1234:ABCDef...) : " BOT_TOKEN
read -rp " ➔ Entrez votre ID Telegram (ex: 123456789) : " ADMIN_ID

if [ -z "$BOT_TOKEN" ] || [ -z "$ADMIN_ID" ]; then
    echo -e "${RED}[!] Erreur: Le TOKEN et l'ID Admin ne peuvent pas être vides.${NC}"
    exit 1
fi

echo -e ""

# 3. Installation des paquets système requis
echo -e "${YELLOW}[+] Mise à jour du système et dépendances...${NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y python3 python3-pip python3-venv git curl > /dev/null 2>&1

# 4. Préparation et nettoyage du répertoire cible
echo -e "${YELLOW}[+] Préparation de l'environnement d'installation...${NC}"
mkdir -p "$CONFIG_DIR"

if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e "${YELLOW}[+] Mise à jour du code depuis GitHub...${NC}"
    cd "$INSTALL_DIR"
    git reset --hard > /dev/null 2>&1
    git pull origin fix/telegram-bot-deployment > /dev/null 2>&1 || git pull origin main > /dev/null 2>&1
else
    echo -e "${YELLOW}[+] Clonage du dépôt principal...${NC}"
    rm -rf "$INSTALL_DIR" 2>/dev/null
    git clone "$REPO_URL" "$INSTALL_DIR" > /dev/null 2>&1
fi

cd "$INSTALL_DIR"

# 5. Vérification de la structure des fichiers
echo -e "${YELLOW}[+] Vérification de la structure des fichiers...${NC}"

# Créer les répertoires s'ils n'existent pas
mkdir -p "$INSTALL_DIR/bot/modules"

# Vérifier et copier les fichiers bot si nécessaire
if [ ! -f "$INSTALL_DIR/bot/main.py" ]; then
    if [ -f "$INSTALL_DIR/doty_bot_source/main.py" ]; then
        echo -e "${YELLOW}[+] Copie des fichiers depuis doty_bot_source...${NC}"
        cp -r "$INSTALL_DIR/doty_bot_source/"* "$INSTALL_DIR/bot/" 2>/dev/null || true
    fi
fi

# Créer les fichiers __init__.py manquants
touch "$INSTALL_DIR/bot/__init__.py"
touch "$INSTALL_DIR/bot/modules/__init__.py"

# 6. Environnement virtuel Python
echo -e "${YELLOW}[+] Configuration de l'environnement virtuel Python...${NC}"
python3 -m venv "$INSTALL_DIR/venv" > /dev/null 2>&1
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip > /dev/null 2>&1

# Installer les dépendances
echo -e "${YELLOW}[+] Installation des dépendances Python...${NC}"
if [ -f "$INSTALL_DIR/bot/requirements.txt" ]; then
    "$INSTALL_DIR/venv/bin/pip" install -r "$INSTALL_DIR/bot/requirements.txt" > /dev/null 2>&1
else
    # Installer les dépendances essentielles
    "$INSTALL_DIR/venv/bin/pip" install \
        "pyTelegramBotAPI>=4.0.0" \
        "requests>=2.28.0" \
        "psutil>=5.9.0" \
        "python-dotenv>=0.20.0" > /dev/null 2>&1
fi

# 7. Génération de la configuration JSON sécurisée
echo -e "${YELLOW}[+] Génération de la configuration...${NC}"
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "127.0.0.1")

cat > "$CONFIG_DIR/config.json" <<EOF
{
  "bot_token": "$BOT_TOKEN",
  "super_admin": $ADMIN_ID,
  "admin_id": $ADMIN_ID,
  "admins": [],
  "brand": "THE_S BOT",
  "vps_ip": "$PUBLIC_IP"
}
EOF

chmod 600 "$CONFIG_DIR/config.json"
echo -e "${GREEN}[✓] Configuration sauvegardée dans $CONFIG_DIR/config.json${NC}"

# 8. Création des fichiers de données
echo -e "${YELLOW}[+] Initialisation des fichiers de données...${NC}"
touch "$CONFIG_DIR/resellers.json" 2>/dev/null || true
touch "$CONFIG_DIR/convs.json" 2>/dev/null || true
touch "$CONFIG_DIR/visitors.json" 2>/dev/null || true
touch "$CONFIG_DIR/admins.json" 2>/dev/null || true

# Initialiser les fichiers JSON s'ils sont vides
for file in resellers convs visitors admins; do
    if [ ! -s "$CONFIG_DIR/${file}.json" ]; then
        echo "{}" > "$CONFIG_DIR/${file}.json"
    fi
done

chmod 600 "$CONFIG_DIR"/*.json

# 9. Configuration du service Systemd
echo -e "${YELLOW}[+] Configuration du service Systemd...${NC}"

cat > /etc/systemd/system/${SERVICE_NAME}.service <<EOF
[Unit]
Description=THE_S Telegram Bot Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python3 $INSTALL_DIR/bot/main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment=PYTHONUNBUFFERED=1
Environment=PYTHONPATH=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

chmod 644 /etc/systemd/system/${SERVICE_NAME}.service

# 10. Démarrage du service
echo -e "${YELLOW}[+] Activation et démarrage du service...${NC}"
systemctl daemon-reload > /dev/null 2>&1
systemctl enable ${SERVICE_NAME}.service > /dev/null 2>&1
systemctl restart ${SERVICE_NAME}.service > /dev/null 2>&1

# 11. Vérification du statut
echo -e "${YELLOW}[+] Vérification du statut du service...${NC}"
sleep 3

if systemctl is-active --quiet ${SERVICE_NAME}.service; then
    echo -e ""
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "${GREEN}   ✓ Configuration du Bot Telegram réussie !        ${NC}"
    echo -e "${GREEN}=====================================================${NC}"
    echo -e ""
    echo -e " 📱 INSTRUCTIONS:"
    echo -e " 1. Allez sur Telegram et tapez /start avec le bot"
    echo -e " 2. Votre ID Admin: ${GREEN}$ADMIN_ID${NC}"
    echo -e " 3. Configuration: $CONFIG_DIR/config.json"
    echo -e " 4. Logs: journalctl -u ${SERVICE_NAME} -f"
    echo -e ""
    echo -e " ${GREEN}[✓] Service Status:${NC} $(systemctl is-active ${SERVICE_NAME})"
    echo -e " ${GREEN}[✓] Bot Directory:${NC} $INSTALL_DIR"
    echo -e " ${GREEN}[✓] Config Directory:${NC} $CONFIG_DIR"
    echo -e ""
else
    echo -e ""
    echo -e "${RED}=====================================================${NC}"
    echo -e "${RED}   [!] Erreur: Le bot n'a pas pu démarrer          ${NC}"
    echo -e "${RED}=====================================================${NC}"
    echo -e ""
    echo -e " ${RED}[!] Vérifiez les logs:${NC}"
    echo -e " journalctl -u ${SERVICE_NAME} -n 50 --no-pager"
    echo -e ""
    journalctl -u ${SERVICE_NAME} -n 20 --no-pager
    exit 1
fi

echo -e " Appuyez sur ENTRÉE pour terminer."
read
