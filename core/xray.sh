#!/bin/bash
set -e

export SERVER_HOST="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main"
export DEBIAN_FRONTEND=noninteractive

log() { printf "%b\n" "[INFO] $*"; }
err() { printf "%b\n" "[ERROR] $*" >&2; exit 1; }

apt_install() {
    packages=("$@")
    if [ ! -f /var/lib/apt/periodic/update-success-stamp ]; then
        apt-get update -y
    fi
    apt-get install -y "${packages[@]}"
}

setup_environment() {
    log "Gathering environment info"
    mkdir -p /etc/xray
    apt_install iptables iptables-persistent curl wget ca-certificates
}

setup_time() {
    log "Setting system time"
    if [ -f /etc/timezone ]; then
        tz=$(cat /etc/timezone)
    else
        tz="UTC"
    fi
    timedatectl set-timezone "$tz" 2>/dev/null || ln -snf "/usr/share/zoneinfo/$tz" /etc/localtime
}

install_dependencies() {
    log "Installing dependencies"
    apt-get update -y
    apt_install curl socat xz-utils wget apt-transport-https gnupg dnsutils lsb-release unzip pwgen openssl netcat-openbsd cron bash-completion zip
}

install_xray() {
    log "Preparing directories for Xray..."
    mkdir -p /var/log/xray /etc/xray /run/xray
    chmod 755 /var/log/xray
    for f in access.log error.log access2.log error2.log; do
        [ -f "/var/log/xray/$f" ] || touch "/var/log/xray/$f"
    done

    log "Installing official Xray core..."
    bash -c "$(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" -- install -u www-data

    log "Replacing official Xray with MOD v25.3.31..."
    tmpzip="/tmp/Xray_core_mod.zip"
    curl -sL -f "https://github.com/dotywrt/Xray-core-mod/releases/download/v25.3.31/Xray-linux-64-v25.3.31.zip" -o "$tmpzip"
    unzip -oq "$tmpzip" -d /tmp || err "Failed to unzip MOD release."
    mv -f /tmp/xray /usr/local/bin/xray
    chmod +x /usr/local/bin/xray
    rm -f "$tmpzip"
    [ -x /usr/local/bin/xray ] || err "Xray binary not installed."
}

install_ssl() {
    if [[ -f /root/domain ]]; then
        domain=$(cat /root/domain)
    elif [[ -f /etc/xray/domain ]]; then
        domain=$(cat /etc/xray/domain)
    else
        err "Domain file not found!"
    fi

    log "Stopping nginx for standalone cert issuance"
    systemctl stop nginx 2>/dev/null || true
    systemctl stop xray 2>/dev/null || true

    mkdir -p /root/.acme.sh
    curl -fsSL https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh
    /root/.acme.sh/acme.sh --upgrade --auto-upgrade
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    /root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256
    /root/.acme.sh/acme.sh --installcert -d "$domain" --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc

    wget -q -O /usr/local/bin/ssl_renew.sh "${SERVER_HOST}/module/ssl_renew.sh"
    chmod +x /usr/local/bin/ssl_renew.sh
    echo "15 03 */3 * * /usr/local/bin/ssl_renew.sh" | crontab -
}

configure_xray() {
    log "Fetching Xray configuration and systemd units..."
    mkdir -p /home/vps/public_html
    wget -q -O /etc/xray/config.json "${SERVER_HOST}/module/config.json"
    chmod 644 /etc/xray/config.json
    chown root:root /etc/xray/config.json

    wget -q -O /etc/systemd/system/xray.service "${SERVER_HOST}/module/xray.service"
    wget -q -O /etc/systemd/system/runn.service "${SERVER_HOST}/module/runn.service"
    systemctl daemon-reload
    rm -rf /etc/systemd/system/xray.service.d /etc/systemd/system/xray@.service
}

configure_nginx() {
    log "Downloading nginx xray conf"
    apt_install nginx
    domain=$(cat /root/domain 2>/dev/null || cat /etc/xray/domain 2>/dev/null || err "Domain file not found!")
    wget -q -O /etc/nginx/nginx.conf "${SERVER_HOST}/module/nginx.conf"

    sed -i "s/server_name \\*\\.xxxxxx;/server_name *.$domain;/" /etc/nginx/nginx.conf
    sed -i "s/server_name xxxxxx;/server_name $domain;/" /etc/nginx/nginx.conf
    sed -i "s#https://xxxxxx:86/#https://$domain:86/#" /etc/nginx/nginx.conf

    chmod 644 /etc/nginx/nginx.conf
    chown root:root /etc/nginx/nginx.conf
    systemctl daemon-reload
}

restart_services() {
    log "Enabling and restarting services"
    systemctl daemon-reload
    systemctl enable --now xray nginx runn
    systemctl restart xray nginx runn
}

finalize() {
    [ -f /root/domain ] && mv /root/domain /etc/xray/
    rm -f xray.sh
}

main() {
    setup_environment
    setup_time
    install_dependencies
    install_xray
    install_ssl
    configure_xray
    configure_nginx
    restart_services
    log "XRAY Core Installed Successfully."
    sleep 2
    finalize
}

main
