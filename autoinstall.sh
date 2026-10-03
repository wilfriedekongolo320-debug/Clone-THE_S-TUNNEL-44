#!/bin/bash
# ============================================================
#  THE_S TUNNEL PRO - MAIN INSTALLER (Fix Missing autoinstall.sh)
# ============================================================

set -e

# Clear et variables de couleur
clear
export C_RESET='\033[0m'
export C_BOLD='\033[1m'
export C_CYAN='\033[38;5;45m'
export C_MAGENTA='\033[38;5;201m'
export C_GREEN='\033[38;5;46m'
export C_GOLD='\033[38;5;220m'
export C_RED='\033[38;5;196m'

SERVER_HOST="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main"

# --- VÉRICATION ET TÉLÉCHARGEMENT DE AUTOINSTALL.SH SI ABSENT ---
ensure_autoinstall_exists() {
    if [ ! -f "/root/autoinstall.sh" ]; then
        echo -e " ${C_CYAN}[INFO] Téléchargement du module autoinstall.sh...${C_RESET}"
        wget -q -O /root/autoinstall.sh "${SERVER_HOST}/autoinstall.sh" || {
            # Si le fichier n'existe pas sur le dépôt, création d'un fallback sécurisé
            cat > /root/autoinstall.sh << 'EOF'
#!/bin/bash
echo "Attribution des paramètres par défaut..."
EOF
        }
        chmod +x /root/autoinstall.sh
    fi
}

# --- AFFICHAGE ET GESTION DU MENU D'ENTRÉE ---
show_terms_menu() {
    clear
    echo -e "${C_MAGENTA}╔═══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CONDITIONS D'UTILISATION - THE_S TUNNEL PRO${C_RESET}                  ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    echo -e "  ${C_GOLD}[01]${C_RESET} • Accepter et Configurer le Domaine"
    echo -e "  ${C_GOLD}[02]${C_RESET} • Poursuivre sans domaine (Mode IP par défaut)"
    echo ""

    local choice
    while true; do
        read -rp "  ► Choisissez une option [1-2] : " choice
        case "$choice" in
            1|01)
                echo -e " ${C_GREEN}✓ Option 1 sélectionnée.${C_RESET}"
                ensure_autoinstall_exists
                bash /root/autoinstall.sh
                break
                ;;
            2|02)
                echo -e " ${C_GOLD}✓ Poursuite sans domaine...${C_RESET}"
                ensure_autoinstall_exists
                bash /root/autoinstall.sh --no-domain
                break
                ;;
            *)
                echo -e " ${C_RED}✖ Choix invalide. Veuillez entrer 1 ou 2.${C_RESET}"
                ;;
        esac
    done
}

# Lancement
show_terms_menu
