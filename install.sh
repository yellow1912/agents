#!/bin/bash
# Install AI-Native Development Framework
#
# Usage (from cloned repo):
#   ./install.sh [--target DIR]
#
# Usage (one-liner from GitHub):
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ai-agents/main/install.sh | bash
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default installation directory
DEFAULT_TARGET="$HOME/.claude-agents"

# GitHub repo (update this when you publish)
GITHUB_REPO="YOUR_USERNAME/ai-agents"
GITHUB_BRANCH="main"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: $1 is required but not installed.${NC}"
        exit 1
    fi
}

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================

TARGET="$DEFAULT_TARGET"
REMOTE_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --target|-t)
            TARGET="$2"
            shift 2
            ;;
        --help|-h)
            echo "AI-Native Development Framework Installer"
            echo ""
            echo "Usage:"
            echo "  ./install.sh [options]"
            echo ""
            echo "Options:"
            echo "  --target, -t DIR    Install to DIR (default: ~/.claude-agents)"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "One-liner install:"
            echo "  curl -fsSL https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/install.sh | bash"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# ============================================================================
# DETECT INSTALL MODE
# ============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""

# Check if we're running from a cloned repo or via curl
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR/L0 - Meta Layer" ]; then
    REMOTE_INSTALL=true
fi

# ============================================================================
# BANNER
# ============================================================================

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   AI-Native Development Framework - Installer              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# CHECK PREREQUISITES
# ============================================================================

echo -e "${CYAN}Checking prerequisites...${NC}"

check_command "bash"
check_command "mkdir"
check_command "cp"

if [ "$REMOTE_INSTALL" = true ]; then
    check_command "curl"
    check_command "tar"
fi

# Check for Python (needed for validation scripts)
if command -v python3 &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} python3"
elif command -v python &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} python"
else
    echo -e "  ${YELLOW}⚠${NC} python not found (optional, needed for validation)"
fi

echo ""

# ============================================================================
# REMOTE INSTALL (via curl)
# ============================================================================

if [ "$REMOTE_INSTALL" = true ]; then
    echo -e "Source: ${YELLOW}GitHub ($GITHUB_REPO)${NC}"
    echo -e "Target: ${YELLOW}$TARGET${NC}"
    echo ""

    # Check if target exists
    if [ -d "$TARGET" ]; then
        echo -e "${YELLOW}Warning: $TARGET already exists.${NC}"
        read -p "Overwrite? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            echo "Installation cancelled."
            exit 0
        fi
        rm -rf "$TARGET"
    fi

    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    echo -e "${CYAN}Downloading framework...${NC}"

    # Download tarball from GitHub
    TARBALL_URL="https://api.github.com/repos/$GITHUB_REPO/tarball/$GITHUB_BRANCH"

    curl -fsSL "$TARBALL_URL" -o "$TEMP_DIR/repo.tar.gz" &
    spinner $!

    if [ ! -f "$TEMP_DIR/repo.tar.gz" ]; then
        echo -e "${RED}Error: Failed to download from GitHub.${NC}"
        echo ""
        echo "Try cloning manually:"
        echo "  git clone https://github.com/$GITHUB_REPO.git"
        echo "  cd $(basename $GITHUB_REPO)"
        echo "  ./install.sh"
        exit 1
    fi

    echo -e "  ${GREEN}✓${NC} Downloaded"

    # Extract
    echo -e "${CYAN}Extracting...${NC}"
    tar -xzf "$TEMP_DIR/repo.tar.gz" -C "$TEMP_DIR" &
    spinner $!
    echo -e "  ${GREEN}✓${NC} Extracted"

    # Find extracted directory (GitHub adds a prefix)
    EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "*-*" | head -1)

    if [ -z "$EXTRACTED_DIR" ]; then
        echo -e "${RED}Error: Could not find extracted directory.${NC}"
        exit 1
    fi

    # Use extracted dir as source
    SCRIPT_DIR="$EXTRACTED_DIR"
fi

# ============================================================================
# LOCAL INSTALL
# ============================================================================

echo -e "Source: ${YELLOW}$SCRIPT_DIR${NC}"
echo -e "Target: ${YELLOW}$TARGET${NC}"
echo ""

# Check if target exists (for local install)
if [ "$REMOTE_INSTALL" = false ] && [ -d "$TARGET" ]; then
    echo -e "${YELLOW}Warning: $TARGET already exists.${NC}"
    read -p "Overwrite? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Installation cancelled."
        exit 0
    fi
    rm -rf "$TARGET"
fi

# Create target directory
echo -e "${CYAN}Installing framework...${NC}"
mkdir -p "$TARGET"

# Copy framework files
echo "  Copying L0 - Meta Layer..."
cp -r "$SCRIPT_DIR/L0 - Meta Layer" "$TARGET/"

echo "  Copying L1 - Specialist Agents..."
cp -r "$SCRIPT_DIR/L1 - Specialist Agents" "$TARGET/"

echo "  Copying L2 - Orchestration & Governance..."
cp -r "$SCRIPT_DIR/L2 - Orchestration & Governance" "$TARGET/"

echo "  Copying L3 - Workflows & Contracts..."
cp -r "$SCRIPT_DIR/L3 - Workflows & Contracts" "$TARGET/"

echo "  Copying scripts..."
cp -r "$SCRIPT_DIR/scripts" "$TARGET/"

echo "  Copying commands..."
cp -r "$SCRIPT_DIR/commands" "$TARGET/"

echo "  Copying hooks..."
cp -r "$SCRIPT_DIR/hooks" "$TARGET/"

echo "  Copying slash-commands..."
cp -r "$SCRIPT_DIR/slash-commands" "$TARGET/"

echo "  Copying setup.sh..."
cp "$SCRIPT_DIR/setup.sh" "$TARGET/"

# Copy README, CHANGELOG, VERSION if exists
[ -f "$SCRIPT_DIR/README.md" ] && cp "$SCRIPT_DIR/README.md" "$TARGET/"
[ -f "$SCRIPT_DIR/CHANGELOG.md" ] && cp "$SCRIPT_DIR/CHANGELOG.md" "$TARGET/"
[ -f "$SCRIPT_DIR/VERSION" ] && cp "$SCRIPT_DIR/VERSION" "$TARGET/"

# Make scripts executable
chmod +x "$TARGET/setup.sh"
chmod +x "$TARGET/scripts/"*.sh 2>/dev/null || true
chmod +x "$TARGET/scripts/"*.py 2>/dev/null || true
chmod +x "$TARGET/commands/"*.sh 2>/dev/null || true
chmod +x "$TARGET/hooks/"*.sh 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo -e "Framework installed to: ${YELLOW}$TARGET${NC}"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                      NEXT STEPS                            ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  1. Go to your project directory (or create one):"
echo -e "     ${YELLOW}mkdir my-app && cd my-app${NC}"
echo ""
echo "  2. Initialize the framework for your project:"
echo -e "     ${YELLOW}$TARGET/setup.sh${NC}"
echo ""
echo "     For existing projects, it will auto-detect your tech stack."
echo ""
echo "  3. Start Claude Code and describe what you want to build!"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Add to PATH suggestion
if [[ ":$PATH:" != *":$TARGET:"* ]]; then
    echo -e "${CYAN}Tip:${NC} Add to your shell profile for easier access:"
    echo ""
    echo "  echo 'export PATH=\"\$PATH:$TARGET\"' >> ~/.bashrc"
    echo "  # or for zsh:"
    echo "  echo 'export PATH=\"\$PATH:$TARGET\"' >> ~/.zshrc"
    echo ""
    echo "  Then you can just run: setup.sh"
    echo ""
fi
