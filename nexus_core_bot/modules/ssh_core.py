#!/usr/bin/env python3
"""
Patch helper sécurisé pour injecter la logique SSH dans nexus_bot.py.
Le script évite toute exécution via shell afin d'empêcher les injections.
"""

from pathlib import Path

TARGET = Path("nexus_bot.py")

SSH_LOGIC = '''
# --- LOGIQUE DE CRÉATION SSH (STATE MACHINE) ---
@bot.callback_query_handler(func=lambda call: call.data == "add_ssh")
def add_ssh_start(call):
    if not is_admin(call.from_user.id):
        return
    bot.edit_message_text(
        "⚙️ Module SSH activé.",
        chat_id=call.message.chat.id,
        message_id=call.message.message_id,
    )
    msg = bot.send_message(
        call.message.chat.id,
        "👤 <b>Étape 1/3</b>\nEntrez le nom d'utilisateur SSH :",
        parse_mode="HTML",
    )
    bot.register_next_step_handler(msg, process_ssh_user)


def process_ssh_user(message):
    user = str(message.text).strip()
    msg = bot.send_message(
        message.chat.id,
        "🔑 <b>Étape 2/3</b>\nEntrez le mot de passe :",
        parse_mode="HTML",
    )
    bot.register_next_step_handler(msg, process_ssh_pass, user)


def process_ssh_pass(message, user):
    password = str(message.text).strip()
    msg = bot.send_message(
        message.chat.id,
        "⏳ <b>Étape 3/3</b>\nEntrez la durée (en jours) :",
        parse_mode="HTML",
    )
    bot.register_next_step_handler(msg, process_ssh_days, user, password)


def process_ssh_days(message, user, password):
    days = str(message.text).strip()
    if not days.isdigit():
        bot.send_message(
            message.chat.id,
            "❌ Le nombre de jours doit être un entier. Annulation.",
            reply_markup=main_menu_keyboard(),
        )
        return

    bot.send_message(
        message.chat.id,
        f"⚙️ Déploiement du compte <b>{user}</b> au niveau du noyau...",
        parse_mode="HTML",
    )

    import subprocess
    from datetime import datetime, timedelta

    exp_date = (datetime.now() + timedelta(days=int(days))).strftime("%Y-%m-%d")
    create_cmd = ["useradd", "-e", exp_date, "-s", "/bin/false", "-M", user]
    res = subprocess.run(create_cmd, capture_output=True, text=True, timeout=15)

    if res.returncode != 0:
        bot.send_message(
            message.chat.id,
            f"❌ Échec de la création :\n<code>{res.stderr}</code>",
            parse_mode="HTML",
            reply_markup=main_menu_keyboard(),
        )
        return

    chpasswd = subprocess.run(
        ["chpasswd"],
        input=f"{user}:{password}\n",
        capture_output=True,
        text=True,
        timeout=15,
    )

    if chpasswd.returncode == 0:
        success_msg = (
            f"✅ <b>COMPTE SSH FORGÉ AVEC SUCCÈS</b>\n\n"
            f"👤 Username : <code>{user}</code>\n"
            f"🔑 Password : <code>{password}</code>\n"
            f"⏳ Validité : {days} Jours"
        )
        bot.send_message(
            message.chat.id,
            success_msg,
            parse_mode="HTML",
            reply_markup=main_menu_keyboard(),
        )
    else:
        bot.send_message(
            message.chat.id,
            f"❌ Échec de la création :\n<code>{chpasswd.stderr}</code>",
            parse_mode="HTML",
            reply_markup=main_menu_keyboard(),
        )

'''


if __name__ == "__main__":
    if not TARGET.exists():
        raise FileNotFoundError(f"Fichier introuvable : {TARGET}")

    content = TARGET.read_text(encoding="utf-8")
    marker = "if __name__ == \"__main__\":"
    if marker not in content:
        raise ValueError("Point d'insertion non trouvé dans nexus_bot.py")

    safe_content = content.replace(marker, SSH_LOGIC + "\n" + marker)
    TARGET.write_text(safe_content, encoding="utf-8")
    print(f"Injection SSH sécurisée appliquée dans {TARGET}")
