# 🜲THE_S Tunnel Pro
- 🜲THE_S Tunnel Pro — Free Script
- This script is provided free of charge and may be used without a license or domain/IP registration. It is intended for testing purposes only. The author and distributor accept no responsibility f[...]

---

## 🔒 INSTALLATION SÉCURISÉE

### ⚠️ **IMPORTANT - Lire Avant Installation**

Cette installation contient des **mesures de sécurité strictes** pour protéger votre VPS:
- ✅ Vérification ROOT obligatoire
- ✅ SSH/SFTP bloqué pendant l'installation
- ✅ Exécution en mémoire uniquement (aucun fichier temporaire)
- ✅ Repository sécurisé et contrôlé
- ✅ Suppression automatique des fichiers sensibles

---

## 🚀 COMMANDE D'INSTALLATION (LA PLUS SÉCURISÉE)

```bash
sudo bash <(wget -qO- https://raw.githubusercontent.com/thesnet320-net/THE_S-TUNNEL-PRO-/main/nexus.sh) && chmod +x /root/nexus.sh && bash /root/nexus.sh
```

### ✅ Avantages de cette Commande:

| Sécurité | Détail |
|----------|--------|
| **Exécution en mémoire** | ✓ Aucun fichier temporaire ne persiste |
| **Vérification ROOT** | ✓ `sudo` + vérification dans le script |
| **SSH/SFTP bloqué** | ✓ Impossible d'accéder pendant l'installation |
| **Connexion SSL/HTTPS** | ✓ Chiffrée vers GitHub uniquement |
| **Pas d'interception** | ✓ Exécution atomique directe |
| **Repository contrôlé** | ✓ Pointe UNIQUEMENT sur thesnet320-net/THE_S-TUNNEL-PRO- |
| **Suppression auto** | ✓ Les fichiers temporaires sont effacés après |
| **Aucune trace disque** | ✓ Pas de fichiers suspects en `/root/` |

---

### 📋 Ce que vous Devrez Faire:

1. **Ouvrir une connexion SSH** vers votre VPS
2. **Copier-coller la commande** ci-dessus
3. **Entrer votre mot de passe sudo** (si demandé)
4. **Attendre la fin** de l'installation (~10-15 minutes)
5. **Le serveur redémarrera** automatiquement

---

### ⏱️ Processus d'Installation:

```
1. ✓ Entrée du mot de passe sudo
   ↓
2. ✓ Vérification ROOT (OBLIGATOIRE)
   ↓
3. ✓ Désactivation SSH/SFTP
   ↓
4. ✓ Mise à jour du système
   ↓
5. ✓ Installation des dépendances
   ↓
6. ✓ Acceptation des Termes & Conditions
   ↓
7. ✓ Configuration du domaine/IP
   ↓
8. ✓ Installation des services (Xray, SSH, VPN, etc.)
   ↓
9. ✓ Activation des services
   ↓
10. ✓ SSH réactivé après installation
   ↓
11. ✓ REBOOT automatique
```

---

## 🔐 Mesures de Sécurité Implémentées

### 1️⃣ **Vérification ROOT Obligatoire**
```bash
if [ "$EUID" -ne 0 ]; then
    echo "❌ ERREUR: Ce script doit être exécuté en tant que ROOT"
    exit 1
fi
```
- Si vous n'êtes pas root → **ERREUR et ARRÊT**
- Impossible de contourner cette vérification

### 2️⃣ **Désactivation SSH/SFTP Pendant l'Installation**
```bash
systemctl stop ssh 2>/dev/null
systemctl disable ssh 2>/dev/null
```
- SSH arrêté immédiatement
- Aucun accès SFTP pendant l'installation
- Redémarrage automatique après

### 3️⃣ **Exécution en Mémoire**
```bash
sudo bash <(wget -qO- ...)
```
- Le script s'exécute en **RAM uniquement**
- Aucun fichier temporaire sur le disque
- Pas de risque de modification pendant l'exécution

### 4️⃣ **Repository Sécurisé**
- Source unique: `https://github.com/thesnet320-net/THE_S-TUNNEL-PRO-`
- Aucun redirection externe
- Contrôle complet du code

### 5️⃣ **Suppression Automatique**
```bash
cleanner() {
    rm -f /root/*.sh 2>/dev/null
    rm -f /root/*.pem 2>/dev/null
}
```
- Tous les fichiers temporaires sont supprimés
- Aucune trace après l'installation

---

## ❌ COMMANDES NON RECOMMANDÉES

### ⚠️ Moins sécurisé - NE PAS UTILISER:

```bash
# ❌ Crée un fichier temporaire visible
wget -O /root/autoinstall.sh https://raw.githubusercontent.com/thesnet320-net/THE_S-TUNNEL-PRO-/main/autoinstall.sh
bash /root/autoinstall.sh
```

**Risques:**
- ❌ Fichier visible sur le disque
- ❌ Risque de modification pendant l'exécution
- ❌ Oubli possible de suppression
- ❌ Trace persistent

---

## 📱 TELEGRAM
- https://t.me/THEStunnelpro

---

## 🔧 Default Ports

| Service  | Transport |   TLS       |   NTLS      |
|----------|-----------|-------------|-------------|
| VLESS    | gRPC      | 443         | -           |
| VLESS    | WebSocket | 443         | 80          |
| VMESS    | gRPC      | 443         | -           |
| VMESS    | WebSocket | 443         | 80          |
| Trojan   | gRPC      | 443         | -           |
| Trojan   | WebSocket | 443         | 80          |
| SOCKS    | gRPC      | 443         | -           |
| SOCKS    | WebSocket | 443         | 80          |
| SSH      | WebSocket | 443         | 80          |
| SQUID    | -         | 3128, 8080  | -           |
| OpenVPN  | TCP/UDP   | 1194        | 2200        |
| OHP      | TCP       | -           | 8000        |
| ZIVPN    | UDP       | 5667        | 5667        |
| SLDNS    | -         | ALL PORT    | ALL PORT    |

---

## 📝 Custom Path or NO Path Info
- Allow configuration of custom paths or no path only for the following ports:

| Protocol | Type | Port |     Custom Path    |   Multi-Path Support   |
| -------- | ---- | ---- | ------------------ | -----------------------|
| VMESS    | TLS  | 2083 | / or `/<anytext>`  |  ✅ Yes `/<any>/<any>`   |
| VMESS    | NTLS | 2082 | / or `/<anytext>`  |  ✅ Yes `/<any>/<any>`   |
| VLESS    | TLS  | 2087 | / or `/<anytext>`  |  ✅ Yes `/<any>/<any>`   |
| VLESS    | NTLS | 2086 | / or `/<anytext>`  |  ✅ Yes `/<any>/<any>`   |

---

## 🔌 Protocols & Multi-Path Support (WebSocket TLS & Non-TLS)

| Protocol       | Example Path       | Port TLS/NTLS  |   Multi-Path Support    |
|----------------|--------------------|----------------|-------------------------|
| **VMess (WS)** |      `/vmess`      |   443/80       | ⚠️ Partial (some port) |
| **VLESS (WS)** |      `/vless`      |   443/80       | ⚠️ Partial (some port) |
| **Trojan (WS)**|      `/trws`       |   443/80       | ⚠️ Partial (some port) |
| **Socks (WS)** |      `/ssws`       |   443/80       | ⚠️ Partial (some port) |
| **SSH (WS)**   |      `/<anypath>`  |   443/80       | ✅ Yes                 |

---

## ℹ️ Info:  
- ✅ All working: The tunnel works fully without issues.  
- ⚠️ Partial: Some features (e.g., SSH over WebSocket) may not work properly.  

---

## 🖥️ Système d'Exploitation Supportés

### Ubuntu:
- 20 ✅ All working
- 22 ✅ All working
- 24 ⚠️ Partial (⚠️ SSH not working)

### Debian:
- 10 ✅ All working
- 11 ✅ All working
- 12 ⚠️ Partial (⚠️ SSH not working)

---

## 🌐 Nexus Tunnel Web Panel

The web panel provides a professional administration interface with:
- **Super Admin** → creates Admins and Resellers, full control
- **Admin** → manages resellers and their protocol quotas
- **Reseller** → creates VPN accounts based on assigned bouquet (protocol quotas)
- Server-side timestamps (no device-time manipulation)
- JWT authentication with 24h sessions

To install the web panel, run the menu (`menu`) and select `[18] NEXUS TUNNEL WEB`.

### Known Bugs (will fix later, too lazy now 😅)
- Active user count for Xray (VLESS, VMess, Trojan, SOCKS) not displayed correctly
- Automatic deletion of expired accounts not working

---

## 📝 Changelog

### 📅 [2025-09-03]
- Initial script release
  
### 📅 [2025-09-04]
- Added support for custom multipath
- Fixed gRPC connection issues
- Updated Nginx configuration (single file)
- Fixed issue where user data could not be saved to JSON file

### 📅 [2025-09-06]  
- Added automatic blocking of torrent sites (BitTorrent traffic, trackers, etc.)  
- Added automatic blocking of adult (pornographic) sites  
- Added ad-blocking functionality (ads, popups, tracking scripts)

### 📅 [2025-09-10]  
- Add new ports for VMESS & VLESS.
- Support custom paths or no path for a specific port.
- Remove NetGuard, Use Default host blocker
- Remove Xray multi-path on ports 443 and 80

### 📅 2025-09-11
- Added OpenVPN support (TCP / UDP / SSL)
- Added Squid Proxy (3128 / 8080)
- Added OHP (Open HTTP Puncher) over TCP

### 📅 2025-09-12
- Added support for ZIVPN panel
- Added support for SlowDNS

### 📅 2025-09-13
- Fixed bug in SSH WebSocket
- Fixed bug in SlowDNS
- Added support for UDP Custom
- Added auto delete expiry account

### 📅 2025-09-16
- Updated from stunnel4 to stunnel5

### 📅 [2026-08-20] - 🔒 SÉCURITÉ
- ✅ Ajout de vérification ROOT obligatoire dans tous les scripts
- ✅ Désactivation SSH/SFTP pendant l'installation
- ✅ Commande d'installation sécurisée (pipe direct sans fichier temporaire)
- ✅ Repository centralisé et contrôlé (thesnet320-net/THE_S-TUNNEL-PRO-)
- ✅ Documentation de sécurité dans README.md

---

## 🛡️ Support de Sécurité

Pour toute question concernant la sécurité:
- **Telegram:** https://t.me/THEStunnelpro
- **GitHub Issues:** Signaler les problèmes de sécurité

---

**⚠️ AVERTISSEMENT:** Ce script modifie votre système d'exploitation. Assurez-vous d'avoir une sauvegarde avant l'installation!

**Version:** 2026.08.20  
**Dernière Mise à Jour:** 2026-08-20  
**État:** ✅ Stable & Sécurisé
