#!/bin/bash

# ==============================================================================
#  THE_S - MENU PRINCIPAL (Version propre)
# ==============================================================================

MYIP=$(curl -sS ipv4.icanhazip.com)
readonly SERVER_HOST="https://github.com/thesnet320-source/THE_S-TUNNEL-PRO-.git"

# Couleurs
LN='\033[34m'          # Bleu clair (bordures)
BG='\033[44m'          # Fond bleu
NC='\033[0m'
GR='\033[32m'          # Vert
RD='\033[31m'          # Rouge
GOLD='\033[38;5;220m'  # Or
BOLD='\033[1m'
WHITE='\033[97m'

# ==============================================================================
#  BARRE DE PROGRESSION (10 BLOCS)
# ==============================================================================
draw_bar() {
    local val=${1:-0}
    local filled=$(( val / 10 ))
    local empty=$(( 10 - filled ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    echo "$bar"
}

# ==============================================================================
#  RÉCUPÉRATION DES INFOS
# ==============================================================================
domain=$(cat /etc/xray/domain 2>/dev/null || echo "N/A")
uptime="$(uptime -p 2>/dev/null | cut -d " " -f 2-10)"
IPV4=$(curl -s -4 ifconfig.co 2>/dev/null || echo "N/A")
IPV6=$(curl -s -6 ifconfig.co 2>/dev/null)

VERSION_FILE="/etc/version"
INSTALLED_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "2.3.0")
LATEST_VERSION=$(curl -sS "$SERVER_HOST/version" 2>/dev/null || echo "$INSTALLED_VERSION")
UPDATE_AVAILABLE=0

CPU_USAGE=$(top -bn1 2>/dev/null | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}')
RAM_USAGE=$(free 2>/dev/null | awk '/Mem:/ {print int($3/$2 * 100)}')

CPU_BAR=$(draw_bar ${CPU_USAGE:-0})
RAM_BAR=$(draw_bar ${RAM_USAGE:-0})

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

# Status services
nginx=$(systemctl is-active nginx 2>/dev/null)
[[ \( nginx == "active" ]] && status_nginx=" \){GR}RUN\( {NC}" || status_nginx=" \){RD}OFF${NC}"

xray=$(systemctl is-active xray 2>/dev/null)
[[ \( xray == "active" ]] && status_xray=" \){GR}RUN\( {NC}" || status_xray=" \){RD}OFF${NC}"

ssh_ws=$(systemctl is-active ws-stunnel 2>/dev/null)
[[ \( ssh_ws == "active" ]] && status_ws=" \){GR}RUN\( {NC}" || status_ws=" \){RD}OFF${NC}"

clear

# ==============================================================================
#  BANNER ASCII "THE_S" EN OR (CENTRÉ)
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

echo -e "\( {GOLD} \){BOLD}"
while IFS= read -r line; do
    LINE_LEN=${#line}
    PADDING=$(( (TERM_WIDTH - LINE_LEN) / 2 ))
    [ $PADDING -lt 0 ] && PADDING=0
    printf "%*s%s\n" "$PADDING" "" "$line"
done <<< "$BANNER"
echo -e "${NC}"

# ==============================================================================
#  INFOS SYSTÈME
# ==============================================================================
echo -e "\( {LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ \){NC}"
echo -e "\( {LN}┃ \){NC}  OS         : ${WHITE}$OS \( VER \){NC}"
echo -e "\( {LN}┃ \){NC}  UPTIME     : ${WHITE}\( uptime \){NC}"
printf "\( {LN}┃ \){NC}  CPU USAGE  : [\( {GOLD}%s \){NC}] \( {GOLD}%3d%% \){NC}\n" "\( CPU_BAR" " \){CPU_USAGE:-0}"
printf "\( {LN}┃ \){NC}  RAM USAGE  : [\( {GOLD}%s \){NC}] \( {GOLD}%3d%% \){NC}\n" "\( RAM_BAR" " \){RAM_USAGE:-0}"
echo -e "\( {LN}┃ \){NC}  IPv4       : \( {WHITE} \){IPV4}${NC}"
[ -n "\( IPV6" ] && echo -e " \){LN}┃${NC}  IPv6       : ${WHITE}\( IPV6 \){NC}"
echo -e "\( {LN}┃ \){NC}  DOMAIN     : ${WHITE}\( domain \){NC}"
echo -e "\( {LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \){NC}"

# Status services
echo -e "\( {LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ \){NC}"
echo -e "\( {LN}┃ \){NC}   NGINX : [\( {status_nginx}]    XRAY : [ \){status_xray}]    WS : [${status_ws}]"
echo -e "\( {LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \){NC}"

# ==============================================================================
#  MENU
# ==============================================================================
echo -e "\( {LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ \){NC}"
echo -e "\( {LN}┃ \){NC} \( {BG} \){BOLD}                       MENU                      \( {NC} \){LN}┃${NC}"
echo -e "\( {LN}┃ \){NC}"
echo -e "\( {LN}┃ \){NC} [01] • SSH/WS MENU          [04] • TROJAN MENU"
echo -e "\( {LN}┃ \){NC} [02] • VMESS MENU           [05] • SOCKS MENU"
echo -e "\( {LN}┃ \){NC} [03] • VLESS MENU           [06] • ZIVPN MENU"
echo -e "\( {LN}┗━━━━━━━━━━━━━━━━━━━━━━━━ 🜲THE_S ━━━━━━━━━━━━━━━━━━━┛ \){NC}"

# ==============================================================================
#  TOOLS
# ==============================================================================
echo -e "\( {LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ \){NC}"
echo -e "\( {LN}┃ \){NC} \( {BG} \){BOLD}                      TOOLS                      \( {NC} \){LN}┃${NC}"
echo -e "\( {LN}┃ \){NC}"
echo -e "\( {LN}┃ \){NC} [07] • DNS PANEL            [11] • NETGUARD PANEL"
echo -e "\( {LN}┃ \){NC} [08] • DOMAIN PANEL         [12] • VPN PORT INFO"
echo -e "\( {LN}┃ \){NC} [09] • IPV6 PANEL           [13] • CLEAN VPS LOGS"
echo -e "\( {LN}┃ \){NC} [10] • VPS STATUS           [14] • 🜲THE_S BOT PANEL"
echo -e "\( {LN}┃ \){NC} [15] • UNINSTALL THE_S      [16] • FAST DNS MENU"
echo -e "\( {LN}┃ \){NC}"
echo -e "\( {LN}┃ \){NC} [00] • EXIT                 [88] • REBOOT VPS"
echo -e "\( {LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \){NC}"

# ==============================================================================
#  WEB PANEL
# ==============================================================================
echo -e "\( {LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ \){NC}"
echo -e "\( {LN}┃ \){NC} \( {BG} \){BOLD}                   WEB PANEL                     \( {NC} \){LN}┃${NC}"
echo -e "\( {LN}┃ \){NC}"
echo -e "\( {LN}┃ \){NC} [18] • 🜲THE_S PANEL"
echo -e "\( {LN}┃ \){NC}"
echo -e "\( {LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \){NC}"

# Update disponible
if [ "$UPDATE_AVAILABLE" -eq 1 ]; then
    echo -e "\( {RD}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ \){NC}"
    echo -e "\( {RD}┃ \){NC} \( {RD} \){BOLD}[99] • UPDATE SCRIPT (v\( LATEST_VERSION) \){NC}"
    echo -e "\( {RD}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ \){NC}"
fi

# ==============================================================================
#  FOOTER ROUGE (CENTRÉ)
# ==============================================================================
VERSION=$(cat /etc/version 2>/dev/null || echo "2.3.0")
FOOTER1="VERSION: ${VERSION}  |  SCRIPT BY 🜲THE_S"
FOOTER2="CONTACT Admin: +237 621 67 16 48"

echo
echo -e "\( {RD} \){BOLD}"
printf "%*s%s\n" $(( (TERM_WIDTH - ${#FOOTER1}) / 2 )) "" "$FOOTER1"
printf "%*s%s\n" $(( (TERM_WIDTH - ${#FOOTER2}) / 2 )) "" "$FOOTER2"
echo -e "${NC}"

# ==============================================================================
#  CHOIX
# ==============================================================================
read -p " Select menu : " opt
echo

case $opt in
    1|01) clear ; ssh ;;
    2|02) clear ; vmess ;;
    3|03) clear ; vless ;;
    4|04) clear ; trojan ;;
    5|05) clear ; socks ;;
    6|06) clear ; zivpn ;;
    7|07) clear ; dns ;;
    8|08) clear ; domain ;;
    9|09) clear ; iptools ;;
    10)   clear ; status ;;
    11)   clear ; netguard ;;
    12)   clear ; port ;;
    13)   clear ; log ;;
    14)   clear ; tgbot ;;
    15)   clear ; uninstall ;;
    16)   clear ; fastdns ;;
    18)   clear ; web ;;
    88)   reboot ;;
    99)   clear ; update ;;
    0|00) exit ;;
    *)    clear ; menu ;;
esac
