#!/bin/bash
set -euo pipefail

SERVER_HOST="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main"

configure_nginx() {
    echo "Downloading nginx xray conf..."
    domain=$(cat /root/domain 2>/dev/null || cat /etc/xray/domain 2>/dev/null || echo "127.0.0.1")
    if [ ! -f /etc/nginx/nginx.conf ]; then
        wget -q -O /etc/nginx/nginx.conf "${SERVER_HOST}/module/nginx.conf"
    fi

    if grep -q "xxxxxx" /etc/nginx/nginx.conf; then
        sed -i "s/server_name \\*\\.xxxxxx;/server_name *.$domain;/" /etc/nginx/nginx.conf
        sed -i "s/server_name xxxxxx;/server_name $domain;/" /etc/nginx/nginx.conf
        sed -i "s#https://xxxxxx:2081/#https://$domain:2081/#" /etc/nginx/nginx.conf
    fi

    chmod 644 /etc/nginx/nginx.conf
    chown root:root /etc/nginx/nginx.conf
    nginx -t >/dev/null 2>&1 || true
    systemctl daemon-reload
}

validate_services() {
    for svc in ssh nginx xray; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo "[OK] $svc active"
        else
            echo "[WARN] $svc not active"
        fi
    done
}

configure_nginx
validate_services
