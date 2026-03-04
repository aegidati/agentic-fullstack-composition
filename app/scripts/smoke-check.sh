#!/bin/bash
# Smoke check: Verify all services are healthy and responding

set -euo pipefail

# Change to the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "❌ .env file not found. Please run ./scripts/up.sh first."
    exit 1
fi

echo "🔍 Running smoke checks..."
echo ""

FAILED=0

# Check PostgreSQL
echo -n "Testing PostgreSQL... "
if docker compose exec -T postgres pg_isready -U ${POSTGRES_USER} > /dev/null 2>&1; then
    echo "✅"
else
    echo "❌"
    FAILED=$((FAILED + 1))
fi

# Check Backend
echo -n "Testing Backend health (/health)... "
BACKEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${BACKEND_PORT}/health 2>/dev/null || echo "000")
if [ "$BACKEND_HEALTH" = "200" ]; then
    echo "✅"
else
    echo "❌ (HTTP $BACKEND_HEALTH)"
    FAILED=$((FAILED + 1))
fi

# Check Web Frontend
echo -n "Testing Web frontend (/)... "
WEB_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${WEB_PORT}/ 2>/dev/null || echo "000")
if [ "$WEB_HEALTH" = "200" ]; then
    echo "✅"
else
    echo "❌ (HTTP $WEB_HEALTH)"
    FAILED=$((FAILED + 1))
fi

echo ""

if [ $FAILED -eq 0 ]; then
    echo "✅ All services are healthy!"
    echo ""
    echo "📋 Ready to use:"
    echo "  Backend: http://localhost:${BACKEND_PORT}"
    echo "  Web:     http://localhost:${WEB_PORT}"
    echo "  DB:      localhost:${POSTGRES_PORT}"
    exit 0
else
    echo "❌ Some services failed health checks ($FAILED errors)"
    echo ""
    echo "💡 Debug tips:"
    echo "  View logs: docker compose logs -f"
    echo "  Check service status: docker compose ps"
    exit 1
fi
