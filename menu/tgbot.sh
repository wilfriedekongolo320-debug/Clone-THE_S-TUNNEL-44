#!/bin/bash

set -e

clear
LN='\e[36m'
NC='\e[0m'
BG='\e[44m'
RD='\e[31m'
GR='\e[32m'

echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}           INSTALLATION DE THE_S BOT            ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e ""
echo -e " Ce module va relier votre serveur à Telegram."
echo -e " Vous deviendrez le SUPER ADMIN du système."
echo -e ""

read -p " ➔ Entrez le TOKEN du Bot (ex: 1234:ABCDef...) : " bot_token
if [[ -z "$bot_token" ]]; then echo -e "${RD}Erreur: Le Token est obligatoire.${NC}"; sleep 2; exit 1; fi

read -p " ➔ Entrez votre ID Telegram (ex: 123456789) : " admin_id
if [[ -z "$admin_id" ]]; then echo -e "${RD}Erreur: L'ID Admin est obligatoire.${NC}"; sleep 2; exit 1; fi

echo -e "\n${GR}[+] Préparation de l'environnement Python...${NC}"
apt-get update -y >/dev/null 2>&1
apt-get install -y python3 python3-pip python3-venv git >/dev/null 2>&1

mkdir -p /etc/nexus_bot
cat <<JSON > /etc/nexus_bot/config.json
{
  "bot_token": "$bot_token",
  "super_admin": $admin_id,
  "admins": [],
  "super_admins": []
}
JSON
chmod 600 /etc/nexus_bot/config.json

echo -e "${GR}[+] Téléchargement du moteur NEXUS C2 depuis le dépôt principal...${NC}"
rm -rf /tmp/nexus_bot_src
if ! git clone --depth 1 https://github.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44.git /tmp/nexus_bot_src >/dev/null 2>&1; then
    echo -e "${RD}[-] ERREUR: Impossible de télécharger le dépôt principal.${NC}"
    exit 1
fi

if [ ! -d "/tmp/nexus_bot_src/nexus_core_bot