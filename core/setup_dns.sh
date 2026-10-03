#!/bin/bash
set -euo pipefail

clear
export LN='\033[34m'
export BG='\033[44m'
export NC='\033[0m'
export GR='\033[32m'
export RD='\033[31m'
export YL='\033[33m'
export CY='\033[36m'
export WH='\033[37m'
export GN='\033[32m'

echo "Please Wait ... Installing required packages"
REQUIRED_PACKAGES=(
curl wget dnsutils git screen whois pwgen python jq fail2ban sudo
gnutls-bin mlocate dh-make libaudit-dev build-essential dos2unix debconf-utils
)
for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg-query -W --showformat='${Status}\n' "$package" 2>/dev/null | grep -q "install ok installed"; then
        apt-get -qq install "$package" -y &>/dev/null
    fi
done

clear
echo "Installing Go (golang)..."
rm -rf /usr/bin/go
wget -q https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
rm -f /root/go1.22.0.linux-amd64.tar.gz
export PATH="/usr/local/go/bin:$PATH"

go version

install_slowdns() {
    cd /root || exit 1
    rm -rf /etc/slowdns /root/dnstt
    git clone https://www.bamsoftware.com/git/dnstt.git
    cd dnstt/dnstt-server || exit 1
    rm -f go.sum
    go mod tidy
    go build
    mkdir -p /etc/slowdns
    mv dnstt-server /etc/slowdns/dns-server
    chmod +x /etc/slowdns/dns-server
    /etc/slowdns/dns-server -gen-key \
        -privkey-file /etc/slowdns/server.key \
        -pubkey-file /etc/slowdns/server.pub

    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}           ◆ DOMAIN PANEL ◆                     ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo
    echo -e "  ${CY}►${NC} ${WH}Configure SlowDNS Nameserver${NC}"
    echo

    Nameserver="$1"

    if [[ -z "$Nameserver" && -f /etc/slowdns/nsdomain ]]; then
        Nameserver=$(cat /etc/slowdns/nsdomain | tr -d '\r\n')
    fi

    if [[ -z "$Nameserver" && -f /root/nsdomain ]]; then
        Nameserver=$(cat /root/nsdomain | tr -d '\r\n')
    fi

    if [[ -z "$Nameserver" && -t 0 ]]; then
        while true; do
            echo -ne "  ${YL}[ NS DOMAIN ]${NC} ${GN}›${NC} "
            read -r Nameserver
            if [[ -z "$Nameserver" ]]; then
                echo -e "  ${RD}✖ ERROR : NS Domain cannot be empty !${NC}"
                echo
            else
                break
            fi
        done
    fi

    if [[ -z "$Nameserver" ]]; then
        MY_IP=$(wget -qO- ipv4.icanhazip.com || echo "127.0.0.1")
        Nameserver="ns.${MY_IP}.nip.io"
        echo -e "  ${YL}⚠️ Aucun domaine NS détecté. Valeur attribuée par défaut : ${Nameserver}${NC}"
    fi

    echo
    echo -e "  ${GN}✔ Saving domain... (${Nameserver})${NC}"
    mkdir -p /etc/slowdns
    echo "$Nameserver" > /etc/slowdns/nsdomain

    echo -e "  ${GN}✔ Stopping old services...${NC}"
    systemctl stop dnstt 2>/dev/null || true
    pkill -9 dns-server 2>/dev/null || true
    rm -f /etc/systemd/system/dnstt.service

    echo -e "  ${GN}✔ Creating new service unit...${NC}"
    cat >/etc/systemd/system/dnstt.service <<END
[Unit]
Description=SlowDNS Cyber-Matrix Service
Documentation=https://thes.mrtomtech.site
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/etc/slowdns/dns-server -udp :5300 -privkey-file /etc/slowdns/server.key $Nameserver 127.0.0.1:22
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

    systemctl daemon-reload
    systemctl enable dnstt
    systemctl start dnstt
    sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding yes/' /etc/ssh/sshd_config
    systemctl restart ssh
}

install_firewall() {
    local interface
    interface=$(ip route get 8.8.8.8 2>/dev/null | awk '/dev/ {print $5}')
    if [[ -n "$interface" ]]; then
        iptables -I INPUT -p udp --dport 5300 -j ACCEPT &>/dev/null
        iptables -t nat -I PREROUTING -i "$interface" -p udp --dport 53 -j REDIRECT --to-ports 5300
        iptables-save >/etc/iptables.up.rules 2>/dev/null || true
        iptables-restore < /etc/iptables.up.rules 2>/dev/null || true
        if command -v netfilter-persistent &>/dev/null; then
            netfilter-persistent save &>/dev/null || true
            netfilter-persistent reload &>/dev/null || true
        fi
    fi
}

install_slowdns "$1"
install_firewall

echo ""
rm -rf /root/go /root/dnstt
echo -e " ${GN}SlowDNS Autoscript installation completed!${NC}"
