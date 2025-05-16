#!/bin/bash
set -e

# Banner
echo "=========================================="
echo "Ollama Systemd Service Setup"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)."
    exit 1
fi

# Get the current directory
REPO_PATH=$(pwd)
DOCKER_PATH=$(which docker)

# Create systemd service file
SERVICE_FILE="/etc/systemd/system/ollama-docker.service"
echo "Creating systemd service file at: $SERVICE_FILE"

cat > "$SERVICE_FILE" << EOL
[Unit]
Description=Ollama Docker Compose Service
After=network.target docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${REPO_PATH}
ExecStart=${DOCKER_PATH} compose up -d
ExecStop=${DOCKER_PATH} compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd and enable the service
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling ollama-docker service..."
systemctl enable ollama-docker.service

echo "Starting ollama-docker service..."
systemctl start ollama-docker.service

echo "=========================================="
echo "✅ Systemd service setup complete!"
echo "Ollama will now automatically start on system boot."
echo "Service status: $(systemctl is-active ollama-docker.service)"
echo
echo "Use these commands to manage the service:"
echo "  - Check status: sudo systemctl status ollama-docker.service"
echo "  - Stop service: sudo systemctl stop ollama-docker.service"
echo "  - Start service: sudo systemctl start ollama-docker.service"
echo "  - Disable autostart: sudo systemctl disable ollama-docker.service"
echo "=========================================="
