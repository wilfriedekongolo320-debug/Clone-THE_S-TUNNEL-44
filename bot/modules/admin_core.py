"""
Module Administration - Gestion des revendeurs et administrateurs
"""
import json
import os
from datetime import datetime, timedelta


ADMINS_FILE = '/etc/the_s_bot/admins.json'
RESELLERS_FILE = '/etc/the_s_bot/resellers.json'


def load_admins():
    """Charge la liste des administrateurs"""
    if not os.path.exists(ADMINS_FILE):
        return {}
    try:
        with open(ADMINS_FILE, 'r') as f:
            return json.load(f)
    except:
        return {}


def save_admins(data):
    """Sauvegarde la liste des administrateurs"""
    os.makedirs(os.path.dirname(ADMINS_FILE), exist_ok=True)
    with open(ADMINS_FILE, 'w') as f:
        json.dump(data, f, indent=2)


def add_admin(user_id, username):
    """Ajoute un administrateur"""
    try:
        admins = load_admins()
        admins[str(user_id)] = {
            'username': username,
            'added_at': datetime.now().isoformat()
        }
        save_admins(admins)
        return True, f"Administrateur {username} ajouté"
    except Exception as e:
        return False, f"Erreur: {str(e)}"


def remove_admin(user_id):
    """Supprime un administrateur"""
    try:
        admins = load_admins()
        if str(user_id) in admins:
            del admins[str(user_id)]
            save_admins(admins)
            return True, "Administrateur supprimé"
        return False, "Administrateur non trouvé"
    except Exception as e:
        return False, f"Erreur: {str(e)}"


def is_admin(user_id, super_admin):
    """Vérifie si l'utilisateur est administrateur"""
    if user_id == super_admin:
        return True
    admins = load_admins()
    return str(user_id) in admins


def get_admin_list():
    """Retourne la liste des administrateurs"""
    admins = load_admins()
    return admins
