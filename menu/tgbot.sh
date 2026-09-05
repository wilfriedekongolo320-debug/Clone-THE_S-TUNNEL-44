#!/bin/bash
# ==============================================================================
# Script d'installation du Bot Telegram - Menu principal
# Dépôt GitHub : https://github.com/thesnet320-source/THE_S-TUNNEL-PRO-.git
#
# CORRECTIONS APPORTÉES:
# 1. Chemins unifiés: /etc/the_s_bot (au lieu de /etc/nexus_bot)
# 2. Utilisation du script install_bot.sh optimisé
# 3. Vérification correcte du déploiement
# ==============================================================================

clear
LN='\e[36m'
NC='\e[0m'
BG='\e[44m'
RD='\e[31m'
GR='\e[32m'
YL='\e[33m'

echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}        INSTALLATION BOT TELEGRAM THE_S         ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e ""
echo -e " ${YL}Ce module va relier votre serveur à Telegram.${NC}"
echo -e " ${YL}Vous deviendrez le SUPER ADMIN du système.${NC}"
echo -e ""

# Vérification des droits ROOT
if [ "$EUID" -ne 0 ]; then
    echo -e "${RD}[!] Erreur: Ce script doit être exécuté en tant que root${NC}"
    echo -e "${RD}    Commande: sudo bash menu/tgbot.sh${NC}"
    sleep 2
    exit 1
fi

read -p " ➔ Entrez le TOKEN du Bot (ex: 1234:ABCDef...) : " bot_token
if [[ -z "$bot_token" ]]; then 
    echo -e "${RD}[!] Erreur: Le Token est obligatoire.${NC}"
    sleep 2
    exit 1
fi

read -p " ➔ Entrez votre ID Telegram (ex: 123456789) : " admin_id
if [[ -z "$admin_id" ]]; then 
    echo -e "${RD}[!] Erreur: L'ID Admin est obligatoire.${NC}"
    sleep 2
    exit 1
fi

echo -e ""

# Définir les variables
INSTALL_DIR="/opt/the_s_bot"
CONFIG_DIR="/etc/the_s_bot"
SERVICE_NAME="the_s_bot"
REPO_URL="https://github.com/thesnet320-source/THE_S-TUNNEL-PRO-.git"

# Créer un script d'installation temporaire
TEMP_INSTALL="/tmp/install_bot_temp.sh"
cat > "$TEMP_INSTALL" <<'EOFINSTALL'
#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="$1"
INSTALL_DIR="$2"
CONFIG_DIR="$3"
SERVICE_NAME="$4"
BOT_TOKEN="$5"
ADMIN_ID="$6"

echo -e "${YELLOW}[+] Préparation de l'environnement...${NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y python3 python3-pip python3-venv git curl > /dev/null 2>&1

mkdir -p "$CONFIG_DIR"

if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e "${YELLOW}[+] Mise à jour du code...${NC}"
    cd "$INSTALL_DIR"
    git reset --hard > /dev/null 2>&1
    git pull origin fix/telegram-bot-deployment > /dev/null 2>&1 || git pull origin main > /dev/null 2>&1
else
    echo -e "${YELLOW}[+] Clonage du dépôt...${NC}"
    rm -rf "$INSTALL_DIR" 2>/dev/null
    git clone "$REPO_URL" "$INSTALL_DIR" > /dev/null 2>&1
fi

cd "$INSTALL_DIR"

mkdir -p "$INSTALL_DIR/bot/modules"
touch "$INSTALL_DIR/bot/__init__.py"
touch "$INSTALL_DIR/bot/modules/__init__.py"

if [ ! -f "$INSTALL_DIR/bot/main.py" ]; then
    if [ -f "$INSTALL_DIR/doty_bot_source/main.py" ]; then
        cp -r "$INSTALL_DIR/doty_bot_source/"* "$INSTALL_DIR/bot/" 2>/dev/null || true
    fi
fi

echo -e "${YELLOW}[+] Configuration de Python...${NC}"
python3 -m venv "$INSTALL_DIR/venv" > /dev/null 2>&1
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip > /dev/null 2>&1

if [ -f "$INSTALL_DIR/bot/requirements.txt" ]; then
    "$INSTALL_DIR/venv/bin/pip" install -r "$INSTALL_DIR/bot/requirements.txt" > /dev/null 2>&1
else
    "$INSTALL_DIR/venv/bin/pip" install \
        "pyTelegramBotAPI>=4.0.0" \
        "requests>=2.28.0" \
        "psutil>=5.9.0" \
        "python-dotenv>=0.20.0" > /dev/null 2>&1
fi

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

for file in resellers convs visitors admins; do
    echo "{}" > "$CONFIG_DIR/${file}.json"
done
chmod 600 "$CONFIG_DIR"/*.json

echo -e "${YELLOW}[+] Configuration du service...${NC}"

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

systemctl daemon-reload > /dev/null 2>&1
systemctl enable ${SERVICE_NAME}.service > /dev/null 2>&1
systemctl restart ${SERVICE_NAME}.service > /dev/null 2>&1

sleep 3

if systemctl is-active --quiet ${SERVICE_NAME}.service; then
    echo -e "${GREEN}✓ Installation réussie!${NC}"
else
    echo -e "${RED}✗ Erreur au démarrage${NC}"
    journalctl -u ${SERVICE_NAME} -n 20 --no-pager
fi

EOFINSTALL

chmod +x "$TEMP_INSTALL"

# Exécuter le script d'installation
bash "$TEMP_INSTALL" "$REPO_URL" "$INSTALL_DIR" "$CONFIG_DIR" "$SERVICE_NAME" "$bot_token" "$admin_id"

# Nettoyage
rm -f "$TEMP_INSTALL"

echo -e ""
echo -e "${GR}[✓] Configuration du Bot Telegram complétée !${NC}"
echo -e " 📱 Allez sur Telegram et tapez /start avec le bot"
echo -e " 🆔 Votre ID Admin: ${GR}$admin_id${NC}"
echo -e " 📂 Configuration: ${GR}$CONFIG_DIR/config.json${NC}"
echo -e " 📋 Logs: ${GR}journalctl -u $SERVICE_NAME -f${NC}"
echo -e ""
echo -e " Appuyez sur ENTRÉE pour retourner au menu."
read

# Retourner au menu si la fonction menu existe
if type menu &> /dev/null; then
    menu
fi
