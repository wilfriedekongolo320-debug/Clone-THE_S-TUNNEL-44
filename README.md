````markdown
# 🜲THE_S Tunnel Pro - Clone Personnel

**Dépôt OFFICIEL**: 

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

```# 1. Télécharger et inspecter
wget https://raw.githubusercontent.com/thesnet320-source/THE_S-TUNNEL-PRO-/main/autoinstall.sh
cat autoinstall.sh  # Vérifier le contenu

# 2. Exécuter après vérification
sudo bash autoinstall.sh
```

### ✅ Avantages de cette Commande:

| Sécurité | Détail |
|----------|--------|
| **Exécution en mémoire** | ✓ Aucun fichier temporaire ne persiste |
| **Vérification ROOT** | ✓ `sudo` + vérification dans le script |
| **SSH/SFTP bloqué** | ✓ Impossible d'accéder pendant l'installation |
| **Connexion SSL/HTTPS** | ✓ Chiffrée vers GitHub uniquement |
| **Pas d'interception** | ✓ Exécution atomique directe |
| **Repository contrôlé** | ✓ Pointe UNIQUEMENT sur wilfriedekongolo320-coder/Clone-THE_S-TUNNEL- |
| **Suppression auto** | ✓ Les fichiers temporaires sont effacés après |
| **Aucune trace disque** | ✓ Pas de fichiers suspects en `/root/` |

---

## 📋 Ce que vous Devrez Faire:

1. **Ouvrir une connexion SSH** vers votre VPS
2. **Copier-coller la commande** ci-dessus
3. **Entrer votre mot de passe sudo** (si demandé)
4. **Attendre la fin** de l'installation (~10-15 minutes)
5. **Le serveur redémarrera** automatiquement

---

## ⏱️ Processus d'Installation:

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
- Source unique: ``
- Aucune redirection externe
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

### ⚠�� Moins sécurisé - NE PAS UTILISER:

```bash
# ❌ Crée un fichier temporaire visible
wget -O /root/nexus.sh 
bash /root/nexus.sh
```

**Risques:**
- ❌ Fichier visible sur le disque
- ❌ Risque de modification pendant l'exécution
- ❌ Oubli possible de suppression
- ❌ Trace persistent

---

## 📱 SUPPORT

- **Telegram**: https://t.me/THEStunnelpro
- **GitHub Issues**: 

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

**NOTE**: Web panel est **DÉSACTIVÉ** par défaut dans ce clone.  
Pour l'installer, voir `GUIDE_CORRECTION.md`

---

## 🛡️ Support de Sécurité

Pour toute question concernant la sécurité:
- **Telegram:** https://t.me/THEStunnelpro
- **GitHub Issues:** Signaler les problèmes de sécurité

---

## 📚 Documentation Supplémentaire

- **MODIFICATIONS.md** - Changements effectués
- **DIAGNOSTIC_PROTOCOLES.md** - Diagnostic des problèmes
- **GUIDE_CORRECTION.md** - Solutions et implémentation

---

**⚠️ AVERTISSEMENT:** Ce script modifie votre système d'exploitation. Assurez-vous d'avoir une sauvegarde avant l'installation!

**Version:** 2026.08.26  
**État**: ✅ Prêt à déployer (URLs pointent vers wilfriedekongolo320-coder/Clone-THE_S-TUNNEL-)
````
