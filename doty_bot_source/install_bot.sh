#!/bin/bash
# Fichier : install_bot.sh
# Rôle : Installation automatisée du Bot Telegram Nexus Tunnel Pro

set -e

echo -e "\e[32m[+] Démarrage de l'installation du Bot Telegram Nexus Tunnel Pro...\e[0m"

# 1. Mise à jour et dépendances
echo -e "\e[33m[*] Installation des dépendances Python et Système...\e[0m"
apt-get update -y
apt-get install -y git python3 python3-pip unzip zip qrencode
python3 -m pip install --upgrade pip
python3 -m pip install pyTelegramBotAPI psutil qrcode pillow requests

# 2. Création des dossiers
echo -e "\e[33m[*] Création des dossiers du bot...\e[0m"
mkdir -p /root/doty_bot
mkdir -p /etc/pps_bot

# 3. Récupération du dépôt (copie des sources)
REPO_URL="https://github.com/wilfriedekongolo320-jpg/THE_S237-.git"
REPO_DIR="/root/doty_bot_repo"
if [ -d "$REPO_DIR" ]; then
  echo "[*] Le dépôt existe déjà dans $REPO_DIR, mise à jour..."
  cd "$REPO_DIR" && git pull --rebase || true
else
  git clone "$REPO_URL" "$REPO_DIR"
fi

# Copie des sources doty_bot_source vers /root/doty_bot
cp -r "$REPO_DIR/doty_bot_source"/* /root/doty_bot/ || true
chown -R root:root /root/doty_bot

# 4. Configuration initiale (création de /etc/pps_bot/config.json - format attendu par main.py)
echo -e "\e[36m========================================\e[0m"
read -p "Entrez le Token de votre Bot Telegram : " BOT_TOKEN
read -p "Entrez votre ID Telegram (Super Admin) : " ADMIN_ID
read -p "Entrez le nom de marque (optionnel, appuyez sur Entrée pour 🜲THE_S) : " BRAND
if [ -z "$BRAND" ]; then BRAND="🜲THE_S"; fi
echo -e "\e[36m========================================\e[0m"

cat <<EOF > /etc/pps_bot/config.json
{
  "bot_token": "${BOT_TOKEN}",
  "super_admin": ${ADMIN_ID},
  "admins": [${ADMIN_ID}],
  "brand": "${BRAND}"
}
EOF

chmod 600 /etc/pps_bot/config.json

# 5. Création du service SystemD
echo -e "\e[33m[*] Création et activation du service systemd...\e[0m"
cat <<EOF > /etc/systemd/system/dotybot.service
[Unit]
Description=Nexus Tunnel Pro Telegram Bot
After=network.target

[Service]
ExecStart=/usr/bin/python3 /root/doty_bot/doty_bot_source/main.py
WorkingDirectory=/root/doty_bot
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dotybot || true

# 6. Vérification du token via l'API Telegram
echo -e "\e[33m[*] Vérification du token Telegram...\e[0m"
python3 /root/doty_bot/doty_bot_source/check_telegram.py || true

# 7. Lancement du service
echo -e "\e[33m[*] Démarrage du service dotybot...\e[0m"
systemctl restart dotybot || true

echo -e "\e[32m[+] Installation terminée ! Utilisez 'sudo systemctl status dotybot' et 'sudo journalctl -u dotybot -f' pour suivre les logs.\e[0m"
