import telebot
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton
import json
import os
import logging
from modules import system_core, ssh_core, admin_core, xray_core, zivpn_core

logging.basicConfig(level=logging.WARNING, format='%(asctime)s %(levelname)s %(message)s')

CONFIG_FILE = '/etc/nexus_bot/config.json'

MENU_IMAGE_URL = "https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main/assets/menu_image.jpg"
