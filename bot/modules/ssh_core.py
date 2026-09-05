"""
Module SSH - Gestion des comptes SSH/WS
"""
import subprocess
import json
import os


def add_ssh_user(username, password, days):
    """Ajoute un compte SSH avec durée d'expiration"""
    try:
        # Créer l'utilisateur
        subprocess.run(
            ['useradd', '-m', '-s', '/bin/bash', username],
            check=True,
            stderr=subprocess.DEVNULL
        )
        
        # Définir le mot de passe
        subprocess.run(
            f'echo "{username}:{password}" | chpasswd',
            shell=True,
            check=True,
            stderr=subprocess.DEVNULL
        )
        
        # Configurer l'expiration
        expiration_days = days
        subprocess.run(
            ['chage', '-E', str(expiration_days), username],
            check=True,
            stderr=subprocess.DEVNULL
        )
        
        return True, f"Utilisateur {username} créé avec succès"
    except Exception as e:
        return False, f"Erreur: {str(e)}"


def delete_ssh_user(username):
    """Supprime un compte SSH"""
    try:
        subprocess.run(
            ['userdel', '-r', username],
            check=True,
            stderr=subprocess.DEVNULL
        )
        return True, f"Utilisateur {username} supprimé"
    except Exception as e:
        return False, f"Erreur: {str(e)}"


def list_ssh_users():
    """Liste les comptes SSH actifs"""
    try:
        result = subprocess.getoutput("cat /etc/passwd | grep -E ':(1000|[0-9]{4}):' | cut -d':' -f1")
        users = result.strip().split('\n') if result.strip() else []
        return users
    except Exception as e:
        return []


def lock_ssh_user(username):
    """Verrouille un compte SSH"""
    try:
        subprocess.run(['usermod', '-L', username], check=True)
        return True, f"Utilisateur {username} verrouillé"
    except Exception as e:
        return False, f"Erreur: {str(e)}"


def unlock_ssh_user(username):
    """Déverrouille un compte SSH"""
    try:
        subprocess.run(['usermod', '-U', username], check=True)
        return True, f"Utilisateur {username} déverrouillé"
    except Exception as e:
        return False, f"Erreur: {str(e)}"


def renew_ssh_user(username, days):
    """Renouvelle la durée d'expiration d'un compte"""
    try:
        subprocess.run(
            ['chage', '-E', str(days), username],
            check=True
        )
        return True, f"Compte {username} renouvelé pour {days} jour(s)"
    except Exception as e:
        return False, f"Erreur: {str(e)}"
