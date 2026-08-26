````markdown
# 🛠️ GUIDE DE CORRECTION ET IMPLÉMENTATION

**Dépôt**: https://github.com/wilfriedekongolo320-coder/Clone-THE_S-TUNNEL-  
**Date**: 2026-08-26  
**Objectif**: Corriger les problèmes critiques des protocoles  
**Temps estimé**: 2-3 heures  
**Difficulté**: Intermédiaire

---

## 📋 TABLE DES MATIÈRES

1. [Corrections Immédiates](#corrections-immédiates)
2. [Créer les Scripts Core](#créer-les-scripts-core)
3. [Configurer Nginx](#configurer-nginx)
4. [Gérer les Certificats](#gérer-les-certificats)
5. [Valider l'Installation](#valider-linstallation)
6. [Tester les Protocoles](#tester-les-protocoles)

---

## 🚨 CORRECTIONS IMMÉDIATES

### ÉTAPE 1: Corriger `nexus.sh` (Ligne 176)

**Fichier**: `nexus.sh`

**Problème**: Nginx est supprimé puis le script essaie de le redémarrer

**Action**:

```bash
# AVANT ❌
apt-get remove --purge -y ufw firewalld exim4 nginx* dropbear* apache2*

# APRÈS ✅
apt-get remove --purge -y ufw firewalld exim4 dropbear* apache2*
# nginx n'est pas supprimé, seulement réinstallé avec config
```

**Comment appliquer**:
```bash
# Option 1: Éditer directement
sed -i 's/apt-get remove --purge -y ufw firewalld exim4 nginx\* dropbear\* apache2\*/apt-get remove --purge -y ufw firewalld exim4 dropbear* apache2*/' nexus.sh

# Option 2: Édition manuelle
nano nexus.sh  # Ligne 176, supprimer "nginx*"
```

**Commit**:
```bash
git add nexus.sh
git commit -m "🔧 URGENT: Ne pas supprimer nginx (problème ligne 176)"
git push origin main
```

---

### ÉTAPE 2: Ajouter Fonction de Validation (Ligne 348)

**Fichier**: `nexus.sh`

**Ajouter avant la ligne 348** (avant `doty_completed()`):

```bash
# ✓ VALIDATION POST-INSTALLATION
verify_installation() {
    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}    VALIDATION POST-INSTALLATION              ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo ""
    
    local ERRORS=0
    
    # Vérifier les services critiques
    echo -e "${LN}● Services:${NC}"
    for service in xray nginx ssh; do
        if systemctl is-active --quiet $service 2>/dev/null; then
            echo -e "  ${GR}✓${NC} $service is running"
        else
            echo -e "  ${RD}✗${NC} $service is NOT running"
            ((ERRORS++))
        fi
    done
    
    echo ""
    echo -e "${LN}● Ports d'écoute:${NC}"
    for port in 443 80 10000 6900; do
        if netstat -tlnp 2>/dev/null | grep -q ":$port " || ss -tlnp 2>/dev/null | grep -q ":$port "; then
            echo -e "  ${GR}✓${NC} Port $port is listening"
        else
            echo -e "  ${RD}✗${NC} Port $port NOT listening"
            ((ERRORS++))
        fi
    done
    
    echo ""
    echo -e "${LN}● Certificats SSL:${NC}"
    if [ -f /etc/xray/cert.crt ]; then
        EXPIRY=$(openssl x509 -in /etc/xray/cert.crt -noout -enddate 2>/dev/null | cut -d= -f2)
        echo -e "  ${GR}✓${NC} Certificate found (expires: $EXPIRY)"
    else
        echo -e "  ${RD}✗${NC} Certificate NOT found (/etc/xray/cert.crt)"
        ((ERRORS++))
    fi
    
    echo ""
    echo -e "${LN}● Configuration Nginx:${NC}"
    if [ -f /etc/nginx/sites-enabled/xray ]; then
        if nginx -t 2>&1 | grep -q "successful"; then
            echo -e "  ${GR}✓${NC} Nginx config is valid"
        else
            echo -e "  ${RD}✗${NC} Nginx config has errors"
            ((ERRORS++))
        fi
    else
        echo -e "  ${RD}✗${NC} Nginx config not found"
        ((ERRORS++))
    fi
    
    echo ""
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    if [ $ERRORS -eq 0 ]; then
        echo -e "${LN}┃${NC} ${GR}✓ ALL CHECKS PASSED! Installation is OK.${NC} ${LN}┃${NC}"
    else
        echo -e "${LN}┃${NC} ${RD}✗ $ERRORS ERRORS FOUND! Review above.${NC} ${LN}┃${NC}"
    fi
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo ""
    
    return $ERRORS
}
```

**Modifier la fonction `main()` pour appeler la validation**:

```bash
main() {
    check_root_virt
    check_os
    setup_host_time
    prepare_env
    update_system
    install_packages
    show_tns
    run_scripts
    install_menu
    setup_ssh_banner
    setup_profile
    setup_autoreboot
    setup_autolog
    setup_autoexp
    enable_bbr
    restart_services
    set_version
    
    # ✓ AJOUTER CES LIGNES
    verify_installation || {
        echo -e "${RD}Installation verification failed!${NC}"
        echo "Fix the errors above before rebooting."
        exit 1
    }
    
    doty_completed
    cleanner
    echo "Installation finished. Server will reboot in 10 seconds."
    sleep 10
    reboot
}
```

---

## 📁 CRÉER LES SCRIPTS CORE

### Structure à créer:

```
Clone-THE_S-TUNNEL-/
└── core/
    ├── xray.sh              ← Installer Xray
    ├── sshws.sh             ← SSH WebSocket via Stunnel5
    ├── setup_dns.sh         ← DNS & SlowDNS
    ├── setup_zivpn.sh       ← ZipVPN
    ├── setup_udp.sh         ← UDP Custom
    ├── vpn.sh               ← OpenVPN
    ├── websocket.sh         ← Config WebSocket (nginx)
    ├── setup_ssh_banner.sh  ← Bannière SSH
    └── validator.sh         ← Validateur
```

---

### Créer: `/core/xray.sh`

**Fichier**: `core/xray.sh`

```bash
#!/bin/bash

# Installation Xray (VLESS, VMESS, Trojan, SOCKS)

set -e

echo "[*] Installing Xray Core..."

# Télécharger la dernière version de Xray
XRAY_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep tag_name | cut -d'"' -f4 | sed 's/v//')

if [ -z "$XRAY_VERSION" ]; then
    echo "❌ Failed to fetch Xray version"
    exit 1
fi

echo "[*] Xray version: $XRAY_VERSION"

# Créer le répertoire
mkdir -p /usr/local/bin /etc/xray /var/log/xray

# Télécharger et installer
cd /tmp
wget -q "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-64.zip"
unzip -o Xray-linux-64.zip -d /usr/local/bin/
chmod +x /usr/local/bin/xray

# Créer configuration minimale
cat > /etc/xray/config.json <<'EOF'
{
  "log": {
    "loglevel": "info",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "port": 10000,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
            "level": 0,
            "alterId": 0
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF

chmod 644 /etc/xray/config.json
chown nobody:nogroup /etc/xray/config.json

# Créer service systemd
cat > /etc/systemd/system/xray.service <<'EOF'
[Unit]
Description=Xray Service
After=network.target

[Service]
Type=simple
User=nobody
WorkingDirectory=/etc/xray
ExecStart=/usr/local/bin/xray -c /etc/xray/config.json
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Activer et démarrer
systemctl daemon-reload
systemctl enable xray
systemctl start xray

echo "[✓] Xray installed successfully"
```

---

### Créer: `/core/websocket.sh`

**Fichier**: `core/websocket.sh`

```bash
#!/bin/bash

# Configuration Nginx pour WebSocket

set -e

echo "[*] Configuring Nginx for WebSocket support..."

DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "example.com")

# Créer configuration Nginx
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

cat > /etc/nginx/sites-available/xray <<EOF
upstream xray_backend {
    server 127.0.0.1:10000;
}

server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN;
    
    ssl_certificate /etc/xray/cert.crt;
    ssl_certificate_key /etc/xray/key.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Root location
    location / {
        return 404;
    }
    
    # VLESS WebSocket
    location /vless {
        proxy_pass http://xray_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 86400;
    }
    
    # VMESS WebSocket
    location /vmess {
        proxy_pass http://xray_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_read_timeout 86400;
    }
    
    # Trojan
    location /trojan {
        proxy_pass http://xray_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }
}
EOF

# Activer la configuration
if [ ! -L /etc/nginx/sites-enabled/xray ]; then
    ln -s /etc/nginx/sites-available/xray /etc/nginx/sites-enabled/xray
fi

# Tester la configuration
if nginx -t; then
    systemctl restart nginx
    echo "[✓] Nginx configured successfully"
else
    echo "❌ Nginx config error!"
    exit 1
fi
```

---

### Créer: `/core/setup_ssh_banner.sh`

**Fichier**: `core/setup_ssh_banner.sh`

```bash
#!/bin/bash

# Configuration bannière SSH

cat > /etc/ssh/banner <<'EOF'
╔════════════════════════════════════════════════════════════════╗
║                  🜲 THE_S TUNNEL PRO                           ║
║                                                                ║
║  Welcome to THE_S Tunnel Pro SSH Service                      ║
║  All activities are monitored and logged                      ║
║  Unauthorized access is prohibited                            ║
╚════════════════════════════════════════════════════════════════╝
EOF

chmod 644 /etc/ssh/banner

# Configurer sshd
if ! grep -q "^Banner" /etc/ssh/sshd_config; then
    echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config
fi

systemctl restart ssh

echo "[✓] SSH banner configured"
```

---

## 🔐 GÉRER LES CERTIFICATS

### Générer Certificats Let's Encrypt

**Script**: À ajouter dans `nexus.sh` après `show_tns()`:

```bash
setup_certificates() {
    local DOMAIN=$(cat /etc/xray/domain)
    local EMAIL="admin@${DOMAIN}"
    
    echo "[*] Requesting Let's Encrypt certificate for $DOMAIN..."
    
    # Arrêter nginx temporairement
    systemctl stop nginx
    
    # Demander le certificat
    certbot certonly --standalone \
        -d "$DOMAIN" \
        --email "$EMAIL" \
        --agree-tos \
        -n \
        --rsa-key-size 2048
    
    # Copier les certificats
    cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/xray/cert.crt
    cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /etc/xray/key.key
    chmod 755 /etc/xray/cert.crt
    chmod 755 /etc/xray/key.key
    
    # Redémarrer nginx
    systemctl start nginx
    
    echo "[✓] Certificate installed successfully"
}
```

**Ajouter un renouvellement automatique**:

```bash
# Ajouter à /etc/crontab
0 3 * * * root certbot renew --quiet && cp /etc/letsencrypt/live/*/fullchain.pem /etc/xray/cert.crt && cp /etc/letsencrypt/live/*/privkey.pem /etc/xray/key.key && systemctl restart nginx
```

---

## ✅ VALIDER L'INSTALLATION

### Checklist Post-Installation

**Sur le serveur**, exécuter:

```bash
#!/bin/bash

echo "=== VALIDATION INSTALLATION THE_S TUNNEL PRO ==="
echo ""

# 1. Services
echo "📋 Services Status:"
systemctl status xray --no-pager | head -5
systemctl status nginx --no-pager | head -5
echo ""

# 2. Ports
echo "📡 Ports Listening:"
netstat -tlnp 2>/dev/null | grep -E 'Proto|:80 |:443 |:10000 |:6900 '
echo ""

# 3. Certificat
echo "🔐 Certificate Status:"
openssl x509 -in /etc/xray/cert.crt -noout -text 2>/dev/null | grep -E 'Subject:|Not Before|Not After' || echo "Certificate not found!"
echo ""

# 4. Config Xray
echo "⚙️  Xray Config:"
xray -c /etc/xray/config.json -test 2>&1 | tail -3
echo ""

# 5. Nginx
echo "🌐 Nginx Test:"
nginx -t 2>&1 | tail -1
echo ""

echo "✓ Validation complete"
```

---

## 🧪 TESTER LES PROTOCOLES

### Test 1: Connectivité HTTP/HTTPS

```bash
# HTTP -> HTTPS redirect
curl -I http://your-domain.com
# Expected: 301 Location: https://...

# HTTPS
curl -kI https://your-domain.com
# Expected: 200 OK
```

### Test 2: WebSocket

```bash
# Test WebSocket upgrade
curl -kI -H "Upgrade: websocket" -H "Connection: Upgrade" https://your-domain.com/vless
# Expected: 101 Switching Protocols (ou erreur d'authentification Xray)
```

### Test 3: Configuration Xray

```bash
# Tester la config Xray
xray -c /etc/xray/config.json -test
# Expected: Configuration OK

# Voir les logs
journalctl -u xray -f
```

### Test 4: Logs

```bash
# Logs Xray
tail -f /var/log/xray/access.log
tail -f /var/log/xray/error.log

# Logs Nginx
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

---

## 📝 RÉSUMÉ DES ACTIONS

| Étape | Action | Priorité | Temps |
|-------|--------|----------|-------|
| 1 | Corriger nginx (ligne 176) | 🔴 CRITIQUE | 5 min |
| 2 | Ajouter validation | 🟡 HAUTE | 10 min |
| 3 | Créer /core/xray.sh | 🔴 CRITIQUE | 15 min |
| 4 | Créer /core/websocket.sh | 🔴 CRITIQUE | 10 min |
| 5 | Créer /core/setup_ssh_banner.sh | 🟡 HAUTE | 5 min |
| 6 | Configurer certificats | 🔴 CRITIQUE | 20 min |
| 7 | Tester installation | 🟡 HAUTE | 15 min |
| **TOTAL** | | | **80 min** |

---

## 🚀 DÉPLOIEMENT

**Une fois les corrections appliquées**:

```bash
# 1. Commit et push
git add .
git commit -m "🔧 CRITICAL FIX: Nginx + Core scripts + Validation"
git push origin main

# 2. Tester sur une VM
cd /tmp
sudo bash <(wget -qO- https://raw.githubusercontent.com/wilfriedekongolo320-coder/Clone-THE_S-TUNNEL-/main/nexus.sh)

# 3. Valider avec le checklist
# Voir section "Valider l'installation"

# 4. Documenter les résultats
```

---

**Guide créé**: 2026-08-26  
**Statut**: 🟢 PRÊT À IMPLÉMENTER  
**Questions?** Consulter DIAGNOSTIC_PROTOCOLES.md

````
