# Agent Hooks Specification

**Version**: 1.0
**Last Updated**: 2025-12-02

---

## Purpose

Hooks automate context loading and validation for agent invocations. They ensure:

- Agents receive required upstream artifacts
- Project configuration is always available
- Output schemas are loaded before work begins
- Artifacts are pre-validated before orchestrator processing

---

## Hook Types

### 1. Pre-Invocation Hooks

Run before an agent starts work. Load required context.

| Hook | Trigger | Action |
|------|---------|--------|
| `load-project-config` | Any agent start | Load `project-config.json` into context |
| `load-upstream-artifacts` | Agent start | Load artifacts from previous stages |
| `load-output-schema` | Agent start | Load the schema for this agent's output |
| `inject-workflow-state` | Agent start | Provide current `workflow-state.json` |

### 2. Post-Completion Hooks

Run after an agent signals completion. Validate and process output.

| Hook | Trigger | Action |
|------|---------|--------|
| `validate-output-artifact` | Completion signal received | Validate artifact against schema |
| `validate-completion-signal` | Completion signal received | Validate signal against `stage-completion-signal-schema.json` |
| `update-workflow-state` | Validation passed | Merge completion into workflow state |
| `notify-orchestrator` | State updated | Signal orchestrator to resolve next agent |

### 3. Gate Hooks

Run at workflow gates. Enforce approval and review requirements.

| Hook | Trigger | Action |
|------|---------|--------|
| `check-human-approval` | Gate reached | Pause if approval required and not received |
| `invoke-safety-review` | Risk-based | Invoke safety_agent if risk level requires |
| `invoke-governance-review` | Risk-based | Invoke governance_agent if required |
| `check-code-health` | Optional gate | Invoke code_health_agent if configured |

### 4. MCP Integration Hooks (Optional)

Enhance agent capabilities with external AI services. Requires MCP servers to be configured.

| Hook | Trigger | Action |
|------|---------|--------|
| `context-refresh` | Implementation stage start | Fetch latest API docs for declared dependencies |
| `second-opinion` | Architecture or high-risk stage | Request external review from secondary AI |

---

## Agent Context Loading Matrix

Each agent requires specific upstream context. Pre-invocation hooks load these automatically.

| Agent | Project Config | Upstream Artifacts | Output Schema |
|-------|---------------|-------------------|---------------|
| `product_manager` | ✓ | (none - first stage) | `pm-output-schema.json` |
| `system_architect` | ✓ | `product-requirements-packet.json` | `architect-output-schema.json` or `architecture-assessment-schema.json` |
| `frontend_engineer` | ✓ | `architecture-handover-packet.json` | `frontend-output-schema.json` |
| `backend_engineer` | ✓ | `architecture-handover-packet.json` | `backend-output-schema.json` |
| `ai_engineer` | ✓ | `architecture-handover-packet.json` | `ai-engineer-output-schema.json` |
| `qa_engineer` | ✓ | All `*-implementation-report.json`, `product-requirements-packet.json` | `qa-output-schema.json` |
| `devops_engineer` | ✓ | `qa-test-report.json`, all implementation reports | `devops-output-schema.json` |
| `safety_agent` | ✓ | Stage artifacts being reviewed | `safety-output-schema.json` |
| `governance_agent` | ✓ | Stage artifacts being reviewed | `governance-output-schema.json` |
| `code_health_agent` | ✓ | Implementation reports (if post-implementation) | `code-health-output-schema.json` |

---

## Hook Implementation

### Pre-Invocation: Load Context

```python
def pre_invoke_agent(agent: str, workflow_state: dict) -> dict:
    """
    Load required context before agent invocation.
    Returns context dict to inject into agent prompt.
    """
    context = {}

    # Always load project config
    context["project_config"] = load_json("project-config.json")

    # Always load workflow state
    context["workflow_state"] = workflow_state

    # Load output schema for this agent
    schema_map = {
        "product_manager": "pm-output-schema.json",
        "system_architect": "architect-output-schema.json",  # or assessment
        "frontend_engineer": "frontend-output-schema.json",
        "backend_engineer": "backend-output-schema.json",
        "ai_engineer": "ai-engineer-output-schema.json",
        "qa_engineer": "qa-output-schema.json",
        "devops_engineer": "devops-output-schema.json",
        "safety_agent": "safety-output-schema.json",
        "governance_agent": "governance-output-schema.json",
        "code_health_agent": "code-health-output-schema.json",
    }
    context["output_schema"] = load_schema(schema_map[agent])

    # Load upstream artifacts
    context["upstream_artifacts"] = load_upstream_artifacts(agent, workflow_state)

    return context


def load_upstream_artifacts(agent: str, workflow_state: dict) -> dict:
    """Load artifacts this agent depends on."""
    artifacts = {}

    if agent == "system_architect":
        artifacts["requirements"] = load_artifact("product-requirements-packet.json")

    elif agent in ["frontend_engineer", "backend_engineer", "ai_engineer"]:
        if workflow_state["execution_mode"] == "full_system":
            artifacts["architecture"] = load_artifact("architecture-handover-packet.json")
        else:
            artifacts["architecture"] = load_artifact("architecture-assessment.json")

    elif agent == "qa_engineer":
        artifacts["requirements"] = load_artifact("product-requirements-packet.json")
        # Load all completed implementation reports
        for impl_stage in ["frontend", "backend", "ai"]:
            stage_key = f"{impl_stage}_implementation"
            if workflow_state["stages"][stage_key]["status"] == "completed":
                artifacts[stage_key] = load_artifact(
                    workflow_state["stages"][stage_key]["output_artifacts"][0]
                )

    elif agent == "devops_engineer":
        artifacts["qa_report"] = load_artifact("qa-test-report.json")
        # Load implementation reports for deployment context
        for impl_stage in ["frontend", "backend", "ai"]:
            stage_key = f"{impl_stage}_implementation"
            if workflow_state["stages"][stage_key]["status"] == "completed":
                artifacts[stage_key] = load_artifact(
                    workflow_state["stages"][stage_key]["output_artifacts"][0]
                )

    elif agent in ["safety_agent", "governance_agent"]:
        # Load artifacts from the stage being reviewed
        current_stage = workflow_state["current_stage"]
        if current_stage in workflow_state["stages"]:
            stage_data = workflow_state["stages"][current_stage]
            if stage_data.get("output_artifacts"):
                for artifact_path in stage_data["output_artifacts"]:
                    artifacts[current_stage] = load_artifact(artifact_path)

    return artifacts
```

### Post-Completion: Validate Output

```python
def post_complete_agent(completion_signal: dict, workflow_state: dict) -> bool:
    """
    Validate agent output after completion signal received.
    Returns True if valid, False if validation failed.
    """

    # 1. Validate the completion signal itself
    signal_valid = validate_artifact(
        completion_signal,
        "stage-completion-signal-schema.json"
    )
    if not signal_valid:
        log_validation_failure("completion_signal", signal_valid.errors)
        return False

    # 2. Validate each output artifact
    for artifact_path in completion_signal.get("output_artifacts", []):
        schema = get_schema_for_artifact(artifact_path)
        artifact_valid = validate_artifact(artifact_path, schema)
        if not artifact_valid:
            log_validation_failure(artifact_path, artifact_valid.errors)
            return False

    # 3. Update workflow state
    merge_completion_into_state(completion_signal, workflow_state)

    # 4. Trigger gate checks
    if not check_gates(completion_signal["stage"], workflow_state):
        return False  # Paused at gate

    # 5. Resolve and invoke next agent
    next_agents = resolve_next_agent(completion_signal, workflow_state)
    if next_agents:
        for agent in next_agents:
            invoke_agent(agent, workflow_state)

    return True
```

---

## Claude Code Hooks Integration

If using Claude Code's native hooks system, place shell scripts in `.claude/hooks/`:

### `.claude/hooks/pre-agent.sh`

```bash
#!/bin/bash
# Pre-invocation hook: inject context into agent prompt

AGENT="$1"
WORKFLOW_STATE="ARTIFACTS/system/workflow-state.json"
PROJECT_CONFIG="project-config.json"

echo "=== Auto-Loading Context for $AGENT ==="

# Always include project config
if [ -f "$PROJECT_CONFIG" ]; then
    echo "Loaded: $PROJECT_CONFIG"
fi

# Always include workflow state
if [ -f "$WORKFLOW_STATE" ]; then
    echo "Loaded: $WORKFLOW_STATE"
fi

# Load agent-specific upstream artifacts
case "$AGENT" in
    system_architect)
        echo "Loaded: ARTIFACTS/product-manager/product-requirements-packet.json"
        ;;
    frontend_engineer|backend_engineer|ai_engineer)
        echo "Loaded: ARTIFACTS/system-architect/architecture-handover-packet.json"
        ;;
    qa_engineer)
        echo "Loaded: All implementation reports"
        ;;
    devops_engineer)
        echo "Loaded: ARTIFACTS/qa-engineer/qa-test-report.json"
        ;;
esac

echo "=== Context Loading Complete ==="
```

### `.claude/hooks/post-artifact.sh`

```bash
#!/bin/bash
# Post-completion hook: validate artifact before orchestrator processes

ARTIFACT="$1"
CONTRACTS_DIR="L3 - Workflows & Contracts/contracts"

# Map artifact to schema
get_schema() {
    local artifact=$(basename "$1")
    case "$artifact" in
        product-requirements-packet.json) echo "pm-output-schema.json" ;;
        architecture-handover-packet.json) echo "architect-output-schema.json" ;;
        architecture-assessment.json) echo "architecture-assessment-schema.json" ;;
        frontend-implementation-report.json) echo "frontend-output-schema.json" ;;
        backend-implementation-report.json) echo "backend-output-schema.json" ;;
        ai-implementation-report.json) echo "ai-engineer-output-schema.json" ;;
        qa-test-report.json) echo "qa-output-schema.json" ;;
        deployment-report.json) echo "devops-output-schema.json" ;;
        stage-completion-signal.json) echo "stage-completion-signal-schema.json" ;;
        *) echo "" ;;
    esac
}

SCHEMA=$(get_schema "$ARTIFACT")
if [ -n "$SCHEMA" ]; then
    echo "Validating $ARTIFACT against $SCHEMA..."
    python scripts/validate.py "$ARTIFACT" "$CONTRACTS_DIR/$SCHEMA"
    if [ $? -ne 0 ]; then
        echo "ERROR: Validation failed. Blocking progression."
        exit 1
    fi
    echo "Validation passed."
fi
```

---

## Security Hooks

### MCP Server Call Validation

If using MCP servers, validate calls before execution:

```bash
#!/bin/bash
# .claude/hooks/pre-mcp.sh - Security scan for MCP calls

MCP_CALL="$1"

# Block dangerous patterns
BLOCKED_PATTERNS=(
    "rm -rf"
    "sudo"
    "curl.*|.*sh"
    "wget.*|.*sh"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
    if echo "$MCP_CALL" | grep -qE "$pattern"; then
        echo "BLOCKED: Dangerous pattern detected: $pattern"
        exit 1
    fi
done

echo "MCP call approved."
```

---

## MCP Integration Hooks

These hooks integrate optional MCP servers (Context7, Gemini) to enhance agent capabilities.

### Context Refresh Hook

**Purpose**: Before implementation stages, fetch up-to-date documentation for declared dependencies.

**Trigger**: Start of `frontend_implementation`, `backend_implementation`, or `ai_implementation` stage.

**Action**:
1. Read `project-config.json` → `technology_stack`
2. For each framework/library, call Context7 MCP to fetch current API docs
3. Store summary in `ARTIFACTS/system/context-refresh-report.json`
4. Attach summary to agent context

```bash
#!/bin/bash
# .claude/hooks/context-refresh.sh
# Fetch latest docs for tech stack before implementation

STAGE="$1"
PROJECT_CONFIG="project-config.json"
OUTPUT="ARTIFACTS/system/context-refresh-report.json"

# Only run for implementation stages
case "$STAGE" in
    frontend_implementation|backend_implementation|ai_implementation) ;;
    *) exit 0 ;;
esac

# Extract tech stack (requires jq or python)
if command -v jq &> /dev/null; then
    FRONTEND=$(jq -r '.technology_stack.frontend.framework // empty' "$PROJECT_CONFIG")
    BACKEND=$(jq -r '.technology_stack.backend.framework // empty' "$PROJECT_CONFIG")
else
    FRONTEND=$(python3 -c "import json; print(json.load(open('$PROJECT_CONFIG')).get('technology_stack',{}).get('frontend',{}).get('framework',''))")
    BACKEND=$(python3 -c "import json; print(json.load(open('$PROJECT_CONFIG')).get('technology_stack',{}).get('backend',{}).get('framework',''))")
fi

echo "Context refresh for: $FRONTEND $BACKEND"
echo "Use Context7 MCP to fetch latest docs for these libraries."
echo ""
echo "Run: /context7 <library-name>"
```

**Usage in workflow**:
```
Before starting frontend implementation:
  → Run /context7 react (or vue, angular, etc.)
  → Attach refreshed API summary to frontend_engineer context
```

### Second Opinion Hook

**Purpose**: Get external AI review for architecture decisions or high-risk stages.

**Trigger**:
- After `architecture` stage produces options (in `full_system` mode)
- When `risk_level` is `high` or `critical`
- Optionally for `safety_review` or `governance_review`

**Action**:
1. Identify artifact to review
2. Call Gemini MCP for architectural/security review
3. Store review in `ARTIFACTS/system/second-opinion-review.json`
4. Human can consider before approval

```bash
#!/bin/bash
# .claude/hooks/second-opinion.sh
# Request external review for architecture or high-risk stages

STAGE="$1"
WORKFLOW_STATE="ARTIFACTS/system/workflow-state.json"
OUTPUT="ARTIFACTS/system/second-opinion-review.json"

# Check if second opinion is warranted
RISK_LEVEL=$(python3 -c "import json; print(json.load(open('$WORKFLOW_STATE')).get('safety_and_governance',{}).get('risk_level','low'))" 2>/dev/null || echo "low")

NEEDS_REVIEW=false

case "$STAGE" in
    architecture)
        NEEDS_REVIEW=true
        ARTIFACT="ARTIFACTS/system-architect/architecture-handover-packet.json"
        ;;
    safety_review|governance_review)
        if [ "$RISK_LEVEL" = "high" ] || [ "$RISK_LEVEL" = "critical" ]; then
            NEEDS_REVIEW=true
        fi
        ;;
esac

if [ "$NEEDS_REVIEW" = true ]; then
    echo "Second opinion recommended for $STAGE (risk: $RISK_LEVEL)"
    echo ""
    echo "Run: /gemini-review $ARTIFACT"
fi
```

**Usage in workflow**:
```
After architect produces architecture-handover-packet.json:
  → Run /gemini-review ARTIFACTS/system-architect/architecture-handover-packet.json
  → Review Gemini's concerns/suggestions
  → Consider feedback before approving architecture
```

---

## MCP Commands

### `/context7` - Fetch Library Documentation

Fetches up-to-date documentation for a library or framework.

**Usage**: `./commands/context7.sh <topic>`

**Example**:
```bash
./commands/context7.sh "Next.js App Router"
./commands/context7.sh "FastAPI dependency injection"
```

**Output**: Stores summary in `ARTIFACTS/system/context-refresh-report.json`

### `/gemini-review` - Request Second Opinion

Requests an external AI review of an artifact.

**Usage**: `./commands/gemini-review.sh <artifact-path>`

**Example**:
```bash
./commands/gemini-review.sh ARTIFACTS/system-architect/architecture-handover-packet.json
./commands/gemini-review.sh ARTIFACTS/safety-agent/safety-review.json
```

**Output**: Stores review in `ARTIFACTS/system/second-opinion-review.json`

---

## MCP Artifact Schemas

### context-refresh-report.json

```json
{
  "topic": "Next.js App Router",
  "source": "context7",
  "source_url": "https://nextjs.org/docs/app",
  "summary": "Key APIs: useRouter, Link, redirect...",
  "fetched_at": "2025-12-02T15:30:00Z",
  "for_stage": "frontend_implementation"
}
```

### second-opinion-review.json

```json
{
  "scope": "architecture-handover-packet.json",
  "reviewer": "gemini",
  "concerns": [
    "Consider rate limiting on the public API endpoints",
    "The JWT secret should be rotated periodically"
  ],
  "suggestions": [
    "Add a caching layer between API and database",
    "Consider event sourcing for audit requirements"
  ],
  "verdict": "approve_with_notes",
  "reviewed_at": "2025-12-02T15:45:00Z"
}
```

---

## References

- [orchestration.md](./orchestration.md) — Orchestration logic
- [stage-completion-guide.md](./stage-completion-guide.md) — Stage completion details
- [validate.py](../../scripts/validate.py) — Validation script
- [validate.sh](../../scripts/validate.sh) — Validation script (bash)

---

**END OF HOOKS SPECIFICATION**
