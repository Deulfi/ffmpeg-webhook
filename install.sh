#!/bin/bash
set -e

INSTALL_DIR="/opt/ffmpeg-webhook"

if [ "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" != "$INSTALL_DIR" ]; then
    echo "ERROR: Repo must be at $INSTALL_DIR"
    exit 1
fi

echo "=== System packages ==="
apt update
apt install -y ffmpeg webhook python3-pip curl wget unzip
apt upgrade -y

echo "=== ffmpeg-progress-yield ==="
pip3 install --upgrade ffmpeg-progress-yield --break-system-packages

echo "=== websocketd ==="
CURRENT=$(websocketd --version 2>&1 || echo "none")
LATEST=$(curl -s https://api.github.com/repos/joewalnes/websocketd/releases/latest | grep -oP '"tag_name": "v\K[^"]+')

if [ "$CURRENT" != "$LATEST" ] && [ -n "$LATEST" ]; then
    echo "Installing websocketd: $CURRENT -> $LATEST"
    wget -q "https://github.com/joewalnes/websocketd/releases/download/v${LATEST}/websocketd-${LATEST}-linux_amd64.zip" -O /tmp/ws.zip
    unzip -o /tmp/ws.zip -d /tmp/ws
    mv /tmp/ws/websocketd /usr/local/bin/websocketd
    chmod +x /usr/local/bin/websocketd
    rm -rf /tmp/ws /tmp/ws.zip
else
    echo "websocketd up to date ($CURRENT)"
fi

echo "=== .env ==="
if [ ! -f "$INSTALL_DIR/.env" ]; then
    cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
    echo ">>> Edit $INSTALL_DIR/.env now <<<"
    read -p "Press Enter when done..."
fi
source "$INSTALL_DIR/.env"

echo "=== Directories & permissions ==="
mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p /tmp/ffmpeg_progress
touch "$LOG_FILE" /tmp/ffmpeg_progress/jobs.log
chmod +x "$INSTALL_DIR/scripts/"*.sh "$INSTALL_DIR/scripts/"*.py

echo "=== Clearing logs ==="
> "$LOG_FILE"
> /tmp/ffmpeg_progress/jobs.log

echo "=== systemd ==="
cp "$INSTALL_DIR/config/webhook.service"    /etc/systemd/system/
cp "$INSTALL_DIR/config/websocketd.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable webhook.service websocketd.service
systemctl restart webhook.service websocketd.service

echo ""
echo "=== Done ==="
IP=$(hostname -I | awk '{print $1}')
echo "Webhook:   http://${IP}:${WEBHOOK_PORT}/hooks/download-stream"
echo "Dashboard: http://${IP}:${WEBSOCKET_PORT}/"
echo ""
echo "webhook:               $(webhook -version 2>&1)"
echo "ffmpeg:                $(ffmpeg -version 2>&1 | head -1)"
echo "websocketd:            $(websocketd --version 2>&1)"
echo "ffmpeg-progress-yield: $(pip3 show ffmpeg-progress-yield 2>/dev/null | grep Version | awk '{print $2}')"
