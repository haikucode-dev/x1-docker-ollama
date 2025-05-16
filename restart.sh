#!/bin/bash
set -e

# Banner
echo "=========================================="
echo "Ollama Docker + Tailscale Funnel Restart"
echo "=========================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to check if we're running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "⚠️  Warning: Some operations require root privileges."
        echo "For a full restart of all services, run this script with sudo."
        echo
        RUNNING_AS_ROOT=false
    else
        RUNNING_AS_ROOT=true
    fi
}

# Function to restart services
restart_services() {
    local needs_systemd_restart=false

    # Check if systemd services are installed
    if $RUNNING_AS_ROOT; then
        if systemctl list-unit-files | grep -q "ollama-docker.service"; then
            echo "🔄 Restarting Ollama Docker systemd service..."
            systemctl restart ollama-docker.service
            echo "✅ Ollama Docker service restarted"
            needs_systemd_restart=false
        fi

        if systemctl list-unit-files | grep -q "ollama-tailscale-funnel.service"; then
            echo "🔄 Restarting Tailscale Funnel systemd service..."
            systemctl restart ollama-tailscale-funnel.service
            echo "✅ Tailscale Funnel service restarted"
            needs_systemd_restart=false
        fi
    fi

    # If no systemd services were found or we're not running as root, restart containers directly
    if [ "$needs_systemd_restart" = true ] || ! $RUNNING_AS_ROOT; then
        # Check if Docker is available
        if command_exists docker; then
            if [ -f "docker-compose.yml" ]; then
                echo "🔄 Restarting Docker containers..."
                docker compose restart
                echo "✅ Docker containers restarted"
            else
                echo "❌ Error: docker-compose.yml not found"
                exit 1
            fi
        else
            echo "❌ Error: Docker is not installed"
            exit 1
        fi

        # Restart Tailscale Funnel if we're root and Tailscale is installed
        if $RUNNING_AS_ROOT && command_exists tailscale; then
            echo "🔄 Checking Tailscale Funnel..."
            # Check if Funnel is configured
            if tailscale funnel status 2>/dev/null | grep -q -v "no funnels"; then
                echo "🔄 Restarting Tailscale Funnel..."
                tailscale funnel reset
                tailscale funnel --https=443 localhost:80
                echo "✅ Tailscale Funnel restarted"
            else
                echo "ℹ️  Tailscale Funnel not configured, skipping"
            fi
        elif command_exists tailscale && ! $RUNNING_AS_ROOT; then
            echo "ℹ️  Tailscale Funnel restart requires root privileges, skipping"
        fi
    fi
}

# Check if we're running as root
check_root

# Perform restart
restart_services

echo
echo "=========================================="
echo "✅ Restart complete!"
echo "Run './status.sh' to check the current status of all services"
echo "=========================================="
