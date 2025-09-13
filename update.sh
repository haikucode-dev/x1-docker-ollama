#!/bin/bash
set -e

# Banner
echo "=========================================="
echo "Ollama Update Script"
echo "=========================================="

# Function to check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        RUNNING_AS_ROOT=true
    else
        RUNNING_AS_ROOT=false
    fi
}

# Function to detect current configuration
detect_configuration() {
    echo "Detecting current configuration..."
    echo

    # Check if .env exists (API token)
    if [ -f .env ]; then
        echo "✓ API token: Found (.env preserved)"
        HAS_ENV=true
    else
        echo "✗ API token: Not configured"
        HAS_ENV=false
    fi

    # Check if Docker containers are running
    if docker ps | grep -q ollama; then
        echo "✓ Docker containers: Running"
        DOCKER_RUNNING=true
    else
        echo "✗ Docker containers: Not running"
        DOCKER_RUNNING=false
    fi

    # Check for systemd services (requires root to fully check)
    if $RUNNING_AS_ROOT; then
        if systemctl list-unit-files | grep -q "ollama-docker.service"; then
            echo "✓ Systemd autostart: Configured (ollama-docker.service)"
            HAS_DOCKER_SYSTEMD=true
        else
            echo "✗ Systemd autostart: Not configured"
            HAS_DOCKER_SYSTEMD=false
        fi

        if systemctl list-unit-files | grep -q "ollama-tailscale-funnel.service"; then
            echo "✓ Tailscale Funnel: Configured (ollama-tailscale-funnel.service)"
            HAS_TAILSCALE_SYSTEMD=true
        else
            echo "✗ Tailscale Funnel: Not configured"
            HAS_TAILSCALE_SYSTEMD=false
        fi
    else
        echo "⚠ Systemd services: Check requires root access"
        if [ -f /etc/systemd/system/ollama-docker.service ]; then
            echo "  → ollama-docker.service file exists"
            HAS_DOCKER_SYSTEMD=true
        else
            HAS_DOCKER_SYSTEMD=false
        fi
        if [ -f /etc/systemd/system/ollama-tailscale-funnel.service ]; then
            echo "  → ollama-tailscale-funnel.service file exists"
            HAS_TAILSCALE_SYSTEMD=true
        else
            HAS_TAILSCALE_SYSTEMD=false
        fi
    fi

    echo
}

# Function to update Docker images
update_docker() {
    echo "Updating Docker images..."
    
    # Pull latest images
    docker compose pull
    
    # Recreate containers with new images
    docker compose up -d
    
    echo "✓ Docker images updated"
}

# Function to update systemd services
update_systemd() {
    if ! $RUNNING_AS_ROOT; then
        echo "⚠ Systemd service update requires root access"
        echo "  Run with: sudo ./update.sh"
        return
    fi

    if $HAS_DOCKER_SYSTEMD || $HAS_TAILSCALE_SYSTEMD; then
        echo "Updating systemd services..."
        
        # Reload systemd daemon to pick up any changes
        systemctl daemon-reload
        
        # Restart services if they exist
        if $HAS_DOCKER_SYSTEMD; then
            systemctl restart ollama-docker.service
            echo "✓ ollama-docker.service restarted"
        fi
        
        if $HAS_TAILSCALE_SYSTEMD; then
            systemctl restart ollama-tailscale-funnel.service
            echo "✓ ollama-tailscale-funnel.service restarted"
        fi
    fi
}

# Function to preserve and verify API token
verify_api_token() {
    if [ -f .env ]; then
        # Check if the file contains API_TOKEN
        if grep -q "API_TOKEN=" .env; then
            echo "✓ API token verified and preserved"
        else
            echo "⚠ Warning: .env exists but doesn't contain API_TOKEN"
        fi
    fi
}

# Main execution
echo "Starting update process..."
echo

# Check if running as root
check_root

# Detect current configuration
detect_configuration

# Verify API token is preserved
verify_api_token

echo
echo "=========================================="
echo "Performing updates..."
echo "=========================================="

# Update Docker containers
update_docker

# Update systemd services if configured
if $HAS_DOCKER_SYSTEMD || $HAS_TAILSCALE_SYSTEMD; then
    update_systemd
fi

echo
echo "=========================================="
echo "✅ Update complete!"
echo "=========================================="
echo

# Show current status
echo "Current status:"
if docker ps | grep -q ollama; then
    echo "✓ Ollama container: Running"
else
    echo "✗ Ollama container: Not running"
fi

if $RUNNING_AS_ROOT && $HAS_DOCKER_SYSTEMD; then
    echo "✓ ollama-docker.service: $(systemctl is-active ollama-docker.service)"
fi

if $RUNNING_AS_ROOT && $HAS_TAILSCALE_SYSTEMD; then
    echo "✓ ollama-tailscale-funnel.service: $(systemctl is-active ollama-tailscale-funnel.service)"
fi

echo
echo "Run './status.sh' for detailed status information"