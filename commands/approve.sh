#!/bin/bash
# Record human approval for a stage
# Usage: ./commands/approve.sh <stage>

STAGE="$1"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WORKFLOW_STATE="$PROJECT_ROOT/ARTIFACTS/system/workflow-state.json"

show_approvable_stages() {
    if [ -f "$WORKFLOW_STATE" ]; then
        python3 << 'PYEOF'
import json
with open("WORKFLOW_STATE_PATH") as f:
    state = json.load(f)
found = False
for stage, data in state.get("stages", {}).items():
    if data.get("human_approval_required"):
        found = True
        if data.get("human_approval_received"):
            print(f"  ✓ {stage} (already approved)")
        else:
            print(f"  ○ {stage} (pending)")
if not found:
    print("  (no stages currently require approval)")
PYEOF
    else
        echo "  requirements, architecture, deployment (default gates)"
    fi
}

if [ -z "$STAGE" ]; then
    echo "Usage: ./commands/approve.sh <stage>"
    echo ""
    echo "Stages that can require approval:"
    show_approvable_stages | sed "s|WORKFLOW_STATE_PATH|$WORKFLOW_STATE|"
    exit 1
fi

if [ ! -f "$WORKFLOW_STATE" ]; then
    echo "No workflow state found. Run ~/.claude-agents/setup.sh first."
    exit 1
fi

python3 << EOF
import json
import sys

with open("$WORKFLOW_STATE") as f:
    state = json.load(f)

stage = "$STAGE"
timestamp = "$TIMESTAMP"

if stage not in state.get("stages", {}):
    print(f"ERROR: Unknown stage: {stage}")
    valid = [s for s in state.get("stages", {}).keys()]
    print(f"Valid stages: {', '.join(valid)}")
    sys.exit(1)

stage_data = state["stages"][stage]

if not stage_data.get("human_approval_required"):
    print(f"Stage '{stage}' does not require human approval.")
    sys.exit(1)

if stage_data.get("human_approval_received"):
    print(f"Stage '{stage}' already approved.")
    sys.exit(0)

# Record approval
state["stages"][stage]["human_approval_received"] = True
state["human_interactions"].append({
    "timestamp": timestamp,
    "stage": stage,
    "interaction_type": "approval",
    "details": "Human approved stage output"
})
state["updated_at"] = timestamp

# If workflow was paused, it may need to resume
if state.get("current_stage") == "paused":
    state["current_stage"] = stage

with open("$WORKFLOW_STATE", "w") as f:
    json.dump(state, f, indent=2)

print(f"✓ Approved: {stage}")
print(f"Workflow can now proceed to next stage.")
EOF

# Auto-checkpoint after approval
if [ $? -eq 0 ]; then
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo ""
        echo "Creating checkpoint after approval..."
        "$SCRIPT_DIR/checkpoint.sh" "Approved: $STAGE" 2>/dev/null || true
    fi
fi
