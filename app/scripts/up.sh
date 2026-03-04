#!/bin/bash
# Start the full-stack composition

set -euo pipefail

# Change to the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

echo "Starting fullstack composition..."
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from .env.example..."
    cp .env.example .env
    echo "✅ Created .env file. Please update it with your settings if needed."
    echo ""
fi

# Load environment variables
export $(grep -v '^#' .env | xargs)

echo "Configuration:"
echo "  Database: ${POSTGRES_DB}@postgres:${POSTGRES_PORT}"
echo "  Backend: http://localhost:${BACKEND_PORT}"
echo "  Web: http://localhost:${WEB_PORT}"
echo ""

# Start composition
docker compose up -d

echo ""
echo "✅ Composition is starting..."
echo ""
echo "Waiting for services to be healthy..."
sleep 5

# Check status
docker compose ps

echo ""
echo "📋 Service URLs:"
echo "  Backend Health: http://localhost:${BACKEND_PORT}/health"
echo "  Web Frontend: http://localhost:${WEB_PORT}"
echo "  Database: localhost:${POSTGRES_PORT}"
echo ""
echo "💡 View logs: docker compose logs -f"
echo "💡 Stop services: ./scripts/down.sh"
echo "💡 Run smoke tests: ./scripts/smoke-check.sh"
