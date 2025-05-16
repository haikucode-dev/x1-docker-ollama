#!/bin/bash
set -e

# Banner
echo "=========================================="
echo "Ollama Docker + Tailscale Funnel Uninstaller"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)."
    exit 1
fi

# Function to gracefully handle errors or commands that might fail
safe_command() {
    "$@" || echo "Command failed: $* (continuing anyway)"
}

# Ask for confirmation
echo "⚠️  WARNING: This will stop and remove Ollama Docker services, Tailscale Funnel,"
echo "   and related systemd services. Docker volumes with your Ollama models will be removed."
echo
read -p "Are you sure you want to proceed? (y/N): " -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall canceled."
    exit 0
fi

# Get repo path
REPO_PATH=$(pwd)

# Stop Tailscale Funnel if it exists
echo "Stopping Tailscale Funnel service..."
if systemctl is-active --quiet ollama-tailscale-funnel.service; then
    safe_command systemctl stop ollama-tailscale-funnel.service
    safe_command systemctl disable ollama-tailscale-funnel.service
    echo "✅ Tailscale Funnel service stopped and disabled"
else
    echo "Tailscale Funnel service not found or not active"
fi

# Remove Tailscale Funnel service file
if [ -f /etc/systemd/system/ollama-tailscale-funnel.service ]; then
    echo "Removing Tailscale Funnel systemd service file..."
    safe_command rm /etc/systemd/system/ollama-tailscale-funnel.service
    echo "✅ Tailscale Funnel service file removed"
fi

# Clean up any Tailscale Funnel configuration
if command -v tailscale &> /dev/null; then
    echo "Removing Tailscale Funnel configuration..."
    safe_command tailscale funnel reset
    echo "✅ Tailscale Funnel configuration reset"
fi

# Stop Ollama Docker service if it exists
echo "Stopping Ollama Docker service..."
if systemctl is-active --quiet ollama-docker.service; then
    safe_command systemctl stop ollama-docker.service
    safe_command systemctl disable ollama-docker.service
    echo "✅ Ollama Docker service stopped and disabled"
else
    echo "Ollama Docker service not found or not active"
fi

# Remove Ollama Docker service file
if [ -f /etc/systemd/system/ollama-docker.service ]; then
    echo "Removing Ollama Docker systemd service file..."
    safe_command rm /etc/systemd/system/ollama-docker.service
    echo "✅ Ollama Docker service file removed"
fi

# Reload systemd
echo "Reloading systemd daemon..."
safe_command systemctl daemon-reload
echo "✅ Systemd daemon reloaded"

# Stop and remove Docker containers and volumes
if [ -f "${REPO_PATH}/docker-compose.yml" ]; then
    echo "Stopping and removing Docker containers and volumes..."
    cd "${REPO_PATH}"
    safe_command docker compose down -v
    echo "✅ Docker containers and volumes removed"
fi

# Ask if user wants to keep the repository
echo
read -p "Do you want to keep the repository files? (Y/n): " -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "This script cannot remove itself while running."
    echo "To remove the repository after the script completes, run:"
    echo "  rm -rf ${REPO_PATH}"
    echo
fi

echo "=========================================="
echo "✅ Uninstallation complete!"
echo "All Ollama Docker and Tailscale Funnel services and configurations have been removed."
echo "=========================================="
