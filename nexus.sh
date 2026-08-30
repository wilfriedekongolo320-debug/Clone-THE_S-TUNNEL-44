#!/bin/bash
# ============================================================
#  THE_S TUNNEL PRO - MAIN INSTALLER (Cyberpunk Theme)
# ============================================================

# --- VÉRIFICATION ROOT ---
if [ "$EUID" -ne 0 ]; then
    echo "❌ ERREUR: Ce script doit être exécuté en tant que ROOT."
    echo "   Veuillez relancer le script parent avec sudo ou en root."
    exit 1
fi

# --- DÉSACTIVATION SSH TEMPORAIRE ---
echo "[*] Désactivation temporaire de SSH/SFTP pour l'installation..."
systemctl stop ssh 2>/dev/null
systemctl disable ssh 2>/dev/null

clear

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

export MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || echo "127.0.0.1")

# --- CONFIGURATION DÉPÔT CENTRAL ---
readonly SERVER_HOST="https://raw.githubusercontent.com/thesnet320-source/THE_S-TUNNEL-PRO-/main"
readonly TIMEZONE="Asia/Kuala_Lumpur"

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            return 0  
        else
            echo -e " ${C_RED}✖ Système d'exploitation non supporté : $ID. Abandon.${C_RESET}"
            exit 1
        fi
    else
        echo -e " ${C_RED}✖ Impossible de détecter l'OS. Abandon.${C_RESET}"
        exit 1
    fi
}

check_root_virt() {
    [ "$EUID" -ne 0 ] && { echo -e " ${C_RED}✖ Exécutez en tant que root.${C_RESET}"; exit 1; }
    [ "$(systemd-detect-virt)" = "openvz" ] && { echo -e " ${C_RED}✖ OpenVZ n'est pas supporté.${C_RESET}"; exit 1; }
}

setup_host_time() {
    local localip hst host_entry
    localip=$(hostname -I | awk '{print $1}')
    hst=$(hostname)
    host_entry=$(awk '{print $2}' /etc/hosts | grep -w "$hst" || true)
    [ "$hst" != "$host_entry" ] && echo "$localip $hst" >> /etc/hosts
    ln -fs "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
}

prepare_env() {
    mkdir -p /etc/xray
    touch /etc/xray/domain
}

function show_tns() {
    clear
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CONDITIONS D'UTILISATION - THE_S TUNNEL PRO${C_RESET}               ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    echo -e "  ${C_GOLD}Bienvenue dans les services 🜲 THE_S TUNNEL PRO !${C_RESET}"
    echo ""
    echo -e "  ${C_GRAY}[*] Veuillez lire attentivement les termes ci-dessous :${C_RESET}"
    echo -e "  ${C_GRAY}[*] Service fourni 'tel quel', sans garantie d'aucune sorte.${C_RESET}"
    echo -e "  ${C_GRAY}[*] Utilisation strictement interdite pour activités illégales.${C_RESET}"
    echo -e "  ${C_GRAY}[*] THE_S Team n'est pas responsable de la perte de données.${C_RESET}"
    echo -e "  ${C_GRAY}[*] Vous devez respecter les lois locales en vigueur.${C_RESET}"
    echo -e "  ${C_GRAY}[*] Termes modifiables sans préavis.${C_RESET}"
    echo ""
    echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
    echo -e "  ${C_GREEN}[01] • Accepter les termes${C_RESET}"
    echo -e "  ${C_RED}[02] • Décliner et Quitter${C_RESET}"
    echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
    echo ""
    read -rp "  🜲 Sélectionnez une option [01-02] : " opt
    echo ""

    case $opt in
    1 | 01)
        clear
        echo -e "  ${C_GREEN}⚡ Vous avez accepté les conditions d'utilisation.${C_RESET}"
        echo -e "  ${C_CYAN}Initialisation en cours...${C_RESET}"
        sleep 2
        add_domain
        ;;
    2 | 02)
        clear
        echo -e "  ${C_RED}✖ Vous avez refusé les conditions d'utilisation.${C_RESET}"
        echo -e "  ${C_RED}Nettoyage des scripts et fermeture...${C_RESET}"
        rm -f /root/*.sh
        sleep 3
        exit 0
        ;;
    *)
        echo -e "  ${C_RED}✖ Option invalide ! Annulation.${C_RESET}"
        rm -f /root/*.sh
        sleep 3
        exit 0
        ;;
    esac
}

function add_domain() {
    clear
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CONFIGURATION DU DOMAINE${C_RESET}                                      ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""

    while true; do
        read -rp "  ► Nom de domaine / Hostname : " host
        if [[ -z "$host" ]]; then
            echo -e "  ${C_RED}✖ Le domaine ne peut pas être vide.${C_RESET}"
            continue
        fi

        domain_ip=$(getent ahosts "$host" | awk '{print $1; exit}')
        if [[ "$domain_ip" == "$MYIP" ]]; then
            break
        else
            clear
            echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
            echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_RED}✖ ERREUR DE POINTEUR DNS${C_RESET}                                          ${C_MAGENTA}║${C_RESET}"
            echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
            echo ""
            echo -e "  ${C_RED}Le domaine ne pointe pas vers cette adresse VPS !${C_RESET}"
            echo -e "  ${C_WHITE}Résolution du domaine :${C_RESET} ${C_GOLD}$domain_ip${C_RESET}"
            echo -e "  ${C_WHITE}Adresse IP publique   :${C_RESET} ${C_GREEN}$MYIP${C_RESET}"
            echo ""
            echo -e "  ${C_GRAY}Corrigez vos enregistrements DNS (A Record) puis réessayez.${C_RESET}"
            echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
            echo ""
            read -n 1 -s -r -p "  Appuyez sur une touche pour réessayer..."
            add_domain
            return
        fi
    done

    echo "$host" > /root/domain
    echo "$host" > /etc/xray/domain

    if [[ -f /root/domain ]]; then
        domain=$(cat /root/domain)
    elif [[ -f /etc/xray/domain ]]; then
        domain=$(cat /etc/xray/domain)
    else
        echo -e "  ${C_RED}✖ Fichier de domaine introuvable !${C_RESET}"
        rm -f /root/*.sh
        exit 1
    fi

    clear
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GREEN}⚡ DOMAINE CONFIGURÉ AVEC SUCCÈS${C_RESET}                                ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    echo -e "  ${C_WHITE}Domaine actif :${C_RESET} ${C_CYAN}${domain}${C_RESET}"
    echo -e "  ${C_GRAY}AutoScript Xray par 🜲 THE_S Team${C_RESET}"
    echo ""
    sleep 3
    echo -e "  ${C_GOLD}[*] Début de l'installation du système...${C_RESET}"
    sleep 2
}

update_system() {
    echo -e "  ${C_CYAN}[INFO] Mise à jour du système...${C_RESET}"
    apt-get update -y
    apt-get upgrade -y
    apt-get dist-upgrade -y
    apt-get remove --purge -y ufw firewalld exim4 nginx* dropbear* apache2*
    apt autoremove -y
}

install_packages() {
    echo -e "  ${C_CYAN}[INFO] Installation des dépendances...${C_RESET}"
    apt-get install -y \
    screen curl jq bzip2 gzip vnstat coreutils rsyslog iftop zip unzip git \
    apt-transport-https build-essential wget figlet ruby-full python3 make cmake \
    net-tools nano sed gnupg gnupg1 bc shc libxml-parser-perl neofetch lsof \
    libsqlite3-dev libz-dev gcc g++ libreadline-dev zlib1g-dev libssl-dev \
    dropbear fail2ban nginx certbot iptables-persistent

    if command -v gem >/dev/null; then
        gem install lolcat >/dev/null 2>&1
    fi

    if ! dpkg -s nginx >/dev/null 2>&1; then
        echo -e "  ${C_RED}[ERREUR] Échec de l'installation de Nginx.${C_RESET}"
        exit 1
    fi
}

run_scripts() {
    scripts=("sshws.sh" "xray.sh" "vpn.sh" "websocket.sh" "setup_zivpn.sh" "setup_dns.sh" "setup_udp.sh" "validator.sh")
    for script in "${scripts[@]}"; do
        url="${SERVER_HOST}/core/${script}"
        echo -e "  ${C_CYAN}[INFO] Téléchargement de $script...${C_RESET}"
        if wget -q "$url" -O "$script"; then
            chmod +x "$script"
            echo -e "  ${C_GREEN}[INFO] Exécution de $script...${C_RESET}"
            ./$script
        else
            echo -e "  ${C_RED}[ERREUR] Impossible de télécharger $script depuis $url${C_RESET}"
        fi
    done
}

install_menu() {
    echo -e "  ${C_CYAN}[INFO] Téléchargement des commandes du menu...${C_RESET}"
    for script in dns zivpn expiry domain iptools menu socks ssh status trojan vless vmess netguard port log tgbot uninstall update web fastdns; do
        wget -q -O "/usr/local/sbin/$script" "${SERVER_HOST}/menu/${script}.sh"
        chmod +x "/usr/local/sbin/$script"
    done
}

setup_ssh_banner() {
    echo -e "  ${C_CYAN}[INFO] Configuration de la bannière SSH...${C_RESET}"
    wget -q -O /etc/ssh/setup_ssh_banner.sh "${SERVER_HOST}/core/setup_ssh_banner.sh"
    chmod +x /etc/ssh/setup_ssh_banner.sh
    bash /etc/ssh/setup_ssh_banner.sh
}

setup_autoreboot() {
    grep -q "shutdown -r now" /etc/crontab || \
    echo "0 0 * * * root /sbin/shutdown -r now" >> /etc/crontab
}

setup_autolog() {
    grep -q "/usr/local/sbin/log" /etc/crontab || \
    echo "*/30 * * * * root /usr/local/sbin/log" >> /etc/crontab
}

setup_autoexp() {
    local cronjob="55 23 * * * root /usr/local/sbin/expiry"
    grep -q "/usr/local/sbin/expiry" /etc/crontab || echo "$cronjob" >> /etc/crontab
}

setup_profile() {
    cat > /root/.profile <<'EOF'
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
clear
menu
EOF
    echo -e "  ${C_GREEN}[*] Profil utilisateur configuré.${C_RESET}"
}

cleanner() {
    rm -f /root/*.sh 2>/dev/null
    rm -f /root/*.pem 2>/dev/null
}

restart_services() {
    echo -e "  ${C_CYAN}[*] Activation et redémarrage de tous les services...${C_RESET}"
    SERVICES=(
        ssh
        dropbear
        stunnel5
        cron
        nginx
        vnstat
        fail2ban
        ws-dropbear
        ws-stunnel
        xray
        runn
        squid
        openvpn
        ohp
        zivpn
        dnstt
        udp-custom
    )
    for svc in "${SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^$svc.service"; then
            echo -e "  ${C_GRAY}► Redémarrage de $svc...${C_RESET}"
            systemctl enable "$svc" --now >/dev/null 2>&1 || true
            systemctl restart "$svc" >/dev/null 2>&1 || true
        fi
    done

    for port in 7100 7200 7300; do
        svc="badvpn@$port"
        if systemctl list-unit-files | grep -q "^$svc.service"; then
            echo -e "  ${C_GRAY}► Redémarrage de $svc...${C_RESET}"
            systemctl enable "$svc" --now >/dev/null 2>&1 || true
            systemctl restart "$svc" >/dev/null 2>&1 || true
        fi
    done
    echo -e "  ${C_GREEN}[OK] Tous les services ont été démarrés avec succès.${C_RESET}"
}

doty_completed() {
    clear
    domain=$(cat /etc/xray/domain 2>/dev/null || echo "N/A")
    MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || echo "127.0.0.1")

    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GREEN}⚡ INSTALLATION TERMINÉE DE THE_S TUNNEL PRO${C_RESET}                  ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
    printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}%-15s${C_RESET} : ${C_CYAN}%-45s${C_RESET} ${C_MAGENTA}║${C_RESET}\n" "Domaine Active" "$domain"
    printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}%-15s${C_RESET} : ${C_GREEN}%-45s${C_RESET} ${C_MAGENTA}║${C_RESET}\n" "IP Serveur VPS" "$MYIP"
    echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_GOLD}Félicitations ! Votre serveur est prêt pour la production.${C_RESET}   ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_GRAY}AutoScript Xray par 🜲 THE_S Team${C_RESET}                                ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

set_version() {
    wget -q "$SERVER_HOST/version" -O /etc/version
    wget -q "$SERVER_HOST/port_info" -O /etc/xray/port_info
}

enable_bbr() {
    echo -e "  ${C_CYAN}[INFO] Activation de TCP BBR...${C_RESET}"
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    grep -q "net.core.default_qdisc" /etc/sysctl.conf || echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    grep -q "net.ipv4.tcp_congestion_control" /etc/sysctl.conf || echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
}

main() {
    check_root_virt
    check_os
    setup_host_time
    prepare_env
    update_system
    install_packages
    show_tns
    run_scripts
    install_menu
    setup_ssh_banner
    setup_profile
    setup_autoreboot
    setup_autolog
    setup_autoexp
    enable_bbr
    restart_services
    set_version
    doty_completed
    cleanner

    echo -e "  ${C_GOLD}L'installation est terminée. Redémarrage dans 10 secondes...${C_RESET}"
    sleep 10
    reboot
}

main
