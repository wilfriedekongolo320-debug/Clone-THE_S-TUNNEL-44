#!/bin/bash
# ============================================================
#  XRAY DNS CONFIGURATION MANAGER (Cyberpunk Theme)
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

wait_key() {
  echo ""
  read -n 1 -s -r -p "  Appuyez sur une touche pour continuer..."
  echo ""
}

# ─── SHOW ACTIVE DNS ──────────────────────────────────────────────────────────
show_current_dns() {
  local current_dns
  current_dns=$(grep -E "^nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}' | xargs)
  if [[ -z "$current_dns" ]]; then
    current_dns="Aucun DNS configuré"
  fi
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}DNS Actif(s)${C_RESET} : ${C_GREEN}%-43s${C_RESET} ${C_MAGENTA}║${C_RESET}\n" "$current_dns"
}

# ─── APPLY DNS ────────────────────────────────────────────────────────────────
apply_dns() {
  if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
    if [ -L /etc/resolv.conf ]; then
      unlink /etc/resolv.conf 2>/dev/null
    fi
    printf "nameserver %s\nnameserver %s\n" "$dns1" "$dns2" | tee /etc/resolv.conf > /dev/null
    systemctl restart systemd-resolved &>/dev/null
  else
    printf "nameserver %s\nnameserver %s\n" "$dns1" "$dns2" | tee /etc/resolv.conf > /dev/null
  fi

  # Attribuer les permissions en lecture seule temporaires si nécessaire pour éviter la réécriture immédiate
  chmod 644 /etc/resolv.conf 2>/dev/null
}

# ─── DNS MENU ─────────────────────────────────────────────────────────────────
dns_menu() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ GESTION ET CONFIGURATION DNS (SYSTEM)${C_RESET}                       ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  show_current_dns
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "   ${C_MAGENTA}[01]${C_RESET} Google DNS (8.8.8.8)       ${C_MAGENTA}[04]${C_RESET} Quad9 DNS (9.9.9.9)"
  echo -e "   ${C_MAGENTA}[02]${C_RESET} Cloudflare (1.1.1.1)      ${C_MAGENTA}[05]${C_RESET} AdGuard Default (Bloq. Pubs)"
  echo -e "   ${C_MAGENTA}[03]${C_RESET} OpenDNS (208.67.222.222)   ${C_MAGENTA}[06]${C_RESET} AdGuard Family (Filtre Ado)"
  echo ""
  echo -e "   ${C_GOLD}[99]${C_RESET} PERSONALISER LES DNS"
  echo ""
  echo -e "   ${C_GRAY}[00] RETOUR MENU PRINCIPAL${C_RESET}"
  echo ""
  echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
  read -rp "  🜲 Sélectionnez un fournisseur DNS [00-99] : " opt
  echo ""

  local dns1 dns2 provider
  case $opt in
    1|01) dns1="8.8.8.8"; dns2="8.8.4.4"; provider="Google DNS" ;;
    2|02) dns1="1.1.1.1"; dns2="1.0.0.1"; provider="Cloudflare DNS" ;;
    3|03) dns1="208.67.222.222"; dns2="208.67.220.220"; provider="OpenDNS" ;;
    4|04) dns1="9.9.9.9"; dns2="149.112.112.112"; provider="Quad9 DNS" ;;
    5|05) dns1="94.140.14.14"; dns2="94.140.15.15"; provider="AdGuard Default" ;;
    6|06) dns1="94.140.14.15"; dns2="94.140.15.16"; provider="AdGuard Family" ;;
    99)
      while true; do
        read -rp "  ► Entrez le DNS Primaire   : " dns1
        if [[ -z "$dns1" ]]; then
          echo -e "  ${C_RED}✖ L'adresse IP ne peut pas être vide.${C_RESET}"
          continue
        fi
        break
      done
      while true; do
        read -rp "  ► Entrez le DNS Secondaire : " dns2
        if [[ -z "$dns2" ]]; then
          dns2="$dns1"
        fi
        break
      done
      provider="Custom DNS"
      ;;
    0|00) clear; menu 2>/dev/null || return ;;
    *)
      echo -e "  ${C_RED}✖ Option invalide !${C_RESET}"
      sleep 1
      dns_menu
      return
      ;;
  esac

  apply_dns

  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GOLD}⚡ SERVEURS DNS APPLIQUÉS AVEC SUCCÈS${C_RESET}                          ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Fournisseur${C_RESET}     : %-43s ${C_MAGENTA}║${C_RESET}\n" "$provider"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}DNS Primaire${C_RESET}    : %-43s ${C_MAGENTA}║${C_RESET}\n" "$dns1"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}DNS Secondaire${C_RESET}  : %-43s ${C_MAGENTA}║${C_RESET}\n" "$dns2"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Auteur${C_RESET}          : %-43s ${C_MAGENTA}║${C_RESET}\n" "🜲 DOTYWRT V1.0"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"

  wait_key
  dns_menu
}

# Initialisation
dns_menu
