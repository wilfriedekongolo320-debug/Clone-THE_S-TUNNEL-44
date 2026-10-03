#!/bin/bash
set -e

echo "[INFO] Checking for nodejs/tmux..."
if ! command -v node >/dev/null 2>&1; then
    apt-get update -y
    apt-get install -y nodejs npm tmux
fi

PROXY_JS="/usr/local/sbin/proxy3.js"

if [[ ! -f "$PROXY_JS" ]]; then
    echo "[ERROR] $PROXY_JS not found. Downloading..."
    wget -q -O "$PROXY_JS" "https://raw.githubusercontent.com/wilfriedekongolo320-debug/Clone-THE_S-TUNNEL-44/main/module/proxy3.js"
    chmod 644 "$PROXY_JS"
fi

# Vérifier si les ports 80/700 sont libres
if ss -lnt | awk '{print $4}' | grep -q ':80$'; then
    echo "[WARN] Port 80 already in use; using 8080 instead"
    SSH_WS_PORT=8080
else
    SSH_WS_PORT=80
fi

if ss -lnt | awk '{print $4}' | grep -q ':700$'; then
    echo "[WARN] Port 700 already in use; using 7000 instead"
    SSH_SSL_WS_PORT=7000
else
    SSH_SSL_WS_PORT=700
fi

tmux kill-session -t sshws >/dev/null 2>&1 || true
tmux kill-session -t sshwsssl >/dev/null 2>&1 || true

echo "[INFO] Starting tmux session for SSH WS..."
tmux new-session -d -s sshws "node $PROXY_JS -dport 109 -mport $SSH_WS_PORT -o /root/sshws.log"

echo "[INFO] Starting tmux session for SSH SSL WS..."
tmux new-session -d -s sshwsssl "node $PROXY_JS -dport 109 -mport $SSH_SSL_WS_PORT -o /root/sshwsssl.log"
