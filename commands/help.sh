#!/bin/bash
# Interactive help and navigation for the AI-Native Development Framework
#
# Usage: ./commands/help.sh
#
# This is the "I don't know what to do" command. It shows you where you are
# and what you can do next.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WORKFLOW_STATE="$PROJECT_ROOT/ARTIFACTS/system/workflow-state.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        AI-Native Development Framework - Help              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if project is set up
if [ ! -f "$WORKFLOW_STATE" ]; then
    echo -e "${YELLOW}Project not set up yet.${NC}"
    echo ""
    echo "To get started, run:"
    echo -e "  ${CYAN}~/.claude-agents/setup.sh${NC}"
    echo ""
    echo "Or for an existing codebase:"
    echo -e "  ${CYAN}~/.claude-agents/setup.sh --analyze${NC}"
    exit 0
fi

# Get current stage
CURRENT_STAGE=$(python3 -c "import json; print(json.load(open('$WORKFLOW_STATE')).get('current_stage', 'unknown'))" 2>/dev/null || echo "unknown")
PROJECT_NAME=$(python3 -c "import json; print(json.load(open('$WORKFLOW_STATE')).get('product_name', 'unknown'))" 2>/dev/null || echo "unknown")

echo -e "Project: ${YELLOW}$PROJECT_NAME${NC}"
echo -e "Current Stage: ${GREEN}$CURRENT_STAGE${NC}"
echo ""

# Show what to do based on current stage
echo -e "${BOLD}What would you like to do?${NC}"
echo ""
echo -e "  ${GREEN}1)${NC} See detailed status"
echo -e "  ${GREEN}2)${NC} See what's next"
echo -e "  ${GREEN}3)${NC} Approve current stage"
echo -e "  ${GREEN}4)${NC} Create a checkpoint"
echo -e "  ${GREEN}5)${NC} Rollback to checkpoint"
echo -e "  ${GREEN}6)${NC} Validate artifacts"
echo -e "  ${GREEN}7)${NC} Export for handoff"
echo -e "  ${GREEN}8)${NC} Reset and start over"
echo -e "  ${GREEN}9)${NC} Show all commands"
echo -e "  ${GREEN}q)${NC} Quit"
echo ""

read -p "Enter choice [1-9, q]: " choice

case "$choice" in
    1)
        echo ""
        "$SCRIPT_DIR/status.sh"
        ;;
    2)
        echo ""
        "$SCRIPT_DIR/next.sh"
        ;;
    3)
        echo ""
        echo "Which stage to approve?"
        echo "  1) requirements"
        echo "  2) architecture"
        echo "  3) deployment"
        read -p "Enter choice [1-3]: " stage_choice
        case "$stage_choice" in
            1) "$SCRIPT_DIR/approve.sh" requirements ;;
            2) "$SCRIPT_DIR/approve.sh" architecture ;;
            3) "$SCRIPT_DIR/approve.sh" deployment ;;
            *) echo "Invalid choice" ;;
        esac
        ;;
    4)
        echo ""
        read -p "Checkpoint message (or press Enter for auto): " msg
        if [ -z "$msg" ]; then
            "$SCRIPT_DIR/checkpoint.sh" --auto
        else
            "$SCRIPT_DIR/checkpoint.sh" "$msg"
        fi
        ;;
    5)
        echo ""
        "$SCRIPT_DIR/rollback.sh"
        ;;
    6)
        echo ""
        "$SCRIPT_DIR/validate.sh" --all
        ;;
    7)
        echo ""
        "$SCRIPT_DIR/export-handoff.sh"
        ;;
    8)
        echo ""
        echo -e "${RED}This will reset ALL progress.${NC}"
        read -p "Are you sure? Type 'yes' to confirm: " confirm
        if [ "$confirm" = "yes" ]; then
            "$SCRIPT_DIR/reset.sh" --confirm
        else
            echo "Reset cancelled."
        fi
        ;;
    9)
        echo ""
        echo -e "${BOLD}All Available Commands:${NC}"
        echo ""
        echo -e "  ${CYAN}./commands/help.sh${NC}"
        echo "      Interactive help (this menu)"
        echo ""
        echo -e "  ${CYAN}./commands/status.sh${NC}"
        echo "      Show current workflow status, stages, and checkpoints"
        echo ""
        echo -e "  ${CYAN}./commands/next.sh${NC}"
        echo "      Show what to do next based on current stage"
        echo ""
        echo -e "  ${CYAN}./commands/approve.sh <stage>${NC}"
        echo "      Approve a stage (requirements, architecture, deployment)"
        echo ""
        echo -e "  ${CYAN}./commands/checkpoint.sh \"message\"${NC}"
        echo "      Create a checkpoint for rollback"
        echo "      --list    Show all checkpoints"
        echo "      --auto    Auto-generate message from current stage"
        echo ""
        echo -e "  ${CYAN}./commands/rollback.sh${NC}"
        echo "      Rollback to a previous checkpoint"
        echo "      --last    Rollback to most recent"
        echo "      --preview Show what would change"
        echo ""
        echo -e "  ${CYAN}./commands/validate.sh${NC}"
        echo "      Validate artifact files"
        echo "      --all     Validate all artifacts"
        echo ""
        echo -e "  ${CYAN}./commands/export-handoff.sh${NC}"
        echo "      Export current state for pausing work"
        echo ""
        echo -e "  ${CYAN}./commands/reset.sh --confirm${NC}"
        echo "      Reset workflow and start over"
        echo ""
        echo -e "  ${CYAN}./commands/stage-complete.sh <agent> <stage> <status>${NC}"
        echo "      (For agents) Signal stage completion"
        echo ""
        ;;
    q|Q)
        echo "Bye!"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        ;;
esac

echo ""
echo -e "${CYAN}Run ./commands/help.sh again anytime you need guidance.${NC}"
