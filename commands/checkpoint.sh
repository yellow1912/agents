#!/bin/bash
# Create a checkpoint (git commit/tag) for easy rollback
#
# Usage:
#   ./commands/checkpoint.sh "description"          # Create checkpoint with message
#   ./commands/checkpoint.sh --list                 # List all checkpoints
#   ./commands/checkpoint.sh --auto                 # Auto-generate message from current stage
#
# Checkpoints are git tags prefixed with 'checkpoint/' for easy identification.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WORKFLOW_STATE="$PROJECT_ROOT/ARTIFACTS/system/workflow-state.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

check_git() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}Error: Not a git repository.${NC}"
        echo ""
        echo "Initialize git first:"
        echo "  git init"
        exit 1
    fi
}

get_current_stage() {
    if [ -f "$WORKFLOW_STATE" ]; then
        python3 -c "import json; print(json.load(open('$WORKFLOW_STATE')).get('current_stage', 'unknown'))" 2>/dev/null || echo "unknown"
    else
        echo "init"
    fi
}

get_checkpoint_count() {
    git tag -l 'checkpoint/*' 2>/dev/null | wc -l | tr -d ' '
}

# ============================================================================
# COMMANDS
# ============================================================================

list_checkpoints() {
    echo -e "${BLUE}=== Checkpoints ===${NC}"
    echo ""

    local checkpoints=$(git tag -l 'checkpoint/*' --sort=-creatordate 2>/dev/null)

    if [ -z "$checkpoints" ]; then
        echo "  (no checkpoints yet)"
        echo ""
        echo "Create one with:"
        echo "  ./commands/checkpoint.sh \"description\""
        return
    fi

    echo "$checkpoints" | while read -r tag; do
        local commit=$(git rev-list -n 1 "$tag" 2>/dev/null)
        local date=$(git log -1 --format=%ci "$tag" 2>/dev/null | cut -d' ' -f1,2)
        local short_commit=$(echo "$commit" | cut -c1-7)
        local name=${tag#checkpoint/}

        # Get tag message if it exists
        local message=$(git tag -l -n1 "$tag" 2>/dev/null | sed "s/^$tag[[:space:]]*//" || echo "")

        echo -e "  ${GREEN}$name${NC} ($short_commit) - $date"
        if [ -n "$message" ]; then
            echo -e "    ${CYAN}$message${NC}"
        fi
    done
    echo ""
}

create_checkpoint() {
    local message="$1"
    local stage=$(get_current_stage)
    local count=$(($(get_checkpoint_count) + 1))
    local timestamp=$(date +%Y%m%d-%H%M%S)

    # Generate checkpoint name
    local checkpoint_name="${count}-${stage}-${timestamp}"
    local tag_name="checkpoint/$checkpoint_name"

    echo -e "${CYAN}Creating checkpoint...${NC}"
    echo ""

    # Check for uncommitted changes
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        echo -e "${YELLOW}Uncommitted changes detected. Committing...${NC}"

        # Stage all changes including artifacts
        git add -A

        # Create commit
        local commit_msg="[Checkpoint] $message"
        if [ "$stage" != "unknown" ] && [ "$stage" != "init" ]; then
            commit_msg="[Checkpoint: $stage] $message"
        fi

        git commit -m "$commit_msg" || {
            echo -e "${YELLOW}Nothing to commit, working tree clean.${NC}"
        }
    fi

    # Create annotated tag
    git tag -a "$tag_name" -m "$message"

    echo -e "${GREEN}Checkpoint created!${NC}"
    echo ""
    echo -e "  Name:    ${YELLOW}$checkpoint_name${NC}"
    echo -e "  Tag:     ${CYAN}$tag_name${NC}"
    echo -e "  Message: $message"
    echo ""
    echo "To rollback to this checkpoint later:"
    echo -e "  ${YELLOW}./commands/rollback.sh $checkpoint_name${NC}"
    echo ""
}

auto_checkpoint() {
    local stage=$(get_current_stage)
    local message

    case "$stage" in
        requirements)
            message="Requirements phase complete"
            ;;
        architecture)
            message="Architecture phase complete"
            ;;
        frontend_implementation)
            message="Frontend implementation complete"
            ;;
        backend_implementation)
            message="Backend implementation complete"
            ;;
        ai_implementation)
            message="AI implementation complete"
            ;;
        qa_testing)
            message="QA testing complete"
            ;;
        deployment)
            message="Deployment complete"
            ;;
        *)
            message="Checkpoint at $stage stage"
            ;;
    esac

    create_checkpoint "$message"
}

# ============================================================================
# MAIN
# ============================================================================

cd "$PROJECT_ROOT"
check_git

case "${1:-}" in
    --list|-l)
        list_checkpoints
        ;;
    --auto|-a)
        auto_checkpoint
        ;;
    --help|-h)
        echo "Checkpoint - Save project state for easy rollback"
        echo ""
        echo "Usage:"
        echo "  checkpoint.sh \"description\"    Create checkpoint with message"
        echo "  checkpoint.sh --list           List all checkpoints"
        echo "  checkpoint.sh --auto           Auto-generate message from stage"
        echo "  checkpoint.sh --help           Show this help"
        echo ""
        echo "Examples:"
        echo "  ./commands/checkpoint.sh \"Before adding auth feature\""
        echo "  ./commands/checkpoint.sh --list"
        echo "  ./commands/checkpoint.sh --auto"
        ;;
    "")
        echo -e "${RED}Error: Please provide a checkpoint description.${NC}"
        echo ""
        echo "Usage:"
        echo "  ./commands/checkpoint.sh \"Before trying new approach\""
        echo "  ./commands/checkpoint.sh --auto"
        echo "  ./commands/checkpoint.sh --list"
        exit 1
        ;;
    *)
        create_checkpoint "$1"
        ;;
esac
