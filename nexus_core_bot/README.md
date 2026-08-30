# 🤖 NEXUS Bot Telegram - C2 Control

Bot Telegram pour la gestion et le contrôle du serveur 🜲THE_S TUNNEL PRO.

## 📋 Installation

### 1. Depuis le Menu Principal
```bash
menu
# Sélectionner l'option [14] - NEXUS BOT PANEL
```

### 2. Manuellement
```bash
sudo bash <(wget -qO- https://raw.githubusercontent.com/thesnet320-source/THE_S-TUNNEL-PRO-/main/menu/tgbot.sh)
```

## 🔑 Configuration Requise

1. **TOKEN du Bot Telegram** - Obtenez-le sur [@BotFather](https://t.me/botfather)
2. **Votre ID Telegram** - Trouvez-le sur [@userinfobot](https://t.me/userinfobot)

## Structure livrée

```
bot_fixes/
├── README_APPLICATION.md          ← ce fichier
├── doty_bot_source/
│   ├── install_bot.sh             ← installateur corrigé
│   ├── check_telegram.py          ← chemin config corrigé
│   └── modules/
│       ├── __init__.py
│       ├── system_core.py
│       ├── admin_core.py
│       ├── ssh_core.py
│       ├── xray_core.py           ← injection robuste + chemins /etc/the_s_bot
│       └── zivpn_core.py
└── nexus_core_bot/
    ├── requirements.txt
    └── modules/
        └── xray_core.py           ← injection robuste + chemins /etc/nexus_bot
```

## 🎮 Commandes Disponibles

| Commande | Description |
|----------|-------------|
| `/start` | Authentification initiale |
| `/status` | Statut du serveur |
| `/users` | Liste des utilisateurs |
| `/add_user` | Ajouter un utilisateur |
| `/ssh_status` | Statut SSH |
| `/xray_status` | Statut Xray |
| `/help` | Aide |

## 🚀 Démarrage du Service

```bash
# Vérifier le statut
systemctl status nexus_bot

# Démarrer
systemctl start nexus_bot

# Arrêter
systemctl stop nexus_bot

# Logs en temps réel
journalctl -u nexus_bot -f
```

## 🔐 Sécurité

- Configuration stockée dans `/etc/nexus_bot/config.json`
- Permissions restrictives (chmod 600)
- Logs d'audit complets
- Authentification par ID Telegram

## 📝 Fichiers Importants

- **Config**: `/etc/nexus_bot/config.json`
- **Logs**: `/var/log/nexus_bot/bot.log`
- **Service**: `/etc/systemd/system/nexus_bot.service`

## ⚡ Dépannage

### Le bot ne démarre pas
```bash
journalctl -u nexus_bot -n 50
```

### Vérifier la configuration
```bash
cat /etc/nexus_bot/config.json
```

### Redémarrer le bot
```bash
systemctl restart nexus_bot
```

---

**Version:** 1.0.0  
**Auteur:** THE_S Team  
**Dépôt:** [GitHub](https://github.com/thesnet320-source/THE_S-TUNNEL-PRO-)
