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

# Check if running on Ubuntu and offer to set up systemd service
if [ -f /etc/lsb-release ] && grep -q "Ubuntu" /etc/lsb-release; then
    # Check if we're in an interactive terminal
    if [ -t 0 ]; then
        echo "Ubuntu detected. Would you like to set up Ollama to start automatically on boot? (y/n)"
        read -r setup_systemd

        if [[ "$setup_systemd" =~ ^[Yy]$ ]]; then
            echo "Setting up systemd service for autostart..."
            if [ "$EUID" -eq 0 ]; then
                # Already running as root
                ./systemd-setup.sh
            else
                # Need sudo
                echo "Sudo permission required to set up systemd service."
                sudo ./systemd-setup.sh
            fi
        else
            echo "Skipping systemd setup. You can set it up later with: sudo ./systemd-setup.sh"
        fi
    else
        # Non-interactive mode - provide instructions but don't prompt
        echo "Ubuntu detected but running in non-interactive mode."
        echo "To enable autostart, run: cd $INSTALL_DIR && sudo ./systemd-setup.sh"
    fi
fi

echo "=========================================="
echo "✅ Installation complete!"
echo "Your Ollama service is now set up and running."
echo "To test the installation, run: cd $INSTALL_DIR && ./test.sh"
if ! [ -f /etc/lsb-release ] || ! grep -q "Ubuntu" /etc/lsb-release || [[ ! "$setup_systemd" =~ ^[Yy]$ ]]; then
    if [ -f /etc/lsb-release ] && grep -q "Ubuntu" /etc/lsb-release && [ ! -t 0 ]; then
        # Skip this on non-interactive Ubuntu as we already provided the instruction
        :
    else
        echo "To set up autostart on boot (Ubuntu): cd $INSTALL_DIR && sudo ./systemd-setup.sh"
    fi
fi
echo "=========================================="
