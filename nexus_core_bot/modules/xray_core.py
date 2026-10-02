import os
import re
import shlex
import subprocess
from datetime import datetime, timedelta

DB_DIR = "/etc/nexus_bot/ssh_accounts"


def get_file(path, default="NON_DEFINI"):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read().strip()
    except Exception:
        return default


def _get_public_ip():
    for cmd in (
        ["wget", "-qO-", "ipv4.icanhazip.com"],
        ["curl", "-s", "ipv4.icanhazip.com"],
        ["curl", "-s", "ifconfig.me"],
    ):
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10, check=False)
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue
    return "N/A"


def _server_info():
    domain = get_file("/etc/xray/domain", "votre-domaine.com")
    pub_key = get_file("/etc/slowdns/server.pub", "PUB_KEY_NOT_FOUND")
    ns_domain = get_file("/etc/slowdns/nsdomain", "NS_DOMAIN_NOT_FOUND")
    myip = _get_public_ip()
    return domain, pub_key, ns_domain, myip


def _format_ssh_details(user, password, exp_date):
    domain, pub_key, ns_domain, myip = _server_info()
    return (
        f"┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n"
        f"┃ <b>SSH ACCOUNT DETAILS</b>\n"
        f"┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"
        f"👤 <b>Username:</b> <code>{user}</code>\n"
        f"🔑 <b>Password:</b> <code>{password}</code>\n"
        f"⏳ <b>Expiry Date:</b> {exp_date}\n"
        f"🖥️ <b>Host/IP:</b> <code>{myip}</code>\n"
        f"🌐 <b>Domain:</b> <code>{domain}</code>\n"
        f"📛 <b>NS Domain:</b> <code>{ns_domain}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"🔌 <b>Ports:</b>\n"
        f"  OpenSSH(22), Dropbear(109,143)\n"
        f"  Stunnel(447,777), WS(80,443)\n"
        f"  UDPGW(7100-7900), Squid(3128,8880)\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"🚀 <b>UDP Custom:</b>\n"
        f"<code>{myip}:1-65535@{user}:{password}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"🐌 <b>Slow DNS PUB:</b>\n"
        f"<code>{pub_key}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"📦 <b>Payload WS:</b>\n"
        f"<code>GET / HTTP/1.1[crlf]Host: {domain}[crlf]Upgrade: websocket[crlf][crlf]</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"📥 <b>OpenVPN:</b> https://{domain}:2081\n"
    )


def create_ssh_account(user, password, days, created_by_id=None):
    exp_date = (datetime.now() + timedelta(days=int(days))).strftime("%Y-%m-%d")
    create_cmd = ["useradd", "-e", exp_date, "-s", "/bin/false", "-M", user]
    res = subprocess.run(create_cmd, capture_output=True, text=True, timeout=20, check=False)
    if res.returncode != 0:
        return False, f"❌ Échec de la création:\n<code>{res.stderr}</code>"

    chpasswd = subprocess.run(
        ["chpasswd"],
        input=f"{user}:{password}\n",
        capture_output=True,
        text=True,
        timeout=15,
        check=False,
    )
    if chpasswd.returncode != 0:
        return False, f"❌ Échec de la création:\n<code>{chpasswd.stderr}</code>"

    os.makedirs(DB_DIR, exist_ok=True)
    with open(f"{DB_DIR}/{user}.txt", "w", encoding="utf-8") as f:
        f.write(
            f"username={user}\n"
            f"password={password}\n"
            f"expiry={exp_date}\n"
            f"createdById={created_by_id}\n"
            f"createdAt={datetime.utcnow().isoformat()}Z\n"
            f"protocol=ssh\n"
            f"status=active\n"
        )
    return True, _format_ssh_details(user, password, exp_date)


def get_ssh_usernames():
    if not os.path.exists(DB_DIR):
        return []
    return [
        f.replace(".txt", "")
        for f in sorted(os.listdir(DB_DIR))
        if f.endswith(".txt")
    ]


def get_ssh_account_details(user):
    db_file = f"{DB_DIR}/{user}.txt"
    if not os.path.exists(db_file):
        return False, f"❌ Compte SSH <code>{user}</code> introuvable."
    data = {}
    with open(db_file, "r", encoding="utf-8") as f:
        for line in f:
            if "=" in line:
                k, v = line.strip().split("=", 1)
                data[k] = v
    return True, _format_ssh_details(
        user, data.get("password", "N/A"), data.get("expiry", "N/A")
    )


def renew_ssh_account(user, days):
    if subprocess.run(["id", user], capture_output=True, check=False).returncode != 0:
        return False, f"❌ Utilisateur <code>{user}</code> introuvable."

    chage_proc = subprocess.run(
        ["chage", "-l", user],
        capture_output=True,
        text=True,
        timeout=15,
        check=False,
    )
    current_exp = ""
    if chage_proc.returncode == 0:
        for line in chage_proc.stdout.splitlines():
            if "Account expires" in line:
                current_exp = line.split(":", 1)[1].strip()
                break

    try:
        if current_exp in ("never", "", "password must be changed"):
            old_date = datetime.now()
        else:
            old_date = datetime.strptime(current_exp, "%b %d, %Y")
        new_exp = (old_date + timedelta(days=int(days))).strftime("%Y-%m-%d")
    except ValueError:
        new_exp = (datetime.now() + timedelta(days=int(days))).strftime("%Y-%m-%d")

    subprocess.run(["usermod", "-e", new_exp, user], check=False)
    subprocess.run(["passwd", "-u", user], capture_output=True, check=False)

    db_file = f"{DB_DIR}/{user}.txt"
    if os.path.exists(db_file):
        with open(db_file, "r", encoding="utf-8") as f:
            db_lines = f.readlines()
        with open(db_file, "w", encoding="utf-8") as f:
            for line in db_lines:
                if line.startswith("expiry="):
                    f.write(f"expiry={new_exp}\n")
                else:
                    f.write(line)

    ok, details = get_ssh_account_details(user)
    if ok:
        header = (
            f"✅ <b>COMPTE SSH RENOUVELÉ</b>\n"
            f"📅 <b>Ancienne expiration:</b> {current_exp} → <b>{new_exp}</b>\n\n"
        )
        return True, header + details
    return True, (
        f"✅ <b>COMPTE SSH RENOUVELÉ</b>\n\n"
        f"👤 <b>Username:</b> <code>{user}</code>\n"
        f"📅 <b>Ancienne expiration:</b> {current_exp}\n"
        f"➕ <b>Jours ajoutés:</b> {days}\n"
        f"📅 <b>Nouvelle expiration:</b> {new_exp}\n"
    )


def delete_ssh_account(user):
    if subprocess.run(["id", user], capture_output=True, check=False).returncode != 0:
        return False, f"❌ Utilisateur <code>{user}</code> introuvable."

    subprocess.run(["pkill", "-u", user], capture_output=True, check=False)
    subprocess.run(["userdel", "-r", user], capture_output=True, check=False)

    db_file = f"{DB_DIR}/{user}.txt"
    if os.path.exists(db_file):
        os.remove(db_file)

    return True, f"🗑️ <b>Compte SSH <code>{user}</code> supprimé avec succès.</b>"


def lock_ssh_account(user):
    if subprocess.run(["id", user], capture_output=True, check=False).returncode != 0:
        return False, f"❌ Utilisateur <code>{user}</code> introuvable."
    subprocess.run(["passwd", "-l", user], capture_output=True, check=False)
    return True, f"🔒 <b>Compte <code>{user}</code> verrouillé.</b>"


def unlock_ssh_account(user):
    if subprocess.run(["id", user], capture_output=True, check=False).returncode != 0:
        return False, f"❌ Utilisateur <code>{user}</code> introuvable."
    subprocess.run(["passwd", "-u", user], capture_output=True, check=False)
    return True, f"🔓 <b>Compte <code>{user}</code> déverrouillé.</b>"


def list_ssh_accounts():
    try:
        with open("/etc/passwd", "r", encoding="utf-8") as f:
            users = []
            for line in f:
                parts = line.strip().split(":")
                if len(parts) >= 3:
                    uid = int(parts[2])
                    username = parts[0]
                    if uid >= 1000 and username != "nobody":
                        users.append(username)
    except OSError:
        return "📋 Aucun compte SSH trouvé."

    if not users:
        return "📋 Aucun compte SSH trouvé."

    msg = "📋 <b>LISTE DES COMPTES SSH:</b>\n\n"
    for user in sorted(users):
        status_proc = subprocess.run(["passwd", "-S", user], capture_output=True, text=True, timeout=10, check=False)
        status = status_proc.stdout.strip().split()[-1] if status_proc.stdout.strip() else ""
        lock_icon = "🔒" if status == "L" else "🔓"

        chage_proc = subprocess.run(["chage", "-l", user], capture_output=True, text=True, timeout=10, check=False)
        exp_date = "N/A"
        if chage_proc.returncode == 0:
            for line in chage_proc.stdout.splitlines():
                if "Account expires" in line:
                    exp_date = line.split(":", 1)[1].strip()
                    break
        msg += f"{lock_icon} <code>{user}</code> | Exp: <i>{exp_date}</i>\n"
    msg += f"\n📊 <b>Total:</b> {len(users)} compte(s)"
    return msg
