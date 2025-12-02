#!/bin/bash
# Fetch up-to-date library documentation using Context7 MCP
#
# Usage:
#   ./commands/context7.sh <topic>           # Fetch docs for a topic
#   ./commands/context7.sh --auto            # Auto-detect from project-config.json
#   ./commands/context7.sh --list            # Show what would be fetched
#
# Requires: Context7 MCP server configured in Claude Code
#
# Output: ARTIFACTS/system/context-refresh-report.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_CONFIG="$PROJECT_ROOT/project-config.json"
OUTPUT="$PROJECT_ROOT/ARTIFACTS/system/context-refresh-report.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

get_tech_stack() {
    if [ ! -f "$PROJECT_CONFIG" ]; then
        echo ""
        return
    fi

    python3 << 'PYEOF'
import json
import sys

try:
    with open("PROJECT_CONFIG_PATH") as f:
        config = json.load(f)

    stack = config.get("technology_stack", config.get("tech_stack", {}))
    items = []

    # Frontend
    fe = stack.get("frontend", {})
    if isinstance(fe, dict):
        if fe.get("framework"):
            items.append(fe["framework"])
    elif fe:
        items.append(str(fe))

    # Backend
    be = stack.get("backend", {})
    if isinstance(be, dict):
        if be.get("framework"):
            items.append(be["framework"])
    elif be:
        items.append(str(be))

    # Database
    db = stack.get("database", {})
    if isinstance(db, dict):
        if db.get("primary"):
            items.append(db["primary"])
    elif db:
        items.append(str(db))

    print(" ".join(items))
except Exception as e:
    print("", file=sys.stderr)
PYEOF
}

# ============================================================================
# MAIN
# ============================================================================

cd "$PROJECT_ROOT"

case "${1:-}" in
    --help|-h)
        echo "Context7 - Fetch up-to-date library documentation"
        echo ""
        echo "Usage:"
        echo "  context7.sh <topic>      Fetch docs for specific topic"
        echo "  context7.sh --auto       Auto-detect from project config"
        echo "  context7.sh --list       Show detected tech stack"
        echo "  context7.sh --help       Show this help"
        echo ""
        echo "Examples:"
        echo "  ./commands/context7.sh 'Next.js App Router'"
        echo "  ./commands/context7.sh 'FastAPI endpoints'"
        echo "  ./commands/context7.sh --auto"
        echo ""
        echo "Requires Context7 MCP server to be configured."
        echo "Output saved to: ARTIFACTS/system/context-refresh-report.json"
        ;;

    --list|-l)
        echo -e "${CYAN}Detected Tech Stack:${NC}"
        STACK=$(get_tech_stack | sed "s|PROJECT_CONFIG_PATH|$PROJECT_CONFIG|")
        if [ -n "$STACK" ]; then
            for item in $STACK; do
                echo "  - $item"
            done
        else
            echo "  (none detected - check project-config.json)"
        fi
        ;;

    --auto|-a)
        echo -e "${CYAN}Auto-detecting tech stack...${NC}"
        STACK=$(get_tech_stack | sed "s|PROJECT_CONFIG_PATH|$PROJECT_CONFIG|")

        if [ -z "$STACK" ]; then
            echo -e "${YELLOW}No tech stack detected in project-config.json${NC}"
            echo "Run with a specific topic instead:"
            echo "  ./commands/context7.sh 'React hooks'"
            exit 1
        fi

        echo -e "Found: ${GREEN}$STACK${NC}"
        echo ""
        echo "To fetch docs, use Context7 MCP in Claude Code:"
        echo ""
        for item in $STACK; do
            echo -e "  ${YELLOW}use context7: $item latest documentation${NC}"
        done
        echo ""
        echo "Or run this command with a specific topic:"
        for item in $STACK; do
            echo "  ./commands/context7.sh '$item'"
        done
        ;;

    "")
        echo "Usage: ./commands/context7.sh <topic>"
        echo ""
        echo "Examples:"
        echo "  ./commands/context7.sh 'React Server Components'"
        echo "  ./commands/context7.sh 'PostgreSQL JSON operators'"
        echo "  ./commands/context7.sh --auto"
        echo ""
        echo "Run --help for more options."
        exit 1
        ;;

    *)
        TOPIC="$1"
        echo -e "${CYAN}Context Refresh Request${NC}"
        echo ""
        echo -e "Topic: ${GREEN}$TOPIC${NC}"
        echo ""
        echo "To fetch documentation, use Context7 MCP in Claude Code:"
        echo ""
        echo -e "  ${YELLOW}use context7: $TOPIC${NC}"
        echo ""
        echo "Then save the summary to the context refresh report."
        echo ""

        # Create a placeholder report
        mkdir -p "$(dirname "$OUTPUT")"
        cat > "$OUTPUT" << EOF
{
  "topic": "$TOPIC",
  "source": "context7",
  "source_url": null,
  "summary": "Pending - run 'use context7: $TOPIC' in Claude Code",
  "fetched_at": "$TIMESTAMP",
  "for_stage": null,
  "status": "pending"
}
EOF
        echo "Placeholder created: $OUTPUT"
        echo "Update with actual content after fetching."
        ;;
esac
