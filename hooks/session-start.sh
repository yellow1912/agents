#!/bin/bash
# AI-Native Framework - Session Start Hook
# Displays current workflow status when Claude Code starts
#
# This hook runs once at session start to remind Claude of:
# - The active framework and current workflow stage
# - Which agent spec to follow
# - Where to save artifacts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Find framework path from project-config.json
FRAMEWORK_PATH=""
if [ -f "$PROJECT_ROOT/project-config.json" ]; then
    FRAMEWORK_PATH=$(grep -o '"framework_path"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROJECT_ROOT/project-config.json" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "")
fi

# Fallback to common locations
if [ -z "$FRAMEWORK_PATH" ] || [ ! -d "$FRAMEWORK_PATH" ]; then
    if [ -d "$HOME/.claude-agents" ]; then
        FRAMEWORK_PATH="$HOME/.claude-agents"
    elif [ -d "/root/.claude-agents" ]; then
        FRAMEWORK_PATH="/root/.claude-agents"
    fi
fi

# Check for workflow state
WORKFLOW_STATE="$PROJECT_ROOT/ARTIFACTS/system/workflow-state.json"

if [ ! -f "$WORKFLOW_STATE" ]; then
    # No workflow state - framework not fully set up
    cat << 'EOF'

══════════════════════════════════════════════════════════════
  AI-NATIVE DEVELOPMENT FRAMEWORK
══════════════════════════════════════════════════════════════

Framework detected but no workflow state found.
Run ./commands/status.sh or describe what you want to build.

EOF
    exit 0
fi

# Extract workflow info
CURRENT_STAGE=$(grep -o '"current_stage"[[:space:]]*:[[:space:]]*"[^"]*"' "$WORKFLOW_STATE" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")
PRODUCT_NAME=$(grep -o '"product_name"[[:space:]]*:[[:space:]]*"[^"]*"' "$WORKFLOW_STATE" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")
EXEC_MODE=$(grep -o '"execution_mode"[[:space:]]*:[[:space:]]*"[^"]*"' "$WORKFLOW_STATE" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "full_system")

# Map stage to agent
get_agent_for_stage() {
    case "$1" in
        requirements) echo "product-manager" ;;
        architecture) echo "system-architect" ;;
        frontend_implementation) echo "frontend-engineer" ;;
        backend_implementation) echo "backend-engineer" ;;
        ai_implementation) echo "ai-engineer" ;;
        qa_testing) echo "qa-engineer" ;;
        deployment) echo "devops-engineer" ;;
        *) echo "product-manager" ;;
    esac
}

CURRENT_AGENT=$(get_agent_for_stage "$CURRENT_STAGE")
AGENT_SPEC="$FRAMEWORK_PATH/L1 - Specialist Agents/${CURRENT_AGENT}.md"

# Output the context reminder
cat << EOF

══════════════════════════════════════════════════════════════
  AI-NATIVE DEVELOPMENT FRAMEWORK ACTIVE
══════════════════════════════════════════════════════════════

Project: $PRODUCT_NAME
Mode: $EXEC_MODE
Current Stage: $CURRENT_STAGE

INSTRUCTIONS:
1. Read the agent spec: @$AGENT_SPEC
2. Follow the workflow for this stage
3. Save artifacts to: ARTIFACTS/${CURRENT_AGENT}/
4. Ask for user approval at gates

Commands: ./commands/status.sh | ./commands/next.sh

══════════════════════════════════════════════════════════════

EOF

exit 0
