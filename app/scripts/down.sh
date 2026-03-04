#!/bin/bash
# Stop the full-stack composition

set -euo pipefail

# Change to the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

echo "Stopping fullstack composition..."

docker compose down

echo "✅ Composition stopped"
echo ""
echo "💡 To remove volumes as well: docker compose down -v"
