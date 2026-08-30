#!/bin/bash
# ============================================================
#  Xray VMess Manager (Cyberpunk / Neo-Terminal Theme)
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

DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "example.com")
MYIP=$(ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

wait_key() {
  echo ""
  read -n 1 -s -r -p "  Appuyez sur une touche pour continuer..."
  echo ""
}

# ─── ADD VMESS ────────────────────────────────────────────────────────────────
function add_vmess() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CRÉER UN COMPTE VMESS${C_RESET}                                         ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  local user masaaktif
  while true; do
    read -rp "  ► Nom d'utilisateur : " -e user
    if [[ -z "$user" ]]; then
      echo -e "  ${C_RED}✖ Le nom d'utilisateur ne peut pas être vide.${C_RESET}"
      continue
    fi
    if [[ ! "$user" =~ ^[a-zA-Z0-9_]+$ ]]; then
      echo -e "  ${C_RED}✖ Lettres, chiffres et underscores uniquement.${C_RESET}"
      continue
    fi
    if grep -q -w "$user" /etc/xray/config.json 2>/dev/null; then
      echo -e "  ${C_RED}✖ Cet utilisateur existe déjà.${C_RESET}"
      wait_key
      clear
      echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
      echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CRÉER UN COMPTE VMESS${C_RESET}                                         ${C_MAGENTA}║${C_RESET}"
      echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
      echo ""
      continue
    fi
    break
  done

  while true; do
    read -rp "  ► Durée de validité (jours) : " masaaktif
    if [[ -z "$masaaktif" || ! "$masaaktif" =~ ^[0-9]+$ || "$masaaktif" -le 0 ]]; then
      echo -e "  ${C_RED}✖ Veuillez entrer un nombre valide de jours.${C_RESET}"
      continue
    fi
    break
  done

  local uuid exp
  uuid=$(cat /proc/sys/kernel/random/uuid)
  exp=$(date -d "$masaaktif days" +"%Y-%m-%d")

  sed -i '/#vmess$/a\### '"$user $exp $uuid"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /etc/xray/config.json

  sed -i '/#vmessgrpc$/a\### '"$user $exp $uuid"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /etc/xray/config.json

  local ws_tls ws_nontls grpc vmesslink1 vmesslink2 vmesslink3
  ws_tls=$(cat <<EOF
{"v":"2","ps":"${user}","add":"${DOMAIN}","port":"443","id":"${uuid}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"tls"}
EOF
  )
  ws_nontls=$(cat <<EOF
{"v":"2","ps":"${user}","add":"${DOMAIN}","port":"80","id":"${uuid}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"none"}
EOF
  )
  grpc=$(cat <<EOF
{"v":"2","ps":"${user}","add":"${DOMAIN}","port":"443","id":"${uuid}","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"","tls":"tls"}
EOF
  )

  vmesslink1="vmess://$(echo -n "$ws_tls" | base64 -w 0)"
  vmesslink2="vmess://$(echo -n "$ws_nontls" | base64 -w 0)"
  vmesslink3="vmess://$(echo -n "$grpc" | base64 -w 0)"

  systemctl restart xray > /dev/null 2>&1
  service cron restart > /dev/null 2>&1

  local custom_tls custom_ntls
  custom_tls=$(grep -w "VMESS CUSTOM TLS" /etc/xray/port_info 2>/dev/null | cut -d: -f2 | tr -d ' ')
  custom_ntls=$(grep -w "VMESS CUSTOM NTLS" /etc/xray/port_info 2>/dev/null | cut -d: -f2 | tr -d ' ')

  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GOLD}⚡ DÉTAILS DU COMPTE VMESS${C_RESET}                                       ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Username${C_RESET}    : %-48s ${C_MAGENTA}║${C_RESET}\n" "$user"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Expiration${C_RESET}  : %-48s ${C_MAGENTA}║${C_RESET}\n" "$exp"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}UUID${C_RESET}        : %-48s ${C_MAGENTA}║${C_RESET}\n" "$uuid"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Domain${C_RESET}      : %-48s ${C_MAGENTA}║${C_RESET}\n" "$DOMAIN"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Port TLS${C_RESET}    : %-48s ${C_MAGENTA}║${C_RESET}\n" "443"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Port NonTLS${C_RESET} : %-48s ${C_MAGENTA}║${C_RESET}\n" "80"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Port gRPC${C_RESET}   : %-48s ${C_MAGENTA}║${C_RESET}\n" "443"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Path WS${C_RESET}     : %-48s ${C_MAGENTA}║${C_RESET}\n" "/vmess"
  [ -n "$custom_tls" ] && printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Custom TLS${C_RESET}  : %-48s ${C_MAGENTA}║${C_RESET}\n" "$custom_tls"
  [ -n "$custom_ntls" ] && printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Custom NTLS${C_RESET} : %-48s ${C_MAGENTA}║${C_RESET}\n" "$custom_ntls"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}LIEN TLS :${C_RESET}"
  echo -e "  ${C_GREEN}${vmesslink1}${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}LIEN NON-TLS :${C_RESET}"
  echo -e "  ${C_GREEN}${vmesslink2}${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}LIEN GRPC :${C_RESET}"
  echo -e "  ${C_GREEN}${vmesslink3}${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"

  wait_key
  vmess_menu
}

# ─── RENEW VMESS ──────────────────────────────────────────────────────────────
function renew_vmess() {
  clear
  local NUMBER_OF_CLIENTS
  NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/etc/xray/config.json" 2>/dev/null || echo 0)

  if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ RENOUVELER COMPTE VMESS${C_RESET}                                      ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    echo -e "  ${C_RED}✖ Aucun compte VMess trouvé.${C_RESET}"
    wait_key
    vmess_menu
    return
  fi

  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ RENOUVELER COMPTE VMESS${C_RESET}                                      ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  printf "  ${C_BOLD}%-24s %-20s${C_RESET}\n" "UTILISATEUR" "EXPIRATION"
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  grep -E "^### " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r u ex; do
    printf "  %-24s %-20s\n" "$u" "$ex"
  done
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  echo ""

  local user masaaktif
  while true; do
    read -rp "  ► Nom d'utilisateur (Entrée pour annuler) : " user
    if [[ -z "$user" ]]; then
      vmess_menu
      return
    fi
    if ! grep -q -wE "^### $user" "/etc/xray/config.json"; then
      echo -e "  ${C_RED}✖ Utilisateur introuvable.${C_RESET}"
      continue
    fi
    break
  done

  while true; do
    read -rp "  ► Jours à ajouter : " masaaktif
    if [[ -z "$masaaktif" || ! "$masaaktif" =~ ^[0-9]+$ || "$masaaktif" -le 0 ]]; then
      echo -e "  ${C_RED}✖ Entrez un nombre entier positif.${C_RESET}"
      continue
    fi
    break
  done

  local exp uuid now d1 d2 exp2 exp3 exp4
  exp=$(grep -wE "^### $user" "/etc/xray/config.json" | awk '{print $3}' | head -n1)
  uuid=$(grep -wE "^### $user" "/etc/xray/config.json" | awk '{print $4}' | head -n1)
  now=$(date +%Y-%m-%d)
  d1=$(date -d "$exp" +%s 2>/dev/null || date +%s)
  d2=$(date -d "$now" +%s)
  
  if [ "$d1" -lt "$d2" ]; then
    exp4=$(date -d "$masaaktif days" +"%Y-%m-%d")
  else
    exp2=$(( (d1 - d2) / 86400 ))
    exp3=$(( exp2 + masaaktif ))
    exp4=$(date -d "$exp3 days" +"%Y-%m-%d")
  fi

  sed -i "/### $user/c\### $user $exp4 $uuid" /etc/xray/config.json
  systemctl restart xray > /dev/null 2>&1

  echo ""
  echo -e "  ${C_GREEN}⚡ [OK] Le compte '$user' a été renouvelé jusqu'au $exp4 ($masaaktif jours ajoutés).${C_RESET}"
  wait_key
  vmess_menu
}

# ─── DELETE VMESS ─────────────────────────────────────────────────────────────
function delete_vmess() {
  clear
  local NUMBER_OF_CLIENTS
  NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/etc/xray/config.json" 2>/dev/null || echo 0)

  if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_RED}❖ SUPPRIMER COMPTE VMESS${C_RESET}                                      ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    echo -e "  ${C_RED}✖ Aucun compte VMess trouvé.${C_RESET}"
    wait_key
    vmess_menu
    return
  fi

  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_RED}❖ SUPPRIMER COMPTE VMESS${C_RESET}                                      ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  printf "  ${C_BOLD}%-24s %-20s${C_RESET}\n" "UTILISATEUR" "EXPIRATION"
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  grep -E "^### " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r u ex; do
    printf "  %-24s %-20s\n" "$u" "$ex"
  done
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  echo ""

  local user
  read -rp "  ► Nom d'utilisateur à supprimer (Entrée pour annuler) : " user
  if [[ -z "$user" ]]; then
    vmess_menu
    return
  fi

  local exp
  exp=$(grep -wE "^### $user" "/etc/xray/config.json" | awk '{print $3}' | head -n1)
  if [[ -z "$exp" ]]; then
    echo -e "  ${C_RED}✖ Utilisateur non trouvé.${C_RESET}"
    sleep 1.5
    vmess_menu
    return
  fi

  sed -i "/^### $user $exp/,/^},{/d" /etc/xray/config.json
  systemctl restart xray > /dev/null 2>&1

  echo ""
  echo -e "  ${C_GREEN}⚡ [OK] Le compte '$user' a été supprimé avec succès.${C_RESET}"
  wait_key
  vmess_menu
}

# ─── ACTIVE USERS ─────────────────────────────────────────────────────────────
function vmess_login() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ UTILISATEURS VMESS CONNECTÉS${C_RESET}                                 ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  echo -n > /tmp/other.txt
  local data=( $(grep '^### ' /etc/xray/config.json 2>/dev/null | awk '{print $2}' | sort -u) )
  local any_active=false

  for user in "${data[@]}"; do
    [[ -z "$user" ]] && continue
    echo -n > /tmp/ipvmess.txt
    local data2=( $(netstat -anp 2>/dev/null | grep ESTABLISHED | grep tcp6 | grep xray | awk '{print $5}' | cut -d: -f1 | sort -u) )
    for ip in "${data2[@]}"; do
      local match
      match=$(grep -w "$user" /var/log/xray/access.log 2>/dev/null | awk '{print $3}' | cut -d: -f1 | grep -w "$ip" | sort -u)
      if [[ "$match" == "$ip" ]]; then
        echo "$match" >> /tmp/ipvmess.txt
      else
        echo "$ip" >> /tmp/other.txt
      fi
      local current
      current=$(cat /tmp/ipvmess.txt)
      sed -i "/$current/d" /tmp/other.txt > /dev/null 2>&1
    done

    if [[ -s /tmp/ipvmess.txt ]]; then
      any_active=true
      echo -e "  ${C_GOLD}User : ${C_WHITE}$user${C_RESET}"
      nl /tmp/ipvmess.txt | while read -r line; do
        echo -e "    ${C_CYAN}↳ $line${C_RESET}"
      done
      echo ""
    fi
    rm -f /tmp/ipvmess.txt
  done

  if [[ -s /tmp/other.txt ]]; then
    local oth
    oth=$(sort -u /tmp/other.txt | nl)
    if [[ -n "$oth" ]]; then
      any_active=true
      echo -e "  ${C_GOLD}Autres connexions non identifiées :${C_RESET}"
      echo "$oth" | while read -r line; do
        echo -e "    ${C_GRAY}↳ $line${C_RESET}"
      done
      echo ""
    fi
  fi

  if [[ "$any_active" == false ]]; then
    echo -e "  ${C_GRAY}Aucun utilisateur VMess actuellement connecté.${C_RESET}"
  fi

  rm -f /tmp/other.txt
  wait_key
  vmess_menu
}

# ─── VIEW CONFIG ──────────────────────────────────────────────────────────────
function view_config() {
  clear
  local NUMBER_OF_CLIENTS
  NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/etc/xray/config.json" 2>/dev/null || echo 0)

  if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ DÉTAILS COMPTE VMESS${C_RESET}                                         ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    echo -e "  ${C_RED}✖ Aucun compte VMess trouvé.${C_RESET}"
    wait_key
    vmess_menu
    return
  fi

  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ VOIR COMPTE VMESS${C_RESET}                                            ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  printf "  ${C_BOLD}%-24s %-20s${C_RESET}\n" "UTILISATEUR" "EXPIRATION"
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  grep -E "^### " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r u ex; do
    printf "  %-24s %-20s\n" "$u" "$ex"
  done
  echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
  echo ""

  local user
  read -rp "  ► Entrez le nom d'utilisateur : " user
  if [[ -z $user ]]; then
    vmess_menu
    return
  fi

  local exp UUID
  exp=$(grep -wE "^### $user" "/etc/xray/config.json" | awk '{print $3}' | head -n1)
  if [[ -z "$exp" ]]; then
    echo -e "  ${C_RED}✖ Utilisateur non trouvé.${C_RESET}"
    sleep 1.5
    vmess_menu
    return
  fi
  UUID=$(grep -wE "^### $user" "/etc/xray/config.json" | awk '{print $4}' | head -n1)

  local ws_tls ws_nontls grpc vmesslink1 vmesslink2 vmesslink3
  ws_tls=$(cat <<EOF
{"v":"2","ps":"${user}","add":"${DOMAIN}","port":"443","id":"${UUID}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"tls"}
EOF
  )
  ws_nontls=$(cat <<EOF
{"v":"2","ps":"${user}","add":"${DOMAIN}","port":"80","id":"${UUID}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"none"}
EOF
  )
  grpc=$(cat <<EOF
{"v":"2","ps":"${user}","add":"${DOMAIN}","port":"443","id":"${UUID}","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"","tls":"tls"}
EOF
  )

  vmesslink1="vmess://$(echo -n "$ws_tls" | base64 -w 0)"
  vmesslink2="vmess://$(echo -n "$ws_nontls" | base64 -w 0)"
  vmesslink3="vmess://$(echo -n "$grpc" | base64 -w 0)"

  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GOLD}⚡ DÉTAILS DU COMPTE : $user${C_RESET}"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Username${C_RESET}   : %-48s ${C_MAGENTA}║${C_RESET}\n" "$user"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Expiration${C_RESET} : %-48s ${C_MAGENTA}║${C_RESET}\n" "$exp"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}UUID${C_RESET}       : %-48s ${C_MAGENTA}║${C_RESET}\n" "$UUID"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}LIEN TLS :${C_RESET}"
  echo -e "  ${C_GREEN}${vmesslink1}${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}LIEN NON-TLS :${C_RESET}"
  echo -e "  ${C_GREEN}${vmesslink2}${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_CYAN}LIEN GRPC :${C_RESET}"
  echo -e "  ${C_GREEN}${vmesslink3}${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"

  wait_key
  vmess_menu
}

# ─── VMESS MENU ───────────────────────────────────────────────────────────────
function vmess_menu() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ VMESS PROTOCOL MANAGER${C_RESET}                                        ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "   ${C_MAGENTA}[01]${C_RESET} CRÉER UN COMPTE        ${C_MAGENTA}[04]${C_RESET} VOIR LES CONF / LIENS"
  echo -e "   ${C_MAGENTA}[02]${C_RESET} RENOUVELER UN COMPTE   ${C_MAGENTA}[05]${C_RESET} UTILISATEURS CONNECTÉS"
  echo -e "   ${C_RED}[03]${C_RESET} SUPPRIMER UN COMPTE"
  echo ""
  echo -e "   ${C_GRAY}[00] RETOUR MENU PRINCIPAL${C_RESET}"
  echo ""
  echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
  read -rp "  🜲 Sélectionnez une option [00-05] : " opt
  echo ""

  case $opt in
    1|01) add_vmess ;;
    2|02) renew_vmess ;;
    3|03) delete_vmess ;;
    4|04) view_config ;;
    5|05) vmess_login ;;
    0|00) clear; menu 2>/dev/null || return ;;
    *)
      echo -e "  ${C_RED}✖ Option invalide !${C_RESET}"
      sleep 1
      vmess_menu
      ;;
  esac
}

# Lancement du menu
vmess_menu
