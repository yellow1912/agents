# Workflow Commands

**Version**: 1.0
**Last Updated**: 2025-12-02

---

## Purpose

This document provides ready-to-use command templates for common workflow operations. These can be:

- Executed directly in a shell
- Placed in `.claude/commands/` as slash commands
- Used as reference for building automation scripts

---

## Project Initialization

Project initialization is handled by the framework's `setup.sh` script, not a command.

```bash
# From any project directory:
~/.claude-agents/setup.sh [project-name]
```

This creates:
- `CLAUDE.md` - Project context
- `project-config.json` - Project settings
- `ARTIFACTS/` - Agent output directories
- `commands/` - Helper commands

See the main [README.md](../../README.md) for full setup instructions.

---

## Stage Completion

### `/stage-complete` — Emit Stage Completion Signal

Template for agents to signal stage completion.

```bash
#!/bin/bash
# Usage: ./commands/stage-complete.sh <agent> <stage> <status> [artifact-path]

AGENT="$1"
STAGE="$2"
STATUS="${3:-completed}"
ARTIFACT="$4"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Validate inputs
VALID_AGENTS="product_manager system_architect frontend_engineer backend_engineer ai_engineer qa_engineer devops_engineer safety_agent governance_agent code_health_agent"
VALID_STAGES="requirements architecture frontend_implementation backend_implementation ai_implementation qa_testing deployment safety_review governance_review code_health_assessment"
VALID_STATUSES="completed completed_with_warnings failed blocked requires_human_intervention"

if ! echo "$VALID_AGENTS" | grep -qw "$AGENT"; then
    echo "ERROR: Invalid agent: $AGENT"
    exit 1
fi

if ! echo "$VALID_STAGES" | grep -qw "$STAGE"; then
    echo "ERROR: Invalid stage: $STAGE"
    exit 1
fi

if ! echo "$VALID_STATUSES" | grep -qw "$STATUS"; then
    echo "ERROR: Invalid status: $STATUS"
    exit 1
fi

# Build artifacts array
if [ -n "$ARTIFACT" ]; then
    ARTIFACTS_JSON="[\"$ARTIFACT\"]"
else
    ARTIFACTS_JSON="[]"
fi

# Generate completion signal
cat > ARTIFACTS/system/stage-completion-signal.json << EOF
{
  "agent": "$AGENT",
  "stage": "$STAGE",
  "status": "$STATUS",
  "timestamp": "$TIMESTAMP",
  "output_artifacts": $ARTIFACTS_JSON
}
EOF

echo "Stage completion signal created:"
cat ARTIFACTS/system/stage-completion-signal.json

# Validate the signal
echo ""
echo "Validating..."
python scripts/validate.py ARTIFACTS/system/stage-completion-signal.json
```

### Quick Completion Templates by Agent

**Product Manager:**
```bash
./commands/stage-complete.sh product_manager requirements completed \
  "ARTIFACTS/product-manager/product-requirements-packet.json"
```

**System Architect (full_system):**
```bash
./commands/stage-complete.sh system_architect architecture completed \
  "ARTIFACTS/system-architect/architecture-handover-packet.json"
```

**System Architect (fast_feature):**
```bash
./commands/stage-complete.sh system_architect architecture completed \
  "ARTIFACTS/system-architect/architecture-assessment.json"
```

**Frontend Engineer:**
```bash
./commands/stage-complete.sh frontend_engineer frontend_implementation completed \
  "ARTIFACTS/frontend-engineer/frontend-implementation-report.json"
```

**Backend Engineer:**
```bash
./commands/stage-complete.sh backend_engineer backend_implementation completed \
  "ARTIFACTS/backend-engineer/backend-implementation-report.json"
```

**AI Engineer:**
```bash
./commands/stage-complete.sh ai_engineer ai_implementation completed \
  "ARTIFACTS/ai-engineer/ai-implementation-report.json"
```

**QA Engineer:**
```bash
./commands/stage-complete.sh qa_engineer qa_testing completed \
  "ARTIFACTS/qa-engineer/qa-test-report.json"
```

**DevOps Engineer:**
```bash
./commands/stage-complete.sh devops_engineer deployment completed \
  "ARTIFACTS/devops-engineer/deployment-report.json"
```

---

## Validation

### `/validate-all` — Validate All Artifacts

```bash
#!/bin/bash
# Usage: ./commands/validate-all.sh

echo "Validating all artifacts..."
python scripts/validate.py --all

if [ $? -eq 0 ]; then
    echo ""
    echo "All artifacts passed validation."
else
    echo ""
    echo "Some artifacts failed validation. See errors above."
    exit 1
fi
```

### `/validate` — Validate Single Artifact

```bash
#!/bin/bash
# Usage: ./commands/validate.sh <artifact-path>

ARTIFACT="$1"

if [ -z "$ARTIFACT" ]; then
    echo "Usage: ./commands/validate.sh <artifact-path>"
    exit 1
fi

python scripts/validate.py "$ARTIFACT"
```

### `/check-tools` — Check Validation Dependencies

```bash
#!/bin/bash
# Usage: ./commands/check-tools.sh

echo "Checking validation tools..."
echo ""

# Check Python
if command -v python3 &> /dev/null; then
    echo "✓ python3: $(python3 --version)"
elif command -v python &> /dev/null; then
    echo "✓ python: $(python --version)"
else
    echo "✗ python: not found"
fi

# Check jq
if command -v jq &> /dev/null; then
    echo "✓ jq: $(jq --version)"
else
    echo "✗ jq: not found"
fi

# Check jsonschema
if python3 -c "import jsonschema" 2>/dev/null; then
    echo "✓ jsonschema: available"
else
    echo "✗ jsonschema: not installed (run: pip install jsonschema)"
fi

echo ""
./scripts/validate.sh --check-tools
```

---

## Workflow Status

### `/status` — Show Current Workflow Status

```bash
#!/bin/bash
# Usage: ./commands/status.sh

WORKFLOW_STATE="ARTIFACTS/system/workflow-state.json"

if [ ! -f "$WORKFLOW_STATE" ]; then
    echo "No workflow state found. Run ~/.claude-agents/setup.sh first."
    exit 1
fi

echo "=== Workflow Status ==="
echo ""

# Extract key info using jq or python
if command -v jq &> /dev/null; then
    echo "Workflow ID: $(jq -r '.workflow_id' "$WORKFLOW_STATE")"
    echo "Product: $(jq -r '.product_name' "$WORKFLOW_STATE")"
    echo "Mode: $(jq -r '.execution_mode' "$WORKFLOW_STATE")"
    echo "Current Stage: $(jq -r '.current_stage' "$WORKFLOW_STATE")"
    echo ""
    echo "=== Stage Status ==="
    jq -r '.stages | to_entries[] | "\(.key): \(.value.status)"' "$WORKFLOW_STATE"
    echo ""
    echo "=== Blocking Issues ==="
    jq -r '.blocking_issues[] | "- \(.description) [\(.severity)]"' "$WORKFLOW_STATE" 2>/dev/null || echo "(none)"
else
    python3 -c "
import json
with open('$WORKFLOW_STATE') as f:
    state = json.load(f)
print(f\"Workflow ID: {state['workflow_id']}\")
print(f\"Product: {state['product_name']}\")
print(f\"Mode: {state['execution_mode']}\")
print(f\"Current Stage: {state['current_stage']}\")
print()
print('=== Stage Status ===')
for stage, data in state['stages'].items():
    print(f\"{stage}: {data['status']}\")
print()
print('=== Blocking Issues ===')
if state['blocking_issues']:
    for issue in state['blocking_issues']:
        print(f\"- {issue['description']} [{issue['severity']}]\")
else:
    print('(none)')
"
fi
```

### `/next` — Show Next Required Action

```bash
#!/bin/bash
# Usage: ./commands/next.sh

WORKFLOW_STATE="ARTIFACTS/system/workflow-state.json"

if [ ! -f "$WORKFLOW_STATE" ]; then
    echo "No workflow state found. Run ~/.claude-agents/setup.sh first."
    exit 1
fi

python3 << 'EOF'
import json

with open("ARTIFACTS/system/workflow-state.json") as f:
    state = json.load(f)

current = state["current_stage"]

if current == "completed":
    print("Workflow completed successfully!")
elif current == "failed":
    print("Workflow failed. Review blocking issues.")
elif current == "paused":
    print("Workflow paused. Awaiting human input.")
    # Find which stage needs approval
    for stage, data in state["stages"].items():
        if data.get("human_approval_required") and not data.get("human_approval_received"):
            print(f"  → Approve: {stage}")
else:
    stage_data = state["stages"].get(current, {})
    agent = stage_data.get("agent", "unknown")
    status = stage_data.get("status", "unknown")

    if status == "pending":
        print(f"Next: Invoke {agent} for {current} stage")
    elif status == "in_progress":
        print(f"In progress: {agent} is working on {current}")
    elif status == "blocked":
        print(f"Blocked: {current} stage has blocking issues")
    else:
        print(f"Current: {current} ({status})")
EOF
```

---

## Human Approvals

### `/approve` — Record Human Approval

```bash
#!/bin/bash
# Usage: ./commands/approve.sh <stage>

STAGE="$1"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
WORKFLOW_STATE="ARTIFACTS/system/workflow-state.json"

if [ -z "$STAGE" ]; then
    echo "Usage: ./commands/approve.sh <stage>"
    echo "Stages requiring approval: requirements, architecture, deployment"
    exit 1
fi

if [ ! -f "$WORKFLOW_STATE" ]; then
    echo "No workflow state found."
    exit 1
fi

python3 << EOF
import json

with open("$WORKFLOW_STATE") as f:
    state = json.load(f)

stage = "$STAGE"
if stage not in state["stages"]:
    print(f"ERROR: Unknown stage: {stage}")
    exit(1)

state["stages"][stage]["human_approval_received"] = True
state["human_interactions"].append({
    "timestamp": "$TIMESTAMP",
    "stage": stage,
    "interaction_type": "approval",
    "details": "Human approved stage output"
})
state["updated_at"] = "$TIMESTAMP"

# If workflow was paused, resume to current stage
if state["current_stage"] == "paused":
    state["current_stage"] = stage

with open("$WORKFLOW_STATE", "w") as f:
    json.dump(state, f, indent=2)

print(f"Approved: {stage}")
print(f"Workflow can now proceed.")
EOF
```

---

## Utility Commands

### `/reset` — Reset Workflow State

```bash
#!/bin/bash
# Usage: ./commands/reset.sh [--confirm]

if [ "$1" != "--confirm" ]; then
    echo "This will reset the workflow state and delete all artifacts."
    echo "Run with --confirm to proceed."
    exit 1
fi

rm -rf ARTIFACTS/*
mkdir -p ARTIFACTS/{product-manager,system-architect,frontend-engineer,backend-engineer,ai-engineer,qa-engineer,devops-engineer,system}

echo "Workflow reset. Run ~/.claude-agents/setup.sh to start fresh."
```

### `/export-handoff` — Export Workflow Handoff Document

Generates a comprehensive handoff document for pausing/resuming workflows.

```bash
#!/bin/bash
# Usage: ./commands/export-handoff.sh

python scripts/generate-handoff.py --output ARTIFACTS/system/workflow-handoff.md

echo "Exported to: ARTIFACTS/system/workflow-handoff.md"
```

**Alternative (manual generation):**

```bash
#!/bin/bash
# Usage: ./commands/export-handoff.sh --simple

./commands/status.sh > ARTIFACTS/system/workflow-handoff.md

cat >> ARTIFACTS/system/workflow-handoff.md << 'EOF'

---

## Artifact Locations

- Requirements: `ARTIFACTS/product-manager/`
- Architecture: `ARTIFACTS/system-architect/`
- Frontend: `ARTIFACTS/frontend-engineer/`
- Backend: `ARTIFACTS/backend-engineer/`
- AI: `ARTIFACTS/ai-engineer/`
- QA: `ARTIFACTS/qa-engineer/`
- Deployment: `ARTIFACTS/devops-engineer/`
- System: `ARTIFACTS/system/`

## Resume Instructions

1. Review current stage status above
2. Load `ARTIFACTS/system/workflow-state.json`
3. Continue from current stage with appropriate agent

EOF

echo "Exported to: ARTIFACTS/system/workflow-handoff.md"
```

---

## Claude Code Slash Commands

Place these in `.claude/commands/` for slash command access:

### `.claude/commands/validate.md`

```markdown
Validate artifacts against their schemas.

Run: `python scripts/validate.py --all`

Report any validation errors and suggest fixes.
```

### `.claude/commands/status.md`

```markdown
Show current workflow status.

Read ARTIFACTS/system/workflow-state.json and display:
- Workflow ID and product name
- Current stage
- Status of each stage
- Any blocking issues
- Next required action
```

---

## References

- [orchestration.md](./orchestration.md) — Orchestration logic
- [hooks.md](./hooks.md) — Hook specifications
- [standard-workflow.md](./standard-workflow.md) — Workflow definitions
- [validate.py](../../scripts/validate.py) — Validation script

---

**END OF COMMANDS DOCUMENTATION**
