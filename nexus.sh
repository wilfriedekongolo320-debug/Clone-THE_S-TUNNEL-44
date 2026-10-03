#!/bin/bash
# ============================================================
#  THE_S TUNNEL PRO - MAIN INSTALLER (Fix Redirects & Paths)
# ============================================================

set -e

# --- VÉRIFICATION ROOT ---
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "❌ ERREUR: Ce script doit être exécuté en tant que ROOT."
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

SERVER_HOST="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main"
TIMEZONE="Asia/Kuala_Lumpur"

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
            echo -e " ${C_RED}✖ OS non supporté : ${ID}.${C_RESET}"
            exit 1
        fi
    fi
}

check_root_virt() {
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        if [ "$(systemd-detect-virt)" = "openvz" ]; then
            echo -e " ${C_GOLD}[!] OpenVZ détecté.${C_RESET}"
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

update_system() {
    echo -e " ${C_CYAN}[INFO] Mise à jour du système...${C_RESET}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get upgrade -y
    apt-get remove --purge -y ufw firewalld exim4 apache2* >/dev/null 2>&1 || true
    apt-get autoremove -y
}

install_packages() {
    echo -e " ${C_CYAN}[INFO] Installation des paquets requis...${C_RESET}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y \
        screen curl jq bzip2 gzip vnstat coreutils rsyslog iftop zip unzip git \
        apt-transport-https build-essential wget figlet ruby-full python3 make cmake \
        net-tools nano sed gnupg bc shc libxml-parser-perl neofetch lsof \
        libsqlite3-dev libz-dev gcc g++ libreadline-dev zlib1g-dev libssl-dev \
        dropbear fail2ban nginx certbot iptables-persistent openvpn

    if command -v gem >/dev/null 2>&1; then
        gem install lolcat >/dev/null 2>&1 || true
    fi
}

install_nodejs() {
    echo -e " ${C_CYAN}[INFO] Installation Node.js 20.x...${C_RESET}"
    if ! command -v node >/dev/null 2>&1; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
    fi
}

run_scripts() {
    echo -e " ${C_CYAN}[INFO] Exécution des sous-modules du noyau...${C_RESET}"
    local scripts=("sshws.sh" "xray.sh" "vpn.sh" "websocket.sh" "setup_zivpn.sh" "setup_dns.sh" "setup_udp.sh" "validator.sh")
    
    cd /root
    for script in "${scripts[@]}"; do
        echo -e "  ► Exécution de : ${C_GREEN}$script${C_RESET}"
        wget -q "${SERVER_HOST}/core/${script}" -O "/root/$script"
        chmod +x "/root/$script"
        
        # On exécute en ignorant les erreurs de chaînage interne des sous-scripts
        bash "/root/$script" || true
        rm -f "/root/$script"
    done
}

install_menu() {
    echo -e " ${C_CYAN}[INFO] Installation des scripts de menu...${C_RESET}"
    local menus=("dns" "zivpn" "expiry" "domain" "iptools" "menu" "socks" "ssh" "status" "trojan" "vless" "vmess" "netguard" "port" "log" "tgbot" "uninstall" "update" "web" "fastdns")
    for script in "${menus[@]}"; do
        wget -q -O "/usr/local/sbin/$script" "${SERVER_HOST}/menu/${script}.sh" || true
        chmod +x "/usr/local/sbin/$script" || true
    done
}

show_tns() {
    clear
    echo -e "${C_MAGENTA}╔═══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CONDITIONS D'UTILISATION - THE_S TUNNEL PRO${C_RESET}               ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    echo -e "  ${C_GREEN}[01] • Accepter et Configurer le Domaine${C_RESET}"
    echo -e "  ${C_RED}[02] • Poursuivre sans domaine${C_RESET}"
    echo ""
    read -rp "  🜲 Sélectionnez une option [01-02] : " opt
    echo ""

    case $opt in
        1 | 01)
            add_domain
            ;;
        *)
            echo -e "  ${C_GOLD}Passage de la configuration domaine...${C_RESET}"
            ;;
    esac
}

add_domain() {
    clear
    echo -e "${C_MAGENTA}╔═══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CONFIGURATION DU DOMAINE${C_RESET}                                      ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""

    read -rp "  ► Votre nom de domaine : " host
    if [[ -n "$host" ]]; then
        echo "$host" > /root/domain
        echo "$host" > /etc/xray/domain
        echo -e "  ${C_GREEN}✓ Domaine enregistré : $host${C_RESET}"
    fi
}

install_nexus_web() {
    echo -e " ${C_CYAN}[INFO] Installation du Panel Web Nexus...${C_RESET}"
    local work_dir="/tmp/nexus-build"
    rm -rf "$work_dir"
    mkdir -p "$work_dir"

    if git clone --depth 1 "https://github.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44.git" "$work_dir/repo" >/dev/null 2>&1; then
        if [ -f "$work_dir/repo/nexus-web/install.sh" ]; then
            cd "$work_dir/repo/nexus-web"
            bash install.sh || true
            cd /root
        fi
    fi
    rm -rf "$work_dir"
}

setup_ssh_banner() {
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
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1 || true
}

restart_services() {
    echo -e " ${C_CYAN}[INFO] Redémarrage des services...${C_RESET}"
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
    echo -e "${C_MAGENTA}║${C_RESET} ${C_GOLD}Tapez 'menu' pour afficher le panneau de gestion.${C_RESET}             ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

main() {
    check_root_virt
    check_os
    setup_host_time
    prepare_env
    update_system
    install_packages
    install_nodejs
    run_scripts
    install_menu
    show_tns
    setup_ssh_banner
    install_nexus_web
    setup_profile
    setup_cron_jobs
    enable_bbr
    restart_services
    doty_completed
}

main
