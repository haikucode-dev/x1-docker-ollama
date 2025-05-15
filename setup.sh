#!/bin/bash
set -e

# Banner
echo "=========================================="
echo "Ollama Docker Setup with API Authentication"
echo "=========================================="

# Check for docker and docker-compose
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is not installed. Please install Docker Compose first."
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
docker-compose up -d

echo "=========================================="
echo "✅ Setup complete!"
echo "Ollama service is now running."
echo "API is available with Bearer token authentication."
echo "Run './test.sh' to verify everything is working correctly."
echo "=========================================="
