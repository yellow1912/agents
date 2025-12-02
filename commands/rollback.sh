#!/bin/bash
# Rollback to a previous checkpoint
#
# Usage:
#   ./commands/rollback.sh                          # Interactive: show checkpoints and pick one
#   ./commands/rollback.sh <checkpoint-name>        # Rollback to specific checkpoint
#   ./commands/rollback.sh --last                   # Rollback to most recent checkpoint
#   ./commands/rollback.sh --preview <name>         # Show what would change (dry run)
#
# This creates a new commit that undoes changes back to the checkpoint.
# It does NOT rewrite history, so it's safe to use even after pushing.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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
        exit 1
    fi
}

check_clean() {
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        echo -e "${RED}Error: You have uncommitted changes.${NC}"
        echo ""
        echo "Please commit or stash your changes first:"
        echo "  git stash"
        echo "  # then after rollback:"
        echo "  git stash pop"
        exit 1
    fi
}

get_checkpoint_tag() {
    local name="$1"

    # If it's already a full tag name
    if git rev-parse "checkpoint/$name" >/dev/null 2>&1; then
        echo "checkpoint/$name"
        return
    fi

    # If it's already prefixed
    if [[ "$name" == checkpoint/* ]] && git rev-parse "$name" >/dev/null 2>&1; then
        echo "$name"
        return
    fi

    # Try partial match
    local matches=$(git tag -l "checkpoint/*$name*" 2>/dev/null | head -1)
    if [ -n "$matches" ]; then
        echo "$matches"
        return
    fi

    echo ""
}

list_checkpoints() {
    echo -e "${BLUE}=== Available Checkpoints ===${NC}"
    echo ""

    local i=1
    git tag -l 'checkpoint/*' --sort=-creatordate 2>/dev/null | while read -r tag; do
        local name=${tag#checkpoint/}
        local commit=$(git rev-list -n 1 "$tag" 2>/dev/null | cut -c1-7)
        local date=$(git log -1 --format=%ci "$tag" 2>/dev/null | cut -d' ' -f1)
        local message=$(git tag -l -n1 "$tag" 2>/dev/null | sed "s/^$tag[[:space:]]*//" || echo "")

        echo -e "  ${GREEN}$i)${NC} $name"
        echo -e "     ${CYAN}$date${NC} - $message"
        echo ""
        ((i++))
    done
}

preview_rollback() {
    local tag="$1"

    echo -e "${BLUE}=== Preview: Rollback to ${tag#checkpoint/} ===${NC}"
    echo ""

    local current=$(git rev-parse HEAD)
    local target=$(git rev-parse "$tag")

    echo -e "Current:  ${YELLOW}$(git log -1 --format='%h %s' HEAD)${NC}"
    echo -e "Target:   ${GREEN}$(git log -1 --format='%h %s' $tag)${NC}"
    echo ""

    echo -e "${CYAN}Files that would change:${NC}"
    git diff --stat "$tag"..HEAD 2>/dev/null || echo "  (unable to diff)"
    echo ""

    echo -e "${CYAN}Commits that would be reverted:${NC}"
    git log --oneline "$tag"..HEAD 2>/dev/null || echo "  (none)"
    echo ""
}

do_rollback() {
    local tag="$1"
    local checkpoint_name="${tag#checkpoint/}"

    echo -e "${CYAN}Rolling back to checkpoint: $checkpoint_name${NC}"
    echo ""

    # Get tag message for commit description
    local tag_message=$(git tag -l -n1 "$tag" 2>/dev/null | sed "s/^$tag[[:space:]]*//" || echo "checkpoint")

    # Create a revert by resetting the index and working tree to the checkpoint
    # then committing those changes (this doesn't rewrite history)
    git checkout "$tag" -- . 2>/dev/null

    # Stage all changes
    git add -A

    # Check if there are changes to commit
    if git diff --cached --quiet 2>/dev/null; then
        echo -e "${YELLOW}No changes needed - already at checkpoint state.${NC}"
        return
    fi

    # Commit the rollback
    git commit -m "Rollback to checkpoint: $checkpoint_name

Original checkpoint message: $tag_message

This reverts the codebase to the state at checkpoint '$checkpoint_name'.
Created by: ./commands/rollback.sh"

    echo ""
    echo -e "${GREEN}Rollback complete!${NC}"
    echo ""
    echo -e "  Restored to: ${YELLOW}$checkpoint_name${NC}"
    echo -e "  New commit:  ${CYAN}$(git log -1 --format='%h')${NC}"
    echo ""
    echo "To undo this rollback:"
    echo "  git revert HEAD"
}

interactive_select() {
    local checkpoints=($(git tag -l 'checkpoint/*' --sort=-creatordate 2>/dev/null))

    if [ ${#checkpoints[@]} -eq 0 ]; then
        echo -e "${YELLOW}No checkpoints found.${NC}"
        echo ""
        echo "Create one with:"
        echo "  ./commands/checkpoint.sh \"description\""
        exit 1
    fi

    list_checkpoints

    echo -n "Enter checkpoint number (or name): "
    read -r selection

    # If it's a number, get the corresponding tag
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        local index=$((selection - 1))
        if [ $index -ge 0 ] && [ $index -lt ${#checkpoints[@]} ]; then
            echo "${checkpoints[$index]}"
            return
        fi
    fi

    # Otherwise treat as name
    get_checkpoint_tag "$selection"
}

# ============================================================================
# MAIN
# ============================================================================

cd "$PROJECT_ROOT"
check_git

case "${1:-}" in
    --help|-h)
        echo "Rollback - Restore project to a previous checkpoint"
        echo ""
        echo "Usage:"
        echo "  rollback.sh                      Interactive selection"
        echo "  rollback.sh <name>               Rollback to named checkpoint"
        echo "  rollback.sh --last               Rollback to most recent checkpoint"
        echo "  rollback.sh --preview <name>     Preview what would change"
        echo "  rollback.sh --help               Show this help"
        echo ""
        echo "Examples:"
        echo "  ./commands/rollback.sh                          # Pick interactively"
        echo "  ./commands/rollback.sh 2-architecture-20241201  # By name"
        echo "  ./commands/rollback.sh --last                   # Most recent"
        echo "  ./commands/rollback.sh --preview --last         # Preview first"
        echo ""
        echo "Note: Rollback creates a new commit (safe, doesn't rewrite history)."
        ;;

    --last|-l)
        check_clean
        local last_tag=$(git tag -l 'checkpoint/*' --sort=-creatordate 2>/dev/null | head -1)
        if [ -z "$last_tag" ]; then
            echo -e "${YELLOW}No checkpoints found.${NC}"
            exit 1
        fi
        echo -e "${YELLOW}Rolling back to most recent checkpoint...${NC}"
        do_rollback "$last_tag"
        ;;

    --preview|-p)
        shift
        local target="${1:---last}"
        if [ "$target" = "--last" ] || [ "$target" = "-l" ]; then
            target=$(git tag -l 'checkpoint/*' --sort=-creatordate 2>/dev/null | head -1)
        else
            target=$(get_checkpoint_tag "$target")
        fi

        if [ -z "$target" ]; then
            echo -e "${RED}Checkpoint not found.${NC}"
            exit 1
        fi

        preview_rollback "$target"
        ;;

    "")
        check_clean
        selected=$(interactive_select)
        if [ -z "$selected" ]; then
            echo -e "${RED}Checkpoint not found.${NC}"
            exit 1
        fi

        echo ""
        preview_rollback "$selected"

        echo -n "Proceed with rollback? (y/N): "
        read -r confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            do_rollback "$selected"
        else
            echo "Rollback cancelled."
        fi
        ;;

    *)
        check_clean
        tag=$(get_checkpoint_tag "$1")
        if [ -z "$tag" ]; then
            echo -e "${RED}Checkpoint not found: $1${NC}"
            echo ""
            echo "Available checkpoints:"
            git tag -l 'checkpoint/*' --sort=-creatordate 2>/dev/null | sed 's/checkpoint\//  /'
            exit 1
        fi

        preview_rollback "$tag"

        echo -n "Proceed with rollback? (y/N): "
        read -r confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            do_rollback "$tag"
        else
            echo "Rollback cancelled."
        fi
        ;;
esac
