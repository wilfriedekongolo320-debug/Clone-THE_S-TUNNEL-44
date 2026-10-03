#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export SERVER_HOST="https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main"

setup_variables() {
    MYIP=$(wget -qO- https://api.ipify.org || echo "127.0.0.1")
    NET=$(ip -o -4 route show to default | awk '{print $5}')
    source /etc/os-release
    ver=$VERSION_ID
}

set_simple_password() {
    if [ -f /etc/pam.d/common-password ]; then
        if ! grep -q "pam_unix.so obscure sha512" /etc/pam.d/common-password; then
            echo "password [success=1 default=ignore] pam_unix.so obscure sha512" >> /etc/pam.d/common-password
        fi
    fi
}

setup_rc_local() {
    cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

    cat > /etc/rc.local <<-END
exit 0
END

    chmod +x /etc/rc.local
    systemctl daemon-reload
    systemctl enable rc-local
    systemctl start rc-local
}

disable_ipv6() {
    echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
    sed -i '$ i echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
}

configure_nginx() {
    apt-get install -y nginx
    rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
    wget -q -O /etc/nginx/nginx.conf "${SERVER_HOST}/module/nginx.conf"
    rm -f /etc/nginx/conf.d/default.conf
    mkdir -p /etc/systemd/system/nginx.service.d
    printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
    systemctl daemon-reload
    systemctl enable --now nginx
}

setup_web_directories() {
    mkdir -p /home/vps/public_html
    wget -q -O /home/vps/public_html/index.html "${SERVER_HOST}/module/index"
    chown -R www-data:www-data /home/vps/public_html
}

install_badvpn() {
    wget -q -O /usr/bin/badvpn-udpgw "${SERVER_HOST}/module/newudpgw"
    chmod +x /usr/bin/badvpn-udpgw
    wget -q -O /etc/systemd/system/badvpn@.service "${SERVER_HOST}/module/badvpn@.service"
    systemctl daemon-reload
    systemctl enable --now badvpn@7100
    systemctl enable --now badvpn@7200
    systemctl enable --now badvpn@7300
}

configure_ssh_dropbear() {
    apt-get install -y dropbear
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    for port in 500 40000 81 51443 58080 666; do
        sed -i "/^Port 22/a Port $port" /etc/ssh/sshd_config
    done
    systemctl restart ssh
    sed -i 's/^NO_START=1/NO_START=0/' /etc/default/dropbear
    sed -i 's/^NO_START=1/NO_START=0/g' /etc/default/dropbear
    sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
    sed -i 's#DROPBEAR_EXTRA_ARGS=.*#DROPBEAR_EXTRA_ARGS="-p 50000 -p 109 -p 110 -p 69"#g' /etc/default/dropbear
    echo "/bin/false" >> /etc/shells
    echo "/usr/sbin/nologin" >> /etc/shells
    systemctl enable --now dropbear
}

configure_stunnel() {
    STUNNEL_VERSION="5.75"
    STUNNEL_URL="https://www.stunnel.org/downloads/stunnel-${STUNNEL_VERSION}.tar.gz"
    INSTALL_DIR="/usr/local/bin"
    ETC_DIR="/etc/stunnel5"
    CONF_FILE="$ETC_DIR/stunnel5.conf"
    PEM_FILE="$ETC_DIR/stunnel5.pem"
    SYSTEMD_UNIT="/etc/systemd/system/stunnel5.service"

    apt update -y
    apt install -y build-essential libssl-dev libwrap0-dev zlib1g-dev unzip wget

    cd /root
    rm -rf "stunnel-${STUNNEL_VERSION}" "stunnel-${STUNNEL_VERSION}.tar.gz"
    wget -q -O "stunnel-${STUNNEL_VERSION}.tar.gz" "$STUNNEL_URL"
    tar xzf "stunnel-${STUNNEL_VERSION}.tar.gz"
    cd "stunnel-${STUNNEL_VERSION}"
    ./configure --prefix=/usr/local
    make -j"$(nproc)"
    make install
    cp /usr/local/bin/stunnel "$INSTALL_DIR/stunnel5"
    chmod 755 "$INSTALL_DIR/stunnel5"

    rm -rf "$ETC_DIR"
    mkdir -p "$ETC_DIR"

    if [[ -f /etc/xray/xray.crt && -f /etc/xray/xray.key ]]; then
        cat /etc/xray/xray.key /etc/xray/xray.crt > "$PEM_FILE"
    else
        openssl req -new -x509 -days 1095 -nodes \
            -subj "/C=MY/ST=Selangor/L=ShahAlam/O=nexustunnelpro/OU=stunnel/CN=$(hostname -f)/emailAddress=admin@localhost" \
            -out "$ETC_DIR/stunnel.crt" -keyout "$ETC_DIR/stunnel.key"
        cat "$ETC_DIR/stunnel.key" "$ETC_DIR/stunnel.crt" > "$PEM_FILE"
    fi

    chmod 600 "$PEM_FILE"

    cat > "$CONF_FILE" <<-EOF
cert = $PEM_FILE
client = no
foreground = yes
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear-447]
accept = 447
connect = 127.0.0.1:109

[openssh-777]
accept = 777
connect = 127.0.0.1:22

[openvpn-442]
accept = 442
connect = 127.0.0.1:1194

[openssh-8181]
accept = 8181
connect = 127.0.0.1:22
EOF

    cat > "$SYSTEMD_UNIT" <<-EOF
[Unit]
Description=Stunnel5 Service
Documentation=https://stunnel.org
After=network.target
[Service]
ExecStart=$INSTALL_DIR/stunnel5 $CONF_FILE
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable stunnel5
    systemctl restart stunnel5
    rm -rf /root/stunnel-5.75
    rm -f /root/stunnel-5.75.tar.gz
}

main() {
    setup_variables
    set_simple_password
    setup_rc_local
    disable_ipv6
    configure_nginx
    setup_web_directories
    install_badvpn
    configure_ssh_dropbear
    configure_stunnel
    echo ""
    echo "[*] SSH Tunnel Installed Successfully!"
}

main
