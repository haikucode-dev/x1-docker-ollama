#!/bin/bash
set -e

# Banner
echo "=========================================="
echo "Ollama Docker + Tailscale Funnel Status"
echo "=========================================="
echo

# Quick status overview
echo "Configuration Overview:"
echo "─────────────────────"

# API Token
if [ -f ".env" ]; then
    echo "✓ API Token: Configured"
else
    echo "✗ API Token: Not configured"
fi

# Docker
if command -v docker &> /dev/null; then
    echo "✓ Docker: Installed"
else
    echo "✗ Docker: Not installed"
fi

# Docker Containers
if docker ps 2>/dev/null | grep -q ollama; then
    echo "✓ Ollama Container: Running"
else
    echo "✗ Ollama Container: Not running"
fi

# Systemd Services
if [ -f /etc/systemd/system/ollama-docker.service ]; then
    echo "✓ Systemd Autostart: Configured"
else
    echo "✗ Systemd Autostart: Not configured"
fi

# Tailscale
if command -v tailscale &> /dev/null; then
    echo "✓ Tailscale: Installed"
else
    echo "✗ Tailscale: Not installed"
fi

# Tailscale Funnel Service
if [ -f /etc/systemd/system/ollama-tailscale-funnel.service ]; then
    echo "✓ Tailscale Funnel Service: Configured"
else
    echo "✗ Tailscale Funnel Service: Not configured"
fi

echo
echo "Detailed Status:"
echo "═══════════════════════════════════════"

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to check systemd service status
check_service_status() {
    local service_name="$1"
    local status
    local autostart

    if systemctl list-unit-files | grep -q "$service_name"; then
        status=$(systemctl is-active "$service_name")
        autostart=$(systemctl is-enabled "$service_name" 2>/dev/null || echo "disabled")
        echo "  - Status: $status"
        echo "  - Autostart: $autostart"

        # Show the last few log entries if the service is active
        if [ "$status" = "active" ]; then
            echo "  - Recent logs:"
            systemctl status "$service_name" --no-pager -n 3 | grep -v "^$" | grep -v "^●" | sed 's/^/    /'
        fi
    else
        echo "  - Not installed"
    fi
}

# Check Docker
echo "🐳 Docker:"
if command_exists docker; then
    echo "  - Installed: Yes"

    # Check Docker service
    docker_service_status=$(systemctl is-active docker 2>/dev/null || echo "inactive")
    docker_service_autostart=$(systemctl is-enabled docker 2>/dev/null || echo "disabled")
    echo "  - Service: $docker_service_status (autostart: $docker_service_autostart)"

    # Check if Docker Compose file exists
    if [ -f "docker-compose.yml" ]; then
        echo "  - docker-compose.yml: Found"

        # Check for running containers
        echo "  - Containers:"
        if docker compose ps --services | grep -q ollama; then
            for service in $(docker compose ps --services); do
                container_status=$(docker compose ps --format json $service | grep -o '"State":"[^"]*"' | cut -d'"' -f4)
                echo "    - $service: $container_status"
            done
        else
            echo "    - No containers running"
        fi

        # List Ollama models if container is running
        if docker ps | grep -q ollama; then
            echo "  - Ollama Models:"
            docker exec -it ollama ollama list 2>/dev/null | tail -n +2 | while read -r line; do
                model_name=$(echo "$line" | awk '{print $1}')
                model_size=$(echo "$line" | awk '{print $2}')
                echo "    - $model_name ($model_size)"
            done
        fi
    else
        echo "  - docker-compose.yml: Not found"
    fi
else
    echo "  - Installed: No"
fi

# Check Ollama Docker service
echo
echo "🚀 Ollama Docker Service:"
check_service_status "ollama-docker.service"

# Check Tailscale
echo
echo "🔗 Tailscale:"
if command_exists tailscale; then
    echo "  - Installed: Yes"
    ts_status=$(tailscale status --json | grep -o '"BackendState":"[^"]*"' | cut -d'"' -f4)
    echo "  - Status: $ts_status"

    # Check if Funnel is configured
    funnel_status=$(tailscale funnel status 2>/dev/null | grep -q "no funnels" && echo "not configured" || echo "configured")
    echo "  - Funnel: $funnel_status"

    # Show funnel details if configured
    if [ "$funnel_status" = "configured" ]; then
        echo "  - Funnel Details:"
        tailscale funnel status | grep -v "^$" | sed 's/^/    /'
    fi
else
    echo "  - Installed: No"
fi

# Check Tailscale Funnel service
echo
echo "🌐 Tailscale Funnel Service:"
check_service_status "ollama-tailscale-funnel.service"

# Check API access
echo
echo "🔑 API Access:"
if [ -f ".env" ]; then
    source .env
    echo "  - API Token: Configured"

    # Test API access
    if docker ps | grep -q caddy && docker ps | grep -q ollama; then
        echo "  - Testing API connection..."
        api_status=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $API_TOKEN" http://localhost/api/tags 2>/dev/null || echo "Failed")

        if [ "$api_status" = "200" ]; then
            echo "  - API Connection: Successful (Status $api_status)"
        else
            echo "  - API Connection: Failed (Status $api_status)"
        fi
    else
        echo "  - API Connection: Containers not running"
    fi
else
    echo "  - API Token: Not configured"
fi

echo
echo "=========================================="
echo "Recommended Actions:"
echo "=========================================="

# Check what's missing and suggest actions
if [ ! -f ".env" ]; then
    echo "→ Run './setup.sh' to create API token"
fi

if ! docker ps 2>/dev/null | grep -q ollama; then
    echo "→ Run './setup.sh' to start Docker containers"
fi

if [ ! -f /etc/systemd/system/ollama-docker.service ]; then
    echo "→ Run 'sudo ./systemd-setup.sh' to enable autostart on boot"
fi

if command -v tailscale &> /dev/null && [ ! -f /etc/systemd/system/ollama-tailscale-funnel.service ]; then
    echo "→ Run 'sudo ./tailscale-setup.sh' to enable Tailscale Funnel"
fi

# Always available actions
echo "→ Run './test.sh' for detailed API tests"
echo "→ Run './update.sh' to update to latest version"
echo "=========================================="
