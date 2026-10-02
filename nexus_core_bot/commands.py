import subprocess
import psutil


def _run_command(args, timeout=10):
    return subprocess.run(args, capture_output=True, text=True, timeout=timeout, check=False)


def get_vps_status():
    try:
        uptime = _run_command(["uptime", "-p"], timeout=5)
        if uptime.returncode != 0:
            raise RuntimeError(uptime.stderr.strip() or "uptime command failed")

        os_name = "Inconnu"
        try:
            with open("/etc/os-release", "r", encoding="utf-8") as f:
                for line in f:
                    if line.startswith("PRETTY_NAME="):
                        os_name = line.split("=", 1)[1].strip().strip('"')
                        break
        except OSError:
            os_name = "Inconnu"

        cpu_usage = psutil.cpu_percent(interval=1)
        ram = psutil.virtual_memory()
        disk = psutil.disk_usage("/")

        status_msg = (
            f"📊 <b>ÉTAT DU SERVEUR NEXUS</b>\n\n"
            f"🖥️ <b>OS:</b> <code>{os_name}</code>\n"
            f"⏱️ <b>Uptime:</b> <code>{uptime.stdout.strip()}</code>\n"
            f"⚙️ <b>CPU:</b> <code>{cpu_usage}%</code>\n"
            f"💾 <b>RAM:</b> <code>{ram.percent}%</code> ({ram.used // (1024**2)}MB / {ram.total // (1024**2)}MB)\n"
            f"💽 <b>Disque:</b> <code>{disk.percent}%</code> ({disk.used // (1024**3)}GB / {disk.total // (1024**3)}GB)\n"
        )
        return status_msg
    except (OSError, RuntimeError, ValueError) as e:
        return f"❌ Erreur de lecture système : {str(e)}"


def clean_system_logs():
    try:
        _run_command(["journalctl", "--vacuum-time=1d"], timeout=30)
        _run_command(["apt-get", "clean"], timeout=60)
        return "🧹 <b>Logs et Cache nettoyés avec succès.</b>"
    except subprocess.TimeoutExpired:
        return "⚠️ <b>Nettoyage système annulé : délai dépassé.</b>"
