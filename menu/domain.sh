#!/bin/bash
# ============================================================
#  XRAY DOMAIN & SSL CERTIFICATE MANAGER (Cyberpunk Theme)
# ============================================================

# ==============================================================================
#  PALETTE NEON CYBERPUNK (ANSI 256)
# ==============================================================================
export C_RESET='\033[0m'
export C_BOLD='\033[1m'
export C_CYAN='\033[38;5;45m'
export C_MAGENTA='\033[38;5;201m'
export C_GREEN='\033[38;5;46m'
export C_GOLD='\033[38;5;220m'
export C_RED='\033[38;5;196m'
export C_GRAY='\033[38;5;242m'
export C_WHITE='\033[38;5;255m'

export DOMAIN=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || echo "")
export MYIP=$(ip -4 addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
[ -z "$MYIP" ] && MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || echo "127.0.0.1")

wait_key() {
  echo ""
  read -n 1 -s -r -p "  Appuyez sur une touche pour continuer..."
  echo ""
}

# ─── CHANGE DOMAIN ────────────────────────────────────────────────────────────
function add_domain() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CONFIGURER LE NOM DE DOMAINE${C_RESET}                           ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  local host domain_ip
  while true; do
    read -rp "  ► Nom de domaine / Hostname : " host
    if [[ -z "$host" ]]; then
      echo -e "  ${C_RED}✖ Le domaine ne peut pas être vide.${C_RESET}"
      continue
    fi

    echo -e "  ${C_GRAY}Vérification du pointage DNS...${C_RESET}"
    domain_ip=$(getent ahosts "$host" | awk '{print $1; exit}')

    if [[ "$domain_ip" == "$MYIP" ]]; then
      echo -e "  ${C_GREEN}⚡ [OK] Le domaine pointe correctement vers ce VPS ($MYIP).${C_RESET}"
      break
    else
      echo ""
      echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
      echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_RED}✖ ÉCHEC DE LA VÉRIFICATION DNS${C_RESET}                                 ${C_MAGENTA}║${C_RESET}"
      echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
      printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Résolution du domaine${C_RESET} : %-39s ${C_MAGENTA}║${C_RESET}\n" "${domain_ip:-Introuvable}"
      printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Adresse IP du VPS${C_RESET}    : %-39s ${C_MAGENTA}║${C_RESET}\n" "$MYIP"
      echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
      echo -e "${C_MAGENTA}║${C_RESET} ${C_GOLD}Veuillez corriger votre enregistrement A dans Cloudflare/DNS${C_RESET}   ${C_MAGENTA}║${C_RESET}"
      echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
      wait_key
      domain
      return
    fi
  done

  mkdir -p /etc/xray
  echo "$host" > /root/domain
  echo "$host" > /etc/xray/domain

  local domain
  domain=$(cat /etc/xray/domain 2>/dev/null)

  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GOLD}⚡ DOMAINE MIS À JOUR AVEC SUCCÈS${C_RESET}                               ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Nouveau Domaine${C_RESET} : %-43s ${C_MAGENTA}║${C_RESET}\n" "$domain"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Auteur${C_RESET}          : %-43s ${C_MAGENTA}║${C_RESET}\n" "🜲 DOTYWRT V1.0"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  
  echo ""
  echo -e "   ${C_MAGENTA}[01]${C_RESET} MODIFIER À NOUVEAU      ${C_MAGENTA}[02]${C_RESET} GÉNÉRER LE CERTIFICAT SSL"
  echo ""
  echo -e "   ${C_GRAY}[00] RETOUR MENU PRINCIPAL${C_RESET}"
  echo ""
  echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
  read -rp "  🜲 Sélectionnez une option : " opt
  case $opt in
    1|01) add_domain ;;
    2|02) renew_cert ;;
    0|00) clear; menu 2>/dev/null || return ;;
    *)
      echo -e "  ${C_RED}✖ Option invalide !${C_RESET}"
      sleep 1
      domain
      ;;
  esac
}

# ─── RENEW / ISSUE SSL CERTIFICATE ────────────────────────────────────────────
function renew_cert() {
  clear
  local domain
  if [[ -f /etc/xray/domain ]]; then
    domain=$(cat /etc/xray/domain)
  elif [[ -f /root/domain ]]; then
    domain=$(cat /root/domain)
  else
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_RED}✖ ERREUR : Aucun domaine configuré${C_RESET}                            ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    wait_key
    domain
    return
  fi

  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ GÉNÉRATION DU CERTIFICAT SSL (ACME.SH)${C_RESET}                        ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "  ${C_GRAY}► Arrêt temporaire des services Web pour libérer le port 80...${C_RESET}"

  systemctl stop nginx &> /dev/null
  systemctl stop xray &> /dev/null
  local Cek
  Cek=$(lsof -i:80 2>/dev/null | awk 'NR==2 {print $1}')
  if [[ -n "$Cek" ]]; then
    systemctl stop "$Cek" &> /dev/null
  fi

  mkdir -p /usr/bin/xray /etc/xray /usr/local/etc/xray

  if [ ! -f "/root/.acme.sh/acme.sh" ]; then
    echo -e "  ${C_GOLD}► Téléchargement et installation de Acme.sh...${C_RESET}"
    curl -s https://get.acme.sh | sh &>/dev/null
  else
    echo -e "  ${C_GREEN}⚡ [OK] Acme.sh est déjà installé.${C_RESET}"
  fi

  alias acme.sh=~/.acme.sh/acme.sh
  /root/.acme.sh/acme.sh --upgrade --auto-upgrade &>/dev/null
  /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt &>/dev/null

  echo -e "  ${C_CYAN}► Demande d'émission du certificat Let's Encrypt (EC-256)...${C_RESET}"
  /root/.acme.sh/acme.sh --issue -d "${domain}" --standalone --keylength ec-256

  echo -e "  ${C_CYAN}► Installation des clés dans /etc/xray/...${C_RESET}"
  /root/.acme.sh/acme.sh --install-cert -d "${domain}" --ecc \
    --fullchain-file /etc/xray/xray.crt \
    --key-file /etc/xray/xray.key

  chown -R nobody:nogroup /etc/xray 2>/dev/null
  chmod 644 /etc/xray/xray.crt
  chmod 644 /etc/xray/xray.key

  echo -e "  ${C_GRAY}► Redémarrage des services...${C_RESET}"
  systemctl start nginx &> /dev/null
  systemctl start xray &> /dev/null
  if [[ -n "$Cek" ]]; then
    systemctl start "$Cek" &> /dev/null
  fi

  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GOLD}⚡ CERTIFICAT SSL ÉMIS ET INSTALLÉ AVEC SUCCÈS${C_RESET}                 ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Domaine Target${C_RESET} : %-43s ${C_MAGENTA}║${C_RESET}\n" "$domain"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Fichier Cert${C_RESET}   : %-43s ${C_MAGENTA}║${C_RESET}\n" "/etc/xray/xray.crt"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Fichier Key${C_RESET}    : %-43s ${C_MAGENTA}║${C_RESET}\n" "/etc/xray/xray.key"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Auteur${C_RESET}         : %-43s ${C_MAGENTA}║${C_RESET}\n" "🜲 DOTYWRT V1.0"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"

  wait_key
  domain
}

# ─── MENU DOMAINE ─────────────────────────────────────────────────────────────
function domain() {
  clear
  local cur_domain
  cur_domain=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || echo "Non configuré")

  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ GESTION DU DOMAINE ET SÉCURITÉ SSL${C_RESET}                          ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Domaine Actuel${C_RESET} : %-43s ${C_MAGENTA}║${C_RESET}\n" "$cur_domain"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "   ${C_MAGENTA}[01]${C_RESET} CHANGER DE DOMAINE"
  echo -e "   ${C_MAGENTA}[02]${C_RESET} RENOUVELER / RÉÉMETTRE LE CERTIFICAT SSL"
  echo ""
  echo -e "   ${C_GRAY}[00] RETOUR MENU PRINCIPAL${C_RESET}"
  echo ""
  echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
  read -rp "  🜲 Sélectionnez une option [00-02] : " opt
  echo ""

  case $opt in
    1|01) add_domain ;;
    2|02) renew_cert ;;
    0|00) clear; menu 2>/dev/null || return ;;
    *)
      echo -e "  ${C_RED}✖ Option invalide !${C_RESET}"
      sleep 1
      domain
      ;;
  esac
}

# Initialisation
domain
