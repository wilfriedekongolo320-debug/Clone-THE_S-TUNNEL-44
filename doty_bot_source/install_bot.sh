#!/bin/bash
# =============================================================================
# install_bot.sh — Installation corrigée du Bot Telegram THE_S Tunnel Pro
# =============================================================================
set -euo pipefail

GREEN='\e[32m';YELLOW='\e[33m'
CYAN='\e[36m'
RED='\e[31m'
NC='\e[0m'

echo -e "${GREEN}[+] Installation du Bot Telegram THE_S Tunnel Pro...${NC}"

# -----------------------------------------------------------------------------
# 1. Dépendances
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[*] Installation des dépendances...${NC}"
apt-get update -y
apt-get install -y git python3 python3-pip unzip zip qrencode curl
python3 -m pip install --upgrade pip
python3 -m pip install "pyTelegramBotAPI>=4.14.0" psutil qrcode pillow requests

# -----------------------------------------------------------------------------
# 2. Dossiers
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[*] Création des dossiers...${NC}"
mkdir -p /root/doty_bot/modules
mkdir -p /etc/the_s_bot
mkdir -p /etc/the_s_bot/ssh_accounts
mkdir -p /etc/the_s_bot/xray_accounts
mkdir -p /etc/the_s_bot/zivpn_accounts

# -----------------------------------------------------------------------------
# 3. Récupération des sources (CE dépôt)
# -----------------------------------------------------------------------------
REPO_URL="https://github.com/thesnet320-source/THE_S-TUNNEL-PRO-.git"
REPO_DIR="/tmp/the_s_bot_repo"

echo -e "${YELLOW}[*] Clonage du dépôt...${NC}"
rm -rf "$REPO_DIR"
git clone --depth 1 "$REPO_URL" "$REPO_DIR"

# Sources principales
cp -r "$REPO_DIR/doty_bot_source/"* /root/doty_bot/ 2>/dev/null || true

# Modules manquants : on les prend depuis nexus_core_bot (API compatible)
if [ -d "$REPO_DIR/nexus_core_bot/modules" ]; then
  cp -f "$REPO_DIR/nexus_core_bot/modules/"*.py /root/doty_bot/modules/
fi

# S'assurer que __init__.py existe
touch /root/doty_bot/modules/__init__.py

# Adapter les chemins de config des modules (nexus → the_s_bot)
# Les modules originaux utilisent /etc/nexus_bot — on les patch pour ce bot
for f in /root/doty_bot/modules/*.py; do
  [ -f "$f" ] || continue
  sed -i 's|/etc/nexus_bot|/etc/the_s_bot|g' "$f"
done

chown -R root:root /root/doty_bot
find /root/doty_bot -name "*.py" -exec chmod 644 {} \;
chmod +x /root/doty_bot/main.py 2>/dev/null || true
chmod +x /root/doty_bot/check_telegram.py 2>/dev/null || true

# -----------------------------------------------------------------------------
# 4. Configuration interactive
# -----------------------------------------------------------------------------
echo -e "${CYAN}========================================${NC}"
read -r -p "Token du Bot Telegram : " BOT_TOKEN
read -r -p "Ton ID Telegram (Super Admin) : " ADMIN_ID
read -r -p "Nom de marque (Entrée = 🜲THE_S) : " BRAND
[ -z "${BRAND:-}" ] && BRAND="🜲THE_S"
echo -e "${CYAN}========================================${NC}"

if [ -z "${BOT_TOKEN}" ] || [ -z "${ADMIN_ID}" ]; then
  echo -e "${RED}[ERROR] Token et Admin ID sont obligatoires.${NC}"
  exit 1
fi

if ! [[ "${ADMIN_ID}" =~ ^[0-9]+$ ]]; then
  echo -e "${RED}[ERROR] L'ID Telegram doit être un nombre.${NC}"
  exit 1
fi

cat > /etc/the_s_bot/config.json <<EOF
{
  "bot_token": "${BOT_TOKEN}",
  "super_admin": ${ADMIN_ID},
  "admins": [${ADMIN_ID}],
  "brand": "${BRAND}"
}
EOF
chmod 600 /etc/the_s_bot/config.json

# Fichiers de persistance vides si absents
[ -f /etc/the_s_bot/resellers.json ] || echo '{}' > /etc/the_s_bot/resellers.json
[ -f /etc/the_s_bot/convs.json ]    || echo '{}' > /etc/the_s_bot/convs.json
[ -f /etc/the_s_bot/visitors.json ] || echo '{}' > /etc/the_s_bot/visitors.json
chmod 600 /etc/the_s_bot/*.json

# -----------------------------------------------------------------------------
# 5. Service systemd (chemins corrects)
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[*] Création du service systemd...${NC}"
cat > /etc/systemd/system/dotybot.service <<'EOF'
[Unit]
Description=THE_S Tunnel Pro Telegram Bot
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /root/doty_bot/main.py
WorkingDirectory=/root/doty_bot
Restart=always
RestartSec=5
User=root
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dotybot

# -----------------------------------------------------------------------------
# 6. Vérification du token
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[*] Vérification du token Telegram...${NC}"
if [ -f /root/doty_bot/check_telegram.py ]; then
  python3 /root/doty_bot/check_telegram.py || true
else
  echo -e "${YELLOW}[!] check_telegram.py absent, skip.${NC}"
fi

# -----------------------------------------------------------------------------
# 7. Démarrage
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[*] Démarrage du service...${NC}"
systemctl restart dotybot
sleep 2
systemctl --no-pager status dotybot || true

echo ""
echo -e "${GREEN}[+] Installation terminée.${NC}"
echo -e "    Config  : /etc/the_s_bot/config.json"
echo -e "    Sources : /root/doty_bot/"
echo -e "    Service : systemctl status dotybot"
echo -e "    Logs    : journalctl -u dotybot -f"
echo ""
