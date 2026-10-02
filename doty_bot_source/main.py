import telebot
import subprocess
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton
import json
import os
import logging
import threading
import re
from datetime import datetime, timedelta
from modules import system_core, ssh_core, admin_core, xray_core, zivpn_core

logging.basicConfig(level=logging.WARNING, format='%(asctime)s %(levelname)s %(message)s')
CONFIG_FILE    = '/etc/the_s_bot/config.json'
RESELLERS_FILE = '/etc/the_s_bot/resellers.json'
CONVS_FILE     = '/etc/the_s_bot/convs.json'
VISITORS_FILE  = '/etc/the_s_bot/visitors.json'
MENU_IMAGE_URL = "https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main/assets/menu_image.jpg"
