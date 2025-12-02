#!/bin/bash
# Show current workflow status
# Usage: ./commands/status.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WORKFLOW_STATE="$PROJECT_ROOT/ARTIFACTS/system/workflow-state.json"

if [ ! -f "$WORKFLOW_STATE" ]; then
    echo "No workflow state found. Run ~/.claude-agents/setup.sh first."
    exit 1
fi

echo "=== Workflow Status ==="
echo ""

# Use python for reliable JSON parsing
python3 << EOF
import json

with open("$WORKFLOW_STATE") as f:
    state = json.load(f)

print(f"Workflow ID: {state.get('workflow_id', 'N/A')}")
print(f"Product: {state.get('product_name', 'N/A')}")
print(f"Mode: {state.get('execution_mode', 'N/A')}")
print(f"Current Stage: {state.get('current_stage', 'N/A')}")
print()
print("=== Stage Status ===")

stages = state.get('stages', {})
stage_order = [
    'requirements', 'architecture',
    'frontend_implementation', 'backend_implementation', 'ai_implementation',
    'qa_testing', 'deployment',
    'safety_review', 'governance_review', 'code_health_assessment'
]

for stage in stage_order:
    if stage in stages:
        status = stages[stage].get('status', 'unknown')
        approval = ""
        if stages[stage].get('human_approval_required'):
            if stages[stage].get('human_approval_received'):
                approval = " [approved]"
            else:
                approval = " [awaiting approval]"
        print(f"  {stage}: {status}{approval}")

print()
print("=== Blocking Issues ===")
issues = state.get('blocking_issues', [])
if issues:
    for issue in issues:
        if isinstance(issue, dict):
            print(f"  - {issue.get('description', 'Unknown')} [{issue.get('severity', 'unknown')}]")
        else:
            print(f"  - {issue}")
else:
    print("  (none)")

print()
print("=== Safety & Governance ===")
sg = state.get('safety_and_governance', {})
print(f"  Safety: {sg.get('safety_review_status', 'pending')}")
print(f"  Governance: {sg.get('governance_review_status', 'pending')}")
print(f"  Risk Level: {sg.get('risk_level', 'not assessed')}")
EOF

# Show recent checkpoints if git is available
if git rev-parse --git-dir > /dev/null 2>&1; then
    CHECKPOINTS=$(git tag -l 'checkpoint/*' --sort=-creatordate 2>/dev/null | head -3)
    if [ -n "$CHECKPOINTS" ]; then
        echo ""
        echo "=== Recent Checkpoints ==="
        echo "$CHECKPOINTS" | while read -r tag; do
            name=${tag#checkpoint/}
            date=$(git log -1 --format=%ci "$tag" 2>/dev/null | cut -d' ' -f1)
            echo "  $name ($date)"
        done
        echo ""
        echo "  Run ./commands/checkpoint.sh --list for all checkpoints"
    fi
fi
