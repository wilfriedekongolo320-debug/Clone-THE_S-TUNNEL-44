#!/bin/bash
set -euo pipefail
clear

export LN='\033[34m'
export BG='\033[44m'
export NC='\033[0m'
export GR='\033[32m'
export RD='\033[31m'
export YL='\033[33m'

export MYIP=$(
    wget -qO- ipv4.icanhazip.com 2>/dev/null ||
    ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' ||
    echo "127.0.0.1"
)

readonly GITHUB_USER="wilfriedekongolo320-debug"
readonly GITHUB_REPO="Clone-THE_S-TUNNEL-44"
readonly GITHUB_BRANCH="main"
readonly SERVER_HOST="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"
readonly TIMEZONE="Africa/Douala"
readonly LOG_FILE="/var/log/nexus_install.log"

mkdir -p "$(dirname "$LOG_FILE")"
echo "=== Installation Nexus Tunnel - $(date) ===" >> "$LOG_FILE"

log_info() { echo -e "${LN}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RD}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GR}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "${YL}[WARN]${NC} $1" | tee -a "$LOG_FILE"; }

check_os() {
    log_info "Vérification du système..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            log_success "OS supporté: $ID"
            return 0
        else
            log_error "OS non supporté: $ID"
            exit 1
        fi
    else
        log_error "OS non détecté"
        exit 1
    fi
}

check_root_virt() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi

    if [ "$(systemd-detect-virt 2>/dev/null)" = "openvz" ]; then
        log_error "OpenVZ n'est pas supporté"
        exit 1
    fi
}

setup_host_time() {
    local localip hst
    localip=$(hostname -I | awk '{print $1}')
    hst=$(hostname)

    if ! grep -q "$hst" /etc/hosts 2>/dev/null; then
        echo "$localip $hst" >> /etc/hosts
    fi

    ln -fs "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime 2>/dev/null || true
    sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1 || true
    sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1 || true
}

prepare_env() {
    mkdir -p /etc/xray /etc/slowdns
    touch /etc/xray/domain
}

show_tns() {
    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}            TERMS & CONDITIONS PANEL            ${NC} ${LN}┃${NC}"
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
    read -rp " Sélectionnez une option [1-2] : " opt

    case "$opt" in
        1|01)
            add_domain
            ;;
        2|02)
            log_warn "Installation refusée par l'utilisateur"
            exit 0
            ;;
        *)
            log_warn "Option invalide, utilisation de l'IP par défaut"
            echo "$MYIP" > /root/domain
            echo "$MYIP" > /etc/xray/domain
            ;;
    esac
}

add_domain() {
    while true; do
        read -rp " Entrez votre domaine (laisser vide pour utiliser l'IP : $MYIP) : " host
        if [[ -z "$host" ]]; then
            host="$MYIP"
            break
        fi

        domain_ip=$(getent ahosts "$host" 2>/dev/null | awk '{print $1; exit}')
        if [[ "$domain_ip" == "$MYIP" ]]; then
            break
        else
            echo -e "${RD}Le domaine $host pointe sur $domain_ip (IP VPS: $MYIP)${NC}"
            read -rp " Voulez-vous continuer quand même ? (y/n) : " force_dom
            if [[ "$force_dom" == "y" || "$force_dom" == "Y" ]]; then
                break
            fi
        fi
    done

    echo "$host" > /root/domain
    echo "$host" > /etc/xray/domain
    log_success "Domaine configuré: $host"
}

update_system() {
    log_info "Mise à jour du système..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y >> "$LOG_FILE" 2>&1 || return 1
    apt-get upgrade -y >> "$LOG_FILE" 2>&1 || log_warn "Upgrade non bloquant"
}

install_packages() {
    log_info "Installation des paquets..."
    local packages="
        screen curl jq bzip2 gzip vnstat coreutils rsyslog iftop zip unzip git
        apt-transport-https build-essential wget figlet python3 make cmake
        net-tools nano sed gnupg bc libxml-parser-perl lsof dropbear fail2ban
        nginx certbot iptables-persistent ca-certificates
    "

    apt-get install -y $packages >> "$LOG_FILE" 2>&1 || return 1
}

run_scripts() {
    log_info "Téléchargement des scripts core..."
    local scripts=("sshws.sh" "xray.sh" "vpn.sh" "websocket.sh" "setup_zivpn.sh" "setup_udp.sh" "validator.sh")
    local failed=()

    for script in "${scripts[@]}"; do
        url="${SERVER_HOST}/core/${script}"
        tmp_file="/tmp/${script}.$$"

        log_info "Téléchargement: $script"
        if ! wget -q --timeout=30 "$url" -O "$tmp_file"; then
            log_error "Impossible de télécharger $script"
            failed+=("$script")
            continue
        fi

        if [ ! -s "$tmp_file" ]; then
            log_error "Fichier vide: $script"
            failed+=("$script")
            rm -f "$tmp_file"
            continue
        fi

        if ! bash "$tmp_file" >> "$LOG_FILE" 2>&1; then
            log_warn "Échec de l'exécution de $script"
        else
            log_success "$script exécuté"
        fi

        rm -f "$tmp_file"
    done

    if [ ${#failed[@]} -gt 0 ]; then
        log_warn "Scripts échoués: ${failed[*]}"
    fi
}

install_menu() {
    log_info "Installation des commandes du menu..."
    local scripts=("dns" "zivpn" "expiry" "domain" "iptools" "menu" "socks" "ssh" "status" "trojan" "vless" "vmess" "netguard" "port" "log" "tgbot" "uninstall" "update" "web" "fastdns")

    for script in "${scripts[@]}"; do
        dest="/usr/local/sbin/$script"
        if wget -q --timeout=30 "${SERVER_HOST}/menu/${script}.sh" -O "$dest"; then
            chmod +x "$dest" || true
            log_success "Menu installé: $script"
        else
            log_warn "Menu non téléchargé: $script"
        fi
    done
}

install_nexus_web() {
    log_info "Installation du Nexus Web Panel..."
    local work="/tmp/nexus-build-$$"
    rm -rf "$work"
    mkdir -p "$work"

    if git clone --depth 1 --quiet "https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git" "$work/repo" >> "$LOG_FILE" 2>&1; then
        if [ -f "$work/repo/nexus-web/install.sh" ]; then
            cd "$work/repo/nexus-web"
            bash install.sh >> "$LOG_FILE" 2>&1 || log_warn "Install.sh du web panel a échoué"
            cd /root
        fi
    else
        log_warn "Clon du dépôt pour Nexus Web impossible"
    fi

    rm -rf "$work"
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

setup_autoreboot() {
    if ! grep -q "shutdown -r now" /etc/crontab 2>/dev/null; then
        echo "0 0 * * * root /sbin/shutdown -r now" >> /etc/crontab
    fi
}

setup_autolog() {
    if ! grep -q "/usr/local/sbin/log" /etc/crontab 2>/dev/null; then
        echo "*/30 * * * * root /usr/local/sbin/log" >> /etc/crontab
    fi
}

setup_autoexp() {
    local cronjob="55 23 * * * root /usr/local/sbin/expiry"
    if ! grep -q "/usr/local/sbin/expiry" /etc/crontab 2>/dev/null; then
        echo "$cronjob" >> /etc/crontab
    fi
}

restart_services() {
    local services=(ssh dropbear cron nginx vnstat fail2ban xray zivpn dnstt)
    for svc in "${services[@]}"; do
        if systemctl list-unit-files 2>/dev/null | grep -q "^${svc}.service"; then
            systemctl enable "$svc" --now >> "$LOG_FILE" 2>&1 || true
            systemctl restart "$svc" >> "$LOG_FILE" 2>&1 || true
        fi
    done
}

set_version() {
    if wget -q --timeout=30 "$SERVER_HOST/version" -O /etc/version; then
        :
    else
        echo "1.0.0" > /etc/version
    fi
}

enable_bbr() {
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1 || true
}

verify_installation() {
    local errors=0

    for svc in ssh nginx xray; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo "[OK] $svc running"
        else
            echo "[ERROR] $svc not running"
            errors=$((errors + 1))
        fi
    done

    for port in 22 80 443 1194 5667; do
        if ss -lnt | awk '{print $4}' | grep -q ":$port$"; then
            echo "[OK] port $port listening"
        else
            echo "[ERROR] port $port missing"
            errors=$((errors + 1))
        fi
    done

    if [ -f /etc/xray/xray.crt ] && [ -f /etc/xray/xray.key ]; then
        echo "[OK] SSL certs present"
    else
        echo "[ERROR] SSL certs missing"
        errors=$((errors + 1))
    fi

    if [ "$errors" -gt 0 ]; then
        echo "[FATAL] Installation has errors"
        return 1
    fi

    echo "[OK] Installation validation passed"
    return 0
}

main() {
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

    verify_installation || exit 1

    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}              INSTALLATION TERMINÉE              ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${GR}Félicitations ! THE_S TUNNEL PRO est prêt.${NC}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} 🌐 Domaine : $(cat /etc/xray/domain 2>/dev/null || echo "$MYIP")"
    echo -e "${LN}┃${NC} 🖥️  VPS IP  : $MYIP"
    echo -e "${LN}┃${NC} 📦 Dépôt   : github.com/${GITHUB_USER}/${GITHUB_REPO}"
    echo -e "${LN}┃${NC} 📝 Log    : $LOG_FILE"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo
    echo -e "${GR}Installation achevée. Tapez 'menu' pour accéder au panneau.${NC}"
    exit 0
}

main "$@"
