"""
Module système - Gestion des ressources serveur
"""
import subprocess
import psutil
import os


def get_system_stats():
    """Retourne les statistiques système"""
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        return {
            'cpu': cpu_percent,
            'memory_percent': memory.percent,
            'memory_used': memory.used // (1024**3),
            'memory_total': memory.total // (1024**3),
            'disk_percent': disk.percent,
            'disk_used': disk.used // (1024**3),
            'disk_total': disk.total // (1024**3),
        }
    except Exception as e:
        return {'error': str(e)}


def get_uptime():
    """Retourne le temps d'uptime du serveur"""
    try:
        result = subprocess.getoutput("uptime -p").strip()
        return result
    except Exception as e:
        return f"Erreur: {e}"


def restart_services():
    """Redémarre les services du système"""
    try:
        subprocess.run(['systemctl', 'daemon-reload'], check=True)
        return True
    except Exception as e:
        return False


def get_server_info():
    """Retourne les informations du serveur"""
    try:
        hostname = subprocess.getoutput("hostname").strip()
        ip_addr = subprocess.getoutput("curl -s ifconfig.me").strip()
        return {
            'hostname': hostname,
            'ip': ip_addr,
        }
    except Exception as e:
        return {'error': str(e)}
