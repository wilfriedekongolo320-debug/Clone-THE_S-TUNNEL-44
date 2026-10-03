import json
import logging
import os
import subprocess
import threading
import time

import telebot
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton

logging.basicConfig(level=logging.WARNING, format='%(asctime)s %(levelname)s %(message)s')

CONFIG_FILE = '/etc/the_s_bot/config.json'
RESELLERS_FILE = '/etc/the_s_bot/resellers.json'
CONVS_FILE = '/etc/the_s_bot/convs.json'
VISITORS_FILE = '/etc/the_s_bot/visitors.json'
MENU_IMAGE_URL = "https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main/assets/menu_image.jpg"

def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}

def get_bot_token():
    config = load_config()
    token = config.get("bot_token") or os.environ.get("BOT_TOKEN")
    if not token:
        raise RuntimeError("BOT_TOKEN manquant. Vérifiez /etc/the_s_bot/config.json")
    return token

def get_admin_id():
    config = load_config()
    return config.get("admin_id") or os.environ.get("ADMIN_ID")

def get_server_status():
    try:
        result = subprocess.run(["systemctl", "status"], capture_output=True, text=True, timeout=10, check=False)
        return result.stdout or "Statut inconnu."
    except Exception as e:
        return f"Erreur: {str(e)}"

def build_main_menu():
    markup = InlineKeyboardMarkup()
    markup.row(
        InlineKeyboardButton("📊 Statut", callback_data="status"),
        InlineKeyboardButton("ℹ️ Serveur", callback_data="server_info")
    )
    markup.row(
        InlineKeyboardButton("👤 Admin", callback_data="admin"),
        InlineKeyboardButton("❓ Aide", callback_data="help")
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
    bot.reply_to(message, get_server_status())

@bot.message_handler(commands=['server_info'])
def cmd_server_info(message):
    try:
        info = []
        info.append(f"Hostname: <code>{subprocess.check_output(['hostname'], text=True).strip()}</code>")
        info.append(f"IP: <code>{subprocess.check_output(['hostname', '-I'], text=True).strip()}</code>")
        info.append(f"OS: <code>{subprocess.check_output(['cat', '/etc/os-release'], text=True).split('PRETTY_NAME=')[-1].splitlines()[0].strip().strip('\"')}</code>")
        bot.reply_to(message, "\n".join(info))
    except Exception as e:
        bot.reply_to(message, f"Erreur: {str(e)}")

@bot.callback_query_handler(func=lambda call: True)
def callback_handler(call):
    if call.data == "status":
        bot.answer_callback_query(call.id, text="Vérification du statut...")
        bot.send_message(call.message.chat.id, get_server_status())
    elif call.data == "server_info":
        bot.answer_callback_query(call.id, text="Informations serveur...")
        bot.send_message(call.message.chat.id, "Serveur prêt.")
    elif call.data == "help":
        bot.answer_callback_query(call.id, text="Aide")
        bot.send_message(call.message.chat.id, "Commandes: /start /help /status /server_info")

def start_polling():
    bot.infinity_polling(timeout=10, long_polling_timeout=5)

if __name__ == "__main__":
    start_polling()
