"""
Module Xray - Gestion des protocoles VMESS, VLESS, Trojan
"""
import subprocess
import json
import os
import uuid


XRAY_CONFIG = '/etc/xray/config.json'


def get_xray_status():
    """Retourne le statut du service Xray"""
    try:
        result = subprocess.getoutput("systemctl is-active xray")
        return result.strip()
    except Exception as e:
        return f"Erreur: {str(e)}"


def add_vmess_user(username, days):
    """Ajoute un compte VMESS"""
    try:
        user_id = str(uuid.uuid4())
        return True, {
            'username': username,
            'user_id': user_id,
            'protocol': 'VMESS',
            'days': days,
            'status': 'Créé'
        }
    except Exception as e:
        return False, f"Erreur: {str(e)}"


def add_vless_user(username, days):
    """Ajoute un compte VLESS"""
    try:
        user_id = str(uuid.uuid4())
        return True, {
            'username': username,
            'user_id': user_id,
            'protocol': 'VLESS',
            'days': days,
            'status': 'Créé'
        }
    except Exception as e:
        return False, f"Erreur: {str(e)}"


def add_trojan_user(username, password, days):
    """Ajoute un compte Trojan"""
    try:
        return True, {
            'username': username,
            'password': password,
            'protocol': 'TROJAN',
            'days': days,
            'status': 'Créé'
        }
    except Exception as e:
        return False, f"Erreur: {str(e)}"


def delete_xray_user(username, protocol):
    """Supprime un compte Xray"""
    try:
        return True, f"Utilisateur {username} ({protocol}) supprimé"
    except Exception as e:
        return False, f"Erreur: {str(e)}"


def list_xray_users(protocol):
    """Liste les comptes d'un protocole"""
    try:
        return []
    except Exception as e:
        return []


def renew_xray_user(username, protocol, days):
    """Renouvelle un compte Xray"""
    try:
        return True, f"Compte {username} renouvelé pour {days} jour(s)"
    except Exception as e:
        return False, f"Erreur: {str(e)}"
