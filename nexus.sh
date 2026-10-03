#!/bin/bash
clear
export LN='\033[34m'
export BG='\033[44m'
export NC='\033[0m'
export GR='\033[32m'
export RD='\033[31m'
export MYIP=$(wget -qO- ipv4.icanhazip.com || ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo "127.0.0.1")

# --- CONFIGURATION DU DÉPÔT CENTRAL ---
readonly GITHUB_USER="wilfriedekongolo320-debug"
readonly GITHUB_REPO="Clone-THE_S-TUNNEL-44"
readonly GITHUB_BRANCH="main"
readonly SERVER_HOST="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"
readonly TIMEZONE="Africa/Douala"

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" \vert{}\vert{} "$ID" == "debian" ]]; then
            return 0  
        else
            echo -e "${RD}Système non supporté: $ID. Arrêt.${NC}"
            exit 1
        fi
    else
        echo -e "${RD}Impossible de détecter l'OS. Arrêt.${NC}"
        exit 1
    fi
}

check_root_virt() {
    [ "$EUID" -ne 0 ] && { echo -e "${RD}Exécutez en tant que root${NC}"; exit 1; }
    [ "$(systemd-detect-virt 2>/dev/null)" = "openvz" ] && { echo -e "${RD}OpenVZ n'est pas supporté${NC}"; exit 1; }
}

setup_host_time() {
    local localip hst host_entry
    localip=$(hostname -I | awk '{print $1}')
    hst=$(hostname)
    host_entry=$(awk '{print $2}' /etc/hosts \vert{} grep -w "$hst" || true)
    [ "$hst" != "$host_entry" ] && echo "$localip$hst" >> /etc/hosts
    ln -fs "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime 2>/dev/null || true
    sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1 || true
    sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1 || true
}

prepare_env() {
    mkdir -p /etc/xray /etc/slowdns
    touch /etc/xray/domain
}

function show_tns() {
    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}            TERMS & CONDITIONS PANEL${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${GR}Bienvenue sur THE_S TUNNEL PRO / NEXUS SERVICES !${NC}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} [*] Veuillez lire attentivement les termes."
    echo -e "${LN}┃${NC} [*] THE_S TUNNEL est fourni tel quel sans garantie."
    echo -e "${LN}┃${NC} [*] N'utilisez pas ce service pour des activités illégales."
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo -e "${LN}┃${NC} [01] • Accepter les termes"
    echo -e "${LN}┃${NC} [02] • Refuser & Quitter"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo
    read -rp "  Sélectionnez une option [1-2] : " opt
    echo ""
    case $opt in
    1 | 01)
        echo -e " ${GR}Vous avez accepté les Conditions d'Utilisation.${NC}"
        echo -e " ${GR}Chargement...${NC}"
        sleep 2
        add_domain
        ;;
    2 | 02)
        echo -e " ${RD}Vous avez refusé les termes. Annulation...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RD} [ERREUR] Option invalide ! Utilisation de l'IP directe par défaut.${NC}"
        echo "$MYIP" > /root/domain
        echo "$MYIP" > /etc/xray/domain
        sleep 2
        ;;
    esac
}

function add_domain() {
    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}                 DOMAIN PANEL${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo
    while true; do
        read -rp " Entrez votre Domaine (Laissez vide pour utiliser l'IP : $MYIP) : " host
        if [[ -z "$host" ]]; then
            host="$MYIP"
            break
        fi
        
        domain_ip=$(getent ahosts "$host" | awk '{print $1; exit}')
        if [[ "$domain_ip" == "$MYIP" ]]; then
            break
        else
            echo -e "${RD} ✘ Le domaine $host pointe sur$domain_ip (IP VPS: $MYIP)${NC}"
            read -rp " Voulez-vous continuer quand même avec $host ? (y/n) : " force_dom
            if [[ "$force_dom" == "y" \vert{}\vert{} "$force_dom" == "Y" ]]; then
                break
            fi
        fi
    done

    echo "$host" > /root/domain
    echo "$host" > /etc/xray/domain
    
    echo -e "${GR} Domaine configuré avec succès : $host${NC}"
    sleep 2
}

update_system() {
    echo -e "${LN}[INFO] Mise à jour du système...${NC}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get upgrade -y
}

install_packages() {
    echo -e "${LN}[INFO] Installation des paquets nécessaires...${NC}"
    apt-get install -y \
    screen curl jq bzip2 gzip vnstat coreutils rsyslog iftop zip unzip git \
    apt-transport-https build-essential wget figlet python3 make cmake \
    net-tools nano sed gnupg bc libxml-parser-perl lsof \
    dropbear fail2ban nginx certbot iptables-persistent
}

run_scripts() {
    scripts=("sshws.sh" "xray.sh" "vpn.sh" "websocket.sh" "setup_zivpn.sh" "setup_udp.sh" "validator.sh")
    for script in "${scripts[@]}"; do
        url="${SERVER_HOST}/core/${script}"
        echo -e "${LN}[INFO] Téléchargement et exécution de $script...${NC}"
        if wget -q "$url" -O "/root/$script"; then
            chmod +x "/root/$script"
            bash "/root/$script" || true
            rm -f "/root/$script"
        else
            echo -e "${RD}[WARN] Impossible de récupérer $script depuis $url${NC}"
        fi
    done
}

install_menu() {
    echo -e "${LN}[INFO] Installation des commandes du menu...${NC}"
    for script in dns zivpn expiry domain iptools menu socks ssh status trojan vless vmess netguard port log tgbot uninstall update web fastdns; do
        wget -q -O "/usr/local/sbin/$script" "${SERVER_HOST}/menu/${script}.sh" || true
        chmod +x "/usr/local/sbin/$script" || true
    done
}

install_nexus_web() {
    echo -e "${LN}[INFO] Vérification et installation du Web Panel Nexus...${NC}"
    WORK_DIR="/tmp/nexus-build"
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"

    if git clone --depth 1 "https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git" "$WORK_DIR/repo" >/dev/null 2>&1; then
        if [ -f "$WORK_DIR/repo/nexus-web/install.sh" ]; then
            cd "$WORK_DIR/repo/nexus-web"
            bash install.sh || true
            cd /root
        fi
    fi
    rm -rf "$WORK_DIR"
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

cleanner() {
    rm -f /root/*.sh 2>/dev/null
    rm -f /root/*.pem 2>/dev/null
}

restart_services() {
    echo -e "${LN}[*] Activation et redémarrage des services...${NC}"
    SERVICES=(
        ssh
        dropbear
        cron
        nginx
        vnstat
        fail2ban
        xray
        zivpn
        dnstt
    )
    for svc in "${SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^$svc.service"; then
            systemctl enable "$svc" --now || true
            systemctl restart "$svc" || true
        fi
    done
}

doty_completed() {
    clear
    domain=$(cat /etc/xray/domain 2>/dev/null \vert{}\vert{} echo "$MYIP")
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC}${BG}              INSTALLATION TERMINÉE              ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC}${GR}Félicitations ! THE_S TUNNEL PRO est prêt.${NC}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} Domaine :${domain}"
    echo -e "${LN}┃${NC} VPS IP  :${MYIP}"
    echo -e "${LN}┃${NC} Dépôt   : github.com/${GITHUB_USER}/${GITHUB_REPO}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo
}

set_version() {
    wget -q "$SERVER_HOST/version" -O /etc/version || echo "1.0.0" > /etc/version
}

enable_bbr() {
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1 || true
}

main() {
    # Intercept TTY pour éviter le crash du `read`
    exec < /dev/tty 2>/dev/null || true

    check_root_virt
    check_os
    setup_host_time
    prepare_env
    update_system
    install_packages
    show_tns
    run_scripts
    install_menu
    install_nexus_web
    setup_profile
    setup_autoreboot
    setup_autolog
    setup_autoexp
    enable_bbr
    restart_services
    set_version
    doty_completed
    cleanner
    
    echo -e "${GR}Installation achevée. Tapez 'menu' pour accéder au panneau.${NC}"
}

main
