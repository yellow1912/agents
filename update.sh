#!/bin/bash
# Update AI-Native Development Framework
#
# Usage:
#   ~/.claude-agents/update.sh              # Update framework only
#   ~/.claude-agents/update.sh --project    # Update current project's commands
#   ~/.claude-agents/update.sh --check      # Check for updates without installing
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get framework directory
FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$FRAMEWORK_DIR/VERSION"

# GitHub repo (must match install.sh)
GITHUB_REPO="YOUR_USERNAME/ai-agents"
GITHUB_BRANCH="main"

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================

UPDATE_PROJECT=false
CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --project|-p)
            UPDATE_PROJECT=true
            shift
            ;;
        --check|-c)
            CHECK_ONLY=true
            shift
            ;;
        --help|-h)
            echo "AI-Native Development Framework Updater"
            echo ""
            echo "Usage:"
            echo "  update.sh [options]"
            echo ""
            echo "Options:"
            echo "  --project, -p    Update current project's commands to latest"
            echo "  --check, -c      Check for updates without installing"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "Examples:"
            echo "  ~/.claude-agents/update.sh              # Update framework"
            echo "  ~/.claude-agents/update.sh --project    # Update project commands"
            echo "  ~/.claude-agents/update.sh --check      # Check for updates"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

get_local_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE" | tr -d '[:space:]'
    else
        echo "0.0.0"
    fi
}

get_remote_version() {
    local remote_version
    remote_version=$(curl -fsSL "https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/VERSION" 2>/dev/null | tr -d '[:space:]')
    if [ -z "$remote_version" ]; then
        echo ""
    else
        echo "$remote_version"
    fi
}

version_gt() {
    # Returns 0 (true) if $1 > $2
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# ============================================================================
# BANNER
# ============================================================================

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   AI-Native Development Framework - Updater                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# UPDATE PROJECT COMMANDS
# ============================================================================

if [ "$UPDATE_PROJECT" = true ]; then
    TARGET_DIR="$(pwd)"

    # Check if this is a project with the framework
    if [ ! -f "$TARGET_DIR/CLAUDE.md" ] || [ ! -d "$TARGET_DIR/ARTIFACTS" ]; then
        echo -e "${RED}Error: Current directory is not a project using the framework.${NC}"
        echo ""
        echo "Run this from a project directory that was set up with setup.sh"
        exit 1
    fi

    echo -e "Project: ${YELLOW}$TARGET_DIR${NC}"
    echo -e "Framework: ${YELLOW}$FRAMEWORK_DIR${NC}"
    echo ""

    # Update commands
    echo -e "${CYAN}Updating project commands...${NC}"

    if [ -d "$TARGET_DIR/commands" ]; then
        cp "$FRAMEWORK_DIR/commands/"*.sh "$TARGET_DIR/commands/" 2>/dev/null || true
        chmod +x "$TARGET_DIR/commands/"*.sh 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} Updated commands/"
    else
        mkdir -p "$TARGET_DIR/commands"
        cp "$FRAMEWORK_DIR/commands/"*.sh "$TARGET_DIR/commands/"
        chmod +x "$TARGET_DIR/commands/"*.sh
        echo -e "  ${GREEN}✓${NC} Created commands/"
    fi

    # Update CLAUDE.md framework path if needed
    if grep -q "framework_path" "$TARGET_DIR/project-config.json" 2>/dev/null; then
        # Update framework path in config
        local current_path=$(grep -o '"framework_path": "[^"]*"' "$TARGET_DIR/project-config.json" | cut -d'"' -f4)
        if [ "$current_path" != "$FRAMEWORK_DIR" ]; then
            echo -e "  ${YELLOW}Note:${NC} Framework path in project-config.json differs from current framework."
            echo "         Project: $current_path"
            echo "         Current: $FRAMEWORK_DIR"
        fi
    fi

    echo ""
    echo -e "${GREEN}✓ Project updated!${NC}"
    exit 0
fi

# ============================================================================
# CHECK FOR UPDATES
# ============================================================================

LOCAL_VERSION=$(get_local_version)
echo -e "Local version:  ${YELLOW}$LOCAL_VERSION${NC}"

echo -e "${CYAN}Checking for updates...${NC}"
REMOTE_VERSION=$(get_remote_version)

if [ -z "$REMOTE_VERSION" ]; then
    echo -e "${YELLOW}Warning: Could not check remote version.${NC}"
    echo "Make sure you have internet access and the repo exists."
    echo ""
    if [ "$CHECK_ONLY" = true ]; then
        exit 1
    fi
else
    echo -e "Remote version: ${YELLOW}$REMOTE_VERSION${NC}"
    echo ""

    if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]; then
        echo -e "${GREEN}✓ You have the latest version!${NC}"
        if [ "$CHECK_ONLY" = true ]; then
            exit 0
        fi
        echo ""
        read -p "Re-install anyway? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            exit 0
        fi
    elif version_gt "$REMOTE_VERSION" "$LOCAL_VERSION"; then
        echo -e "${CYAN}Update available: $LOCAL_VERSION → $REMOTE_VERSION${NC}"
        if [ "$CHECK_ONLY" = true ]; then
            echo ""
            echo "Run without --check to update:"
            echo "  ~/.claude-agents/update.sh"
            exit 0
        fi
    else
        echo -e "${YELLOW}Local version is newer than remote (development?)${NC}"
        if [ "$CHECK_ONLY" = true ]; then
            exit 0
        fi
    fi
fi

# ============================================================================
# UPDATE FRAMEWORK
# ============================================================================

echo ""
echo -e "${CYAN}Updating framework...${NC}"

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Download tarball
TARBALL_URL="https://api.github.com/repos/$GITHUB_REPO/tarball/$GITHUB_BRANCH"

echo "  Downloading..."
if ! curl -fsSL "$TARBALL_URL" -o "$TEMP_DIR/repo.tar.gz"; then
    echo -e "${RED}Error: Failed to download update.${NC}"
    exit 1
fi

echo "  Extracting..."
tar -xzf "$TEMP_DIR/repo.tar.gz" -C "$TEMP_DIR"

# Find extracted directory
EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "*-*" | head -1)

if [ -z "$EXTRACTED_DIR" ]; then
    echo -e "${RED}Error: Could not find extracted directory.${NC}"
    exit 1
fi

# Backup current VERSION for rollback message
OLD_VERSION="$LOCAL_VERSION"

# Update files (preserve user's install location)
echo "  Updating files..."

# Remove old files and copy new ones
rm -rf "$FRAMEWORK_DIR/L0 - Meta Layer"
rm -rf "$FRAMEWORK_DIR/L1 - Specialist Agents"
rm -rf "$FRAMEWORK_DIR/L2 - Orchestration & Governance"
rm -rf "$FRAMEWORK_DIR/L3 - Workflows & Contracts"
rm -rf "$FRAMEWORK_DIR/scripts"
rm -rf "$FRAMEWORK_DIR/commands"

cp -r "$EXTRACTED_DIR/L0 - Meta Layer" "$FRAMEWORK_DIR/"
cp -r "$EXTRACTED_DIR/L1 - Specialist Agents" "$FRAMEWORK_DIR/"
cp -r "$EXTRACTED_DIR/L2 - Orchestration & Governance" "$FRAMEWORK_DIR/"
cp -r "$EXTRACTED_DIR/L3 - Workflows & Contracts" "$FRAMEWORK_DIR/"
cp -r "$EXTRACTED_DIR/scripts" "$FRAMEWORK_DIR/"
cp -r "$EXTRACTED_DIR/commands" "$FRAMEWORK_DIR/"

# Update root files
cp "$EXTRACTED_DIR/setup.sh" "$FRAMEWORK_DIR/"
cp "$EXTRACTED_DIR/install.sh" "$FRAMEWORK_DIR/"
cp "$EXTRACTED_DIR/update.sh" "$FRAMEWORK_DIR/"
cp "$EXTRACTED_DIR/VERSION" "$FRAMEWORK_DIR/"
[ -f "$EXTRACTED_DIR/README.md" ] && cp "$EXTRACTED_DIR/README.md" "$FRAMEWORK_DIR/"

# Make executable
chmod +x "$FRAMEWORK_DIR/setup.sh"
chmod +x "$FRAMEWORK_DIR/install.sh"
chmod +x "$FRAMEWORK_DIR/update.sh"
chmod +x "$FRAMEWORK_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$FRAMEWORK_DIR/scripts/"*.py 2>/dev/null || true
chmod +x "$FRAMEWORK_DIR/commands/"*.sh 2>/dev/null || true

NEW_VERSION=$(get_local_version)

echo ""
echo -e "${GREEN}✓ Framework updated!${NC}"
echo -e "  $OLD_VERSION → $NEW_VERSION"
echo ""
echo -e "${CYAN}To update your projects' commands:${NC}"
echo "  cd /path/to/your/project"
echo "  ~/.claude-agents/update.sh --project"
echo ""
