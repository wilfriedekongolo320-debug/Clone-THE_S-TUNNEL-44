#!/bin/bash

# ==============================================================================
#  PALETTE NEON CYBERPUNK (TRUE COLOR / ANSI 256)
# ==============================================================================
export C_RESET='\033[0m'
export C_BOLD='\033[1m'
export C_CYAN='\033[38;5;45m'
export C_MAGENTA='\033[38;5;201m'
export C_GREEN='\033[38;5;46m'
export C_GOLD='\033[38;5;220m'
export C_RED='\033[38;5;196m'
export C_BLUE='\033[38;5;39m'
export C_GRAY='\033[38;5;242m'
export C_WHITE='\033[38;5;255m'

export DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "N/A")
export MYIP=$(wget -qO- ipv4.icanhazip.com || echo "N/A")

# ==============================================================================
#  ADD ZIVPN ACCOUNT
# ==============================================================================
add_zivpn() {
    clear
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CREATE ZIVPN ACCOUNT${C_RESET}                                   ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""

    while true; do
        read -rp "  ► Enter username : " user
        if [[ -z "$user" ]]; then
            echo -e "     ${C_RED}✖ Username cannot be empty.${C_RESET}"
            continue
        fi
        if [[ ! "$user" =~ ^[a-zA-Z0-9_]+$ ]]; then
            echo -e "     ${C_RED}✖ Invalid username (letters, numbers, underscore only).${C_RESET}"
            continue
        fi
        if grep -qw "$user" /etc/zivpn/user.db 2>/dev/null; then
            echo -e "     ${C_RED}✖ Username already exists.${C_RESET}"
            continue
        fi
        break
    done

    while true; do
        read -rp "  ► Enter password : " pass
        if [[ -z "$pass" ]]; then
            echo -e "     ${C_RED}✖ Password cannot be empty.${C_RESET}"
            continue
        fi
        if grep -qw "$pass" /etc/zivpn/user.db 2>/dev/null || grep -qw "\"$pass\"" /etc/zivpn/config.json 2>/dev/null; then
            echo -e "     ${C_RED}✖ Password already in use.${C_RESET}"
            continue
        fi
        break
    done

    while true; do
        read -rp "  ► Validity (days): " days
        if [[ -z "$days" || ! "$days" =~ ^[0-9]+$ || "$days" -le 0 ]]; then
            echo -e "     ${C_RED}✖ Expiry days must be a positive number.${C_RESET}"
            continue
        fi
        break
    done

    exp=$(date -d "+$days days" +"%Y-%m-%d")
    sed -i '/"config": \[/a\      "'"$pass"'",' /etc/zivpn/config.json
    sed -i ':a;N;$!ba;s/,\n[ \t]*]/ \n    ]/' /etc/zivpn/config.json
    sed -i "1i$user $pass $exp" /etc/zivpn/user.db
    systemctl restart zivpn

    clear
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GREEN}⚡ ZIVPN ACCOUNT CREATED SUCCESSFULLY${C_RESET}                        ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
    printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Username${C_RESET}  : %-46s ${C_MAGENTA}║${C_RESET}\n" "$user"
    printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Password${C_RESET}  : %-46s ${C_MAGENTA}║${C_RESET}\n" "$pass"
    printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}IPv4${C_RESET}      : %-46s ${C_MAGENTA}║${C_RESET}\n" "$MYIP"
    printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Domain${C_RESET}    : %-46s ${C_MAGENTA}║${C_RESET}\n" "$DOMAIN"
    printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Expiry${C_RESET}    : %-46s ${C_MAGENTA}║${C_RESET}\n" "$exp ($days Days)"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    read -n 1 -s -r -p "  Press any key to return to menu..."
    menu_zivpn
}

# ==============================================================================
#  DELETE ZIVPN ACCOUNT
# ==============================================================================
del_zivpn() {
    clear
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_RED}❖ DELETE ZIVPN ACCOUNT${C_RESET}                                  ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""

    if [[ ! -s /etc/zivpn/user.db ]]; then
        echo -e "  ${C_RED}✖ No active users found.${C_RESET}"
        echo ""
        read -n 1 -s -r -p "  Press any key to return..."
        menu_zivpn
        return
    fi

    echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
    printf " %-5s %-18s %-18s %-12s\n" "NO." "USERNAME" "PASSWORD" "EXPIRY"
    echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
    
    i=1
    while read -r line; do
        username=$(echo "$line" | awk '{print $1}')
        password=$(echo "$line" | awk '{print $2}')
        expiry=$(echo "$line" | awk '{print $3}')
        printf " [%-2d]  %-18s %-18s %-12s\n" "$i" "$username" "$password" "$expiry"
        ((i++))
    done < /etc/zivpn/user.db
    echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
    echo ""

    read -rp "  ► Enter username to delete : " user
    if [[ -z "$user" ]]; then
        echo -e "  ${C_RED}✖ Username cannot be empty.${C_RESET}"
        sleep 1
        menu_zivpn
        return
    fi

    line=$(awk -v u="$user" '$1==u {print; exit}' /etc/zivpn/user.db)
    if [[ -z "$line" ]]; then
        echo -e "  ${C_RED}✖ Username '$user' not found.${C_RESET}"
        read -n 1 -s -r -p "  Press any key..."
        menu_zivpn
        return
    fi

    pass=$(echo "$line" | awk '{print $2}')
    sed -i "/\"$pass\"/d" /etc/zivpn/config.json
    sed -i "/^$user /d" /etc/zivpn/user.db
    systemctl restart zivpn

    echo ""
    echo -e "  ${C_GREEN}⚡ User '$user' deleted successfully.${C_RESET}"
    echo ""
    read -n 1 -s -r -p "  Press any key to return..."
    menu_zivpn
}

# ==============================================================================
#  RENEW ZIVPN ACCOUNT
# ==============================================================================
renew_zivpn() {
    clear
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GOLD}❖ RENEW ZIVPN ACCOUNT${C_RESET}                                   ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""

    if [[ ! -s /etc/zivpn/user.db ]]; then
        echo -e "  ${C_RED}✖ No active users found.${C_RESET}"
        echo ""
        read -n 1 -s -r -p "  Press any key to return..."
        menu_zivpn
        return
    fi

    echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
    printf " %-5s %-18s %-18s %-12s\n" "NO." "USERNAME" "PASSWORD" "EXPIRY"
    echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
    
    i=1
    while read -r line; do
        username=$(echo "$line" | awk '{print $1}')
        password=$(echo "$line" | awk '{print $2}')
        expiry=$(echo "$line" | awk '{print $3}')
        printf " [%-2d]  %-18s %-18s %-12s\n" "$i" "$username" "$password" "$expiry"
        ((i++))
    done < /etc/zivpn/user.db
    echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
    echo ""

    read -rp "  ► Enter username to renew : " user
    if [[ -z "$user" ]]; then
        echo -e "  ${C_RED}✖ Username cannot be empty.${C_RESET}"
        sleep 1
        menu_zivpn
        return
    fi

    line=$(awk -v u="$user" '$1==u {print; exit}' /etc/zivpn/user.db)
    if [[ -z "$line" ]]; then
        echo -e "  ${C_RED}✖ Username '$user' not found.${C_RESET}"
        read -n 1 -s -r -p "  Press any key..."
        menu_zivpn
        return
    fi

    current_exp=$(echo "$line" | awk '{print $3}')
    read -rp "  ► Enter additional days : " add_days
    if [[ -z "$add_days" || ! "$add_days" =~ ^[0-9]+$ || "$add_days" -le 0 ]]; then
        echo -e "  ${C_RED}✖ Invalid number of days.${C_RESET}"
        sleep 1
        menu_zivpn
        return
    fi

    new_exp=$(date -d "$current_exp +$add_days days" +"%Y-%m-%d")
    password=$(echo "$line" | awk '{print $2}')
    sed -i "/^$user /c\\$user $password $new_exp" /etc/zivpn/user.db

    clear
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GREEN}⚡ ZIVPN ACCOUNT RENEWED SUCCESSFULLY${C_RESET}                       ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
    printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Username${C_RESET}    : %-45s ${C_MAGENTA}║${C_RESET}\n" "$user"
    printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Old Expiry${C_RESET}  : %-45s ${C_MAGENTA}║${C_RESET}\n" "$current_exp"
    printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}New Expiry${C_RESET}  : %-45s ${C_MAGENTA}║${C_RESET}\n" "$new_exp"
    printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Days Added${C_RESET}  : %-45s ${C_MAGENTA}║${C_RESET}\n" "+$add_days Days"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    read -n 1 -s -r -p "  Press any key to return to menu..."
    menu_zivpn
}

# ==============================================================================
#  LIST ZIVPN ACCOUNTS
# ==============================================================================
list_zivpn() {
    clear
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ ZIVPN USER DATABASE${C_RESET}                                    ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""

    if [[ ! -s /etc/zivpn/user.db ]]; then
        echo -e "  ${C_RED}✖ No registered users found.${C_RESET}"
    else
        echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
        printf " %-5s %-18s %-18s %-12s\n" "NO." "USERNAME" "PASSWORD" "EXPIRY"
        echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
        
        i=1
        while read -r line; do
            user=$(echo "$line" | awk '{print $1}')
            pass=$(echo "$line" | awk '{print $2}')
            exp=$(echo "$line" | awk '{print $3}')
            printf " [%-2d]  %-18s %-18s %-12s\n" "$i" "$user" "$pass" "$exp"
            ((i++))
        done < /etc/zivpn/user.db
        echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────${C_RESET}"
    fi

    echo ""
    read -n 1 -s -r -p "  Press any key to return to menu..."
    menu_zivpn
}

# ==============================================================================
#  MAIN ZIVPN MENU
# ==============================================================================
menu_zivpn() {
    clear
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ ZIVPN CONTROL CENTER${C_RESET}                                  ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""

    echo -e "${C_CYAN}►► ACCOUNT MANAGEMENT ───────────────────────────────────────────${C_RESET}"
    echo -e "   ${C_MAGENTA}[01]${C_RESET} CREATE ACCOUNT            ${C_MAGENTA}[03]${C_RESET} DELETE ACCOUNT"
    echo -e "   ${C_MAGENTA}[02]${C_RESET} EXTEND / RENEW            ${C_MAGENTA}[04]${C_RESET} USER DATABASE LIST"
    echo ""
    echo -e "   ${C_GRAY}[00] MAIN MENU${C_RESET}"
    echo ""
    echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
    
    read -p "  🜲 Select option [00-04] : " opt
    echo ""

    case $opt in
        1 | 01) clear ; add_zivpn ;;
        2 | 02) clear ; renew_zivpn ;;
        3 | 03) clear ; del_zivpn ;;
        4 | 04) clear ; list_zivpn ;;
        0 | 00) clear ; menu ;;
        *)
            echo -e "  ${C_RED}[ERROR] Invalid selection!${C_RESET}"
            sleep 1
            menu_zivpn
            ;;
    esac
}

menu_zivpn
