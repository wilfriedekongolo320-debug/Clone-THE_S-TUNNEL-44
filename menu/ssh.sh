#!/bin/bash
# ============================================================
#  SSH / OpenVPN / SlowDNS Manager (Cyberpunk Theme)
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
export PUB=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "N/A")
export DNS=$(cat /etc/slowdns/nsdomain 2>/dev/null || echo "N/A")
export MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || echo "127.0.0.1")

wait_key() {
  echo ""
  read -n 1 -s -r -p "  Appuyez sur une touche pour continuer..."
  echo ""
}

# ─── CREATE SSH ACCOUNT ───────────────────────────────────────────────────────
function create_ssh_account() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CRÉER UN COMPTE SSH / OPENVPN${C_RESET}                             ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  local Login Pass DaysActive
  read -rp "  ► Nom d'utilisateur      : " Login
  if [[ -z "$Login" ]]; then
    echo -e "  ${C_RED}✖ Le nom d'utilisateur ne peut pas être vide.${C_RESET}"
    wait_key
    menu_ssh
    return
  fi

  if id "$Login" &>/dev/null; then
    echo -e "  ${C_RED}✖ L'utilisateur '$Login' existe déjà.${C_RESET}"
    wait_key
    menu_ssh
    return
  fi

  read -rp "  ► Mot de passe           : " Pass
  if [[ -z "$Pass" ]]; then
    echo -e "  ${C_RED}✖ Le mot de passe ne peut pas être vide.${C_RESET}"
    wait_key
    menu_ssh
    return
  fi

  read -rp "  ► Validité (en jours)    : " DaysActive
  if [[ -z "$DaysActive" || ! "$DaysActive" =~ ^[0-9]+$ || "$DaysActive" -le 0 ]]; then
    echo -e "  ${C_RED}✖ Durée de validité invalide.${C_RESET}"
    wait_key
    menu_ssh
    return
  fi

  useradd -e "$(date -d "$DaysActive days" +"%Y-%m-%d")" -s /bin/false -M "$Login"
  echo -e "$Pass\n$Pass" | passwd "$Login" &>/dev/null
  local exp
  exp="$(chage -l "$Login" | grep "Account expires" | awk -F": " '{print $2}')"

  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GOLD}⚡ DÉTAILS DU COMPTE SSH${C_RESET}                                         ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Username${C_RESET}     : %-47s ${C_MAGENTA}║${C_RESET}\n" "$Login"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Password${C_RESET}     : %-47s ${C_MAGENTA}║${C_RESET}\n" "$Pass"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Expiration${C_RESET}   : %-47s ${C_MAGENTA}║${C_RESET}\n" "$exp"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Host / IP${C_RESET}    : %-47s ${C_MAGENTA}║${C_RESET}\n" "$MYIP"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Domain${C_RESET}       : %-47s ${C_MAGENTA}║${C_RESET}\n" "$DOMAIN"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}NS Domain${C_RESET}    : %-47s ${C_MAGENTA}║${C_RESET}\n" "$DNS"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_MAGENTA}║${C_RESET}  %-15s : %-47s ${C_MAGENTA}║${C_RESET}\n" "OpenSSH" "22"
  printf "${C_MAGENTA}║${C_RESET}  %-15s : %-47s ${C_MAGENTA}║${C_RESET}\n" "Dropbear" "109, 143"
  printf "${C_MAGENTA}║${C_RESET}  %-15s : %-47s ${C_MAGENTA}║${C_RESET}\n" "Stunnel" "447, 777"
  printf "${C_MAGENTA}║${C_RESET}  %-15s : %-47s ${C_MAGENTA}║${C_RESET}\n" "WS NTLS" "80, 8880"
  printf "${C_MAGENTA}║${C_RESET}  %-15s : %-47s ${C_MAGENTA}║${C_RESET}\n" "WS TLS" "443"
  printf "${C_MAGENTA}║${C_RESET}  %-15s : %-47s ${C_MAGENTA}║${C_RESET}\n" "UDPGW" "7100–7900"
  printf "${C_MAGENTA}║${C_RESET}  %-15s : %-47s ${C_MAGENTA}║${C_RESET}\n" "Squid" "3128, 8880"
  printf "${C_MAGENTA}║${C_RESET}  %-15s : %-47s ${C_MAGENTA}║${C_RESET}\n" "OpenVPN" "TCP 1194, SSL 2200, OHP 8000"
  printf "${C_MAGENTA}║${C_RESET}  %-15s : %-47s ${C_MAGENTA}║${C_RESET}\n" "SlowDNS" "22, 53, 5300, 80, 443"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}UDP CUSTOM :${C_RESET}"
  echo -e "  ${C_GREEN}$DOMAIN:1-65535@$Login:$Pass${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}SLOWDNS PUB KEY :${C_RESET}"
  echo -e "  ${C_GREEN}${PUB}${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}OPENVPN CONFIG DOWNLOAD :${C_RESET}"
  echo -e "  ${C_GREEN}https://$DOMAIN:2081${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}PAYLOAD WEBSOCKET :${C_RESET}"
  echo -e "  ${C_GRAY}GET / HTTP/1.1[crlf]Host: $DOMAIN[crlf]Upgrade: websocket[crlf][crlf]${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"

  wait_key
  menu_ssh
}

# ─── RENEW SSH ACCOUNT ────────────────────────────────────────────────────────
function renew_ssh_account() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ RENOUVELER COMPTE SSH${C_RESET}                                      ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  printf "  ${C_BOLD}%-24s %-20s${C_RESET}\n" "UTILISATEUR" "EXPIRATION"
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"

  while IFS=: read -r user _ uid _; do
    if [[ $uid -ge 1000 && "$user" != "nobody" ]]; then
      local exp
      exp="$(chage -l "$user" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')"
      printf "  %-24s %-20s\n" "$user" "$exp"
    fi
  done < /etc/passwd

  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  echo ""

  local User Days
  read -rp "  ► Nom d'utilisateur (Entrée pour annuler) : " User
  if [[ -z "$User" ]]; then
    menu_ssh
    return
  fi

  if ! id "$User" &>/dev/null; then
    echo -e "  ${C_RED}✖ L'utilisateur '$User' n'existe pas.${C_RESET}"
    wait_key
    menu_ssh
    return
  fi

  read -rp "  ► Nombre de jours à ajouter              : " Days
  if [[ -z "$Days" || ! "$Days" =~ ^[0-9]+$ || "$Days" -le 0 ]]; then
    echo -e "  ${C_RED}✖ Veuillez entrer un nombre valide.${C_RESET}"
    wait_key
    menu_ssh
    return
  fi

  local current_exp old_date extend new_expire Expiration Expiration_Display
  current_exp=$(chage -l "$User" | grep "Account expires" | awk -F": " '{print $2}')
  if [[ "$current_exp" == "never" || -z "$current_exp" ]]; then
    old_date=$(date +%s)
    current_exp="Never"
  else
    old_date=$(date -d "$current_exp +1 day" +%s 2>/dev/null || date +%s)
  fi

  extend=$(( Days * 86400 ))
  new_expire=$(( old_date + extend ))
  Expiration=$(date --date="1970-01-01 $new_expire sec" +%Y-%m-%d)
  Expiration_Display=$(date --date="1970-01-01 $new_expire sec" '+%d %b %Y')

  passwd -u "$User" &>/dev/null
  usermod -e "$Expiration" "$User" &>/dev/null

  echo ""
  echo -e "  ${C_GREEN}⚡ [OK] Le compte '$User' a été prolongé de $Days jour(s).${C_RESET}"
  echo -e "  ${C_WHITE}Ancienne date : $current_exp${C_RESET}"
  echo -e "  ${C_GOLD}Nouvelle date : $Expiration_Display${C_RESET}"

  wait_key
  menu_ssh
}

# ─── DELETE SSH ACCOUNT ───────────────────────────────────────────────────────
function delete_ssh_account() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_RED}❖ SUPPRIMER COMPTE SSH${C_RESET}                                       ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  printf "  ${C_BOLD}%-24s %-20s${C_RESET}\n" "UTILISATEUR" "EXPIRATION"
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"

  while IFS=: read -r user _ uid _; do
    if [[ $uid -ge 1000 && "$user" != "nobody" ]]; then
      local exp
      exp="$(chage -l "$user" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')"
      printf "  %-24s %-20s\n" "$user" "$exp"
    fi
  done < /etc/passwd

  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  echo ""

  local User
  read -rp "  ► Nom d'utilisateur à supprimer (Entrée pour annuler) : " User
  if [[ -z "$User" ]]; then
    menu_ssh
    return
  fi

  if ! id "$User" &>/dev/null; then
    echo -e "  ${C_RED}✖ L'utilisateur '$User' n'existe pas.${C_RESET}"
    wait_key
    menu_ssh
    return
  fi

  pkill -u "$User" &>/dev/null
  userdel -r "$User" &>/dev/null

  echo ""
  echo -e "  ${C_GREEN}⚡ [OK] L'utilisateur '$User' a été complètement supprimé.${C_RESET}"

  wait_key
  menu_ssh
}

# ─── LIST SSH MEMBERS ─────────────────────────────────────────────────────────
function list_ssh_members() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ LISTE DES MEMBRES SSH${C_RESET}                                         ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  printf "  ${C_BOLD}%-18s %-20s %-15s${C_RESET}\n" "UTILISATEUR" "EXPIRATION" "STATUT"
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"

  while read -r expired; do
    local AKUN ID exp status
    AKUN="$(echo "$expired" | cut -d: -f1)"
    ID="$(echo "$expired" | cut -d: -f3)"
    
    if [[ $ID -ge 1000 && "$AKUN" != "nobody" ]]; then
      exp="$(chage -l "$AKUN" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')"
      status="$(passwd -S "$AKUN" 2>/dev/null | awk '{print $2}')"
      
      if [[ "$status" == "L" ]]; then
        printf "  %-18s %-20s ${C_RED}%-15s${C_RESET}\n" "$AKUN" "$exp" "LOCKED"
      else
        printf "  %-18s %-20s ${C_GREEN}%-15s${C_RESET}\n" "$AKUN" "$exp" "UNLOCKED"
      fi
    fi
  done < /etc/passwd

  local JUMLAH
  JUMLAH="$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)"
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  echo -e "  ${C_GOLD}Total des comptes :${C_RESET} ${C_WHITE}$JUMLAH utilisateur(s)${C_RESET}"

  wait_key
  menu_ssh
}

# ─── ACTIVE SSH LOGINS ────────────────────────────────────────────────────────
function active_ssh_logins() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ SESSIONS ACTIVE SSH / DROPBEAR${C_RESET}                               ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  local LOG
  if [ -e "/var/log/auth.log" ]; then
    LOG="/var/log/auth.log"
  elif [ -e "/var/log/secure" ]; then
    LOG="/var/log/secure"
  else
    echo -e "  ${C_RED}✖ Fichier de journalisation introuvable.${C_RESET}"
    wait_key
    menu_ssh
    return
  fi

  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  printf "  ${C_BOLD}%-10s │ %-20s │ %-20s${C_RESET}\n" "PID" "UTILISATEUR" "ADRESSE IP"
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"

  local found=0
  grep -i dropbear "$LOG" | grep -i "Password auth succeeded" > /tmp/login-db.txt
  for PID in $(ps aux | grep -i dropbear | awk '{print $2}'); do
    grep "dropbear\[$PID\]" /tmp/login-db.txt > /tmp/login-db-pid.txt
    if [ -s /tmp/login-db-pid.txt ]; then
      USER=$(awk '{print $10}' /tmp/login-db-pid.txt)
      IP=$(awk '{print $12}' /tmp/login-db-pid.txt)
      printf "  %-10s │ %-20s │ %-20s\n" "$PID" "$USER" "$IP"
      found=1
    fi
  done

  grep -i sshd "$LOG" | grep -i "Accepted password for" > /tmp/login-db.txt
  for PID in $(ps aux | grep "\[priv\]" | awk '{print $2}'); do
    grep "sshd\[$PID\]" /tmp/login-db.txt > /tmp/login-db-pid.txt
    if [ -s /tmp/login-db-pid.txt ]; then
      USER=$(awk '{print $9}' /tmp/login-db-pid.txt)
      IP=$(awk '{print $11}' /tmp/login-db-pid.txt)
      printf "  %-10s │ %-20s │ %-20s\n" "$PID" "$USER" "$IP"
      found=1
    fi
  done

  if [[ $found -eq 0 ]]; then
    echo -e "  ${C_GRAY}Aucune session active détectée.${C_RESET}"
  fi
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"

  rm -f /tmp/login-db-pid.txt /tmp/login-db.txt
  wait_key
  menu_ssh
}

# ─── MENU SSH ─────────────────────────────────────────────────────────────────
function menu_ssh() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ SSH & OPENVPN PROTOCOL MANAGER${C_RESET}                                ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "   ${C_MAGENTA}[01]${C_RESET} CRÉER UN COMPTE        ${C_MAGENTA}[04]${C_RESET} LISTE DES COMPTES"
  echo -e "   ${C_MAGENTA}[02]${C_RESET} RENOUVELER UN COMPTE   ${C_MAGENTA}[05]${C_RESET} SESSIONS EN LIGNE"
  echo -e "   ${C_RED}[03]${C_RESET} SUPPRIMER UN COMPTE"
  echo ""
  echo -e "   ${C_GRAY}[00] RETOUR MENU PRINCIPAL${C_RESET}"
  echo ""
  echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
  read -rp "  🜲 Sélectionnez une option [00-05] : " opt
  echo ""

  case $opt in
    1|01) create_ssh_account ;;
    2|02) renew_ssh_account ;;
    3|03) delete_ssh_account ;;
    4|04) list_ssh_members ;;
    5|05) active_ssh_logins ;;
    0|00) clear; menu 2>/dev/null || return ;;
    *)
      echo -e "  ${C_RED}✖ Option invalide !${C_RESET}"
      sleep 1
      menu_ssh
      ;;
  esac
}

# Lancement du menu
menu_ssh
