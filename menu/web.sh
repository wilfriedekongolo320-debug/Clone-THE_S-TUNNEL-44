#!/bin/bash
# ============================================================
#  Menu 18 — Nexus Tunnel Web (Cyberpunk / Neo-Terminal)
#  Manages the Nexus Tunnel Web panel from terminal.
# ============================================================

# ==============================================================================
#  PALETTE NEON CYBERPUNK (ANSI 256)
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

NEXUS_WEB_DIR="/opt/nexus-tunnel-web"
CONFIG_DIR="/etc/nexus-tunnel-web"
CONFIG_FILE="$CONFIG_DIR/config.json"
SERVICE="nexus-web"
INSTALL_SH="$NEXUS_WEB_DIR/install.sh"
NEXUS_REPO_URL="https://github.com/thesnet320-source/THE_S-TUNNEL-PRO-.git"
TMP_WEB_SRC="/tmp/nexus-web-src-$$"

# ─── Helpers ──────────────────────────────────────────────────────────────────

get_config_value() {
  local key="$1"
  if [ -f "$CONFIG_FILE" ]; then
    python3 -c "import json,sys; d=json.load(open('$CONFIG_FILE')); print(d.get('$key',''))" 2>/dev/null || \
    grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$CONFIG_FILE" | head -1 | sed 's/.*: *"//;s/"//'
  fi
}

set_config_value() {
  local key="$1" value="$2"
  if [ -f "$CONFIG_FILE" ]; then
    python3 - "$CONFIG_FILE" "$key" "$value" <<'PYEOF'
import json, sys
path, key, value = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f: d = json.load(f)
try: value = int(value)
except ValueError:
    try: value = float(value)
    except ValueError: pass
d[key] = value
with open(path, 'w') as f: json.dump(d, f, indent=2)
PYEOF
  fi
}

web_is_installed() {
  [ -f "$NEXUS_WEB_DIR/dist/server/index.js" ]
}

web_is_running() {
  systemctl is-active --quiet "$SERVICE" 2>/dev/null
}

get_web_port() {
  get_config_value "port" || echo "2087"
}

get_web_url() {
  local ip
  ip=$(curl -s4 ipv4.icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}')
  local port
  port=$(get_web_port)
  echo "http://$ip:$port"
}

wait_key() {
  echo ""
  read -n 1 -s -r -p "  Press any key to continue..."
  echo ""
}

log_info() {
  echo -e " ${C_GOLD}[INFO]${C_RESET} $*"
}

resolve_web_source_dir() {
  local base src
  base="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  src="$base/../nexus-web"
  if [ -d "$src" ] && [ -f "$src/install.sh" ]; then
    echo "$src"
    return 0
  fi

  src="/usr/local/sbin/nexus-web"
  if [ -d "$src" ] && [ -f "$src/install.sh" ]; then
    echo "$src"
    return 0
  fi

  src="/opt/nexus-tunnel-web"
  if [ -d "$src" ] && [ -f "$src/install.sh" ]; then
    echo "$src"
    return 0
  fi

  rm -rf "$TMP_WEB_SRC"
  if git clone --depth 1 "$NEXUS_REPO_URL" "$TMP_WEB_SRC" >/dev/null 2>&1; then
    src="$TMP_WEB_SRC/nexus-web"
    if [ -d "$src" ] && [ -f "$src/install.sh" ]; then
      echo "$src"
      return 0
    fi
  fi

  return 1
}

# ─── API Helper ───────────────────────────────────────────────────────────────
api_login() {
  local user="$1" pass="$2"
  local port
  port=$(get_web_port)
  curl -s -X POST "http://localhost:$port/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$user\",\"password\":\"$pass\"}" 2>/dev/null
}

api_call() {
  local method="$1" path="$2" token="$3" body="${4:-}"
  local port
  port=$(get_web_port)
  local url="http://localhost:$port/api$path"
  if [ -n "$body" ]; then
    curl -s -X "$method" "$url" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $token" \
      -d "$body" 2>/dev/null
  else
    curl -s -X "$method" "$url" \
      -H "Authorization: Bearer $token" 2>/dev/null
  fi
}

# ─── MAIN MENU ────────────────────────────────────────────────────────────────
function nexus_web_menu() {
  clear
  local status_str
  if web_is_running; then
    status_str="${C_GREEN}⚡ ONLINE${C_RESET}"
  else
    status_str="${C_RED}✖ OFFLINE${C_RESET}"
  fi

  local url
  url=$(get_web_url 2>/dev/null || echo "http://localhost:2087")
  local admin_usr
  admin_usr=$(get_config_value admin_user 2>/dev/null || echo 'N/A')

  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ NEXUS TUNNEL WEB — CONTROL CENTER${C_RESET}                             ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Status${C_RESET}  : %-52b ${C_MAGENTA}║${C_RESET}\n" "$status_str"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}URL${C_RESET}     : %-46s ${C_MAGENTA}║${C_RESET}\n" "$url"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Admin${C_RESET}   : %-46s ${C_MAGENTA}║${C_RESET}\n" "$admin_usr"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  if ! web_is_installed; then
    echo -e "  ${C_GOLD}[!] Nexus Tunnel Web is NOT installed.${C_RESET}"
    echo ""
    echo -e "   ${C_GREEN}[01]${C_RESET} INSTALL NEXUS TUNNEL WEB"
    echo -e "   ${C_GRAY}[00] MAIN MENU${C_RESET}"
    echo ""
    echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
    read -rp "  🜲 Select option : " opt
    case "$opt" in
      1|01) ntw_install ;;
      0|00) menu ;;
      *) nexus_web_menu ;;
    esac
    return
  fi

  echo -e "${C_CYAN}►► SITE ADMINISTRATION ──────────────────────────────────────────${C_RESET}"
  echo -e "   ${C_MAGENTA}[01]${C_RESET} MODIFIER CREDENTIALS      ${C_MAGENTA}[05]${C_RESET} LOGS & AUDIT"
  echo -e "   ${C_MAGENTA}[02]${C_RESET} MANAGER ADMIN             ${C_MAGENTA}[06]${C_RESET} STATUT & CONTRÔLE"
  echo -e "   ${C_MAGENTA}[03]${C_RESET} MANAGER CLIENT            ${C_GOLD}[07]${C_RESET} METTRE À JOUR PANEL"
  echo -e "   ${C_MAGENTA}[04]${C_RESET} MANAGER PLANS & OFFRES    ${C_RED}[08]${C_RESET} DÉSINSTALLER PANEL"
  echo ""
  echo -e "   ${C_GRAY}[00] RETOUR MAIN MENU${C_RESET}"
  echo ""
  echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
  read -rp "  🜲 Select option [00-08] : " opt
  echo ""

  case "$opt" in
    1|01) ntw_change_credentials ;;
    2|02) ntw_manager_admin ;;
    3|03) ntw_manager_client ;;
    4|04) ntw_manager_plans ;;
    5|05) ntw_view_logs ;;
    6|06) ntw_service_control ;;
    7|07) ntw_update ;;
    8|08) ntw_uninstall ;;
    0|00) menu ;;
    *) nexus_web_menu ;;
  esac
}

# ─── INSTALL ──────────────────────────────────────────────────────────────────
function ntw_install() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ INSTALLATION — NEXUS TUNNEL WEB${C_RESET}                               ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "  Ce script va installer l'interface web Nexus Tunnel."
  echo -e "  Vous aurez besoin de définir un identifiant admin."
  echo ""

  local src_dir
  if src_dir="$(resolve_web_source_dir)"; then
    bash "$src_dir/install.sh"
  elif [ -f /opt/nexus-tunnel-web/install.sh ]; then
    bash /opt/nexus-tunnel-web/install.sh
  else
    echo -e "  ${C_RED}✖ [ERROR] Source install script not found.${C_RESET}"
    echo -e "  Expected one of:"
    echo -e "    - /usr/local/sbin/nexus-web/install.sh"
    echo -e "    - /opt/nexus-tunnel-web/install.sh"
    echo -e "    - <repo>/nexus-web/install.sh"
    wait_key
    nexus_web_menu
    return
  fi

  rm -rf "$TMP_WEB_SRC" 2>/dev/null || true
  wait_key
  nexus_web_menu
}

# ─── CHANGE CREDENTIALS ───────────────────────────────────────────────────────
function ntw_change_credentials() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ MODIFIER IDENTIFIANTS ADMIN${C_RESET}                            ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  read -rp "  ► Username actuel : " curr_pass_user
  read -srp "  ► Mot de passe actuel : " curr_pass; echo ""
  echo ""

  local resp token_val
  resp=$(api_login "$curr_pass_user" "$curr_pass")
  token_val=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('token',''))" 2>/dev/null)

  if [ -z "$token_val" ]; then
    echo -e "  ${C_RED}✖ [ERROR] Identifiants incorrects.${C_RESET}"
    wait_key
    nexus_web_menu
    return
  fi

  echo -e "  ${C_GREEN}⚡ Authentification réussie!${C_RESET}"
  echo ""
  read -rp "  ► Nouveau username (vide=inchangé) : " new_user
  read -srp "  ► Nouveau mot de passe (vide=inchangé) : " new_pass; echo ""
  read -srp "  ► Confirmer nouveau mot de passe : " new_pass2; echo ""

  if [ -n "$new_pass" ] && [ "$new_pass" != "$new_pass2" ]; then
    echo -e "  ${C_RED}✖ [ERROR] Les mots de passe ne correspondent pas.${C_RESET}"
    wait_key
    nexus_web_menu
    return
  fi

  local body='{'
  body+="\"current_password\":\"$curr_pass\""
  [ -n "$new_user" ] && body+=",\"new_username\":\"$new_user\""
  [ -n "$new_pass" ] && body+=",\"new_password\":\"$new_pass\""
  body+='}'

  local result
  result=$(api_call "POST" "/auth/change-password" "$token_val" "$body")
  local msg
  msg=$(echo "$result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('message',d.get('error','')))" 2>/dev/null)

  if echo "$result" | grep -q '"message"'; then
    [ -n "$new_user" ] && { set_config_value admin_user "$new_user"; systemctl restart "$SERVICE" 2>/dev/null; }
    [ -n "$new_pass" ] && { set_config_value admin_password "$new_pass"; systemctl restart "$SERVICE" 2>/dev/null; }
    echo -e "  ${C_GREEN}⚡ [OK] $msg${C_RESET}"
  else
    echo -e "  ${C_RED}✖ [ERROR] $msg${C_RESET}"
  fi

  wait_key
  nexus_web_menu
}

# ─── MANAGER ADMIN ────────────────────────────────────────────────────────────
function ntw_manager_admin() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ ADMIN MANAGEMENT${C_RESET}                                              ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "   ${C_MAGENTA}[01]${C_RESET} CRÉER UN COMPTE ADMIN    ${C_MAGENTA}[04]${C_RESET} SUSPENDRE UN ADMIN"
  echo -e "   ${C_MAGENTA}[02]${C_RESET} VOIR LES ADMINS          ${C_MAGENTA}[05]${C_RESET} PROMOUVOIR EN SUPER_ADMIN"
  echo -e "   ${C_MAGENTA}[03]${C_RESET} MODIFIER UN ADMIN        ${C_GRAY}[00] RETOUR${C_RESET}"
  echo ""
  echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
  read -rp "  🜲 Select option : " opt
  echo ""

  local token
  token=$(ntw_get_token) || { nexus_web_menu; return; }

  case "$opt" in
    1|01) ntw_create_admin "$token" ;;
    2|02) ntw_list_admins "$token" ;;
    3|03) ntw_edit_admin "$token" ;;
    4|04) ntw_suspend_admin "$token" ;;
    5|05) ntw_promote_admin "$token" ;;
    0|00) nexus_web_menu ;;
    *) ntw_manager_admin ;;
  esac
}

function ntw_get_token() {
  local admin_user admin_pass token resp
  admin_user=$(get_config_value admin_user)
  admin_pass=$(get_config_value admin_password)

  resp=$(api_login "$admin_user" "$admin_pass")
  token=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('token',''))" 2>/dev/null)

  if [ -z "$token" ]; then
    echo -e "  ${C_RED}✖ Impossible de s'authentifier. Vérifiez le service.${C_RESET}" >&2
    wait_key >&2
    return 1
  fi
  echo "$token"
}

function ntw_create_admin() {
  local token="$1"
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CRÉER COMPTE ADMIN${C_RESET}                                            ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  read -rp "  ► Nouveau username : " new_user
  read -srp "  ► Mot de passe     : " new_pass; echo ""
  echo -e "  ► Rôle : ${C_CYAN}[1] Admin${C_RESET}  ${C_GOLD}[2] Super Admin${C_RESET}"
  read -rp "  ► Choix : " role_opt
  local role="admin"
  [ "$role_opt" = "2" ] && role="super_admin"

  local result
  result=$(api_call "POST" "/admins" "$token" \
    "{\"username\":\"$new_user\",\"password\":\"$new_pass\",\"role\":\"$role\"}")

  if echo "$result" | grep -q '"id"'; then
    echo -e "  ${C_GREEN}⚡ [OK] Admin '$new_user' ($role) créé avec succès!${C_RESET}"
  else
    local err
    err=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error','Unknown error'))" 2>/dev/null)
    echo -e "  ${C_RED}✖ [ERROR] $err${C_RESET}"
  fi

  wait_key
  ntw_manager_admin
}

function ntw_list_admins() {
  local token="$1"
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ LISTE DES ADMINS${C_RESET}                                              ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  local result
  result=$(api_call "GET" "/admins" "$token")

  echo "$result" | python3 -c "
import json, sys
admins = json.load(sys.stdin)
if isinstance(admins, dict) and 'error' in admins:
    print(f'  [ERROR] {admins[\"error\"]}')
else:
    print('\033[38;5;45m───────────────────────────────────────────────────────────────────\033[0m')
    print(f' {\"USERNAME\":<18} {\"ROLE\":<14} {\"STATUS\":<12} {\"CREATED\":<12}')
    print('\033[38;5;45m───────────────────────────────────────────────────────────────────\033[0m')
    for a in admins:
        print(f'  {a[\"username\"]:<18} {a[\"role\"]:<14} {a[\"status\"]:<12} {a[\"created_at\"][:10]:<12}')
    print('\033[38;5;45m───────────────────────────────────────────────────────────────────\033[0m')
" 2>/dev/null || echo "$result"

  wait_key
  ntw_manager_admin
}

function ntw_edit_admin() {
  local token="$1"
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ MODIFIER INFO ADMIN${C_RESET}                                           ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  local result
  result=$(api_call "GET" "/admins" "$token")
  echo "$result" | python3 -c "
import json, sys
admins = json.load(sys.stdin)
for i, a in enumerate(admins, 1):
    print(f'  [{i}] {a[\"username\"]} ({a[\"role\"]}) — ID: {a[\"id\"]}')
" 2>/dev/null

  echo ""
  read -rp "  ► Entrez l'ID de l'admin à modifier : " admin_id
  read -rp "  ► Nouveau username (vide=inchangé) : " nu
  read -srp "  ► Nouveau mot de passe (vide=inchangé) : " np; echo ""

  local body='{'
  local sep=""
  [ -n "$nu" ] && { body+="${sep}\"username\":\"$nu\""; sep=","; }
  [ -n "$np" ] && { body+="${sep}\"password\":\"$np\""; }
  body+='}'

  if [ "$body" = '{}' ]; then
    echo -e "  ${C_GOLD}[!] Aucune modification.${C_RESET}"
  else
    local res
    res=$(api_call "PUT" "/admins/$admin_id" "$token" "$body")
    if echo "$res" | grep -q '"message"'; then
      echo -e "  ${C_GREEN}⚡ [OK] Admin modifié.${C_RESET}"
    else
      local err
      err=$(echo "$res" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
      echo -e "  ${C_RED}✖ [ERROR] $err${C_RESET}"
    fi
  fi

  wait_key
  ntw_manager_admin
}

function ntw_suspend_admin() {
  local token="$1"
  clear
  read -rp "  ► ID de l'admin à suspendre : " admin_id
  local res
  res=$(api_call "POST" "/admins/$admin_id/suspend" "$token")
  if echo "$res" | grep -q '"message"'; then
    echo -e "  ${C_GREEN}⚡ [OK] Admin suspendu.${C_RESET}"
  else
    local err
    err=$(echo "$res" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
    echo -e "  ${C_RED}✖ [ERROR] $err${C_RESET}"
  fi
  wait_key
  ntw_manager_admin
}

function ntw_promote_admin() {
  local token="$1"
  clear
  read -rp "  ► ID de l'admin à promouvoir : " admin_id
  local res
  res=$(api_call "POST" "/admins/$admin_id/promote" "$token")
  if echo "$res" | grep -q '"message"'; then
    echo -e "  ${C_GREEN}⚡ [OK] Admin promu en super_admin!${C_RESET}"
  else
    local err
    err=$(echo "$res" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
    echo -e "  ${C_RED}✖ [ERROR] $err${C_RESET}"
  fi
  wait_key
  ntw_manager_admin
}

# ─── MANAGER CLIENT ───────────────────────────────────────────────────────────
function ntw_manager_client() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CLIENT MANAGEMENT${C_RESET}                                            ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "   ${C_MAGENTA}[01]${C_RESET} LISTE DES CLIENTS         ${C_MAGENTA}[04]${C_RESET} SUSPENDRE UN CLIENT"
  echo -e "   ${C_MAGENTA}[02]${C_RESET} CRÉER UN CLIENT           ${C_RED}[05]${C_RESET} SUPPRIMER UN CLIENT"
  echo -e "   ${C_MAGENTA}[03]${C_RESET} RENOUVELER UN CLIENT       ${C_GRAY}[00] RETOUR${C_RESET}"
  echo ""
  echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
  read -rp "  🜲 Select option : " opt
  echo ""

  local token
  token=$(ntw_get_token) || { nexus_web_menu; return; }

  case "$opt" in
    1|01) ntw_list_clients "$token" ;;
    2|02) ntw_create_client "$token" ;;
    3|03) ntw_renew_client "$token" ;;
    4|04) ntw_suspend_client "$token" ;;
    5|05) ntw_delete_client "$token" ;;
    0|00) nexus_web_menu ;;
    *) ntw_manager_client ;;
  esac
}

function ntw_list_clients() {
  local token="$1"
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ LISTE DES CLIENTS ACTIVÉS${C_RESET}                                    ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  local result
  result=$(api_call "GET" "/clients" "$token")

  echo "$result" | python3 -c "
import json, sys
clients = json.load(sys.stdin)
if isinstance(clients, dict) and 'error' in clients:
    print(f'  [ERROR] {clients[\"error\"]}')
else:
    print('\033[38;5;45m───────────────────────────────────────────────────────────────────\033[0m')
    print(f' {\"USERNAME\":<18} {\"PROTO\":<10} {\"STATUS\":<10} {\"EXPIRATION\":<12}')
    print('\033[38;5;45m───────────────────────────────────────────────────────────────────\033[0m')
    for c in clients:
        print(f'  {c[\"username\"]:<18} {c[\"protocol\"]:<10} {c[\"status\"]:<10} {str(c.get(\"expires_at\",\"\"))[:10]:<12}')
    print('\033[38;5;45m───────────────────────────────────────────────────────────────────\033[0m')
" 2>/dev/null || echo "$result"
  wait_key
  ntw_manager_client
}

function ntw_create_client() {
  local token="$1"
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CRÉER UN NOUVEAU CLIENT${C_RESET}                                      ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  read -rp "  ► Username         : " username
  read -rp "  ► Mot de passe     : " password
  echo -e "  ► Protocoles : ${C_CYAN}[1] SSH  [2] SlowDNS  [3] UDP Custom  [4] VMess  [5] VLESS  [6] Trojan  [7] ZiVPN${C_RESET}"
  read -rp "  ► Choix Protocole  : " proto_opt
  declare -A proto_map=([1]="ssh" [2]="slowdns" [3]="udpcustom" [4]="vmess" [5]="vless" [6]="trojan" [7]="zivpn")
  local protocol="${proto_map[$proto_opt]:-ssh}"
  read -rp "  ► Durée (jours)   : " days

  local result
  result=$(api_call "POST" "/clients" "$token" \
    "{\"username\":\"$username\",\"password\":\"$password\",\"protocol\":\"$protocol\",\"days\":$days}")

  if echo "$result" | grep -q '"id"'; then
    local expires
    expires=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('expires_at',''))" 2>/dev/null)
    echo ""
    echo -e "  ${C_GREEN}⚡ [OK] Client '$username' créé! Expiration: $expires${C_RESET}"
    echo "$result" | python3 -c "
import json, sys
d = json.load(sys.stdin)
ad = d.get('account_data', {})
if ad:
    print('\033[38;5;201m╔═════════════════════════════════════════════════════════════════╗\033[0m')
    print('\033[38;5;201m║\033[0m \033[1m\033[38;5;220m⚡ DÉTAILS DU COMPTE CRÉÉ\033[0m                                        \033[38;5;201m║\033[0m')
    print('\033[38;5;201m╠═════════════════════════════════════════════════════════════════╣\033[0m')
    for k, v in ad.items():
        if v:
            print(f'\033[38;5;201m║\033[0m  \033[38;5;255m{k:<15}\033[0m : {v:<44} \033[38;5;201m║\033[0m')
    print('\033[38;5;201m╚═════════════════════════════════════════════════════════════════╝\033[0m')
" 2>/dev/null
  else
    local err
    err=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error','Unknown'))" 2>/dev/null)
    echo -e "  ${C_RED}✖ [ERROR] $err${C_RESET}"
  fi

  wait_key
  ntw_manager_client
}

function ntw_renew_client() {
  local token="$1"
  clear
  read -rp "  ► ID du client : " client_id
  read -rp "  ► Jours de renouvellement : " days

  local result
  result=$(api_call "POST" "/clients/$client_id/renew" "$token" "{\"days\":$days}")
  if echo "$result" | grep -q '"expires_at"'; then
    local expires
    expires=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('expires_at',''))" 2>/dev/null)
    echo -e "  ${C_GREEN}⚡ [OK] Renouvelé! Nouvelle expiration: $expires${C_RESET}"
  else
    local err
    err=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
    echo -e "  ${C_RED}✖ [ERROR] $err${C_RESET}"
  fi
  wait_key
  ntw_manager_client
}

function ntw_suspend_client() {
  local token="$1"
  clear
  read -rp "  ► ID du client : " client_id
  local result
  result=$(api_call "POST" "/clients/$client_id/suspend" "$token")
  if echo "$result" | grep -q '"message"'; then
    echo -e "  ${C_GREEN}⚡ [OK] Client suspendu.${C_RESET}"
  else
    local err
    err=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
    echo -e "  ${C_RED}✖ [ERROR] $err${C_RESET}"
  fi
  wait_key
  ntw_manager_client
}

function ntw_delete_client() {
  local token="$1"
  clear
  read -rp "  ► ID du client à supprimer : " client_id
  read -rp "  ► Confirmer suppression? (oui/non) : " confirm
  if [[ "$confirm" != "oui" ]]; then
    echo -e "  ${C_GOLD}[!] Annulé.${C_RESET}"
    wait_key
    ntw_manager_client
    return
  fi
  local result
  result=$(api_call "DELETE" "/clients/$client_id" "$token")
  if echo "$result" | grep -q '"message"'; then
    echo -e "  ${C_GREEN}⚡ [OK] Client supprimé.${C_RESET}"
  else
    local err
    err=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
    echo -e "  ${C_RED}✖ [ERROR] $err${C_RESET}"
  fi
  wait_key
  ntw_manager_client
}

# ─── MANAGER PLANS ────────────────────────────────────────────────────────────
function ntw_manager_plans() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ OFFRES & PLANS D'ABONNEMENT${C_RESET}                                   ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"

  local token
  token=$(ntw_get_token) || { nexus_web_menu; return; }

  local result
  result=$(api_call "GET" "/plans" "$token")
  echo ""
  echo "$result" | python3 -c "
import json, sys
plans = json.load(sys.stdin)
if isinstance(plans, dict) and 'error' in plans:
    print(f'  [ERROR] {plans[\"error\"]}')
elif not plans:
    print('  Aucun plan créé.')
else:
    print('\033[38;5;45m───────────────────────────────────────────────────────────────────\033[0m')
    print(f' {\"NOM\":<18} {\"DURÉE\":<10} {\"PRIX\":<10} {\"MAX CONNS\":<12} {\"STATUT\"}')
    print('\033[38;5;45m───────────────────────────────────────────────────────────────────\033[0m')
    for p in plans:
        print(f'  {p[\"name\"]:<18} {str(p[\"duration_days\"])+\"j\":<10} {\$\"+str(p[\"price\"]):<10} {p[\"max_connections\"]:<12} {p[\"status\"]}')
    print('\033[38;5;45m───────────────────────────────────────────────────────────────────\033[0m')
" 2>/dev/null

  echo ""
  echo -e "   ${C_MAGENTA}[01]${C_RESET} CRÉER UN PLAN          ${C_GRAY}[00] RETOUR${C_RESET}"
  echo ""
  read -rp "  🜲 Select option : " opt

  case "$opt" in
    1|01) ntw_create_plan "$token" ;;
    0|00) nexus_web_menu ;;
    *) ntw_manager_plans ;;
  esac
}

function ntw_create_plan() {
  local token="$1"
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CRÉER UN PLAN D'ABONNEMENT${C_RESET}                                     ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  read -rp "  ► Nom du plan                : " name
  read -rp "  ► Description                : " desc
  read -rp "  ► Durée (jours)              : " days
  read -rp "  ► Prix ($, 0=gratuit)        : " price
  read -rp "  ► Protocoles (ssh,vmess,...) : " protos
  read -rp "  ► Max connexions             : " conns

  local protos_json
  protos_json=$(python3 -c "import json; print(json.dumps([p.strip() for p in '$protos'.split(',') if p.strip()]))" 2>/dev/null || echo '["ssh"]')

  local result
  result=$(api_call "POST" "/plans" "$token" \
    "{\"name\":\"$name\",\"description\":\"$desc\",\"duration_days\":$days,\"price\":${price:-0},\"protocols\":$protos_json,\"max_connections\":${conns:-1}}")

  if echo "$result" | grep -q '"id"'; then
    echo -e "  ${C_GREEN}⚡ [OK] Plan '$name' créé avec succès!${C_RESET}"
  else
    local err
    err=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
    echo -e "  ${C_RED}✖ [ERROR] $err${C_RESET}"
  fi

  wait_key
  ntw_manager_plans
}

# ─── LOGS & AUDIT ─────────────────────────────────────────────────────────────
function ntw_view_logs() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ JOURNAL AUDIT & LOGS SYSTEME${C_RESET}                                 ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""

  local token
  token=$(ntw_get_token) || { nexus_web_menu; return; }

  local result
  result=$(api_call "GET" "/logs?limit=30" "$token")

  echo "$result" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if 'error' in data:
    print(f'  [ERROR] {data[\"error\"]}')
else:
    logs = data.get('logs', [])
    print(f'  Total: {data.get(\"total\", 0)} entrées (30 plus récentes)')
    print('\033[38;5;45m───────────────────────────────────────────────────────────────────\033[0m')
    print(f' {\"DATE\":<18} {\"ADMIN\":<14} {\"ACTION\":<22} {\"CIBLE\"}')
    print('\033[38;5;45m───────────────────────────────────────────────────────────────────\033[0m')
    for l in logs:
        dt = l[\"created_at\"][:19].replace(\"T\", \" \")
        print(f'  {dt:<18} {(l[\"admin_username\"] or \"-\"):<14} {l[\"action\"]:<22} {l[\"target_type\"] or \"-\"}')
    print('\033[38;5;45m───────────────────────────────────────────────────────────────────\033[0m')
" 2>/dev/null || echo "$result"

  wait_key
  nexus_web_menu
}

# ─── SERVICE CONTROL ─────────────────────────────────────────────────────────
function ntw_service_control() {
  clear
  local active_status
  active_status=$(systemctl is-active $SERVICE 2>/dev/null)
  
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_CYAN}❖ CONTRÔLE DE SERVICE SYSTEMD${C_RESET}                                   ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╠═════════════════════════════════════════════════════════════════╣${C_RESET}"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Service${C_RESET} : %-53s ${C_MAGENTA}║${C_RESET}\n" "$SERVICE"
  printf "${C_MAGENTA}║${C_RESET}  ${C_WHITE}Status${C_RESET}  : %-53s ${C_MAGENTA}║${C_RESET}\n" "$active_status"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "   ${C_GREEN}[01]${C_RESET} DÉMARRER               ${C_GREEN}[03]${C_RESET} REDÉMARRER"
  echo -e "   ${C_RED}[02]${C_RESET} ARRÊTER                ${C_BLUE}[04]${C_RESET} JOURNALS SYSTEMD"
  echo ""
  echo -e "   ${C_GRAY}[00] RETOUR${C_RESET}"
  echo ""
  echo -e "${C_GRAY}───────────────────────────────────────────────────────────────────${C_RESET}"
  read -rp "  🜲 Select option : " opt

  case "$opt" in
    1|01) systemctl start "$SERVICE" && echo -e "  ${C_GREEN}⚡ Service démarré.${C_RESET}" ;;
    2|02) systemctl stop "$SERVICE" && echo -e "  ${C_RED}✖ Service arrêté.${C_RESET}" ;;
    3|03) systemctl restart "$SERVICE" && echo -e "  ${C_GREEN}⚡ Service redémarré.${C_RESET}" ;;
    4|04) journalctl -u "$SERVICE" -n 50 --no-pager | less -F ;;
    0|00) nexus_web_menu; return ;;
    *) ;;
  esac

  wait_key
  ntw_service_control
}

# ─── UPDATE ──────────────────────────────────────────────────────────────────
function ntw_update() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_GOLD}❖ MISE À JOUR — NEXUS TUNNEL WEB${C_RESET}                                ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "  Cette option télécharge la dernière version depuis GitHub"
  echo -e "  et redéploie le panel en conservant vos données (DB, config)."
  read -rp "  ► Continuer? (oui/non) : " confirm

  if [[ "$confirm" != "oui" ]]; then
    echo -e "  ${C_GOLD}[!] Annulé.${C_RESET}"
    wait_key
    nexus_web_menu
    return
  fi

  local tmp_src
  tmp_src="$(mktemp -d)"

  log_info "Téléchargement de la dernière version depuis GitHub..."
  if ! git clone --depth 1 "$NEXUS_REPO_URL" "$tmp_src" 2>&1 | tail -5; then
    echo -e "  ${C_RED}✖ [ERROR] Impossible de cloner depuis GitHub.${C_RESET}"
    rm -rf "$tmp_src"
    wait_key
    nexus_web_menu
    return
  fi

  local src_dir="$tmp_src/nexus-web"
  if [ ! -d "$src_dir" ] || [ ! -f "$src_dir/install.sh" ]; then
    echo -e "  ${C_RED}✖ [ERROR] Dossier nexus-web introuvable.${C_RESET}"
    rm -rf "$tmp_src"
    wait_key
    nexus_web_menu
    return
  fi

  log_info "Copie des nouveaux fichiers dans $NEXUS_WEB_DIR..."
  cp -rf "$src_dir"/. "$NEXUS_WEB_DIR/"

  log_info "Application des correctifs (PUBLIC_DIR, CORS)..."
  sed -i "s|const PUBLIC_DIR = .*|const PUBLIC_DIR = '/opt/nexus-tunnel-web/public';|g" \
      "$NEXUS_WEB_DIR/server/index.ts" 2>/dev/null || true
  sed -i 's/callback(null, false);/callback(null, true);/g' \
      "$NEXUS_WEB_DIR/server/index.ts" 2>/dev/null || true

  log_info "Compilation de l'interface graphique (frontend)..."
  if [ -d "$NEXUS_WEB_DIR/frontend" ]; then
    cd "$NEXUS_WEB_DIR/frontend"
    npm install --quiet 2>&1 | tail -3
    npm run build 2>&1 | tail -8
  fi

  log_info "Compilation du serveur Node.js..."
  cd "$NEXUS_WEB_DIR"
  npm install --production=false --quiet 2>&1 | tail -3
  npm run build 2>&1 | tail -5

  log_info "Nettoyage et redémarrage du service..."
  rm -rf "$tmp_src"

  if [ -f "$NEXUS_WEB_DIR/install.sh" ]; then
    bash "$NEXUS_WEB_DIR/install.sh" --watchdog-only 2>/dev/null || true
  fi

  if [ ! -f /etc/cron.d/nexus-web-watchdog ]; then
    echo "* * * * * root /usr/local/bin/nexus-web-watchdog.sh" > /etc/cron.d/nexus-web-watchdog
    chmod 644 /etc/cron.d/nexus-web-watchdog
  fi

  systemctl restart "$SERVICE"
  sleep 2

  echo -e "  ${C_GREEN}⚡ [OK] Mise à jour terminée ! Le panel est maintenant à jour.${C_RESET}"
  wait_key
  nexus_web_menu
}

# ─── UNINSTALL ────────────────────────────────────────────────────────────────
function ntw_uninstall() {
  clear
  echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_MAGENTA}║${C_RESET} ${C_BOLD}${C_RED}❖ DÉSINSTALLER NEXUS TUNNEL WEB${C_RESET}                                ${C_MAGENTA}║${C_RESET}"
  echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════════════════════╝${C_RESET}"
  echo ""
  echo -e "  ${C_RED}ATTENTION: Cette action supprimera l'interface web.${C_RESET}"
  read -rp "  ► Confirmer la désinstallation? (oui/non) : " confirm

  if [[ "$confirm" != "oui" ]]; then
    echo -e "  ${C_GOLD}[!] Annulé.${C_RESET}"
    wait_key
    nexus_web_menu
    return
  fi

  read -rp "  ► Conserver les données (DB, config)? (oui/non) : " keep_data

  echo -e "  ${C_GOLD}[INFO] Arrêt du service...${C_RESET}"
  systemctl stop "$SERVICE" 2>/dev/null || true
  systemctl disable "$SERVICE" 2>/dev/null || true
  rm -f "/etc/systemd/system/$SERVICE.service"
  systemctl daemon-reload

  echo -e "  ${C_GOLD}[INFO] Suppression des fichiers...${C_RESET}"
  rm -rf "$NEXUS_WEB_DIR"

  if [[ "$keep_data" != "oui" ]]; then
    rm -rf "$CONFIG_DIR"
    echo -e "  ${C_RED}[!] Données supprimées.${C_RESET}"
  else
    echo -e "  ${C_GREEN}⚡ Données conservées dans $CONFIG_DIR${C_RESET}"
  fi

  echo -e "  ${C_GREEN}⚡ [OK] Nexus Tunnel Web désinstallé.${C_RESET}"
  wait_key
  menu
}

# ─── ENTRY POINT ─────────────────────────────────────────────────────────────
nexus_web_menu

