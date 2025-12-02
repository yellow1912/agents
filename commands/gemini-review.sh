#!/bin/bash
# Request a second-opinion review from Gemini MCP
#
# Usage:
#   ./commands/gemini-review.sh <artifact-path>    # Review specific artifact
#   ./commands/gemini-review.sh --architecture     # Review architecture handover
#   ./commands/gemini-review.sh --last             # Review most recent artifact
#
# Requires: Gemini MCP server configured in Claude Code
#
# Output: ARTIFACTS/system/second-opinion-review.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT="$PROJECT_ROOT/ARTIFACTS/system/second-opinion-review.json"
WORKFLOW_STATE="$PROJECT_ROOT/ARTIFACTS/system/workflow-state.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

get_risk_level() {
    if [ -f "$WORKFLOW_STATE" ]; then
        python3 -c "import json; print(json.load(open('$WORKFLOW_STATE')).get('safety_and_governance',{}).get('risk_level','unknown'))" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

find_latest_artifact() {
    # Find the most recently modified artifact
    find "$PROJECT_ROOT/ARTIFACTS" -name "*.json" -type f \
        ! -path "*/system/*" \
        -printf '%T@ %p\n' 2>/dev/null | \
        sort -rn | head -1 | cut -d' ' -f2-
}

# ============================================================================
# MAIN
# ============================================================================

cd "$PROJECT_ROOT"

case "${1:-}" in
    --help|-h)
        echo "Gemini Review - Request second-opinion from Gemini AI"
        echo ""
        echo "Usage:"
        echo "  gemini-review.sh <artifact>      Review specific artifact"
        echo "  gemini-review.sh --architecture  Review architecture handover"
        echo "  gemini-review.sh --last          Review most recent artifact"
        echo "  gemini-review.sh --help          Show this help"
        echo ""
        echo "Examples:"
        echo "  ./commands/gemini-review.sh ARTIFACTS/system-architect/architecture-handover-packet.json"
        echo "  ./commands/gemini-review.sh --architecture"
        echo ""
        echo "Requires Gemini MCP server to be configured."
        echo "Output saved to: ARTIFACTS/system/second-opinion-review.json"
        ;;

    --architecture|-a)
        ARTIFACT="$PROJECT_ROOT/ARTIFACTS/system-architect/architecture-handover-packet.json"
        if [ ! -f "$ARTIFACT" ]; then
            ARTIFACT="$PROJECT_ROOT/ARTIFACTS/system-architect/architecture-assessment.json"
        fi
        if [ ! -f "$ARTIFACT" ]; then
            echo -e "${RED}No architecture artifact found.${NC}"
            echo "Run the System Architect agent first."
            exit 1
        fi
        exec "$0" "$ARTIFACT"
        ;;

    --last|-l)
        ARTIFACT=$(find_latest_artifact)
        if [ -z "$ARTIFACT" ]; then
            echo -e "${RED}No artifacts found.${NC}"
            exit 1
        fi
        echo -e "Latest artifact: ${CYAN}$ARTIFACT${NC}"
        exec "$0" "$ARTIFACT"
        ;;

    "")
        echo "Usage: ./commands/gemini-review.sh <artifact-path>"
        echo ""
        echo "Examples:"
        echo "  ./commands/gemini-review.sh ARTIFACTS/system-architect/architecture-handover-packet.json"
        echo "  ./commands/gemini-review.sh --architecture"
        echo "  ./commands/gemini-review.sh --last"
        echo ""
        echo "Run --help for more options."
        exit 1
        ;;

    *)
        ARTIFACT="$1"

        # Handle relative paths
        if [[ ! "$ARTIFACT" = /* ]]; then
            ARTIFACT="$PROJECT_ROOT/$ARTIFACT"
        fi

        if [ ! -f "$ARTIFACT" ]; then
            echo -e "${RED}Artifact not found: $ARTIFACT${NC}"
            exit 1
        fi

        RISK_LEVEL=$(get_risk_level)
        ARTIFACT_NAME=$(basename "$ARTIFACT")

        echo -e "${CYAN}Second Opinion Review Request${NC}"
        echo ""
        echo -e "Artifact:   ${GREEN}$ARTIFACT_NAME${NC}"
        echo -e "Risk Level: ${YELLOW}$RISK_LEVEL${NC}"
        echo ""
        echo "To request a Gemini review, use the Gemini MCP in Claude Code:"
        echo ""
        echo -e "${YELLOW}Ask Gemini to review this artifact for:${NC}"
        echo "  - Security concerns"
        echo "  - Architectural issues"
        echo "  - Best practice violations"
        echo "  - Scalability concerns"
        echo "  - Missing considerations"
        echo ""
        echo "Suggested prompt:"
        echo ""
        echo -e "  ${CYAN}@gemini Please review this architecture/implementation for security,${NC}"
        echo -e "  ${CYAN}scalability, and best practices. Note any concerns or suggestions.${NC}"
        echo ""

        # Create a placeholder report
        mkdir -p "$(dirname "$OUTPUT")"
        cat > "$OUTPUT" << EOF
{
  "scope": "$ARTIFACT_NAME",
  "reviewer": "gemini",
  "risk_level": "$RISK_LEVEL",
  "concerns": [],
  "suggestions": [],
  "verdict": "pending",
  "reviewed_at": "$TIMESTAMP",
  "status": "pending"
}
EOF

        echo "Placeholder created: $OUTPUT"
        echo ""
        echo "After Gemini review, update the file with:"
        echo "  - concerns: list of issues found"
        echo "  - suggestions: recommended improvements"
        echo "  - verdict: approve | approve_with_notes | needs_changes | reject"
        ;;
esac
