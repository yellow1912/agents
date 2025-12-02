#!/bin/bash
# Validate artifacts against schemas
# Usage: ./commands/validate.sh [artifact-path]
#        ./commands/validate.sh --all

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

if [ "$1" == "--all" ]; then
    echo "Validating all artifacts..."
    python3 scripts/validate.py --all
elif [ -n "$1" ]; then
    echo "Validating: $1"
    python3 scripts/validate.py "$1"
else
    echo "Usage: ./commands/validate.sh [artifact-path]"
    echo "       ./commands/validate.sh --all"
    echo ""
    echo "Examples:"
    echo "  ./commands/validate.sh ARTIFACTS/product-manager/product-requirements-packet.json"
    echo "  ./commands/validate.sh --all"
fi
