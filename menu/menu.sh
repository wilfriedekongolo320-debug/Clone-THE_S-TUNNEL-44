#!/bin/bash

MYIP=$(curl -sS ipv4.icanhazip.com)
readonly SERVER_HOST="https://github.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44.git"
clear

# ==============================================================================
#  PALETTE NEON CYBERPUNK (TRUE COLOR / ANSI 256)
# ==============================================================================
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[38;5;45m'
C_MAGENTA='\033[38;5;201m'
C_GREEN='\033[38;5;46m'
C_GOLD='\033[38;5;220m'
C_RED='\033[38;5;196m'
C_BLUE='\033[38;5;39m'
C_GRAY='\033[38;5;242m'
C_WHITE='\033[38;5;255m'

# ==============================================================================
#  FONCTION : BARRE NEON SLIM
# ==============================================================================
draw_cyber_bar() {
    local val=${1:-0}
    local filled=$(( val / 10 ))
    local empty=$(( 10 - filled ))
    local bar=""
    
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="▒"; done
    echo "$bar"
}

# ==============================================================================
#  RÉCUPÉRATION DES MÉTRIQUES SYSTÈME
# ==============================================================================
domain=$(cat /etc/xray/domain 2>/dev/null || echo "N/A")
uptime="$(uptime -p 2>/dev/null | sed 's/up //' | cut -d " " -f 1-6)"
IPV4=$(curl -s -4 ifconfig.co || echo "N/A")
IPV6=$(curl -s -6 ifconfig.co || echo "")
VERSION_FILE="/etc/version"
INSTALLED_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "2.3.0")
LATEST_VERSION=$(curl -sS "$SERVER_HOST/version" 2>/dev/null || echo "$INSTALLED_VERSION")
UPDATE_AVAILABLE=0

CPU_USAGE=$(top -bn1 2>/dev/null | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}')
RAM_USAGE=$(free 2>/dev/null | awk '/Mem:/ {print int($3/$2 * 100)}')

CPU_BAR=$(draw_cyber_bar ${CPU_USAGE:-0})
RAM_BAR=$(draw_cyber_bar ${RAM_USAGE:-0})

version_greater() {
    [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" = "$1" ] && [ "$1" != "$2" ]
}

if version_greater "$LATEST_VERSION" "$INSTALLED_VERSION"; then
    UPDATE_AVAILABLE=1
    wget -q -O /usr/local/sbin/update "$SERVER_HOST/menu/update.sh" && chmod +x /usr/local/sbin/update
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS="$NAME"
    VER="$VERSION_ID"
else
    OS=$(uname -s)
    VER=$(uname -r)
fi

nginx=$(systemctl is-active nginx 2>/dev/null)
[[ $nginx == "active" ]] && status_nginx="${C_GREEN}⚡ ONLINE${C_RESET}" || status_nginx="${C_RED}✖ OFFLINE${C_RESET}"

xray=$(systemctl is-active xray 2>/dev/null)
[[ $xray == "active" ]] && status_xray="${C_GREEN}⚡ ONLINE${C_RESET}" || status_xray="${C_RED}✖ OFFLINE${C_RESET}"

ssh_ws=$(systemctl is-active ws-stunnel 2>/dev/null)
[[ $ssh_ws == "active" ]] && status_ws="${C_GREEN}⚡ ONLINE${C_RESET}" || status_ws="${C_RED}✖ OFFLINE${C_RESET}"

clear

# ==============================================================================
#  1. BANNER ASCII
# ==============================================================================
read -r -d '' BANNER << 'EOF'
████████╗██╗  ██╗███████╗    ███████╗
╚══██╔══╝██║  ██║██╔════╝    ██╔════╝
   ██║   ███████║█████╗      ███████╗
   ██║   ██╔══██║██╔══╝      ╚════██║
   ██║   ██║  ██║███████╗    ███████║
   ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚══════╝
EOF

TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
echo -e "${C_GOLD}${C_BOLD}"
while IFS= read -r line; do
    LINE_LEN=${#line}
    PADDING=$(( (TERM_WIDTH - LINE_LEN) / 2 ))
    if [ $PADDING -gt 0 ]; then
        printf "%*s%s\n" "$PADDING" "" "$line"
    else
        echo "$line"
    fi
done <<< "$BANNER"
echo -e "${C_RESET}"

# ==============================================================================
#  2. MATRICE SYSTEME & SERVICES
# ==============================================================================
echo -e "${C_MAGENTA}╔══════════════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CYBER-MATRIX SYSTEM INFOS${C_RESET}                               ${C_MAGENTA}║${C_RESET}"
echo -e "${C_MAGENTA}╠══════════════════════════════════════════════════════════╣${C_RESET}"
printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}OS${C_RESET}     : %-18s  ${C_WHITE}UPTIME${C_RESET} : %-16s ${C_MAGENTA}║${C_RESET}\n" "$OS $VER" "${uptime:-N/A}"
printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}CPU${C_RESET}    : [${C_CYAN}%s${C_RESET}] %-3d%%    ${C_WHITE}RAM${C_RESET}    : [${C_CYAN}%s${C_RESET}] %-3d%%    ${C_MAGENTA}║${C_RESET}\n" "$CPU_BAR" "${CPU_USAGE:-0}" "$RAM_BAR" "${RAM_USAGE:-0}"
printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}IPv4${C_RESET}   : %-18s  ${C_WHITE}DOMAIN${C_RESET} : %-16s ${C_MAGENTA}║${C_RESET}\n" "${IPV4:-N/A}" "${domain:-N/A}"
if [ -n "$IPV6" ]; then
printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}IPv6${C_RESET}   : %-47s ${C_MAGENTA}║${C_RESET}\n" "$IPV6"
fi
echo -e "${C_MAGENTA}╠══════════════════════════════════════════════════════════╣${C_RESET}"
printf "${C_MAGENTA}║${C_RESET}  ${C_BOLD}${C_RESET}  NGINX [%b]   XRAY [%b]   WS [%b]   ${C_MAGENTA}║${C_RESET}\n" "$status_nginx" "$status_xray" "$status_ws"
echo -e "${C_MAGENTA}╚══════════════════════════════════════════════════════════╝${C_RESET}"
echo ""

# ==============================================================================
#  3. COMMAND CENTER
# ==============================================================================
echo -e "${C_CYAN}►► NETWORKING & TUNNELS ─────────────────────────────────────────${C_RESET}"
echo -e "   ${C_MAGENTA}[01]${C_RESET} SSH / WS CORE             ${C_MAGENTA}[04]${C_RESET} TROJAN PROTOCOL"
echo -e "   ${C_MAGENTA}[02]${C_RESET} VMESS NETWORK             ${C_MAGENTA}[05]${C_RESET} SOCKS PROXY"
echo -e "   ${C_MAGENTA}[03]${C_RESET} VLESS NETWORK             ${C_MAGENTA}[06]${C_RESET} ZIVPN ENGINE"
echo ""

echo -e "${C_CYAN}►► SYSTEM & UTILITIES ───────────────────────────────────────────${C_RESET}"
echo -e "   ${C_BLUE}[07]${C_RESET} DNS MANAGER               ${C_BLUE}[12]${C_RESET} VPN PORTS"
echo -e "   ${C_BLUE}[08]${C_RESET} DOMAIN MANAGER            ${C_BLUE}[13]${C_RESET} PURGE SYSTEM LOGS"
echo -e "   ${C_BLUE}[09]${C_RESET} IPv6 UTILS                ${C_BLUE}[14]${C_RESET} TELEGRAM BOT PANEL"
echo -e "   ${C_BLUE}[10]${C_RESET} SYSTEM MONITOR            ${C_BLUE}[16]${C_RESET} FAST DNS SUITE"
echo -e "   ${C_BLUE}[11]${C_RESET} NETGUARD FIREWALL         ${C_RED}[15]${C_RESET} DÉSINSTALLATION"
echo -e "   ${C_GRAY}[00] EXIT SESSION${C_RESET}              ${C_RED}[88]${C_RESET} REBOOT SERVER"
echo ""

echo -e "${C_CYAN}►► CONTROL DASHBOARD ────────────────────────────────────────────${C_RESET}"
echo -e "   ${C_GOLD}[18]${C_RESET} THE_S WEB CONTROL PANEL"
echo ""

if [ "$UPDATE_AVAILABLE" -eq 1 ]; then
    echo -e "${C_RED}╔═══════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_RED}║${C_RESET} ${C_BOLD}[99] NEW UPDATE AVAILABLE : v$LATEST_VERSION${C_RESET}"
    echo -e "${C_RED}╚═══════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
fi

# ==============================================================================
#  4. FOOTER NEON
# ==============================================================================
VERSION=$(cat /etc/version 2>/dev/null || echo "2.3.0")
echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
echo -e " ${C_BOLD}BUILD:${C_RESET} ${C_CYAN}v${VERSION}${C_RESET} │ ${C_BOLD}DEV:${C_RESET} ${C_GOLD}🜲 THE_S${C_RESET} │ ${C_BOLD}CONTACT:${C_RESET} ${C_GREEN}+237 621 67 16 48${C_RESET}"
echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
echo ""

read -p " 🜲 Enter Option [00-99] : " opt
echo -e ""

case $opt in
    1 | 01) clear ; ssh ;;
    2 | 02) clear ; vmess ;;
    3 | 03) clear ; vless ;;
    4 | 04) clear ; trojan ;;
    5 | 05) clear ; socks ;;
    6 | 06) clear ; zivpn ;;
    7 | 07) clear ; dns ;;
    8 | 08) clear ; domain ;;
    9 | 09) clear ; iptools ;;
    10) clear ; status ;;
    11) clear ; netguard ;;
    12) clear ; port ;;
    13) clear ; log ;;
    14) clear ; tgbot ;;
    15) clear ; uninstall ;;
    16) clear ; fastdns ;;
    18) clear ; web ;;
    88) reboot ;;
    99) clear ; update ;;
    0 | 00) exit ;;
    *) clear ; menu ;;
esac
