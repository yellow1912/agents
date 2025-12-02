#!/bin/bash
# Export workflow handoff document for pausing/resuming
# Usage: ./commands/export-handoff.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT="$PROJECT_ROOT/ARTIFACTS/system/workflow-handoff.md"

cd "$PROJECT_ROOT"

if [ ! -f "ARTIFACTS/system/workflow-state.json" ]; then
    echo "No workflow state found. Run ~/.claude-agents/setup.sh first."
    exit 1
fi

echo "Generating handoff document..."

python3 scripts/generate-handoff.py --output "$OUTPUT"

echo ""
echo "✓ Exported to: $OUTPUT"
echo ""
echo "This document contains:"
echo "  - Current workflow status"
echo "  - Stage progress"
echo "  - Outstanding gates"
echo "  - Blocking issues"
echo "  - Resume instructions"
