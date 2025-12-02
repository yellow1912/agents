#!/bin/bash
# Show next required action
# Usage: ./commands/next.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WORKFLOW_STATE="$PROJECT_ROOT/ARTIFACTS/system/workflow-state.json"

if [ ! -f "$WORKFLOW_STATE" ]; then
    echo "No workflow state found. Run ~/.claude-agents/setup.sh first."
    exit 1
fi

python3 << EOF
import json

with open("$WORKFLOW_STATE") as f:
    state = json.load(f)

current = state.get("current_stage", "requirements")
stages = state.get("stages", {})

print("=== Next Action ===")
print()

if current == "completed":
    print("Workflow completed successfully!")
    print("All stages have finished.")
elif current == "failed":
    print("Workflow failed. Review blocking issues:")
    for issue in state.get("blocking_issues", []):
        if isinstance(issue, dict):
            print(f"  - {issue.get('description', 'Unknown')}")
        else:
            print(f"  - {issue}")
elif current == "paused":
    print("Workflow paused. Awaiting human input.")
    # Find which stage needs approval
    for stage, data in stages.items():
        if data.get("human_approval_required") and not data.get("human_approval_received"):
            if data.get("status") in ["completed", "in_progress"]:
                print(f"  → Run: ./commands/approve.sh {stage}")
else:
    stage_data = stages.get(current, {})
    agent = stage_data.get("agent", "unknown")
    status = stage_data.get("status", "unknown")

    if status == "pending":
        print(f"Next: Invoke {agent} for {current} stage")
        print()
        print(f"The {agent} agent should be given:")

        # Show what context to provide
        if current == "requirements":
            print("  - Your product idea or problem statement")
            print("  - Any constraints (budget, timeline, compliance)")
        elif current == "architecture":
            print("  - ARTIFACTS/product-manager/product-requirements-packet.json")
        elif current in ["frontend_implementation", "backend_implementation", "ai_implementation"]:
            print("  - ARTIFACTS/system-architect/architecture-handover-packet.json")
        elif current == "qa_testing":
            print("  - All *-implementation-report.json files")
            print("  - ARTIFACTS/product-manager/product-requirements-packet.json")
        elif current == "deployment":
            print("  - ARTIFACTS/qa-engineer/qa-test-report.json")

    elif status == "in_progress":
        print(f"In progress: {agent} is working on {current}")
        print()
        print("Wait for the agent to complete and signal completion.")

    elif status == "completed":
        # Check if approval needed
        if stage_data.get("human_approval_required") and not stage_data.get("human_approval_received"):
            print(f"Approval needed for {current} stage")
            print(f"  → Run: ./commands/approve.sh {current}")
        else:
            print(f"Stage {current} completed. Orchestrator should advance workflow.")

    elif status == "blocked":
        print(f"Blocked: {current} stage has blocking issues")
        for issue in stage_data.get("blocking_issues", []):
            print(f"  - {issue}")
    else:
        print(f"Current: {current} ({status})")
EOF
