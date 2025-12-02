#!/usr/bin/env python3
"""
Generate a workflow handoff document from current workflow state.

Usage:
    python scripts/generate-handoff.py [--output PATH]

Reads workflow-state.json and generates a markdown handoff document.
"""

import json
import sys
from datetime import datetime
from pathlib import Path

# Paths
WORKFLOW_STATE_PATH = Path("ARTIFACTS/system/workflow-state.json")
OUTPUT_PATH = Path("ARTIFACTS/system/workflow-handoff.md")

# Stage to artifact mapping
STAGE_ARTIFACTS = {
    "requirements": "ARTIFACTS/product-manager/product-requirements-packet.json",
    "architecture": "ARTIFACTS/system-architect/architecture-handover-packet.json",
    "frontend_implementation": "ARTIFACTS/frontend-engineer/frontend-implementation-report.json",
    "backend_implementation": "ARTIFACTS/backend-engineer/backend-implementation-report.json",
    "ai_implementation": "ARTIFACTS/ai-engineer/ai-implementation-report.json",
    "qa_testing": "ARTIFACTS/qa-engineer/qa-test-report.json",
    "deployment": "ARTIFACTS/devops-engineer/deployment-report.json",
    "safety_review": "ARTIFACTS/system/safety-review-report.json",
    "governance_review": "ARTIFACTS/system/governance-review-report.json",
    "code_health_assessment": "ARTIFACTS/system/code-health-report.json",
}

STAGE_AGENTS = {
    "requirements": "product_manager",
    "architecture": "system_architect",
    "frontend_implementation": "frontend_engineer",
    "backend_implementation": "backend_engineer",
    "ai_implementation": "ai_engineer",
    "qa_testing": "qa_engineer",
    "deployment": "devops_engineer",
    "safety_review": "safety_agent",
    "governance_review": "governance_agent",
    "code_health_assessment": "code_health_agent",
}


def load_workflow_state():
    """Load workflow state from JSON file."""
    if not WORKFLOW_STATE_PATH.exists():
        print(f"ERROR: Workflow state not found at {WORKFLOW_STATE_PATH}")
        sys.exit(1)

    with open(WORKFLOW_STATE_PATH) as f:
        return json.load(f)


def get_stage_status(state: dict, stage: str) -> str:
    """Get status for a specific stage."""
    stages = state.get("stages", {})
    if stage in stages:
        return stages[stage].get("status", "pending")
    return "not_applicable"


def get_pending_gates(state: dict) -> list:
    """Get list of pending human approval gates."""
    gates = []
    stages = state.get("stages", {})

    for stage_name, stage_data in stages.items():
        if stage_data.get("human_approval_required") and not stage_data.get("human_approval_received"):
            status = stage_data.get("status", "pending")
            if status in ["completed", "in_progress"]:
                gates.append({
                    "gate_name": f"{stage_name}_approval",
                    "stage": stage_name,
                    "action": f"Review and approve {stage_name} output"
                })

    return gates


def get_completed_artifacts(state: dict) -> list:
    """Get list of completed artifacts."""
    artifacts = []
    stages = state.get("stages", {})

    for stage_name, stage_data in stages.items():
        if stage_data.get("status") == "completed":
            artifact_path = STAGE_ARTIFACTS.get(stage_name, "")
            if artifact_path and Path(artifact_path).exists():
                artifacts.append({
                    "path": artifact_path,
                    "description": f"Output from {stage_name} stage"
                })

    return artifacts


def get_pending_artifacts(state: dict) -> list:
    """Get list of pending artifacts."""
    artifacts = []
    stages = state.get("stages", {})

    for stage_name, stage_data in stages.items():
        if stage_data.get("status") in ["pending", "in_progress"]:
            artifact_path = STAGE_ARTIFACTS.get(stage_name, "")
            agent = STAGE_AGENTS.get(stage_name, "unknown")
            if artifact_path:
                artifacts.append({
                    "path": artifact_path,
                    "agent": agent
                })

    return artifacts


def generate_handoff(state: dict) -> str:
    """Generate markdown handoff document from workflow state."""
    timestamp = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

    # Get stage statuses
    stages = state.get("stages", {})

    # Build document
    doc = f"""# Workflow Handoff Document

**Generated**: {timestamp}
**Workflow ID**: {state.get('workflow_id', 'N/A')}
**Product Name**: {state.get('product_name', 'N/A')}

---

## Current Status

| Field | Value |
|-------|-------|
| Execution Mode | {state.get('execution_mode', 'N/A')} |
| Current Stage | {state.get('current_stage', 'N/A')} |
| Overall Status | {'active' if state.get('current_stage') not in ['completed', 'failed'] else state.get('current_stage')} |

---

## Stage Progress

| Stage | Status | Agent | Output Artifact |
|-------|--------|-------|-----------------|
"""

    # Add stage rows
    for stage, artifact in STAGE_ARTIFACTS.items():
        status = get_stage_status(state, stage)
        agent = STAGE_AGENTS.get(stage, "unknown")
        artifact_name = Path(artifact).name
        doc += f"| {stage} | {status} | {agent} | `{artifact_name}` |\n"

    doc += """
---

## Outstanding Gates

### Human Approval Gates

| Gate | Stage | Status | Required Action |
|------|-------|--------|-----------------|
"""

    pending_gates = get_pending_gates(state)
    if pending_gates:
        for gate in pending_gates:
            doc += f"| {gate['gate_name']} | {gate['stage']} | Awaiting | {gate['action']} |\n"
    else:
        doc += "| (none) | - | - | - |\n"

    # Safety and governance
    safety_status = state.get("safety_and_governance", {}).get("safety_review_status", "pending")
    gov_status = state.get("safety_and_governance", {}).get("governance_review_status", "pending")

    doc += f"""
### Safety/Governance Gates

| Gate | Status | Risk Level |
|------|--------|------------|
| Safety Review | {safety_status} | {state.get('safety_and_governance', {}).get('risk_level', 'not assessed')} |
| Governance Review | {gov_status} | - |

---

## Blocking Issues

"""

    blocking_issues = state.get("blocking_issues", [])
    if blocking_issues:
        for i, issue in enumerate(blocking_issues, 1):
            doc += f"""### Issue {i}: {issue.get('description', 'Unknown')}

- **Severity**: {issue.get('severity', 'unknown')}
- **Source**: {issue.get('source_stage', 'unknown')}
- **Resolution Required**: {issue.get('resolution', 'Not specified')}

"""
    else:
        doc += "*No blocking issues*\n"

    doc += """
---

## Artifact Locations

| Category | Path |
|----------|------|
| Requirements | `ARTIFACTS/product-manager/` |
| Architecture | `ARTIFACTS/system-architect/` |
| Frontend | `ARTIFACTS/frontend-engineer/` |
| Backend | `ARTIFACTS/backend-engineer/` |
| AI | `ARTIFACTS/ai-engineer/` |
| QA | `ARTIFACTS/qa-engineer/` |
| Deployment | `ARTIFACTS/devops-engineer/` |
| System State | `ARTIFACTS/system/` |

---

## Key Artifacts to Review

### Completed Artifacts

"""

    completed = get_completed_artifacts(state)
    if completed:
        for artifact in completed:
            doc += f"- `{artifact['path']}` - {artifact['description']}\n"
    else:
        doc += "*No completed artifacts yet*\n"

    doc += """
### Pending Artifacts

"""

    pending = get_pending_artifacts(state)
    if pending:
        for artifact in pending:
            doc += f"- `{artifact['path']}` - Awaiting {artifact['agent']}\n"
    else:
        doc += "*No pending artifacts*\n"

    doc += """
---

## Human Interaction Log

| Timestamp | Stage | Interaction Type | Details |
|-----------|-------|------------------|---------|
"""

    interactions = state.get("human_interactions", [])
    if interactions:
        for interaction in interactions:
            doc += f"| {interaction.get('timestamp', 'N/A')} | {interaction.get('stage', 'N/A')} | {interaction.get('interaction_type', 'N/A')} | {interaction.get('details', 'N/A')} |\n"
    else:
        doc += "| (none) | - | - | - |\n"

    # Determine next stage for resume instructions
    current = state.get("current_stage", "requirements")
    next_approval = "requirements" if current == "requirements" else current

    doc += f"""
---

## Resume Instructions

1. **Load workflow state**: Read `ARTIFACTS/system/workflow-state.json`
2. **Review current stage**: Check the {current} stage status
3. **Check blocking issues**: Address any issues listed above
4. **Approve pending gates**: If awaiting approval, review and approve/reject
5. **Invoke next agent**: Based on current stage, invoke the appropriate agent

### Quick Resume Command

```bash
# Check current status
./commands/status.sh

# See what's next
./commands/next.sh

# Approve a stage (if waiting)
./commands/approve.sh {next_approval}
```

---

**Last Updated**: {state.get('updated_at', timestamp)}
"""

    return doc


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(description="Generate workflow handoff document")
    parser.add_argument("--output", "-o", type=Path, default=OUTPUT_PATH,
                        help="Output path for handoff document")
    args = parser.parse_args()

    # Load state
    state = load_workflow_state()

    # Generate document
    doc = generate_handoff(state)

    # Write output
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with open(args.output, "w") as f:
        f.write(doc)

    print(f"Handoff document generated: {args.output}")


if __name__ == "__main__":
    main()
