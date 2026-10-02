# Palette Cyberpunk (Codes ANSI 256 couleurs)
CYAN='\033[38;5;51m'     # Neon Cyan (Bordures & Puces)
MAGENTA='\033[38;5;201m' # Neon Pink/Magenta (Titres & Accentuation)
YELLOW='\033[38;5;226m'  # Neon Yellow (Ports & Valeurs)
GREEN='\033[38;5;46m'    # Neon Green (Sous-titres & Chemins)
BG_PINK='\033[48;5;198m\033[38;5;16m\033[1m' # Fond Rose / Texte Noir Fluo
NC='\033[0m'             # Reset Color

port_info() {
clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC} ${BG_PINK}                ⚡ PORT INFORMATION ⚡                 ${NC} ${CYAN}║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} Nginx                       : ${YELLOW}2081${NC}                  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} SSH-VPN                     : ${YELLOW}22${NC}                    ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} SSH WS HTTPS                : ${YELLOW}443${NC}                   ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} SSH WS HTTP                 : ${YELLOW}80${NC}                    ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} Dropbear                    : ${YELLOW}109, 143${NC}              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} Stunnel4                    : ${YELLOW}447, 777${NC}              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} OpenVPN TCP                 : ${YELLOW}1194${NC}                  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} OpenVPN UDP                 : ${YELLOW}2200${NC}                  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} Squid Proxy                 : ${YELLOW}3128, 8880${NC}            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} OHP                         : ${YELLOW}8000${NC}                  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} Slow DNS                    : ${YELLOW}22, 53, 80, 443${NC}       ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} UDP Custom                  : ${YELLOW}1-65535${NC}               ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} ZIVPN UDP                   : ${YELLOW}AUTO${NC}                  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} XRAY HTTPS                  : ${YELLOW}443${NC}                   ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} XRAY HTTP                   : ${YELLOW}80${NC}                    ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} BadVPN UDP                  : ${YELLOW}7100, 7200, 7300${NC}      ${CYAN}║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC} ${GREEN}[XRAY CUSTOM PATH PORTS]${NC}                                 ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                          ${CYAN}║${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} VMESS HTTPS                 : ${YELLOW}$(grep -w "VMESS CUSTOM TLS" /etc/xray/port_info | cut -d: -f2 | tr -d ' ')${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} VMESS HTTP                  : ${YELLOW}$(grep -w "VMESS CUSTOM NTLS" /etc/xray/port_info | cut -d: -f2 | tr -d ' ')${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} VLESS HTTPS                 : ${YELLOW}$(grep -w "VLESS CUSTOM TLS" /etc/xray/port_info | cut -d: -f2 | tr -d ' ')${NC}"
echo -e "${CYAN}║${NC} ${MAGENTA}►${NC} VLESS HTTP                  : ${YELLOW}$(grep -w "VLESS CUSTOM NTLS" /etc/xray/port_info | cut -d: -f2 | tr -d ' ')${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${MAGENTA} Press any key to return...${NC}"
read -n 1 -s -r
menu
}
port_info
