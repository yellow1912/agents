#!/bin/bash
# Set up a project to use the AI-Native Development Framework
# Usage: ./setup.sh [options] [project-name]
#
# Options:
#   --analyze       Analyze existing codebase and auto-detect tech stack
#   --deep-analyze  Deep analysis with full architecture scan
#   --force, -f     Skip confirmations and overwrite all files
#   --dry-run       Show what would be changed without making changes
#   --yes, -y       Auto-confirm all prompts (still shows what will change)
#   --help          Show this help message

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

# Get framework directory (where this script lives)
FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
ANALYZE=false
DEEP_ANALYZE=false
FORCE_MODE=false
DRY_RUN=false
AUTO_YES=false
PROJECT_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --analyze|-a)
            ANALYZE=true
            shift
            ;;
        --deep-analyze|-d)
            ANALYZE=true
            DEEP_ANALYZE=true
            shift
            ;;
        --force|-f)
            FORCE_MODE=true
            AUTO_YES=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --yes|-y)
            AUTO_YES=true
            shift
            ;;
        --help|-h)
            echo "Usage: ./setup.sh [options] [project-name]"
            echo ""
            echo "Options:"
            echo "  --analyze, -a       Analyze existing codebase and auto-detect tech stack"
            echo "  --deep-analyze, -d  Deep analysis: detect patterns, components, architecture"
            echo "  --force, -f         Skip confirmations and overwrite all files"
            echo "  --dry-run           Show what would be changed without making changes"
            echo "  --yes, -y           Auto-confirm all prompts"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./setup.sh                    # New project in current directory"
            echo "  ./setup.sh my-app             # New project named 'my-app'"
            echo "  ./setup.sh --analyze          # Existing project, detect stack"
            echo "  ./setup.sh --deep-analyze     # Existing project, full architecture scan"
            echo "  ./setup.sh --dry-run          # Preview changes without applying"
            echo "  ./setup.sh -y                 # Apply changes with auto-confirm"
            exit 0
            ;;
        *)
            PROJECT_NAME="$1"
            shift
            ;;
    esac
done

# Target is current directory
TARGET_DIR="$(pwd)"
PROJECT_NAME="${PROJECT_NAME:-$(basename "$TARGET_DIR")}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   AI-Native Development Framework - Project Setup          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

# Check for updates (non-blocking)
VERSION_FILE="$FRAMEWORK_DIR/VERSION"
GITHUB_REPO="YOUR_USERNAME/ai-agents"
GITHUB_BRANCH="main"

if [ -f "$VERSION_FILE" ]; then
    LOCAL_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
    # Quick async check for remote version (timeout after 2 seconds)
    REMOTE_VERSION=$(timeout 2 curl -fsSL "https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/VERSION" 2>/dev/null | tr -d '[:space:]') || true

    if [ -n "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
        # Simple version comparison
        if [[ "$REMOTE_VERSION" > "$LOCAL_VERSION" ]]; then
            echo -e "${YELLOW}Update available: $LOCAL_VERSION → $REMOTE_VERSION${NC}"
            echo -e "Run: ${CYAN}~/.claude-agents/update.sh${NC}"
            echo ""
        fi
    fi
fi

echo -e "Framework: ${YELLOW}$FRAMEWORK_DIR${NC}"
echo -e "Project:   ${YELLOW}$TARGET_DIR${NC}"
echo -e "Name:      ${YELLOW}$PROJECT_NAME${NC}"

# ============================================================================
# CHANGE DETECTION - Figure out what needs to be done
# ============================================================================

# Initialize change tracking
declare -a CHANGES_TO_MAKE=()
declare -a CHANGES_SKIPPED=()
WORKFLOW_IN_PROGRESS=false
HAS_EXISTING_CONFIG=false

# Check existing workflow state
if [ -f "$TARGET_DIR/ARTIFACTS/system/workflow-state.json" ]; then
    CURRENT_STAGE=$(grep -o '"current_stage"[[:space:]]*:[[:space:]]*"[^"]*"' "$TARGET_DIR/ARTIFACTS/system/workflow-state.json" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "")
    # Check if any stage has status other than pending
    if grep -qE '"status"[[:space:]]*:[[:space:]]*"(in_progress|completed)"' "$TARGET_DIR/ARTIFACTS/system/workflow-state.json" 2>/dev/null; then
        WORKFLOW_IN_PROGRESS=true
    fi
fi

# Check existing project config
if [ -f "$TARGET_DIR/project-config.json" ]; then
    HAS_EXISTING_CONFIG=true
fi

# Auto-detect if this looks like an existing project
if [ "$ANALYZE" = false ]; then
    if [ -f "$TARGET_DIR/package.json" ] || [ -f "$TARGET_DIR/requirements.txt" ] || \
       [ -f "$TARGET_DIR/go.mod" ] || [ -f "$TARGET_DIR/Cargo.toml" ] || \
       [ -f "$TARGET_DIR/pyproject.toml" ] || [ -f "$TARGET_DIR/pom.xml" ] || \
       [ -d "$TARGET_DIR/src" ] || [ -d "$TARGET_DIR/app" ]; then
        echo ""
        echo -e "${YELLOW}Existing project detected.${NC}"
        if [ "$AUTO_YES" = false ]; then
            read -p "Analyze codebase to auto-detect tech stack? (Y/n): " do_analyze
            if [ "$do_analyze" != "n" ] && [ "$do_analyze" != "N" ]; then
                ANALYZE=true
            fi
        else
            ANALYZE=true
            echo "Auto-analyzing codebase..."
        fi
    fi
fi

echo ""

# ============================================================================
# ANALYZE EXISTING PROJECT (if --analyze)
# ============================================================================

DETECTED_FRONTEND=""
DETECTED_BACKEND=""
DETECTED_DATABASE=""
DETECTED_AI=""
DETECTED_INFRA=""
DETECTED_STRUCTURE=""
EXISTING_CODEBASE=false
EXECUTION_MODE="full_system"

if [ "$ANALYZE" = true ]; then
    echo -e "${CYAN}Analyzing project structure...${NC}"
    EXISTING_CODEBASE=true
    EXECUTION_MODE="fast_feature"

    # Detect Frontend
    if [ -f "$TARGET_DIR/package.json" ]; then
        if grep -q '"react"' "$TARGET_DIR/package.json" 2>/dev/null; then
            DETECTED_FRONTEND="React"
            if grep -q '"next"' "$TARGET_DIR/package.json" 2>/dev/null; then
                DETECTED_FRONTEND="Next.js"
            fi
        elif grep -q '"vue"' "$TARGET_DIR/package.json" 2>/dev/null; then
            DETECTED_FRONTEND="Vue"
            if grep -q '"nuxt"' "$TARGET_DIR/package.json" 2>/dev/null; then
                DETECTED_FRONTEND="Nuxt"
            fi
        elif grep -q '"svelte"' "$TARGET_DIR/package.json" 2>/dev/null; then
            DETECTED_FRONTEND="Svelte"
        elif grep -q '"angular"' "$TARGET_DIR/package.json" 2>/dev/null; then
            DETECTED_FRONTEND="Angular"
        fi

        # Detect if it's a TypeScript project
        if [ -f "$TARGET_DIR/tsconfig.json" ]; then
            DETECTED_FRONTEND="${DETECTED_FRONTEND} (TypeScript)"
        fi
    fi

    # Detect Backend
    if [ -f "$TARGET_DIR/package.json" ]; then
        if grep -q '"express"' "$TARGET_DIR/package.json" 2>/dev/null; then
            DETECTED_BACKEND="Node.js/Express"
        elif grep -q '"fastify"' "$TARGET_DIR/package.json" 2>/dev/null; then
            DETECTED_BACKEND="Node.js/Fastify"
        elif grep -q '"hono"' "$TARGET_DIR/package.json" 2>/dev/null; then
            DETECTED_BACKEND="Node.js/Hono"
        elif grep -q '"@nestjs"' "$TARGET_DIR/package.json" 2>/dev/null; then
            DETECTED_BACKEND="NestJS"
        fi
    fi

    if [ -f "$TARGET_DIR/requirements.txt" ] || [ -f "$TARGET_DIR/pyproject.toml" ]; then
        if grep -qiE "django|Django" "$TARGET_DIR/requirements.txt" "$TARGET_DIR/pyproject.toml" 2>/dev/null; then
            DETECTED_BACKEND="Python/Django"
        elif grep -qiE "fastapi|FastAPI" "$TARGET_DIR/requirements.txt" "$TARGET_DIR/pyproject.toml" 2>/dev/null; then
            DETECTED_BACKEND="Python/FastAPI"
        elif grep -qiE "flask|Flask" "$TARGET_DIR/requirements.txt" "$TARGET_DIR/pyproject.toml" 2>/dev/null; then
            DETECTED_BACKEND="Python/Flask"
        else
            DETECTED_BACKEND="Python"
        fi
    fi

    if [ -f "$TARGET_DIR/go.mod" ]; then
        DETECTED_BACKEND="Go"
        if grep -q "github.com/gin-gonic/gin" "$TARGET_DIR/go.mod" 2>/dev/null; then
            DETECTED_BACKEND="Go/Gin"
        elif grep -q "github.com/labstack/echo" "$TARGET_DIR/go.mod" 2>/dev/null; then
            DETECTED_BACKEND="Go/Echo"
        fi
    fi

    if [ -f "$TARGET_DIR/Cargo.toml" ]; then
        DETECTED_BACKEND="Rust"
        if grep -q "actix-web" "$TARGET_DIR/Cargo.toml" 2>/dev/null; then
            DETECTED_BACKEND="Rust/Actix"
        elif grep -q "axum" "$TARGET_DIR/Cargo.toml" 2>/dev/null; then
            DETECTED_BACKEND="Rust/Axum"
        fi
    fi

    if [ -f "$TARGET_DIR/pom.xml" ] || [ -f "$TARGET_DIR/build.gradle" ]; then
        DETECTED_BACKEND="Java/Spring"
    fi

    # Detect Database
    if grep -qriE "postgres|postgresql|pg" "$TARGET_DIR/package.json" "$TARGET_DIR/requirements.txt" "$TARGET_DIR/pyproject.toml" "$TARGET_DIR/.env"* 2>/dev/null; then
        DETECTED_DATABASE="PostgreSQL"
    elif grep -qriE "mysql|mariadb" "$TARGET_DIR/package.json" "$TARGET_DIR/requirements.txt" "$TARGET_DIR/.env"* 2>/dev/null; then
        DETECTED_DATABASE="MySQL"
    elif grep -qriE "mongodb|mongoose" "$TARGET_DIR/package.json" "$TARGET_DIR/requirements.txt" "$TARGET_DIR/.env"* 2>/dev/null; then
        DETECTED_DATABASE="MongoDB"
    elif grep -qriE "sqlite" "$TARGET_DIR/package.json" "$TARGET_DIR/requirements.txt" "$TARGET_DIR/.env"* 2>/dev/null; then
        DETECTED_DATABASE="SQLite"
    elif grep -qriE "supabase" "$TARGET_DIR/package.json" "$TARGET_DIR/.env"* 2>/dev/null; then
        DETECTED_DATABASE="Supabase"
    elif grep -qriE "prisma" "$TARGET_DIR/package.json" 2>/dev/null; then
        DETECTED_DATABASE="Prisma (check schema for DB type)"
    fi

    # Detect AI/ML
    if grep -qriE "openai|langchain|anthropic|claude" "$TARGET_DIR/package.json" "$TARGET_DIR/requirements.txt" "$TARGET_DIR/pyproject.toml" 2>/dev/null; then
        DETECTED_AI="LLM Integration"
    fi
    if grep -qriE "tensorflow|pytorch|torch|transformers|sklearn" "$TARGET_DIR/requirements.txt" "$TARGET_DIR/pyproject.toml" 2>/dev/null; then
        DETECTED_AI="${DETECTED_AI:+$DETECTED_AI, }ML/Deep Learning"
    fi

    # Detect Infrastructure
    if [ -f "$TARGET_DIR/Dockerfile" ] || [ -f "$TARGET_DIR/docker-compose.yml" ]; then
        DETECTED_INFRA="Docker"
    fi
    if [ -d "$TARGET_DIR/.github/workflows" ]; then
        DETECTED_INFRA="${DETECTED_INFRA:+$DETECTED_INFRA, }GitHub Actions"
    fi
    if [ -f "$TARGET_DIR/vercel.json" ] || [ -d "$TARGET_DIR/.vercel" ]; then
        DETECTED_INFRA="${DETECTED_INFRA:+$DETECTED_INFRA, }Vercel"
    fi
    if [ -f "$TARGET_DIR/netlify.toml" ]; then
        DETECTED_INFRA="${DETECTED_INFRA:+$DETECTED_INFRA, }Netlify"
    fi
    if [ -d "$TARGET_DIR/terraform" ] || [ -f "$TARGET_DIR/main.tf" ]; then
        DETECTED_INFRA="${DETECTED_INFRA:+$DETECTED_INFRA, }Terraform"
    fi

    # Detect folder structure
    FOLDERS=""
    [ -d "$TARGET_DIR/src" ] && FOLDERS="${FOLDERS}src/ "
    [ -d "$TARGET_DIR/app" ] && FOLDERS="${FOLDERS}app/ "
    [ -d "$TARGET_DIR/lib" ] && FOLDERS="${FOLDERS}lib/ "
    [ -d "$TARGET_DIR/components" ] && FOLDERS="${FOLDERS}components/ "
    [ -d "$TARGET_DIR/pages" ] && FOLDERS="${FOLDERS}pages/ "
    [ -d "$TARGET_DIR/api" ] && FOLDERS="${FOLDERS}api/ "
    [ -d "$TARGET_DIR/tests" ] && FOLDERS="${FOLDERS}tests/ "
    [ -d "$TARGET_DIR/__tests__" ] && FOLDERS="${FOLDERS}__tests__/ "
    [ -d "$TARGET_DIR/test" ] && FOLDERS="${FOLDERS}test/ "
    DETECTED_STRUCTURE="$FOLDERS"

    # Print detection results
    echo ""
    echo -e "${GREEN}Detection Results:${NC}"
    [ -n "$DETECTED_FRONTEND" ] && echo -e "  Frontend:    ${YELLOW}$DETECTED_FRONTEND${NC}"
    [ -n "$DETECTED_BACKEND" ] && echo -e "  Backend:     ${YELLOW}$DETECTED_BACKEND${NC}"
    [ -n "$DETECTED_DATABASE" ] && echo -e "  Database:    ${YELLOW}$DETECTED_DATABASE${NC}"
    [ -n "$DETECTED_AI" ] && echo -e "  AI/ML:       ${YELLOW}$DETECTED_AI${NC}"
    [ -n "$DETECTED_INFRA" ] && echo -e "  Infra:       ${YELLOW}$DETECTED_INFRA${NC}"
    [ -n "$DETECTED_STRUCTURE" ] && echo -e "  Folders:     ${YELLOW}$DETECTED_STRUCTURE${NC}"

    if [ -z "$DETECTED_FRONTEND" ] && [ -z "$DETECTED_BACKEND" ] && [ -z "$DETECTED_DATABASE" ]; then
        echo -e "  ${YELLOW}(Could not auto-detect stack - please edit project-config.json manually)${NC}"
    fi

    echo ""
fi

# ============================================================================
# DETERMINE WHAT CHANGES ARE NEEDED
# ============================================================================

echo -e "${CYAN}Analyzing what needs to be done...${NC}"
echo ""

# --- ARTIFACTS directories ---
ARTIFACTS_DIRS=(
    "ARTIFACTS/product-manager"
    "ARTIFACTS/system-architect"
    "ARTIFACTS/frontend-engineer"
    "ARTIFACTS/backend-engineer"
    "ARTIFACTS/ai-engineer"
    "ARTIFACTS/qa-engineer"
    "ARTIFACTS/devops-engineer"
    "ARTIFACTS/system"
)

ARTIFACTS_NEEDED=false
for dir in "${ARTIFACTS_DIRS[@]}"; do
    if [ ! -d "$TARGET_DIR/$dir" ]; then
        ARTIFACTS_NEEDED=true
        break
    fi
done

if [ "$ARTIFACTS_NEEDED" = true ]; then
    CHANGES_TO_MAKE+=("CREATE: ARTIFACTS/ directory structure")
else
    CHANGES_SKIPPED+=("ARTIFACTS/ directories (already exist)")
fi

# --- Commands directory ---
COMMANDS_NEEDED=false
COMMANDS_OUTDATED=()

if [ ! -d "$TARGET_DIR/commands" ]; then
    COMMANDS_NEEDED=true
    CHANGES_TO_MAKE+=("CREATE: commands/ directory with helper scripts")
else
    # Check if commands need updating by comparing checksums
    for cmd in "$FRAMEWORK_DIR/commands/"*.sh; do
        if [ -f "$cmd" ]; then
            cmd_name=$(basename "$cmd")
            target_cmd="$TARGET_DIR/commands/$cmd_name"
            if [ -f "$target_cmd" ]; then
                # Compare files
                if ! diff -q "$cmd" "$target_cmd" > /dev/null 2>&1; then
                    COMMANDS_OUTDATED+=("$cmd_name")
                fi
            else
                COMMANDS_OUTDATED+=("$cmd_name (new)")
            fi
        fi
    done

    if [ ${#COMMANDS_OUTDATED[@]} -gt 0 ]; then
        CHANGES_TO_MAKE+=("UPDATE: commands/ (${#COMMANDS_OUTDATED[@]} files: ${COMMANDS_OUTDATED[*]})")
    else
        CHANGES_SKIPPED+=("commands/ (already up to date)")
    fi
fi

# --- Hooks ---
HOOKS_NEEDED=false
if [ ! -d "$TARGET_DIR/.claude/hooks" ]; then
    HOOKS_NEEDED=true
    CHANGES_TO_MAKE+=("CREATE: .claude/hooks/ (session start hook)")
elif [ ! -f "$TARGET_DIR/.claude/hooks/session-start.sh" ]; then
    HOOKS_NEEDED=true
    CHANGES_TO_MAKE+=("CREATE: .claude/hooks/session-start.sh")
else
    # Check if hook needs updating
    if [ -f "$FRAMEWORK_DIR/hooks/session-start.sh" ]; then
        if ! diff -q "$FRAMEWORK_DIR/hooks/session-start.sh" "$TARGET_DIR/.claude/hooks/session-start.sh" > /dev/null 2>&1; then
            HOOKS_NEEDED=true
            CHANGES_TO_MAKE+=("UPDATE: .claude/hooks/session-start.sh")
        else
            CHANGES_SKIPPED+=(".claude/hooks/ (already up to date)")
        fi
    fi
fi

# --- .claude/CLAUDE.md ---
FRAMEWORK_START_MARKER="<!-- AI-NATIVE-FRAMEWORK-START -->"
FRAMEWORK_END_MARKER="<!-- AI-NATIVE-FRAMEWORK-END -->"
CLAUDE_MD_ACTION=""

if [ -f "$TARGET_DIR/.claude/CLAUDE.md" ]; then
    if grep -q "$FRAMEWORK_START_MARKER" "$TARGET_DIR/.claude/CLAUDE.md"; then
        # Check if framework section needs updating
        # Extract current framework path from the file
        CURRENT_FW_PATH=$(grep -o 'Framework Location.*FRAMEWORK_DIR_PLACEHOLDER\|/[^`]*' "$TARGET_DIR/.claude/CLAUDE.md" 2>/dev/null | head -1 || echo "")
        # For now, we'll just offer to update if framework dir might have changed
        CLAUDE_MD_ACTION="UPDATE"
        CHANGES_TO_MAKE+=("UPDATE: .claude/CLAUDE.md (refresh framework section)")
    else
        CLAUDE_MD_ACTION="APPEND"
        CHANGES_TO_MAKE+=("APPEND: .claude/CLAUDE.md (add framework section)")
    fi
else
    CLAUDE_MD_ACTION="CREATE"
    CHANGES_TO_MAKE+=("CREATE: .claude/CLAUDE.md (framework instructions)")
fi

# --- project-config.json ---
if [ "$HAS_EXISTING_CONFIG" = true ]; then
    # We'll merge detected values into existing config
    if [ "$ANALYZE" = true ]; then
        CHANGES_TO_MAKE+=("MERGE: project-config.json (update detected tech stack, preserve customizations)")
    else
        CHANGES_SKIPPED+=("project-config.json (already exists, use --analyze to update tech stack)")
    fi
else
    CHANGES_TO_MAKE+=("CREATE: project-config.json")
fi

# --- workflow-state.json ---
if [ -f "$TARGET_DIR/ARTIFACTS/system/workflow-state.json" ]; then
    if [ "$WORKFLOW_IN_PROGRESS" = true ]; then
        CHANGES_SKIPPED+=("workflow-state.json (workflow in progress at stage: $CURRENT_STAGE)")
        echo -e "${YELLOW}⚠ Workflow in progress - workflow-state.json will be preserved${NC}"
    else
        if [ "$FORCE_MODE" = true ]; then
            CHANGES_TO_MAKE+=("RESET: workflow-state.json (--force mode)")
        else
            CHANGES_SKIPPED+=("workflow-state.json (exists, stages are pending)")
        fi
    fi
else
    CHANGES_TO_MAKE+=("CREATE: workflow-state.json")
fi

# --- Deep analysis files ---
if [ "$DEEP_ANALYZE" = true ]; then
    if [ -f "$TARGET_DIR/ARTIFACTS/system/architecture-snapshot.json" ]; then
        # Check status
        ARCH_STATUS=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$TARGET_DIR/ARTIFACTS/system/architecture-snapshot.json" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "")
        if [ "$ARCH_STATUS" = "completed" ]; then
            CHANGES_SKIPPED+=("architecture-snapshot.json (analysis already completed)")
        else
            CHANGES_TO_MAKE+=("UPDATE: architecture-snapshot.json (reset for re-analysis)")
        fi
    else
        CHANGES_TO_MAKE+=("CREATE: architecture-snapshot.json (pending deep analysis)")
        CHANGES_TO_MAKE+=("CREATE: deep-analysis-prompt.md")
    fi
fi

# --- Git initialization ---
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    CHANGES_TO_MAKE+=("INIT: git repository (needed for checkpoints)")
fi

# ============================================================================
# SHOW CHANGE SUMMARY AND ASK FOR CONFIRMATION
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    CHANGE SUMMARY                              ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [ ${#CHANGES_TO_MAKE[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ Everything is already up to date!${NC}"
    echo ""
    if [ ${#CHANGES_SKIPPED[@]} -gt 0 ]; then
        echo -e "${DIM}Skipped (already current):${NC}"
        for skip in "${CHANGES_SKIPPED[@]}"; do
            echo -e "  ${DIM}• $skip${NC}"
        done
    fi
    echo ""
    exit 0
fi

echo -e "${YELLOW}Changes to be made:${NC}"
for change in "${CHANGES_TO_MAKE[@]}"; do
    echo -e "  ${GREEN}➤${NC} $change"
done

echo ""

if [ ${#CHANGES_SKIPPED[@]} -gt 0 ]; then
    echo -e "${DIM}Skipped (no changes needed):${NC}"
    for skip in "${CHANGES_SKIPPED[@]}"; do
        echo -e "  ${DIM}• $skip${NC}"
    done
    echo ""
fi

# Check for potential issues
if [ "$WORKFLOW_IN_PROGRESS" = true ] && [ "$FORCE_MODE" = true ]; then
    echo -e "${RED}⚠ WARNING: --force will reset workflow-state.json even though workflow is in progress!${NC}"
    echo ""
fi

# Ask for confirmation (unless --yes or --force)
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN - No changes made.${NC}"
    exit 0
fi

if [ "$AUTO_YES" = false ]; then
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    read -p "Proceed with these changes? (Y/n): " confirm
    if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

echo ""
echo -e "${CYAN}Applying changes...${NC}"
echo ""

# ============================================================================
# APPLY CHANGES
# ============================================================================

# Create ARTIFACTS directories
if [ "$ARTIFACTS_NEEDED" = true ]; then
    echo "  Creating ARTIFACTS directories..."
    mkdir -p "$TARGET_DIR/ARTIFACTS"/{product-manager,system-architect,frontend-engineer,backend-engineer,ai-engineer,qa-engineer,devops-engineer,system}
fi

# Deep analysis files (before commands, in case we need to reference them)
if [ "$DEEP_ANALYZE" = true ]; then
    DEEP_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [ ! -f "$TARGET_DIR/ARTIFACTS/system/architecture-snapshot.json" ] || [ "$FORCE_MODE" = true ]; then
        echo "  Creating architecture-snapshot.json..."
        cat > "$TARGET_DIR/ARTIFACTS/system/architecture-snapshot.json" << EOF
{
  "project_name": "$PROJECT_NAME",
  "captured_at": "$DEEP_TIMESTAMP",
  "status": "pending",
  "technology_stack": {
    "languages": [],
    "frontend": {
      "framework": ${DETECTED_FRONTEND:+\"$DETECTED_FRONTEND\"}${DETECTED_FRONTEND:-null}
    },
    "backend": {
      "framework": ${DETECTED_BACKEND:+\"$DETECTED_BACKEND\"}${DETECTED_BACKEND:-null}
    },
    "database": {
      "primary": ${DETECTED_DATABASE:+\"$DETECTED_DATABASE\"}${DETECTED_DATABASE:-null}
    }
  },
  "directory_structure": [],
  "components": [],
  "patterns": {},
  "entry_points": [],
  "external_integrations": [],
  "conventions": {},
  "notes": ["Pending deep analysis - run Claude Code to complete"]
}
EOF
    fi

    if [ ! -f "$TARGET_DIR/ARTIFACTS/system/deep-analysis-prompt.md" ]; then
        echo "  Creating deep-analysis-prompt.md..."
        cat > "$TARGET_DIR/ARTIFACTS/system/deep-analysis-prompt.md" << 'EOF'
# Deep Architecture Analysis Required

A deep analysis of this codebase was requested. Please analyze the project and update:

**File to update:** `ARTIFACTS/system/architecture-snapshot.json`

## Analysis Tasks

1. **Directory Structure**: Identify key directories and their purposes
   - Look at top-level folders (src/, app/, lib/, components/, etc.)
   - Note what each directory contains

2. **Components**: Identify major components/modules
   - Pages, components, services, utilities, hooks, contexts
   - Their responsibilities and dependencies

3. **Patterns**: Detect architectural patterns
   - State management approach
   - Data fetching patterns
   - Routing approach
   - Authentication method
   - Error handling strategy
   - Testing approach

4. **Entry Points**: Find main entry points
   - App entry (index.tsx, main.ts, app.py, etc.)
   - API routes
   - Workers or background jobs

5. **External Integrations**: Note external services
   - APIs consumed
   - Third-party services
   - Database connections

6. **Conventions**: Observe coding conventions
   - Naming patterns
   - File organization
   - Import style

## Output

Update `ARTIFACTS/system/architecture-snapshot.json` with your findings.
Set `status` to `"completed"` when done.

**Important**: Do NOT modify any existing project files. Only update files in ARTIFACTS/.
EOF
    fi
fi

# Commands directory
if [ "$COMMANDS_NEEDED" = true ] || [ ${#COMMANDS_OUTDATED[@]} -gt 0 ]; then
    echo "  Setting up commands..."
    mkdir -p "$TARGET_DIR/commands"
    cp "$FRAMEWORK_DIR/commands/"*.sh "$TARGET_DIR/commands/" 2>/dev/null || true
    chmod +x "$TARGET_DIR/commands/"*.sh 2>/dev/null || true
fi

# Hooks directory
echo "  Setting up hooks..."
mkdir -p "$TARGET_DIR/.claude/hooks"
cp "$FRAMEWORK_DIR/hooks/"*.sh "$TARGET_DIR/.claude/hooks/" 2>/dev/null || true
chmod +x "$TARGET_DIR/.claude/hooks/"*.sh 2>/dev/null || true

# Configure hooks in settings.json (merge with existing if present)
if [ -f "$TARGET_DIR/.claude/settings.json" ]; then
    # Check if hooks already configured
    if ! grep -q '"SessionStart"' "$TARGET_DIR/.claude/settings.json" 2>/dev/null; then
        echo "  Adding hooks to existing settings.json..."
        # Use python to merge JSON if available
        if command -v python3 &> /dev/null; then
            python3 << PYEOF
import json

settings_path = "$TARGET_DIR/.claude/settings.json"
hooks_path = "$TARGET_DIR/.claude/hooks"

try:
    with open(settings_path, "r") as f:
        settings = json.load(f)
except:
    settings = {}

if "hooks" not in settings:
    settings["hooks"] = {}

settings["hooks"]["SessionStart"] = [
    {
        "hooks": [
            {
                "type": "command",
                "command": f"{hooks_path}/session-start.sh"
            }
        ]
    }
]

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

PYEOF
        fi
    fi
else
    # Create new settings.json with hooks
    echo "  Creating .claude/settings.json with hooks..."
    cat > "$TARGET_DIR/.claude/settings.json" << EOF
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$TARGET_DIR/.claude/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
EOF
fi

# project-config.json
if [ "$HAS_EXISTING_CONFIG" = true ] && [ "$ANALYZE" = true ]; then
    echo "  Merging project-config.json (preserving customizations)..."
    # Read existing config and merge with detected values
    # We'll use a simple approach: only update null/empty tech_stack values

    TEMP_CONFIG=$(mktemp)

    # Use Python for JSON merging if available, otherwise use jq, otherwise just inform user
    if command -v python3 &> /dev/null; then
        python3 << PYEOF
import json
import sys

try:
    with open("$TARGET_DIR/project-config.json", "r") as f:
        config = json.load(f)
except:
    config = {}

# Only update tech_stack values if they're null or empty
if "tech_stack" not in config:
    config["tech_stack"] = {}

detected = {
    "frontend": "${DETECTED_FRONTEND}" or None,
    "backend": "${DETECTED_BACKEND}" or None,
    "database": "${DETECTED_DATABASE}" or None,
    "ai_ml": "${DETECTED_AI}" or None,
    "infrastructure": "${DETECTED_INFRA}" or None
}

for key, value in detected.items():
    if value and (key not in config["tech_stack"] or not config["tech_stack"][key]):
        config["tech_stack"][key] = value

# Update framework path
config["framework_path"] = "$FRAMEWORK_DIR"

# Update existing_codebase flag
if "existing_codebase" not in config:
    config["existing_codebase"] = {}
config["existing_codebase"]["has_existing_code"] = True
config["existing_codebase"]["has_existing_architecture"] = True

with open("$TEMP_CONFIG", "w") as f:
    json.dump(config, f, indent=2)

PYEOF
        mv "$TEMP_CONFIG" "$TARGET_DIR/project-config.json"
    elif command -v jq &> /dev/null; then
        # jq-based merge (simplified)
        jq --arg fw "${DETECTED_FRONTEND}" \
           --arg be "${DETECTED_BACKEND}" \
           --arg db "${DETECTED_DATABASE}" \
           --arg ai "${DETECTED_AI}" \
           --arg infra "${DETECTED_INFRA}" \
           --arg fwpath "$FRAMEWORK_DIR" \
           '.tech_stack.frontend = (if .tech_stack.frontend == null and $fw != "" then $fw else .tech_stack.frontend end) |
            .tech_stack.backend = (if .tech_stack.backend == null and $be != "" then $be else .tech_stack.backend end) |
            .tech_stack.database = (if .tech_stack.database == null and $db != "" then $db else .tech_stack.database end) |
            .tech_stack.ai_ml = (if .tech_stack.ai_ml == null and $ai != "" then $ai else .tech_stack.ai_ml end) |
            .tech_stack.infrastructure = (if .tech_stack.infrastructure == null and $infra != "" then $infra else .tech_stack.infrastructure end) |
            .framework_path = $fwpath |
            .existing_codebase.has_existing_code = true |
            .existing_codebase.has_existing_architecture = true' \
           "$TARGET_DIR/project-config.json" > "$TEMP_CONFIG" && mv "$TEMP_CONFIG" "$TARGET_DIR/project-config.json"
    else
        echo -e "    ${YELLOW}Note: Install python3 or jq for automatic config merging${NC}"
        echo "    Detected values (update project-config.json manually):"
        [ -n "$DETECTED_FRONTEND" ] && echo "      frontend: $DETECTED_FRONTEND"
        [ -n "$DETECTED_BACKEND" ] && echo "      backend: $DETECTED_BACKEND"
        [ -n "$DETECTED_DATABASE" ] && echo "      database: $DETECTED_DATABASE"
    fi
elif [ "$HAS_EXISTING_CONFIG" = false ]; then
    echo "  Creating project-config.json..."
    cat > "$TARGET_DIR/project-config.json" << EOF
{
  "project_name": "$PROJECT_NAME",
  "project_type": "full_stack_web_app",
  "description": "",
  "tech_stack": {
    "frontend": ${DETECTED_FRONTEND:+\"$DETECTED_FRONTEND\"}${DETECTED_FRONTEND:-null},
    "backend": ${DETECTED_BACKEND:+\"$DETECTED_BACKEND\"}${DETECTED_BACKEND:-null},
    "database": ${DETECTED_DATABASE:+\"$DETECTED_DATABASE\"}${DETECTED_DATABASE:-null},
    "ai_ml": ${DETECTED_AI:+\"$DETECTED_AI\"}${DETECTED_AI:-null},
    "infrastructure": ${DETECTED_INFRA:+\"$DETECTED_INFRA\"}${DETECTED_INFRA:-null}
  },
  "execution_mode_default": "$EXECUTION_MODE",
  "existing_codebase": {
    "has_existing_code": $EXISTING_CODEBASE,
    "has_existing_architecture": $EXISTING_CODEBASE
  },
  "agents": {
    "required": ["product_manager", "system_architect", "qa_engineer", "devops_engineer"],
    "optional": ["frontend_engineer", "backend_engineer", "ai_engineer"],
    "excluded": []
  },
  "quality_gates": {
    "require_tests": true,
    "minimum_coverage": 70,
    "require_security_review": true,
    "code_health_minimum": "acceptable"
  },
  "framework_path": "$FRAMEWORK_DIR"
}
EOF
fi

# .claude/CLAUDE.md
mkdir -p "$TARGET_DIR/.claude"

# Build project context section based on detection
PROJECT_CONTEXT=""
if [ "$ANALYZE" = true ]; then
    PROJECT_CONTEXT="### Detected Tech Stack

| Layer | Technology |
|-------|------------|"
    [ -n "$DETECTED_FRONTEND" ] && PROJECT_CONTEXT="$PROJECT_CONTEXT
| Frontend | $DETECTED_FRONTEND |"
    [ -n "$DETECTED_BACKEND" ] && PROJECT_CONTEXT="$PROJECT_CONTEXT
| Backend | $DETECTED_BACKEND |"
    [ -n "$DETECTED_DATABASE" ] && PROJECT_CONTEXT="$PROJECT_CONTEXT
| Database | $DETECTED_DATABASE |"
    [ -n "$DETECTED_AI" ] && PROJECT_CONTEXT="$PROJECT_CONTEXT
| AI/ML | $DETECTED_AI |"
    [ -n "$DETECTED_INFRA" ] && PROJECT_CONTEXT="$PROJECT_CONTEXT
| Infrastructure | $DETECTED_INFRA |"

    if [ -n "$DETECTED_STRUCTURE" ]; then
        PROJECT_CONTEXT="$PROJECT_CONTEXT

### Project Structure

Key directories: \`$DETECTED_STRUCTURE\`"
    fi

    PROJECT_CONTEXT="$PROJECT_CONTEXT

### Execution Mode

This is an **existing project**. The framework is set to \`fast_feature\` mode by default, which means:
- Lightweight requirements gathering
- Architecture assessment (not full design)
- Focus on incremental changes"
fi

# Framework content to write (with markers for update detection)
FRAMEWORK_CONTENT=$(cat << 'FRAMEWORK_EOF'
<!-- AI-NATIVE-FRAMEWORK-START -->

---

## AI-Native Development Framework

This project uses the AI-Native Development Framework for structured, multi-agent development.

### Framework Location

```
FRAMEWORK_DIR_PLACEHOLDER
```

---

## REQUIRED: Follow This Workflow

When the user describes a **feature, task, or problem to solve**, you MUST follow this workflow:

### Step 1: Check Current Stage
Run `./commands/status.sh` or read `ARTIFACTS/system/workflow-state.json` to see the current stage.

### Step 2: Follow the Current Stage's Agent

| Stage | What To Do |
|-------|------------|
| **requirements** | Read `@FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/product-manager.md` and create `ARTIFACTS/product-manager/requirements.json` |
| **architecture** | Read `@FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/system-architect.md` and create `ARTIFACTS/system-architect/architecture.json` |
| **frontend_implementation** | Read `@FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/frontend-engineer.md` |
| **backend_implementation** | Read `@FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/backend-engineer.md` |
| **ai_implementation** | Read `@FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/ai-engineer.md` |
| **qa_testing** | Read `@FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/qa-engineer.md` |
| **deployment** | Read `@FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/devops-engineer.md` |

### Step 3: Save Artifacts
- Save all outputs to the appropriate `ARTIFACTS/<agent>/` folder
- Use JSON format matching schemas in `FRAMEWORK_DIR_PLACEHOLDER/L3 - Workflows & Contracts/contracts/`

### Step 4: Ask for Approval
At gate stages (requirements, architecture, deployment), ask the user to approve before proceeding:
> "Requirements are ready. Please review ARTIFACTS/product-manager/requirements.json and run `./commands/approve.sh requirements` to proceed."

---

### Commands

- `./commands/status.sh` - Check workflow status
- `./commands/next.sh` - See what to do next
- `./commands/approve.sh <stage>` - Approve a stage
- `./commands/validate.sh --all` - Validate artifacts

### Artifacts Structure

```
ARTIFACTS/
├── product-manager/      # Requirements (requirements.json)
├── system-architect/     # Architecture (architecture.json)
├── frontend-engineer/    # Frontend implementation
├── backend-engineer/     # Backend implementation
├── ai-engineer/          # AI implementation
├── qa-engineer/          # Test reports
├── devops-engineer/      # Deployment reports
└── system/               # Workflow state (workflow-state.json)
```

<!-- AI-NATIVE-FRAMEWORK-END -->
FRAMEWORK_EOF
)

# Replace placeholder with actual framework directory
FRAMEWORK_CONTENT="${FRAMEWORK_CONTENT//FRAMEWORK_DIR_PLACEHOLDER/$FRAMEWORK_DIR}"

if [ "$CLAUDE_MD_ACTION" = "UPDATE" ]; then
    echo "  Updating .claude/CLAUDE.md..."
    # Replace existing framework section between markers
    awk -v new_content="$FRAMEWORK_CONTENT" '
        /<!-- AI-NATIVE-FRAMEWORK-START -->/ { skip=1; print new_content; next }
        /<!-- AI-NATIVE-FRAMEWORK-END -->/ { skip=0; next }
        !skip { print }
    ' "$TARGET_DIR/.claude/CLAUDE.md" > "$TARGET_DIR/.claude/CLAUDE.md.tmp"
    mv "$TARGET_DIR/.claude/CLAUDE.md.tmp" "$TARGET_DIR/.claude/CLAUDE.md"
elif [ "$CLAUDE_MD_ACTION" = "APPEND" ]; then
    echo "  Appending to .claude/CLAUDE.md..."
    echo "$FRAMEWORK_CONTENT" >> "$TARGET_DIR/.claude/CLAUDE.md"
else
    echo "  Creating .claude/CLAUDE.md..."
    cat > "$TARGET_DIR/.claude/CLAUDE.md" << EOF
# $PROJECT_NAME

$FRAMEWORK_CONTENT

---

## Project Context

$PROJECT_CONTEXT

### Description

<!-- Describe your project here -->

### Goals

<!-- What are you trying to achieve? -->

### Constraints

<!-- Budget, timeline, compliance requirements, etc. -->

### Notes

<!-- Any other relevant information -->

EOF
fi

# workflow-state.json
SHOULD_CREATE_WORKFLOW=false
if [ ! -f "$TARGET_DIR/ARTIFACTS/system/workflow-state.json" ]; then
    SHOULD_CREATE_WORKFLOW=true
elif [ "$FORCE_MODE" = true ] && [ "$WORKFLOW_IN_PROGRESS" = false ]; then
    SHOULD_CREATE_WORKFLOW=true
elif [ "$FORCE_MODE" = true ] && [ "$WORKFLOW_IN_PROGRESS" = true ]; then
    # Even with --force, warn about in-progress workflow
    echo -e "  ${YELLOW}Resetting workflow-state.json (--force mode)...${NC}"
    SHOULD_CREATE_WORKFLOW=true
fi

if [ "$SHOULD_CREATE_WORKFLOW" = true ]; then
    echo "  Creating workflow-state.json..."
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    WORKFLOW_ID="wf-$(date +%s)-$$"

    cat > "$TARGET_DIR/ARTIFACTS/system/workflow-state.json" << EOF
{
  "workflow_id": "$WORKFLOW_ID",
  "product_name": "$PROJECT_NAME",
  "execution_mode": "$EXECUTION_MODE",
  "current_stage": "requirements",
  "stages": {
    "requirements": {
      "status": "pending",
      "agent": "product_manager",
      "human_approval_required": true,
      "human_approval_received": false
    },
    "architecture": {
      "status": "pending",
      "agent": "system_architect",
      "human_approval_required": true,
      "human_approval_received": false
    },
    "frontend_implementation": {
      "status": "pending",
      "agent": "frontend_engineer"
    },
    "backend_implementation": {
      "status": "pending",
      "agent": "backend_engineer"
    },
    "ai_implementation": {
      "status": "pending",
      "agent": "ai_engineer"
    },
    "qa_testing": {
      "status": "pending",
      "agent": "qa_engineer"
    },
    "deployment": {
      "status": "pending",
      "agent": "devops_engineer",
      "human_approval_required": true,
      "human_approval_received": false
    },
    "safety_review": {
      "status": "pending",
      "agent": "safety_agent"
    },
    "governance_review": {
      "status": "pending",
      "agent": "governance_agent"
    },
    "code_health_assessment": {
      "status": "pending",
      "agent": "code_health_agent"
    }
  },
  "parallel_execution": {
    "enabled": true,
    "parallel_stages": [
      ["frontend_implementation", "backend_implementation", "ai_implementation"]
    ]
  },
  "safety_and_governance": {
    "safety_review_status": "pending",
    "governance_review_status": "pending",
    "risk_level": null
  },
  "human_interactions": [],
  "blocking_issues": [],
  "metadata": {
    "created_by": "setup.sh",
    "project_name": "$PROJECT_NAME",
    "framework_path": "$FRAMEWORK_DIR",
    "existing_codebase": $EXISTING_CODEBASE,
    "tags": []
  },
  "created_at": "$TIMESTAMP",
  "updated_at": "$TIMESTAMP"
}
EOF
fi

# Initialize git if not already a repo (needed for checkpoints)
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "  Initializing git repository..."
    git init -q "$TARGET_DIR"
    GIT_INITIALIZED=true
else
    GIT_INITIALIZED=false
fi

# Check .gitignore
if [ ! -f "$TARGET_DIR/.gitignore" ]; then
    touch "$TARGET_DIR/.gitignore"
fi

# Create initial commit if we just initialized git
if [ "$GIT_INITIALIZED" = true ]; then
    echo "  Creating initial commit..."
    git -C "$TARGET_DIR" add -A
    git -C "$TARGET_DIR" commit -q -m "Initial project setup with AI-Native Development Framework"
fi

# ============================================================================
# DONE
# ============================================================================

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "Project: ${YELLOW}$PROJECT_NAME${NC}"
if [ "$EXISTING_CODEBASE" = true ]; then
    echo -e "Mode: ${YELLOW}fast_feature${NC} (existing codebase)"
else
    echo -e "Mode: ${YELLOW}full_system${NC} (new project)"
fi

echo ""
echo -e "${BLUE}Changes applied:${NC}"
for change in "${CHANGES_TO_MAKE[@]}"; do
    echo -e "  ${GREEN}✓${NC} $change"
done

if [ ${#CHANGES_SKIPPED[@]} -gt 0 ]; then
    echo ""
    echo -e "${DIM}Preserved (no changes):${NC}"
    for skip in "${CHANGES_SKIPPED[@]}"; do
        echo -e "  ${DIM}• $skip${NC}"
    done
fi

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo ""
if [ "$DEEP_ANALYZE" = true ]; then
    echo "  1. Open Claude Code - it will see the deep analysis prompt"
    echo "  2. Claude will analyze your codebase and fill in architecture-snapshot.json"
    echo "  3. Then describe what you want to build"
else
    echo "  1. Review .claude/CLAUDE.md for accuracy"
    echo "  2. Open Claude Code and describe what you want to build"
fi
echo ""
echo "  Check status: ${YELLOW}./commands/status.sh${NC}"
echo ""
