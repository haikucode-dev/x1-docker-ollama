#!/bin/bash
set -e

# Banner
echo "=========================================="
echo "Ollama Docker Setup with API Authentication"
echo "=========================================="

# Check for docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file with a secure API token..."
    # Generate a random token
    RANDOM_TOKEN=$(openssl rand -hex 32)
    echo "API_TOKEN=$RANDOM_TOKEN" > .env
    echo "✅ API token generated and saved to .env file"
    echo "⚠️  Important: Keep this token secure. You'll need it to access the API."
    echo "Your API token is: $RANDOM_TOKEN"
else
    echo "✅ .env file already exists, using existing configuration"
fi

# Start the service
echo "Starting Ollama service..."
docker compose up -d

echo "=========================================="
echo "✅ Setup complete!"
echo "Ollama service is now running."
echo "API is available with Bearer token authentication."
echo "Run './test.sh' to verify everything is working correctly."
echo "=========================================="

# Check if we're in an interactive terminal
if [ -t 0 ]; then
    echo
    echo "Would you like to download the gemma3:1b model? (y/n)"
    read -r download_gemma

    if [[ "$download_gemma" =~ ^[Yy]$ ]]; then
        echo "Downloading gemma3:1b model..."
        echo "This may take a few minutes depending on your internet connection."
        docker exec -it ollama ollama pull gemma3:1b
        echo "✅ gemma3:1b model has been downloaded successfully!"
        echo "You can now use it with: docker exec -it ollama ollama run gemma3:1b"
    else
        echo "Skipping gemma3:1b model download."
        echo "You can download it later with: docker exec -it ollama ollama pull gemma3:1b"
    fi
fi
