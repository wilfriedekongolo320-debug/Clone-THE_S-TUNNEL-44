#!/bin/bash
# ============================================================
#  XRAY TROJAN ACCOUNT MANAGER (Cyberpunk Theme)
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

export DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "example.com")
export MYIP=$(ip -4 addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
[ -z "$MYIP" ] && MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || echo "127.0.0.1")

wait_key() {
  echo ""
  read -n 1 -s -r -p "  Appuyez sur une touche pour continuer..."
  echo ""
}

# ─── CREATE TROJAN ACCOUNT ────────────────────────────────────────────────────
function add_trojan() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CRÉER UN COMPTE TROJAN (XRAY)${C_RESET}                               ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  local user masaaktif CLIENT_EXISTS
  while true; do
    read -rp "  ► Nom d'utilisateur      : " user
    if [[ -z "$user" ]]; then
      echo -e "  ${C_RED}✖ Le nom d'utilisateur ne peut pas être vide.${C_RESET}"
      continue
    fi
    if [[ ! "$user" =~ ^[a-zA-Z0-9_]+$ ]]; then
      echo -e "  ${C_RED}✖ Format invalide (lettres, chiffres et '_' uniquement).${C_RESET}"
      continue
    fi
    CLIENT_EXISTS=$(grep -w "$user" /etc/xray/config.json 2>/dev/null | wc -l)
    if [[ "$CLIENT_EXISTS" -gt 0 ]]; then
      echo -e "  ${C_RED}✖ L'utilisateur '$user' existe déjà.${C_RESET}"
      wait_key
      clear
      continue
    fi
    break
  done

  while true; do
    read -rp "  ► Validité (en jours)    : " masaaktif
    if [[ -z "$masaaktif" || ! "$masaaktif" =~ ^[0-9]+$ || "$masaaktif" -le 0 ]]; then
      echo -e "  ${C_RED}✖ Veuillez entrer un nombre de jours valide.${C_RESET}"
      continue
    fi
    break
  done

  local uuid exp trojanlink1 trojanlink2 trojanlink3
  uuid=$(cat /proc/sys/kernel/random/uuid)
  exp=$(date -d "+$masaaktif days" +"%Y-%m-%d")

  sed -i '/#trojanws$/a\#! '"$user $exp $uuid"'\
},{"password": "'"$uuid"'","email": "'"$user"'"' /etc/xray/config.json
  sed -i '/#trojangrpc$/a\#! '"$user $exp $uuid"'\
},{"password": "'"$uuid"'","email": "'"$user"'"' /etc/xray/config.json

  trojanlink1="trojan://${uuid}@${DOMAIN}:443?path=/trws&security=tls&encryption=none&host=${DOMAIN}&type=ws#${user}"
  trojanlink2="trojan://${uuid}@${DOMAIN}:80?path=/trws&encryption=none&security=none&host=${DOMAIN}&type=ws#${user}"
  trojanlink3="trojan://${uuid}@${DOMAIN}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=${DOMAIN}#${user}"

  systemctl restart xray >/dev/null 2>&1

  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GOLD}⚡ DÉTAILS DU COMPTE TROJAN${C_RESET}                                     ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Username${C_RESET}     : %-47s ${C_MAGENTA}║${C_RESET}\n" "$user"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Expiry Date${C_RESET}  : %-47s ${C_MAGENTA}║${C_RESET}\n" "$exp"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Password/UUID${C_RESET}: %-47s ${C_MAGENTA}║${C_RESET}\n" "$uuid"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Domain${C_RESET}       : %-47s ${C_MAGENTA}║${C_RESET}\n" "$DOMAIN"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Path / Net${C_RESET}   : /trws | WS / gRPC                              ${C_MAGENTA}║${C_RESET}\n"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}TROJAN WS TLS (Port 443) :${C_RESET}"
  echo -e "  ${C_GREEN}${trojanlink1}${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}TROJAN WS NTLS (Port 80) :${C_RESET}"
  echo -e "  ${C_GREEN}${trojanlink2}${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}TROJAN gRPC TLS (Port 443) :${C_RESET}"
  echo -e "  ${C_GREEN}${trojanlink3}${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"

  wait_key
  trojan_menu
}

# ─── RENEW TROJAN ACCOUNT ─────────────────────────────────────────────────────
function renew_trojan() {
  clear
  local NUMBER_OF_CLIENTS
  NUMBER_OF_CLIENTS=$(grep -c -E "^#! " "/etc/xray/config.json" 2>/dev/null || echo 0)

  if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ RENOUVELER UN COMPTE TROJAN${C_RESET}                                  ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo -e "  ${C_RED}✖ Aucun compte Trojan existant sur le serveur.${C_RESET}"
    wait_key
    trojan_menu
    return
  fi

  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ RENOUVELER UN COMPTE TROJAN${C_RESET}                                  ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  printf "  ${C_BOLD}%-24s %-20s${C_RESET}\n" "UTILISATEUR" "EXPIRATION"
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"

  grep -E "^#! " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r u ex; do
    printf "  %-24s %-20s\n" "$u" "$ex"
  done

  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  echo ""

  local user masaaktif CLIENT_EXISTS
  while true; do
    read -rp "  ► Nom d'utilisateur (Entrée pour annuler) : " user
    if [[ -z "$user" ]]; then
      trojan_menu
      return
    fi
    CLIENT_EXISTS=$(grep -wE "^#! $user" "/etc/xray/config.json" | wc -l)
    if [[ $CLIENT_EXISTS -eq 0 ]]; then
      echo -e "  ${C_RED}✖ Utilisateur non trouvé. Réessayez.${C_RESET}"
      continue
    fi
    break
  done

  while true; do
    read -rp "  ► Nombre de jours à ajouter              : " masaaktif
    if [[ -z "$masaaktif" || ! "$masaaktif" =~ ^[0-9]+$ || "$masaaktif" -le 0 ]]; then
      echo -e "  ${C_RED}✖ Le nombre de jours doit être un entier positif.${C_RESET}"
      continue
    fi
    break
  done

  local exp uuid now d1 d2 exp2 exp3 exp4
  exp=$(grep -wE "^#! $user" "/etc/xray/config.json" | awk '{print $3}' | sort -u | head -n 1)
  uuid=$(grep -wE "^#! $user" /etc/xray/config.json | awk '{print $4}' | grep -v '^[[:space:]]*$' | sort -u | head -n 1)

  now=$(date +%Y-%m-%d)
  d1=$(date -d "$exp" +%s 2>/dev/null || date +%s)
  d2=$(date -d "$now" +%s)

  if [[ $d1 -lt $d2 ]]; then
    exp3=$masaaktif
  else
    exp2=$(( (d1 - d2) / 86400 ))
    exp3=$(( exp2 + masaaktif ))
  fi

  exp4=$(date -d "$exp3 days" +"%Y-%m-%d")

  sed -i "/^#! $user /c\#! $user $exp4 $uuid" /etc/xray/config.json
  systemctl restart xray > /dev/null 2>&1

  echo ""
  echo -e "  ${C_GREEN}⚡ [OK] Le compte '$user' a été prolongé de $masaaktif jour(s).${C_RESET}"
  echo -e "  ${C_WHITE}Ancienne date : $exp${C_RESET}"
  echo -e "  ${C_GOLD}Nouvelle date : $exp4${C_RESET}"

  wait_key
  trojan_menu
}

# ─── DELETE TROJAN ACCOUNT ────────────────────────────────────────────────────
function delete_trojan() {
  clear
  local NUMBER_OF_CLIENTS
  NUMBER_OF_CLIENTS=$(grep -c -E "^#! " "/etc/xray/config.json" 2>/dev/null || echo 0)

  if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_RED}❖ SUPPRIMER UN COMPTE TROJAN${C_RESET}                                  ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo -e "  ${C_RED}✖ Aucun compte Trojan existant sur le serveur.${C_RESET}"
    wait_key
    trojan_menu
    return
  fi

  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_RED}❖ SUPPRIMER UN COMPTE TROJAN${C_RESET}                                  ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  printf "  ${C_BOLD}%-24s %-20s${C_RESET}\n" "UTILISATEUR" "EXPIRATION"
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"

  grep -E "^#! " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r u ex; do
    printf "  %-24s %-20s\n" "$u" "$ex"
  done

  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  echo ""

  local duser exp
  read -rp "  ► Nom d'utilisateur à supprimer (Entrée pour annuler) : " duser
  if [[ -z "$duser" ]]; then
    trojan_menu
    return
  fi

  exp=$(grep -wE "^#! $duser" "/etc/xray/config.json" | awk '{print $3}' | sort -u)
  if [[ -z "$exp" ]]; then
    echo -e "  ${C_RED}✖ Utilisateur non trouvé.${C_RESET}"
    wait_key
    trojan_menu
    return
  fi

  sed -i -e "/^#! $duser /d" -e "/\"email\": \"$duser\"/d" /etc/xray/config.json
  systemctl restart xray > /dev/null 2>&1

  echo ""
  echo -e "  ${C_GREEN}⚡ [OK] Le compte '$duser' a été supprimé avec succès.${C_RESET}"

  wait_key
  trojan_menu
}

# ─── VIEW TROJAN CONFIGS ──────────────────────────────────────────────────────
function view_trojan() {
  clear
  local NUMBER_OF_CLIENTS
  NUMBER_OF_CLIENTS=$(grep -c -E "^#! " "/etc/xray/config.json" 2>/dev/null || echo 0)

  if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ AFFICHER LES CONFIGURATIONS TROJAN${C_RESET}                          ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo -e "  ${C_RED}✖ Aucun compte Trojan existant sur le serveur.${C_RESET}"
    wait_key
    trojan_menu
    return
  fi

  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ AFFICHER LES CONFIGURATIONS TROJAN${C_RESET}                          ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  printf "  ${C_BOLD}%-24s %-20s${C_RESET}\n" "UTILISATEUR" "EXPIRATION"
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"

  grep -E "^#! " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r u ex; do
    printf "  %-24s %-20s\n" "$u" "$ex"
  done

  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  echo ""

  local user exp UUID trojanlink1 trojanlink2 trojanlink3
  read -rp "  ► Nom d'utilisateur : " user
  if [[ -z "$user" ]]; then
    trojan_menu
    return
  fi

  exp=$(grep -wE "^#! $user" "/etc/xray/config.json" | awk '{print $3}' | sort -u | head -n 1)
  if [[ -z "$exp" ]]; then
    echo -e "  ${C_RED}✖ Utilisateur non trouvé.${C_RESET}"
    wait_key
    trojan_menu
    return
  fi

  UUID=$(grep -wE "^#! $user" "/etc/xray/config.json" | awk '{print $4}' | sort -u | head -n 1)

  trojanlink1="trojan://${UUID}@${DOMAIN}:443?path=/trws&security=tls&encryption=none&host=${DOMAIN}&type=ws#${user}"
  trojanlink2="trojan://${UUID}@${DOMAIN}:80?path=/trws&encryption=none&security=none&host=${DOMAIN}&type=ws#${user}"
  trojanlink3="trojan://${UUID}@${DOMAIN}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=${DOMAIN}#${user}"

  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GOLD}⚡ CLEFS TROJAN - $user${C_RESET}                                         ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Username${C_RESET}     : %-47s ${C_MAGENTA}║${C_RESET}\n" "$user"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Expiry Date${C_RESET}  : %-47s ${C_MAGENTA}║${C_RESET}\n" "$exp"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Password/UUID${C_RESET}: %-47s ${C_MAGENTA}║${C_RESET}\n" "$UUID"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}TROJAN WS TLS (Port 443) :${C_RESET}"
  echo -e "  ${C_GREEN}${trojanlink1}${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}TROJAN WS NTLS (Port 80) :${C_RESET}"
  echo -e "  ${C_GREEN}${trojanlink2}${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}TROJAN gRPC TLS (Port 443) :${C_RESET}"
  echo -e "  ${C_GREEN}${trojanlink3}${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"

  wait_key
  trojan_menu
}

# ─── ACTIVE TROJAN USERS ──────────────────────────────────────────────────────
function trojan_login() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ UTILISATEURS TROJAN EN LIGNE${C_RESET}                                 ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  local data any_active=false log_file="/var/log/xray/access.log"
  data=( $(grep '^#!' /etc/xray/config.json 2>/dev/null | awk '{print $2}' | sort -u) )

  if [[ ! -f "$log_file" ]]; then
    echo -e "  ${C_GRAY}Fichier de log Xray introuvable ($log_file).${C_RESET}"
    wait_key
    trojan_menu
    return
  fi

  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"

  for user in "${data[@]}"; do
    [[ -z "$user" ]] && continue

    local user_ips
    user_ips=$(grep -w "$user" "$log_file" 2>/dev/null | tail -n 200 | awk '{print $3}' | cut -d: -f1 | grep -v "127.0.0.1" | sort -u)

    if [[ -n "$user_ips" ]]; then
      any_active=true
      echo -e "  ${C_GOLD}User :${C_RESET} ${C_WHITE}$user${C_RESET}"
      while read -r ip; do
        [[ -n "$ip" ]] && echo -e "  ${C_CYAN}└─ IP Connected :${C_RESET} $ip"
      done <<< "$user_ips"
      echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
    fi
  done

  if [[ "$any_active" == false ]]; then
    echo -e "  ${C_GRAY}Aucun utilisateur Trojan actif actuellement.${C_RESET}"
    echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  fi

  wait_key
  trojan_menu
}

# ─── MENU TROJAN ──────────────────────────────────────────────────────────────
function trojan_menu() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ XRAY TROJAN PROTOCOL MANAGER${C_RESET}                                  ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "   ${C_MAGENTA}[01]${C_RESET} CRÉER UN COMPTE        ${C_MAGENTA}[04]${C_RESET} AFFICHER / LISTER CONFIGS"
  echo -e "   ${C_MAGENTA}[02]${C_RESET} RENOUVELER UN COMPTE   ${C_MAGENTA}[05]${C_RESET} UTILISATEURS ACTIFS (ONLINE)"
  echo -e "   ${C_RED}[03]${C_RESET} SUPPRIMER UN COMPTE"
  echo ""
  echo -e "   ${C_GRAY}[00] RETOUR MENU PRINCIPAL${C_RESET}"
  echo ""
  echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
  read -rp "  🜲 Sélectionnez une option [00-05] : " opt
  echo ""

  case $opt in
    1|01) add_trojan ;;
    2|02) renew_trojan ;;
    3|03) delete_trojan ;;
    4|04) view_trojan ;;
    5|05) trojan_login ;;
    0|00) clear; menu 2>/dev/null || return ;;
    *)
      echo -e "  ${C_RED}✖ Option invalide !${C_RESET}"
      sleep 1
      trojan_menu
      ;;
  esac
}

# Initialisation
trojan_menu

