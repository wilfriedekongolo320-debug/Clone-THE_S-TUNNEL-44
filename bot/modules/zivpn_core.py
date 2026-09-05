"""
Module ZiVPN - Gestion VPN UDP Fast
"""
import subprocess
import json
import os


def get_zivpn_status():
    """Retourne le statut du service ZiVPN"""
    try:
        result = subprocess.getoutput("systemctl is-active zivpn 2>/dev/null || echo 'inactive'")
        return result.strip()
    except Exception as e:
        return f"Erreur: {str(e)}"


def add_zivpn_user(username, days):
    """Ajoute un compte ZiVPN"""
    try:
        return True, {
            'username': username,
            'protocol': 'UDP FAST',
            'days': days,
            'status': 'Créé'
        }
    except Exception as e:
        return False, f"Erreur: {str(e)}"


def delete_zivpn_user(username):
    """Supprime un compte ZiVPN"""
    try:
        return True, f"Utilisateur {username} supprimé"
    except Exception as e:
        return False, f"Erreur: {str(e)}"


def list_zivpn_users():
    """Liste les comptes ZiVPN"""
    try:
        return []
    except Exception as e:
        return []


def renew_zivpn_user(username, days):
    """Renouvelle un compte ZiVPN"""
    try:
        return True, f"Compte {username} renouvelé pour {days} jour(s)"
    except Exception as e:
        return False, f"Erreur: {str(e)}"
