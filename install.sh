#!/bin/bash
set -e

# Banner
echo "=========================================="
echo "Ollama Docker Installer"
echo "=========================================="

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Error: Git is not installed. Please install Git first."
    exit 1
fi

# Create installation directory
INSTALL_DIR="$HOME/x1-docker-ollama"
echo "Installing to: $INSTALL_DIR"

# Clone or update repository
if [ -d "$INSTALL_DIR" ]; then
    echo "Repository already exists, updating..."
    cd "$INSTALL_DIR"
    git pull
else
    echo "Cloning repository..."
    git clone https://github.com/haikucode-dev/x1-docker-ollama.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Make scripts executable
chmod +x setup.sh test.sh systemd-setup.sh

# Run setup script
echo "Running setup script..."
./setup.sh

echo "=========================================="
echo "✅ Installation complete!"
echo "Your Ollama service is now set up and running."
echo "To test the installation, run: cd $INSTALL_DIR && ./test.sh"
echo "To set up autostart on boot (Ubuntu): cd $INSTALL_DIR && sudo ./systemd-setup.sh"
echo "=========================================="
