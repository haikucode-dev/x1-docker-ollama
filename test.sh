#!/bin/bash
set -e

# Banner
echo "=========================================="
echo "Ollama API Test Script"
echo "=========================================="

# Check if the .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found. Please run setup.sh first."
    exit 1
fi

# Source the .env file to get the API token
source .env

# Check if the API_TOKEN is set
if [ -z "$API_TOKEN" ]; then
    echo "Error: API_TOKEN not found in .env file."
    exit 1
fi

echo "Testing Ollama API connection..."

# Test the API connection
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $API_TOKEN" http://localhost/api/tags)

if [ "$STATUS" -eq 200 ]; then
    echo "✅ API connection successful! (Status code: $STATUS)"
    echo "Fetching available models..."

    # Get available models
    MODELS=$(curl -s -H "Authorization: Bearer $API_TOKEN" http://localhost/api/tags)
    echo "$MODELS"

    echo "=========================================="
    echo "✅ All tests passed!"
    echo "Your Ollama instance is running correctly with API authentication."
    echo "=========================================="
    echo "Usage example:"
    echo "curl -H \"Authorization: Bearer $API_TOKEN\" http://localhost/api/tags"
else
    echo "❌ API connection failed! (Status code: $STATUS)"
    echo "Please check that:"
    echo "  1. The Ollama service is running (docker-compose ps)"
    echo "  2. Your API token is correct"
    echo "  3. The Caddy reverse proxy is properly configured"
    echo "=========================================="
    echo "To view logs: docker-compose logs"
    echo "To restart: docker-compose restart"
fi
