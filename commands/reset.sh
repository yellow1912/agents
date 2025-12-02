#!/bin/bash
# Reset workflow state and delete all artifacts
# Usage: ./commands/reset.sh --confirm

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ "$1" != "--confirm" ]; then
    echo "This will reset the workflow state and delete all artifacts."
    echo "Run with --confirm to proceed:"
    echo ""
    echo "  ./commands/reset.sh --confirm"
    exit 1
fi

cd "$PROJECT_ROOT"

echo "Resetting workflow..."

# Remove all artifacts
rm -rf ARTIFACTS/*

# Recreate directory structure
mkdir -p ARTIFACTS/{product-manager,system-architect,frontend-engineer,backend-engineer,ai-engineer,qa-engineer,devops-engineer,system}

echo "✓ Workflow reset complete."
echo ""
echo "Run ~/.claude-agents/setup.sh to start fresh."
