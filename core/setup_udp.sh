#!/bin/bash
set -euo pipefail

clear

export SERVER_HOST="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main"
export UDP_DIR="/etc/udp-custom"
export SERVICE_FILE="/etc/systemd/system/udp-custom.service"

update_system() {
    apt-get update -y
    apt-get upgrade -y
    apt-get install -y wget unzip
}

install_udp_custom() {
    rm -rf "$UDP_DIR"
    mkdir -p "$UDP_DIR"

    wget -q "${SERVER_HOST}/module/udp-custom-linux-amd64" -O "$UDP_DIR/udp-custom"
    chmod +x "$UDP_DIR/udp-custom"

    wget -q "${SERVER_HOST}/module/udp_config.json" -O "$UDP_DIR/config.json"
    chmod 644 "$UDP_DIR/config.json"
}

create_service() {
    local exclude_arg=""
    if [ -n "${1:-}" ]; then
        exclude_arg="-exclude $1"
    fi

    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=UDP Custom by Clone-THE_S-TUNNEL
[Service]
User=root
Type=simple
ExecStart=$UDP_DIR/udp-custom server $exclude_arg
WorkingDirectory=$UDP_DIR
Restart=always
RestartSec=2s
[Install]
WantedBy=multi-user.target
EOF
}

start_service() {
    systemctl daemon-reload
    systemctl enable udp-custom >/dev/null 2>&1 || true
    systemctl restart udp-custom >/dev/null 2>&1 || true
}

update_system
install_udp_custom
create_service "${1:-}"
start_service
