# x1-docker-ollama

# Docker Setup for Ollama with API Authentication

A `docker` setup to run an [Ollama](https://ollama.com/) instance protected with API authentication (Bearer token) on a Minisforum X1 Pro with AMD ROCm GPU support.

## Features
- **Ollama in Docker**: Easily run Ollama in a containerized environment.
- **API Auth**: Secured with Bearer token authentication.
- **Automated Setup**: One-line installation command to set everything up.
- **Testing Tools**: Verify your installation with a simple test script.
- **Autostart Support**: Systemd service setup for automatic startup on boot.
- **Tailscale Funnel**: Expose your Ollama instance securely over the internet using Tailscale Funnel.
- **Clean Uninstall**: Easily remove all components with a single script.
- **Model Download**: Option to download gemma3:1b during setup.
- **Status Monitoring**: Comprehensive status overview of all services.
- **Quick Restart**: Restart all services with a single command.

## Quick Install (One-Line Command)

```bash
curl -fsSL https://raw.githubusercontent.com/haikucode-dev/x1-docker-ollama/main/install.sh | bash
```

This command will:
1. Clone the repository to your home directory
2. Set up a secure random API token
3. Start the Ollama service
4. On Ubuntu systems, offer to configure autostart on boot (systemd)

## Setup Options

| Script | Purpose | Requires Sudo | Creates Systemd Services | Preserves API Token |
|--------|---------|---------------|---------------------------|---------------------|
| `./setup.sh` | Basic Docker setup | No | No | Yes |
| `./systemd-setup.sh` | Enable autostart on boot | Yes | ollama-docker.service | N/A |
| `./tailscale-setup.sh` | Enable Tailscale Funnel + autostart | Yes | ollama-docker.service<br>ollama-tailscale-funnel.service | N/A |
| `./update.sh` | Update to latest version | Optional* | No (restarts existing) | Yes |
| `./restart.sh` | Restart all services | Optional* | No | N/A |
| `./status.sh` | Check system status | No | No | N/A |
| `./test.sh` | Test API connectivity | No | No | N/A |
| `./uninstall.sh` | Remove all components | Yes | Removes all | N/A |

*Sudo required for systemd service operations, but script works without it for Docker operations

## Common Workflows

### Initial Setup
```bash
# Basic setup (Docker only)
./setup.sh

# Enable autostart on boot
sudo ./systemd-setup.sh

# Or, enable with Tailscale Funnel
sudo ./tailscale-setup.sh
```

### Updating Your Installation
```bash
# Pull latest changes
git pull

# Update while preserving your API token
./update.sh

# Or with sudo to also restart systemd services
sudo ./update.sh
```

### Checking System Health
```bash
# Get complete status overview
./status.sh

# Test API connectivity
./test.sh
```

### Maintenance
```bash
# Restart all services
sudo ./restart.sh

# Complete removal
sudo ./uninstall.sh
```

## API Authentication

The API is protected with Bearer token authentication. The setup script automatically generates a secure token and saves it in the `.env` file.

To interact with the API, include the token in your requests:

```bash
curl -H "Authorization: Bearer YOUR_API_TOKEN" http://localhost/api/tags
```

## Using Ollama commands

```bash
docker exec -it ollama ollama run phi4:latest
docker exec ollama ollama list
```

## Manual Installation

If you prefer to install manually:

1. Clone this repository:
   ```bash
   git clone https://github.com/haikucode-dev/x1-docker-ollama.git
   cd x1-docker-ollama
   ```

2. Run the setup script:
   ```bash
   ./setup.sh
   ```

   This will:
   - Generate a secure random API token and save it to `.env`
   - Start the Ollama service with docker compose

3. Test your installation:
   ```bash
   ./test.sh
   ```

## Run on Startup (Ubuntu)

To set up Ollama to start automatically on system boot, simply run the systemd setup script:

```bash
sudo ./systemd-setup.sh
```

This script will:
1. Create a systemd service file with the correct paths
2. Enable the service to start on boot
3. Start the service immediately

### Managing the Service

After setup, you can manage the service with these commands:

```bash
# Check status
sudo systemctl status ollama-docker.service

# Stop the service
sudo systemctl stop ollama-docker.service

# Start the service
sudo systemctl start ollama-docker.service

# Disable autostart
sudo systemctl disable ollama-docker.service
```

## Expose Ollama with Tailscale Funnel

To expose your Ollama instance securely over the internet using Tailscale Funnel, run:

```bash
sudo ./tailscale-setup.sh
```

This script will:
1. Install the Ollama Docker service (similar to systemd-setup.sh)
2. Configure a Tailscale Funnel service that exposes port 80 with HTTPS
3. Set up both services to start automatically on boot and restart on failure

### Prerequisites

- [Tailscale](https://tailscale.com/) must be installed and logged in
- You need a Tailscale account with Funnel capability enabled

### Managing Tailscale Funnel

After setup, you can manage the Tailscale Funnel service with:

```bash
# Check Tailscale Funnel status
sudo systemctl status ollama-tailscale-funnel.service

# Stop Tailscale Funnel
sudo systemctl stop ollama-tailscale-funnel.service

# Start Tailscale Funnel
sudo systemctl start ollama-tailscale-funnel.service

# View your Funnel URL
tailscale funnel status
```

## System Status

To get a comprehensive overview of all services, their status, and configuration, run:

```bash
./status.sh
```

This script provides information about:
- Docker and container status
- Installed Ollama models
- Systemd services status and autostart configuration
- Tailscale and Funnel configuration
- API connectivity

It's a great way to quickly diagnose issues or verify that everything is running correctly.

## Restarting Services

To restart all components of the system (Docker containers and systemd services), run:

```bash
sudo ./restart.sh
```

This script will:
- Restart the Ollama Docker service if installed
- Restart the Tailscale Funnel service if installed
- Restart Docker containers directly if systemd services aren't available
- Reset and reconfigure Tailscale Funnel if needed

Running without sudo will still restart Docker containers but may not be able to restart systemd services.

## Uninstallation

To completely remove all components installed by this repository, run:

```bash
sudo ./uninstall.sh
```

This script will:
1. Stop and remove all systemd services (Ollama Docker and Tailscale Funnel)
2. Reset any Tailscale Funnel configurations
3. Stop and remove Docker containers and volumes
4. Provide instructions for removing the repository files

The uninstall script includes confirmation prompts to prevent accidental deletions.

---

*Note: The setup scripts automatically detect your repository path and required executables, so no manual configuration is needed.*
