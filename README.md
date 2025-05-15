# x1-docker-ollama

# Docker Compose Setup for Ollama with API Authentication

A `docker-compose` setup to run an [Ollama](https://ollama.com/) instance protected with API authentication (Bearer token) on a Minisforum X1 Pro with AMD ROCm GPU support.

## Features
- **Ollama in Docker**: Easily run Ollama in a containerized environment.
- **API Auth**: Secured with Bearer token authentication.
- **Automated Setup**: One-line installation command to set everything up.
- **Testing Tools**: Verify your installation with a simple test script.
- **Autostart Support**: Systemd service setup for automatic startup on boot.

## Quick Install (One-Line Command)

```bash
curl -fsSL https://raw.githubusercontent.com/haikucode-dev/x1-docker-ollama/main/install.sh | bash
```

This command will:
1. Clone the repository to your home directory
2. Set up a secure random API token
3. Start the Ollama service
4. On Ubuntu systems, offer to configure autostart on boot (systemd)

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
   - Start the Ollama service with docker-compose

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

---

*Note: The systemd setup script automatically detects your repository path and docker-compose location, so no manual configuration is needed.*
