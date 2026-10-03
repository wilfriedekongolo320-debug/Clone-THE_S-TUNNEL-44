#!/bin/bash
# ============================================================
#  THE_S TUNNEL PRO - MAIN INSTALLER (Cyberpunk Theme)
# ============================================================

set -euo pipefail

# --- VÉRIFICATION ROOT ---
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "❌ ERREUR: Ce script doit être exécuté en tant que ROOT."
    echo "   Veuillez relancer avec sudo ou sous le compte root."
    exit 1
fi

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

export MYIP
MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo "127.0.0.1")

# --- CONFIGURATION DÉPÔT CENTRAL ---
readonly SERVER_HOST="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main"
readonly TIMEZONE="Asia/Kuala_Lumpur"

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            return 0
        else
            echo -e " ${C_RED}✖ Système d'exploitation non supporté : ${ID:-inconnu}. Abandon.${C_RESET}"
            exit 1
        fi
    else
        echo -e " ${C_RED}✖ Impossible de détecter l'OS. Abandon.${C_RESET}"
        exit 1
    fi
}

check_root_virt() {
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        if [ "$(systemd-detect-virt)" = "openvz" ]; then
            echo -e " ${C_GOLD}[!] Attention: VPS OpenVZ détecté. Poursuite de l'installation...${C_RESET}"
        fi
    fi
}

setup_host_time() {
    local localip hst host_entry
    localip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")
    hst=$(hostname)
    host_entry=$(awk '{print $2}' /etc/hosts | grep -w "$hst" || true)
    [ "$hst" != "$host_entry" ] && echo "$localip $hst" >> /etc/hosts
    
    if [ -f "/usr/share/zoneinfo/$TIMEZONE" ]; then
        ln -fs "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    fi

    sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1 || true
    sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1 || true
}

prepare_env() {
    mkdir -p /etc/xray
    touch /etc/xray/domain
}

show_tns() {
    clear
    echo -e "${C_MAGENTA}╔═══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CONDITIONS D'UTILISATION - THE_S TUNNEL PRO${C_RESET}               ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    echo -e "  ${C_GOLD}Bienvenue dans les services 🜲 THE_S TUNNEL PRO !${C_RESET}"
    echo ""
    echo -e "  ${C_GRAY}[*] Veuillez lire attentivement les termes ci-dessous :${C_RESET}"
    echo -e "  ${C_GRAY}[*] Service fourni 'tel quel', sans garantie d'aucune sorte.${C_RESET}"
    echo -e "  ${C_GRAY}[*] Utilisation strictement interdite pour activités illégales.${C_RESET}"
    echo -e "  ${C_GRAY}[*] THE_S Team n'est pas responsable de la perte de données.${C_RESET}"
    echo -e "  ${C_GRAY}[*] Vous devez respecter les lois locales en vigueur.${C_RESET}"
    echo ""
    echo -e "${C_CYAN}──────────────────────────────────────────────────────────────────────${C_RESET}"
    echo -e "  ${C_GREEN}[01] • Accepter les termes${C_RESET}"
    echo -e "  ${C_RED}[02] • Décliner et Quitter${C_RESET}"
    echo -e "${C_CYAN}──────────────────────────────────────────────────────────────────────${C_RESET}"
    echo ""
    read -rp "  🜲 Sélectionnez une option [01-02] : " opt
    echo ""

    case $opt in
        1 | 01)
            clear
            echo -e "  ${C_GREEN}⚡ Vous avez accepté les conditions d'utilisation.${C_RESET}"
            echo -e "  ${C_CYAN}Initialisation en cours...${C_RESET}"
            sleep 1
            add_domain
            ;;
        2 | 02)
            clear
            echo -e "  ${C_RED}✖ Vous avez refusé les conditions d'utilisation.${C_RESET}"
            echo -e "  ${C_RED}Fermeture de l'installateur...${C_RESET}"
            exit 0
            ;;
        *)
            echo -e "  ${C_RED}✖ Option invalide ! Annulation.${C_RESET}"
            exit 1
            ;;
    esac
}

add_domain() {
    clear
    echo -e "${C_MAGENTA}╔═══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CONFIGURATION DU DOMAINE${C_RESET}                                      ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""

    while true; do
        read -rp "  ► Nom de domaine / Hostname : " host
        if [[ -z "$host" ]]; then
            echo -e "  ${C_RED}✖ Le domaine ne peut pas être vide.${C_RESET}"
            continue
        fi

        domain_ip=$(getent ahosts "$host" | awk '{print $1; exit}' || echo "")
        if [[ "$domain_ip" == "$MYIP" ]]; then
            break
        else
            clear
            echo -e "${C_MAGENTA}╔═══════════════════════════════════════════════════════════════════════╗${C_RESET}"
            echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_RED}✖ ERREUR DE POINTEUR DNS${C_RESET}                                          ${C_MAGENTA}║${C_RESET}"
            echo -e "${C_MAGENTA}╚═══════════════════════════════════════════════════════════════════════╝${C_RESET}"
            echo ""
            echo -e "  ${C_RED}Le domaine ne pointe pas vers cette adresse VPS !${C_RESET}"
            echo -e "  ${C_WHITE}Résolution du domaine :${C_RESET} ${C_GOLD}${domain_ip:-Introuvable}${C_RESET}"
            echo -e "  ${C_WHITE}Adresse IP publique   :${C_RESET} ${C_GREEN}$MYIP${C_RESET}"
            echo ""
            echo -e "  ${C_GRAY}Corrigez vos enregistrements DNS (A Record) puis réessayez.${C_RESET}"
            echo -e "${C_CYAN}──────────────────────────────────────────────────────────────────────${C_RESET}"
            echo ""
            read -n 1 -s -r -p "  Appuyez sur une touche pour réessayer..."
            echo ""
        fi
    done

    echo "$host" > /root/domain
    echo "$host" > /etc/xray/domain

    clear
    echo -e "${C_MAGENTA}╔═══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GREEN}⚡ DOMAINE CONFIGURÉ AVEC SUCCÈS${C_RESET}                                ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    echo -e "  ${C_WHITE}Domaine actif :${C_RESET} ${C_CYAN}${host}${C_RESET}"
    echo -e "  ${C_GRAY}AutoScript Xray par 🜲 THE_S Team${C_RESET}"
    echo ""
    sleep 2
}

update_system() {
    echo -e "  ${C_CYAN}[INFO] Mise à jour du système...${C_RESET}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get upgrade -y
    apt-get remove --purge -y ufw firewalld exim4 apache2* >/dev/null 2>&1 || true
    apt-get autoremove -y
}

install_packages() {
    echo -e "  ${C_CYAN}[INFO] Installation des dépendances...${C_RESET}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y \
        screen curl jq bzip2 gzip vnstat coreutils rsyslog iftop zip unzip git \
        apt-transport-https build-essential wget figlet ruby-full python3 make cmake \
        net-tools nano sed gnupg bc shc libxml-parser-perl neofetch lsof \
        libsqlite3-dev libz-dev gcc g++ libreadline-dev zlib1g-dev libssl-dev \
        dropbear fail2ban nginx certbot iptables-persistent

    if command -v gem >/dev/null 2>&1; then
        gem install lolcat >/dev/null 2>&1 || true
    fi

    if ! command -v nginx >/dev/null 2>&1; then
        echo -e "  ${C_RED}[ERREUR] Échec de l'installation de Nginx.${C_RESET}"
        exit 1
    fi
}

install_nodejs() {
    local node_major=0

    if command -v node >/dev/null 2>&1; then
        node_major=$(node -p "process.versions.node.split('.')[0]" 2>/dev/null || echo 0)
        if [ "$node_major" -ge 18 ]; then
            echo -e "  ${C_GREEN}[OK] Node.js $(node --version) déjà installé.${C_RESET}"
            return 0
        fi
    fi

    echo -e "  ${C_CYAN}[INFO] Installation de Node.js 20.x...${C_RESET}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs

    echo -e "  ${C_GREEN}[OK] Node.js $(node --version) installé.${C_RESET}"
}

install_nexus_web() {
    echo -e "  ${C_CYAN}[INFO] Installation du panel Nexus Tunnel Web...${C_RESET}"

    local work_dir="/tmp/nexus-build"
    rm -rf "$work_dir"
    mkdir -p "$work_dir"

    if ! git clone --depth 1 "https://github.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44.git" "$work_dir/repo" >/dev/null 2>&1; then
        echo -e "  ${C_RED}[ERREUR] Impossible de cloner le dépôt du panel web.${C_RESET}"
        rm -rf "$work_dir"
        exit 1
    fi

    if [ -f "$work_dir/repo/nexus-web/install.sh" ]; then
        cd "$work_dir/repo/nexus-web"
        bash install.sh
        cd /root
        rm -rf "$work_dir"
        echo -e "  ${C_GREEN}[OK] Panel Nexus Tunnel Web installé.${C_RESET}"
    else
        echo -e "  ${C_RED}[ERREUR] Script d'installation du panel introuvable dans le dépôt.${C_RESET}"
        rm -rf "$work_dir"
        exit 1
    fi
}

run_scripts() {
    local scripts=("sshws.sh" "xray.sh" "vpn.sh" "websocket.sh" "setup_zivpn.sh" "setup_dns.sh" "setup_udp.sh" "validator.sh")
    for script in "${scripts[@]}"; do
        local url="${SERVER_HOST}/core/${script}"
        echo -e "  ${C_CYAN}[INFO] Téléchargement de $script...${C_RESET}"
        if ! wget -q "$url" -O "/tmp/$script"; then
            echo -e "  ${C_RED}[ERREUR] Impossible de télécharger $script depuis $url${C_RESET}"
            exit 1
        fi
        chmod +x "/tmp/$script"
        echo -e "  ${C_GREEN}[INFO] Exécution de $script...${C_RESET}"
        if ! "/tmp/$script"; then
            echo -e "  ${C_RED}[ERREUR] Échec lors de l'exécution de $script${C_RESET}"
            rm -f "/tmp/$script"
            exit 1
        fi
        rm -f "/tmp/$script"
    done
}

install_menu() {
    echo -e "  ${C_CYAN}[INFO] Téléchargement des commandes du menu...${C_RESET}"
    local menus=("dns" "zivpn" "expiry" "domain" "iptools" "menu" "socks" "ssh" "status" "trojan" "vless" "vmess" "netguard" "port" "log" "tgbot" "uninstall" "update" "web" "fastdns")
    for script in "${menus[@]}"; do
        if ! wget -q -O "/usr/local/sbin/$script" "${SERVER_HOST}/menu/${script}.sh"; then
            echo -e "  ${C_RED}[ERREUR] Téléchargement du menu $script impossible.${C_RESET}"
            exit 1
        fi
        chmod +x "/usr/local/sbin/$script"
    done
}

setup_ssh_banner() {
    echo -e "  ${C_CYAN}[INFO] Configuration de la bannière SSH...${C_RESET}"
    if wget -q -O /etc/ssh/setup_ssh_banner.sh "${SERVER_HOST}/core/setup_ssh_banner.sh"; then
        chmod +x /etc/ssh/setup_ssh_banner.sh
        bash /etc/ssh/setup_ssh_banner.sh || true
    fi
}

setup_cron_jobs() {
    grep -q "shutdown -r now" /etc/crontab || echo "0 0 * * * root /sbin/shutdown -r now" >> /etc/crontab
    grep -q "/usr/local/sbin/log" /etc/crontab || echo "*/30 * * * * root /usr/local/sbin/log" >> /etc/crontab
    grep -q "/usr/local/sbin/expiry" /etc/crontab || echo "55 23 * * * root /usr/local/sbin/expiry" >> /etc/crontab
}

setup_profile() {
    cat > /root/.profile <<'EOF'
if [ -n "$BASH_VERSION" ]; then
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi
clear
if [ -x /usr/local/sbin/menu ]; then
    /usr/local/sbin/menu
fi
EOF
}

enable_bbr() {
    echo -e "  ${C_CYAN}[INFO] Activation de TCP BBR...${C_RESET}"
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1 || true
    grep -q "net.core.default_qdisc" /etc/sysctl.conf || echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    grep -q "net.ipv4.tcp_congestion_control" /etc/sysctl.conf || echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1 || true
}

restart_services() {
    echo -e "  ${C_CYAN}[*] Redémarrage des services...${C_RESET}"
    local SERVICES=(ssh dropbear cron nginx fail2ban xray zivpn dnstt udp-custom)
    for svc in "${SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^$svc.service"; then
            systemctl enable "$svc" >/dev/null 2>&1 || true
            systemctl restart "$svc" >/dev/null 2>&1 || true
        fi
    done
}

doty_completed() {
    clear
    local domain
    domain=$(cat /etc/xray/domain 2>/dev/null || echo "N/A")

    echo -e "${C_MAGENTA}╔═══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GREEN}⚡ INSTALLATION TERMINÉE DE THE_S TUNNEL PRO${C_RESET}                  ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╠═══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}%-15s${C_RESET} : ${C_CYAN}%-45s${C_RESET} ${C_MAGENTA}║${C_RESET}\n" "Domaine Actif" "$domain"
    printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}%-15s${C_RESET} : ${C_GREEN}%-45s${C_RESET} ${C_MAGENTA}║${C_RESET}\n" "IP Serveur VPS" "$MYIP"
    echo -e "${C_MAGENTA}╠═══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_GOLD}Félicitations ! Votre serveur est prêt pour la production.${C_RESET}   ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_GRAY}AutoScript Xray par 🜲 THE_S Team${C_RESET}                                ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

main() {
    check_root_virt
    check_os
    show_tns
    setup_host_time
    prepare_env
    update_system
    install_packages
    install_nodejs
    run_scripts
    install_menu
    setup_ssh_banner
    install_nexus_web
    setup_profile
    setup_cron_jobs
    enable_bbr
    restart_services
    doty_completed

    if [ "${AUTO_REBOOT:-no}" = "yes" ]; then
        echo -e "  ${C_GOLD}Redémarrage automatique dans 10 secondes...${C_RESET}"
        sleep 10
        reboot
    fi
}

main
