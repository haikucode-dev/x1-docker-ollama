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
chmod +x setup.sh test.sh systemd-setup.sh tailscale-setup.sh uninstall.sh status.sh restart.sh

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

            # Offer to set up Tailscale Funnel
            if command -v tailscale &> /dev/null; then
                echo "Tailscale detected. Would you like to set up Tailscale Funnel to expose Ollama over HTTPS? (y/n)"
                read -r setup_tailscale

                if [[ "$setup_tailscale" =~ ^[Yy]$ ]]; then
                    echo "Setting up Tailscale Funnel..."
                    if [ "$EUID" -eq 0 ]; then
                        # Already running as root
                        ./tailscale-setup.sh
                    else
                        # Need sudo
                        echo "Sudo permission required to set up Tailscale Funnel."
                        sudo ./tailscale-setup.sh
                    fi
                else
                    echo "Skipping Tailscale Funnel setup. You can set it up later with: sudo ./tailscale-setup.sh"
                fi
            else
                echo "Tailscale not detected. If you'd like to expose Ollama with Tailscale Funnel,"
                echo "install Tailscale first and then run: sudo ./tailscale-setup.sh"
            fi
        else
            echo "Skipping systemd setup. You can set it up later with: sudo ./systemd-setup.sh"
        fi
    else
        # Non-interactive mode - provide instructions but don't prompt
        echo "Ubuntu detected but running in non-interactive mode."
        echo "To enable autostart, run: cd $INSTALL_DIR && sudo ./systemd-setup.sh"
        echo "To set up Tailscale Funnel, run: cd $INSTALL_DIR && sudo ./tailscale-setup.sh"
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

        # Only suggest Tailscale setup if Tailscale is installed
        if command -v tailscale &> /dev/null; then
            echo "To set up Tailscale Funnel: cd $INSTALL_DIR && sudo ./tailscale-setup.sh"
        fi
    fi
fi
echo "=========================================="
