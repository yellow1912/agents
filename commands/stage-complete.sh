#!/bin/bash
# Emit a stage completion signal (for agent use)
# Usage: ./commands/stage-complete.sh <agent> <stage> <status> [artifact-path]

AGENT="$1"
STAGE="$2"
STATUS="${3:-completed}"
ARTIFACT="$4"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -z "$AGENT" ] || [ -z "$STAGE" ]; then
    echo "Usage: ./commands/stage-complete.sh <agent> <stage> <status> [artifact-path]"
    echo ""
    echo "Valid agents:"
    echo "  product_manager, system_architect, frontend_engineer, backend_engineer,"
    echo "  ai_engineer, qa_engineer, devops_engineer, safety_agent, governance_agent,"
    echo "  code_health_agent"
    echo ""
    echo "Valid stages:"
    echo "  requirements, architecture, frontend_implementation, backend_implementation,"
    echo "  ai_implementation, qa_testing, deployment, safety_review, governance_review,"
    echo "  code_health_assessment"
    echo ""
    echo "Valid statuses:"
    echo "  completed, completed_with_warnings, failed, blocked, requires_human_intervention"
    exit 1
fi

# Validate inputs
VALID_AGENTS="product_manager system_architect frontend_engineer backend_engineer ai_engineer qa_engineer devops_engineer safety_agent governance_agent code_health_agent"
VALID_STAGES="requirements architecture frontend_implementation backend_implementation ai_implementation qa_testing deployment safety_review governance_review code_health_assessment"
VALID_STATUSES="completed completed_with_warnings failed blocked requires_human_intervention"

if ! echo "$VALID_AGENTS" | grep -qw "$AGENT"; then
    echo "ERROR: Invalid agent: $AGENT"
    exit 1
fi

if ! echo "$VALID_STAGES" | grep -qw "$STAGE"; then
    echo "ERROR: Invalid stage: $STAGE"
    exit 1
fi

if ! echo "$VALID_STATUSES" | grep -qw "$STATUS"; then
    echo "ERROR: Invalid status: $STATUS"
    exit 1
fi

# Build artifacts array
if [ -n "$ARTIFACT" ]; then
    ARTIFACTS_JSON="[\"$ARTIFACT\"]"
else
    ARTIFACTS_JSON="[]"
fi

# Generate completion signal
cat > "$PROJECT_ROOT/ARTIFACTS/system/stage-completion-signal.json" << EOF
{
  "agent": "$AGENT",
  "stage": "$STAGE",
  "status": "$STATUS",
  "timestamp": "$TIMESTAMP",
  "output_artifacts": $ARTIFACTS_JSON,
  "blocking_issues": [],
  "next_agent_required": null
}
EOF

echo "Stage completion signal created:"
echo ""
cat "$PROJECT_ROOT/ARTIFACTS/system/stage-completion-signal.json"
echo ""

# Validate the signal
echo "Validating..."
cd "$PROJECT_ROOT"
python3 scripts/validate.py ARTIFACTS/system/stage-completion-signal.json

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Signal is valid. Orchestrator can process it."

    # Auto-checkpoint on successful stage completion
    if [ "$STATUS" = "completed" ] || [ "$STATUS" = "completed_with_warnings" ]; then
        if git rev-parse --git-dir > /dev/null 2>&1; then
            echo ""
            echo "Creating automatic checkpoint..."
            "$SCRIPT_DIR/checkpoint.sh" --auto 2>/dev/null || true
        fi
    fi
else
    echo ""
    echo "✗ Signal validation failed."
    exit 1
fi
