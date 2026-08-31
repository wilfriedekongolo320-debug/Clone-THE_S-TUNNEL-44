#!/bin/bash

# ──────────────────────────────────────────────
# THE_S Style - SlowDNS Autoscript
# ──────────────────────────────────────────────

clear

# Colors
export LN='\033[38;5;51m'      # Cyan
export MG='\033[38;5;201m'     # Magenta
export YL='\033[38;5;226m'     # Yellow
export GR='\033[38;5;46m'      # Green
export RD='\033[38;5;196m'     # Red
export WH='\033[1;37m'         # White
export GY='\033[38;5;245m'     # Gray
export BG='\033[44m'
export NC='\033[0m'

# Header
echo -e "\( {MG}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ \){NC}"
echo -e "\( {MG}┃ \){NC}  \( {YL}████████╗██╗  ██╗███████╗    ███████╗ \){NC}                      \( {MG}┃ \){NC}"
echo -e "\( {MG}┃ \){NC}  \( {YL}╚══██╔══╝██║  ██║██╔════╝    ██╔════╝ \){NC}                      \( {MG}┃ \){NC}"
echo -e "\( {MG}┃ \){NC}  \( {YL}   ██║   ███████║█████╗      ███████╗ \){NC}                      \( {MG}┃ \){NC}"
echo -e "\( {MG}┃ \){NC}  \( {YL}   ██║   ██╔══██║██╔══╝      ╚════██║ \){NC}                      \( {MG}┃ \){NC}"
echo -e "\( {MG}┃ \){NC}  \( {YL}   ██║   ██║  ██║███████╗    ███████║ \){NC}                      \( {MG}┃ \){NC}"
echo -e "\( {MG}┃ \){NC}  \( {YL}   ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚══════╝ \){NC}                      \( {MG}┃ \){NC}"
echo -e "\( {MG}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \){NC}"
echo
echo -e "\( {LN}▸ CYBER-MATRIX SYSTEM INIT \){NC}"
echo -e "\( {GY}──────────────────────────────────────────────────────────── \){NC}"
echo -e "  \( {WH}Please Wait ... Installing required packages \){NC}"
echo

REQUIRED_PACKAGES=(
curl wget dnsutils git screen whois pwgen python jq fail2ban sudo
gnutls-bin mlocate dh-make libaudit-dev build-essential dos2unix debconf-utils
)

for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg-query -W --showformat='${Status}\n' "$package" 2>/dev/null | grep -q "install ok installed"; then
        echo -e "  \( {GY}[+] \){NC} Installing ${LN}\( package \){NC} ..."
        apt-get -qq install "$package" -y &>/dev/null
    else
        echo -e "  \( {GR}[✓] \){NC} ${package} already installed"
    fi
done

echo
echo -e "\( {LN}▸ INSTALLING GOLANG \){NC}"
echo -e "\( {GY}──────────────────────────────────────────────────────────── \){NC}"

rm -fr /usr/bin/go
wget -q https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
rm -f /root/go1.22.0.linux-amd64.tar.gz
echo 'export PATH="/usr/local/go/bin:$PATH:/rere"' > /root/.bashrc
cd \~ || exit
source .bashrc

echo -e "  \( {GR}[✓] \){NC} Go version : $(go version)"
echo

install_slowdns() {
    cd /root || exit
    rm -rf /etc/slowdns
    git clone https://www.bamsoftware.com/git/dnstt.git
    cd dnstt/dnstt-server || exit
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

    # Domain Panel - THE_S Style
    echo -e "\( {MG}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ \){NC}"
    echo -e "\( {MG}┃ \){NC}  \( {YL}◆ CYBER-MATRIX DOMAIN PANEL \){NC}                              \( {MG}┃ \){NC}"
    echo -e "\( {MG}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \){NC}"
    echo
    echo -e "\( {LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━● \){NC}"
    echo -e "  \( {WH}Configure your NS Domain for SlowDNS tunnel \){NC}"
    echo -e "\( {LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━● \){NC}"
    echo

    while true; do
        echo -ne "  \( {YL}▸ NS Domain \){NC} \( {GY}: \){NC} "
        read -r Nameserver
        if [[ -z "$Nameserver" ]]; then
            echo -e "  \( {RD}[!] NS Domain cannot be empty. Please enter a value. \){NC}"
            echo
        else
            break
        fi
    done

    echo "$Nameserver" > /etc/slowdns/nsdomain

    systemctl stop dnstt 2>/dev/null || true
    pkill dns-server 2>/dev/null || true
    rm -f /etc/systemd/system/dnstt.service

    cat >/etc/systemd/system/dnstt.service <<END
[Unit]
Description=SlowDNS Service
Documentation=https://google.com
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
    interface=$(ip route get 8.8.8.8 | awk '/dev/ {print $5}')
    iptables -I INPUT -p udp --dport 5300 -j ACCEPT &>/dev/null
    iptables -t nat -I PREROUTING -i "$interface" -p udp --dport 53 -j REDIRECT --to-ports 5300
    iptables-save >/etc/iptables.up.rules
    iptables-restore < /etc/iptables.up.rules
    netfilter-persistent save
    netfilter-persistent reload
}

install_slowdns
install_firewall

echo
echo -e "\( {GY}──────────────────────────────────────────────────────────── \){NC}"
rm -rf /root/go /root/dnstt

# Final Status Panel
echo
echo -e "\( {MG}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ \){NC}"
echo -e "\( {MG}┃ \){NC}  \( {YL}◆ INSTALLATION COMPLETE \){NC}                                  \( {MG}┃ \){NC}"
echo -e "\( {MG}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \){NC}"
echo
echo -e "  \( {WH}NS Domain \){NC}     \( {GY}: \){NC} ${LN}\( Nameserver \){NC}"
echo -e "  \( {WH}Service \){NC}       \( {GY}: \){NC} \( {GR}[ ONLINE ] \){NC}"
echo -e "  \( {WH}Port \){NC}          \( {GY}: \){NC} \( {LN}5300/UDP \){NC}"
echo -e "  \( {WH}Protocol \){NC}      \( {GY}: \){NC} \( {LN}SlowDNS / DNSTT \){NC}"
echo
echo -e "\( {LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━● \){NC}"
echo -e "  \( {GR}SlowDNS Autoscript installation completed successfully! \){NC}"
echo -e "\( {LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━● \){NC}"
echo
