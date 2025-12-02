#!/bin/bash
# Set up a project to use the AI-Native Development Framework
# Usage: ./setup.sh [options] [project-name]
#
# Options:
#   --analyze    Analyze existing codebase and auto-detect tech stack
#   --help       Show this help message

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get framework directory (where this script lives)
FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
ANALYZE=false
DEEP_ANALYZE=false
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
        --help|-h)
            echo "Usage: ./setup.sh [options] [project-name]"
            echo ""
            echo "Options:"
            echo "  --analyze, -a       Analyze existing codebase and auto-detect tech stack"
            echo "  --deep-analyze, -d  Deep analysis: detect patterns, components, architecture"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./setup.sh                    # New project in current directory"
            echo "  ./setup.sh my-app             # New project named 'my-app'"
            echo "  ./setup.sh --analyze          # Existing project, detect stack"
            echo "  ./setup.sh --deep-analyze     # Existing project, full architecture scan"
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

# Auto-detect if this looks like an existing project
if [ "$ANALYZE" = false ]; then
    if [ -f "$TARGET_DIR/package.json" ] || [ -f "$TARGET_DIR/requirements.txt" ] || \
       [ -f "$TARGET_DIR/go.mod" ] || [ -f "$TARGET_DIR/Cargo.toml" ] || \
       [ -f "$TARGET_DIR/pyproject.toml" ] || [ -f "$TARGET_DIR/pom.xml" ] || \
       [ -d "$TARGET_DIR/src" ] || [ -d "$TARGET_DIR/app" ]; then
        echo ""
        echo -e "${YELLOW}Existing project detected.${NC}"
        read -p "Analyze codebase to auto-detect tech stack? (Y/n): " do_analyze
        if [ "$do_analyze" != "n" ] && [ "$do_analyze" != "N" ]; then
            ANALYZE=true
        fi
    fi
fi

echo ""

# Check if already set up (look for our .claude/CLAUDE.md, not root CLAUDE.md)
if [ -f "$TARGET_DIR/.claude/CLAUDE.md" ] && [ -d "$TARGET_DIR/ARTIFACTS" ]; then
    echo -e "${YELLOW}Warning: This project appears to already be set up.${NC}"
    read -p "Reinitialize? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

echo "Setting up project..."

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
    echo ""
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
# CREATE PROJECT FILES
# ============================================================================

# Create ARTIFACTS directory structure
echo "  Creating ARTIFACTS directories..."
mkdir -p "$TARGET_DIR/ARTIFACTS"/{product-manager,system-architect,frontend-engineer,backend-engineer,ai-engineer,qa-engineer,devops-engineer,system}

# ============================================================================
# DEEP ANALYSIS (if --deep-analyze)
# ============================================================================

if [ "$DEEP_ANALYZE" = true ]; then
    echo -e "${CYAN}Preparing deep architecture analysis...${NC}"
    DEEP_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create pending architecture snapshot
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

    # Create analysis prompt for Claude Code
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

    echo -e "  Created: ${YELLOW}ARTIFACTS/system/architecture-snapshot.json${NC} (pending)"
    echo -e "  Created: ${YELLOW}ARTIFACTS/system/deep-analysis-prompt.md${NC}"
    echo ""
    echo -e "${YELLOW}Deep analysis will run when you start Claude Code.${NC}"
    echo ""
fi

# Create commands directory and copy commands
echo "  Setting up commands..."
mkdir -p "$TARGET_DIR/commands"
cp "$FRAMEWORK_DIR/commands/"*.sh "$TARGET_DIR/commands/" 2>/dev/null || true
chmod +x "$TARGET_DIR/commands/"*.sh 2>/dev/null || true

# Create project-config.json
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

# Create .claude/CLAUDE.md (framework instructions)
# This goes in .claude/ so it doesn't conflict with existing root CLAUDE.md
mkdir -p "$TARGET_DIR/.claude"

# Markers for framework section (used for updates/upgrades)
FRAMEWORK_START_MARKER="<!-- AI-NATIVE-FRAMEWORK-START -->"
FRAMEWORK_END_MARKER="<!-- AI-NATIVE-FRAMEWORK-END -->"

# Check if .claude/CLAUDE.md already exists and if it has our framework section
if [ -f "$TARGET_DIR/.claude/CLAUDE.md" ]; then
    if grep -q "$FRAMEWORK_START_MARKER" "$TARGET_DIR/.claude/CLAUDE.md"; then
        echo -e "  ${YELLOW}.claude/CLAUDE.md has existing framework section${NC}"
        echo "  Updating framework instructions..."
        UPDATE_MODE=true
        APPEND_MODE=false
    else
        echo -e "  ${YELLOW}.claude/CLAUDE.md exists without framework section${NC}"
        echo "  Appending framework instructions..."
        UPDATE_MODE=false
        APPEND_MODE=true
    fi
else
    echo "  Creating .claude/CLAUDE.md..."
    UPDATE_MODE=false
    APPEND_MODE=false
fi

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

### How to Use

1. **Describe what you want to build** - Start with your idea or problem statement
2. **Follow the agent workflow** - Each agent will guide you through their stage
3. **Approve at gates** - You'll be asked to approve requirements, architecture, and deployment

### Agent Specifications

When working on this project, load the relevant agent specs from the framework:

| Stage | Agent Spec |
|-------|------------|
| Requirements | `FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/product-manager.md` |
| Architecture | `FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/system-architect.md` |
| Frontend | `FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/frontend-engineer.md` |
| Backend | `FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/backend-engineer.md` |
| AI/ML | `FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/ai-engineer.md` |
| QA | `FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/qa-engineer.md` |
| DevOps | `FRAMEWORK_DIR_PLACEHOLDER/L1 - Specialist Agents/devops-engineer.md` |

### Orchestration

- Workflow logic: `FRAMEWORK_DIR_PLACEHOLDER/L3 - Workflows & Contracts/workflows/orchestration.md`
- Schemas: `FRAMEWORK_DIR_PLACEHOLDER/L3 - Workflows & Contracts/contracts/`

### Commands

Run from project root:

- `./commands/status.sh` - Check workflow status
- `./commands/next.sh` - See what to do next
- `./commands/approve.sh <stage>` - Approve a stage
- `./commands/validate.sh --all` - Validate artifacts

### Artifacts

All agent outputs go to `ARTIFACTS/`:

```
ARTIFACTS/
├── product-manager/      # Requirements
├── system-architect/     # Architecture
├── frontend-engineer/    # Frontend implementation
├── backend-engineer/     # Backend implementation
├── ai-engineer/          # AI implementation
├── qa-engineer/          # Test reports
├── devops-engineer/      # Deployment reports
└── system/               # Workflow state
```

<!-- AI-NATIVE-FRAMEWORK-END -->
FRAMEWORK_EOF
)

# Replace placeholder with actual framework directory
FRAMEWORK_CONTENT="${FRAMEWORK_CONTENT//FRAMEWORK_DIR_PLACEHOLDER/$FRAMEWORK_DIR}"

if [ "$UPDATE_MODE" = true ]; then
    # Replace existing framework section between markers
    # Use awk to preserve content before and after the markers
    awk -v new_content="$FRAMEWORK_CONTENT" '
        /<!-- AI-NATIVE-FRAMEWORK-START -->/ { skip=1; print new_content; next }
        /<!-- AI-NATIVE-FRAMEWORK-END -->/ { skip=0; next }
        !skip { print }
    ' "$TARGET_DIR/.claude/CLAUDE.md" > "$TARGET_DIR/.claude/CLAUDE.md.tmp"
    mv "$TARGET_DIR/.claude/CLAUDE.md.tmp" "$TARGET_DIR/.claude/CLAUDE.md"
elif [ "$APPEND_MODE" = true ]; then
    # Append to existing file (file exists but no framework section)
    echo "$FRAMEWORK_CONTENT" >> "$TARGET_DIR/.claude/CLAUDE.md"
else
    # Create new file with header
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

# Initialize workflow state
echo "  Initializing workflow state..."
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

# Initialize git if not already a repo (needed for checkpoints)
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "  Initializing git repository..."
    git init -q "$TARGET_DIR"
    GIT_INITIALIZED=true
else
    GIT_INITIALIZED=false
fi

# Note: We intentionally track ARTIFACTS/ in git so checkpoints can capture
# the full project state (requirements, architecture decisions, etc.)
# Only add framework-specific ignores if needed
echo "  Checking .gitignore..."
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
echo -e "${GREEN}✓ Project setup complete!${NC}"
echo ""
echo -e "Project initialized: ${YELLOW}$PROJECT_NAME${NC}"
if [ "$EXISTING_CODEBASE" = true ]; then
    echo -e "Mode: ${YELLOW}fast_feature${NC} (existing codebase detected)"
else
    echo -e "Mode: ${YELLOW}full_system${NC} (new project)"
fi
echo ""
echo -e "${BLUE}What was created:${NC}"
echo "  .claude/CLAUDE.md      - Framework instructions (auto-loaded by Claude Code)"
echo "  project-config.json    - Project configuration"
echo "  ARTIFACTS/             - Directory for agent outputs"
echo "  commands/              - Helper commands"
if [ "$DEEP_ANALYZE" = true ]; then
    echo ""
    echo -e "${BLUE}Deep analysis files:${NC}"
    echo "  ARTIFACTS/system/architecture-snapshot.json  - Architecture (pending)"
    echo "  ARTIFACTS/system/deep-analysis-prompt.md     - Analysis instructions"
fi
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo ""
if [ "$DEEP_ANALYZE" = true ]; then
    echo "  1. Open Claude Code - it will see the deep analysis prompt"
    echo ""
    echo "  2. Claude will analyze your codebase and fill in architecture-snapshot.json"
    echo ""
    echo "  3. Then describe what you want to build"
else
    echo "  1. Review and edit .claude/CLAUDE.md to add your project context"
    echo ""
    echo "  2. Review project-config.json for accuracy"
    echo ""
    echo "  3. Open Claude Code and describe what you want to build:"
    echo -e "     ${YELLOW}claude${NC}"
fi
echo ""
echo "  Check status anytime:"
echo -e "     ${YELLOW}./commands/status.sh${NC}"
echo ""
