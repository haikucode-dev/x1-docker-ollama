#!/bin/bash
set -e

# Banner
echo "=========================================="
echo "Ollama Docker + Tailscale Funnel Setup"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)."
    exit 1
fi

# Check if tailscale is installed
if ! command -v tailscale &> /dev/null; then
    echo "Error: Tailscale is not installed. Please install it first:"
    echo "  curl -fsSL https://tailscale.com/install.sh | sh"
    exit 1
fi

# Get the current directory
REPO_PATH=$(pwd)
DOCKER_PATH=$(which docker)
TAILSCALE_PATH=$(which tailscale)

# Create systemd service file for Docker
DOCKER_SERVICE_FILE="/etc/systemd/system/ollama-docker.service"
echo "Creating systemd service file at: $DOCKER_SERVICE_FILE"

cat > "$DOCKER_SERVICE_FILE" << EOL
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

# Create systemd service file for Tailscale Funnel
TAILSCALE_SERVICE_FILE="/etc/systemd/system/ollama-tailscale-funnel.service"
echo "Creating Tailscale Funnel service file at: $TAILSCALE_SERVICE_FILE"

cat > "$TAILSCALE_SERVICE_FILE" << EOL
[Unit]
Description=Tailscale Funnel for Ollama
After=network.target ollama-docker.service
Requires=ollama-docker.service

[Service]
Type=simple
ExecStart=${TAILSCALE_PATH} funnel --https=443 localhost:80
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd and enable the services
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling and starting ollama-docker service..."
systemctl enable ollama-docker.service
systemctl start ollama-docker.service

echo "Enabling and starting ollama-tailscale-funnel service..."
systemctl enable ollama-tailscale-funnel.service
systemctl start ollama-tailscale-funnel.service

echo "=========================================="
echo "✅ Setup complete!"
echo "Ollama Docker and Tailscale Funnel services are now configured."
echo
echo "Service Status:"
echo "  - Ollama Docker: $(systemctl is-active ollama-docker.service)"
echo "  - Tailscale Funnel: $(systemctl is-active ollama-tailscale-funnel.service)"
echo
echo "Use these commands to manage the services:"
echo "  - Check status: sudo systemctl status ollama-docker.service"
echo "                  sudo systemctl status ollama-tailscale-funnel.service"
echo "  - Stop services: sudo systemctl stop ollama-tailscale-funnel.service"
echo "                   sudo systemctl stop ollama-docker.service"
echo "  - Start services: sudo systemctl start ollama-docker.service"
echo "                    sudo systemctl start ollama-tailscale-funnel.service"
echo "  - View your Funnel URL: tailscale funnel status"
echo "=========================================="
