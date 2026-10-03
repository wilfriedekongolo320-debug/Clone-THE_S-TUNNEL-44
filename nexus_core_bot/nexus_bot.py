#!/usr/bin/env python3
import json
import logging
import os
import subprocess

import telebot
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton

logging.basicConfig(level=logging.WARNING, format='%(asctime)s %(levelname)s %(message)s')

CONFIG_FILE = '/etc/nexus_bot/config.json'
MENU_IMAGE_URL = "https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main/assets/menu_image.jpg"

def load_config():
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def get_bot_token():
    config = load_config()
    token = config.get("bot_token") or os.environ.get("BOT_TOKEN")
    if not token:
        raise RuntimeError("BOT_TOKEN manquant. Vérifiez /etc/nexus_bot/config.json")
    return token

def get_admin_id():
    config = load_config()
    return config.get("admin_id") or os.environ.get("ADMIN_ID")

def build_main_menu():
    markup = InlineKeyboardMarkup()
    markup.row(
        InlineKeyboardButton("📊 Statut", callback_data="status"),
        InlineKeyboardButton("ℹ️ Serveur", callback_data="server_info")
    )
    return markup

bot = telebot.TeleBot(get_bot_token(), parse_mode="HTML")

@bot.message_handler(commands=['start'])
def cmd_start(message):
    admin_id = get_admin_id()
    text = (
        "Bienvenue sur le bot Nexus.\n\n"
        f"Votre ID admin: <code>{admin_id}</code>\n"
        "Utilisez /help pour voir les commandes disponibles."
    )
    bot.reply_to(message, text, reply_markup=build_main_menu())

@bot.message_handler(commands=['help'])
def cmd_help(message):
    bot.reply_to(message, "Commandes disponibles:\n/start\n/help\n/status\n/server_info")

@bot.message_handler(commands=['status'])
def cmd_status(message):
    try:
        output = subprocess.check_output(["systemctl", "status"], text=True, stderr=subprocess.STDOUT)
        bot.reply_to(message, output)
    except Exception as exc:
        bot.reply_to(message, f"Erreur: {exc}")

@bot.message_handler(commands=['server_info'])
def cmd_server_info(message):
    try:
        info = []
        info.append(f"Hostname: <code>{subprocess.check_output(['hostname'], text=True).strip()}</code>")
        info.append(f"IP: <code>{subprocess.check_output(['hostname', '-I'], text=True).strip()}</code>")
        os_release = subprocess.check_output(['cat', '/etc/os-release'], text=True)
        pretty_name = ""
        for line in os_release.splitlines():
            if line.startswith("PRETTY_NAME="):
                pretty_name = line.split("=", 1)[1].strip().strip('"')
                break
        info.append(f"OS: <code>{pretty_name}</code>")
        bot.reply_to(message, "\n".join(info))
    except Exception as exc:
        bot.reply_to(message, f"Erreur: {exc}")

@bot.callback_query_handler(func=lambda call: True)
def callback_handler(call):
    if call.data == "status":
        try:
            out = subprocess.check_output(["systemctl", "status"], text=True, stderr=subprocess.STDOUT)
            bot.send_message(call.message.chat.id, out)
        except Exception as exc:
            bot.send_message(call.message.chat.id, f"Erreur: {exc}")
    elif call.data == "server_info":
        bot.send_message(call.message.chat.id, "Serveur prêt.")

if __name__ == "__main__":
    bot.infinity_polling(timeout=10, long_polling_timeout=5)
