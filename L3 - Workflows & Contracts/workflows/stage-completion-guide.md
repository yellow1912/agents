# Stage Completion Signal Guide

**Version**: 1.0
**Last Updated**: 2025-12-02

---

## Purpose

This guide provides **practical instructions** for agents to write valid `stage-completion-signal.json` files. Every agent must signal completion using this format.

---

## Quick Reference

### Required Fields

```json
{
  "agent": "agent_name",
  "stage": "stage_name",
  "status": "completed",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `agent` | string | Yes | Agent sending the signal |
| `stage` | string | Yes | Stage that was completed |
| `status` | string | Yes | Completion status |
| `timestamp` | string | Yes | ISO 8601 datetime |
| `output_artifacts` | array | No | Paths to generated files |
| `blocking_issues` | array | No | Issues blocking progress |
| `next_agent_required` | string | No | Next agent to invoke |
| `parallel_agents` | array | No | Agents to invoke in parallel |

---

## Agent and Stage Values

### Valid Agent Names

```
product_manager
system_architect
frontend_engineer
backend_engineer
ai_engineer
qa_engineer
devops_engineer
safety_agent
governance_agent
code_health_agent
```

### Valid Stage Names

```
requirements
architecture
frontend_implementation
backend_implementation
ai_implementation
qa_testing
deployment
safety_review
governance_review
code_health_assessment
```

### Valid Status Values

| Status | When to Use |
|--------|-------------|
| `completed` | Stage finished successfully |
| `completed_with_warnings` | Finished but with non-blocking concerns |
| `failed` | Stage failed, cannot proceed |
| `blocked` | Waiting on external dependency or issue |
| `requires_human_intervention` | Human input needed |

---

## Examples by Agent

### Product Manager

**Successful completion:**

```json
{
  "agent": "product_manager",
  "stage": "requirements",
  "status": "completed",
  "timestamp": "2025-01-15T10:30:00Z",
  "output_artifacts": [
    "ARTIFACTS/product-manager/product-requirements-packet.json"
  ],
  "blocking_issues": [],
  "next_agent_required": "system_architect",
  "human_approval_required": true,
  "notes": "Requirements documented. Awaiting human approval before architecture."
}
```

**Blocked for clarification:**

```json
{
  "agent": "product_manager",
  "stage": "requirements",
  "status": "requires_human_intervention",
  "timestamp": "2025-01-15T10:30:00Z",
  "output_artifacts": [
    "ARTIFACTS/product-manager/pm-clarification-questions.json"
  ],
  "blocking_issues": [
    {
      "description": "Unclear target user demographic",
      "severity": "medium",
      "resolution_required": true
    }
  ],
  "human_approval_required": true,
  "notes": "Need clarification on 3 questions before finalizing requirements."
}
```

---

### System Architect

**Full system mode (options ready):**

```json
{
  "agent": "system_architect",
  "stage": "architecture",
  "status": "completed",
  "timestamp": "2025-01-15T14:00:00Z",
  "output_artifacts": [
    "ARTIFACTS/system-architect/architecture-handover-packet.json"
  ],
  "blocking_issues": [],
  "parallel_agents": [
    "frontend_engineer",
    "backend_engineer"
  ],
  "human_approval_required": true,
  "notes": "3 architecture options presented. Awaiting human selection."
}
```

**Fast feature mode (assessment):**

```json
{
  "agent": "system_architect",
  "stage": "architecture",
  "status": "completed",
  "timestamp": "2025-01-15T11:00:00Z",
  "output_artifacts": [
    "ARTIFACTS/system-architect/architecture-assessment.json"
  ],
  "blocking_issues": [],
  "parallel_agents": [
    "frontend_engineer",
    "backend_engineer"
  ],
  "human_approval_required": false,
  "validation_results": {
    "schema_valid": true,
    "validation_errors": []
  },
  "notes": "Feature fits existing architecture with minor changes. Auto-proceeding."
}
```

**Major impact requires full redesign:**

```json
{
  "agent": "system_architect",
  "stage": "architecture",
  "status": "blocked",
  "timestamp": "2025-01-15T11:30:00Z",
  "output_artifacts": [
    "ARTIFACTS/system-architect/architecture-assessment.json"
  ],
  "blocking_issues": [
    {
      "description": "Feature requires major architecture changes - switching to full_system mode",
      "severity": "high",
      "resolution_required": true
    }
  ],
  "human_approval_required": true,
  "notes": "Architecture impact assessed as 'major'. Requires full architecture design."
}
```

---

### Frontend Engineer

**Successful implementation:**

```json
{
  "agent": "frontend_engineer",
  "stage": "frontend_implementation",
  "status": "completed",
  "timestamp": "2025-01-16T09:00:00Z",
  "output_artifacts": [
    "ARTIFACTS/frontend-engineer/frontend-implementation-report.json"
  ],
  "blocking_issues": [],
  "warnings": [
    "Bundle size increased by 15KB due to new charting library"
  ],
  "next_agent_required": "orchestrator",
  "validation_results": {
    "schema_valid": true,
    "quality_checks_passed": true,
    "quality_check_details": {
      "lint_errors": 0,
      "type_errors": 0,
      "test_coverage": 85
    }
  },
  "performance_metrics": {
    "duration_seconds": 3600,
    "tokens_used": 45000
  },
  "notes": "All 12 components implemented. Tests passing. Ready for QA sync."
}
```

---

### Backend Engineer

**Successful implementation:**

```json
{
  "agent": "backend_engineer",
  "stage": "backend_implementation",
  "status": "completed",
  "timestamp": "2025-01-16T10:00:00Z",
  "output_artifacts": [
    "ARTIFACTS/backend-engineer/backend-implementation-report.json"
  ],
  "blocking_issues": [],
  "next_agent_required": "orchestrator",
  "validation_results": {
    "schema_valid": true,
    "quality_checks_passed": true,
    "quality_check_details": {
      "lint_errors": 0,
      "type_errors": 0,
      "test_coverage": 82,
      "api_tests_passing": true
    }
  },
  "performance_metrics": {
    "duration_seconds": 4200,
    "tokens_used": 52000
  },
  "notes": "8 API endpoints implemented. Database migrations complete."
}
```

**Blocked by dependency:**

```json
{
  "agent": "backend_engineer",
  "stage": "backend_implementation",
  "status": "blocked",
  "timestamp": "2025-01-16T08:00:00Z",
  "output_artifacts": [],
  "blocking_issues": [
    {
      "description": "Payment gateway API credentials not provided",
      "severity": "high",
      "resolution_required": true
    }
  ],
  "next_agent_required": "none",
  "notes": "Cannot implement payment integration without Stripe API keys."
}
```

---

### AI Engineer

**Successful implementation:**

```json
{
  "agent": "ai_engineer",
  "stage": "ai_implementation",
  "status": "completed",
  "timestamp": "2025-01-16T11:00:00Z",
  "output_artifacts": [
    "ARTIFACTS/ai-engineer/ai-implementation-report.json"
  ],
  "blocking_issues": [],
  "next_agent_required": "orchestrator",
  "validation_results": {
    "schema_valid": true,
    "quality_checks_passed": true
  },
  "notes": "RAG pipeline implemented. Prompt templates tested. Safety guardrails in place."
}
```

---

### QA Engineer

**Approve for deployment:**

```json
{
  "agent": "qa_engineer",
  "stage": "qa_testing",
  "status": "completed",
  "timestamp": "2025-01-17T15:00:00Z",
  "output_artifacts": [
    "ARTIFACTS/qa-engineer/qa-test-report.json"
  ],
  "blocking_issues": [],
  "next_agent_required": "devops_engineer",
  "human_approval_required": false,
  "validation_results": {
    "schema_valid": true,
    "quality_checks_passed": true,
    "quality_check_details": {
      "tests_passed": 156,
      "tests_failed": 0,
      "coverage": 84
    }
  },
  "notes": "All tests passing. Recommendation: approve_for_deployment"
}
```

**Needs fixes (P1 bugs):**

```json
{
  "agent": "qa_engineer",
  "stage": "qa_testing",
  "status": "blocked",
  "timestamp": "2025-01-17T14:00:00Z",
  "output_artifacts": [
    "ARTIFACTS/qa-engineer/qa-test-report.json"
  ],
  "blocking_issues": [
    {
      "description": "P1 Bug: Authentication bypass on /api/admin endpoint",
      "severity": "critical",
      "resolution_required": true
    },
    {
      "description": "P1 Bug: Data loss on concurrent form submission",
      "severity": "critical",
      "resolution_required": true
    }
  ],
  "next_agent_required": "backend_engineer",
  "human_approval_required": false,
  "notes": "2 P1 bugs found. Must fix before deployment. Returning to implementation."
}
```

**Needs fixes (P2/P3 only - human decides):**

```json
{
  "agent": "qa_engineer",
  "stage": "qa_testing",
  "status": "completed_with_warnings",
  "timestamp": "2025-01-17T14:30:00Z",
  "output_artifacts": [
    "ARTIFACTS/qa-engineer/qa-test-report.json"
  ],
  "blocking_issues": [],
  "warnings": [
    "P2 Bug: Minor UI alignment issue on mobile",
    "P3 Bug: Typo in error message"
  ],
  "next_agent_required": "orchestrator",
  "human_approval_required": true,
  "notes": "No P1 bugs. 2 minor issues found. Human to decide: fix or deploy."
}
```

---

### DevOps Engineer

**Successful deployment:**

```json
{
  "agent": "devops_engineer",
  "stage": "deployment",
  "status": "completed",
  "timestamp": "2025-01-18T09:00:00Z",
  "output_artifacts": [
    "ARTIFACTS/devops-engineer/deployment-report.json"
  ],
  "blocking_issues": [],
  "next_agent_required": "none",
  "validation_results": {
    "schema_valid": true,
    "quality_checks_passed": true,
    "quality_check_details": {
      "health_checks": "passing",
      "rollback_tested": true
    }
  },
  "notes": "Deployed to production. All health checks passing. Workflow complete."
}
```

**Deployment failed - rollback:**

```json
{
  "agent": "devops_engineer",
  "stage": "deployment",
  "status": "failed",
  "timestamp": "2025-01-18T09:15:00Z",
  "output_artifacts": [
    "ARTIFACTS/devops-engineer/deployment-report.json"
  ],
  "blocking_issues": [
    {
      "description": "Health checks failed after deployment. Automatic rollback executed.",
      "severity": "critical",
      "resolution_required": true
    }
  ],
  "next_agent_required": "none",
  "notes": "Deployment failed. Rolled back to previous version. Investigation required."
}
```

---

### Safety Agent

**Passed:**

```json
{
  "agent": "safety_agent",
  "stage": "safety_review",
  "status": "completed",
  "timestamp": "2025-01-15T11:00:00Z",
  "output_artifacts": [
    "ARTIFACTS/system/safety-review-report.json"
  ],
  "blocking_issues": [],
  "next_agent_required": "orchestrator",
  "notes": "Safety review passed. Risk level: low."
}
```

**Blocked:**

```json
{
  "agent": "safety_agent",
  "stage": "safety_review",
  "status": "blocked",
  "timestamp": "2025-01-15T11:00:00Z",
  "output_artifacts": [
    "ARTIFACTS/system/safety-review-report.json"
  ],
  "blocking_issues": [
    {
      "description": "Feature allows unrestricted user content without moderation",
      "severity": "critical",
      "resolution_required": true
    }
  ],
  "next_agent_required": "none",
  "human_approval_required": true,
  "notes": "Critical safety concern. Cannot proceed without content moderation plan."
}
```

---

### Governance Agent

**Compliant:**

```json
{
  "agent": "governance_agent",
  "stage": "governance_review",
  "status": "completed",
  "timestamp": "2025-01-15T11:30:00Z",
  "output_artifacts": [
    "ARTIFACTS/system/governance-review-report.json"
  ],
  "blocking_issues": [],
  "next_agent_required": "orchestrator",
  "notes": "Governance review passed. GDPR compliant with conditions."
}
```

---

## Validation

### Recommended: Built-in Scripts

The system includes validation scripts that work without external dependencies:

**Bash script** (uses jq, python, or node - whichever is available):

```bash
# Validate a single artifact
./scripts/validate.sh ARTIFACTS/system/stage-completion-signal.json

# Validate all artifacts
./scripts/validate.sh --all

# Check available tools
./scripts/validate.sh --check-tools
```

**Python script** (full validation if jsonschema installed, basic otherwise):

```bash
# Validate a single artifact
python scripts/validate.py ARTIFACTS/system/stage-completion-signal.json

# Validate all artifacts
python scripts/validate.py --all

# Check dependencies
python scripts/validate.py --check-deps
```

### Alternative: External Tools

If you prefer external tools:

**jsonschema (Python)**:

```bash
pip install jsonschema
jsonschema -i ARTIFACTS/system/stage-completion-signal.json \
  "L3 - Workflows & Contracts/contracts/stage-completion-signal-schema.json"
```

**ajv (Node.js)**:

```bash
npm install -g ajv-cli
ajv validate \
  -s "L3 - Workflows & Contracts/contracts/stage-completion-signal-schema.json" \
  -d ARTIFACTS/system/stage-completion-signal.json
```

### Quick Check with jq

```bash
# Check required fields exist
jq 'has("agent") and has("stage") and has("status") and has("timestamp")' \
  ARTIFACTS/system/stage-completion-signal.json
```

---

## Writing Signals (Agent Implementation)

### Template Function (Pseudocode)

```python
def write_stage_completion_signal(
    agent: str,
    stage: str,
    status: str,
    output_artifacts: list = None,
    blocking_issues: list = None,
    next_agent: str = None,
    parallel_agents: list = None,
    human_approval_required: bool = False,
    warnings: list = None,
    validation_results: dict = None,
    performance_metrics: dict = None,
    notes: str = None
) -> dict:
    """Write a valid stage completion signal."""

    signal = {
        "agent": agent,
        "stage": stage,
        "status": status,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }

    if output_artifacts:
        signal["output_artifacts"] = output_artifacts

    if blocking_issues:
        signal["blocking_issues"] = blocking_issues

    if next_agent:
        signal["next_agent_required"] = next_agent

    if parallel_agents:
        signal["parallel_agents"] = parallel_agents

    if human_approval_required:
        signal["human_approval_required"] = True

    if warnings:
        signal["warnings"] = warnings

    if validation_results:
        signal["validation_results"] = validation_results

    if performance_metrics:
        signal["performance_metrics"] = performance_metrics

    if notes:
        signal["notes"] = notes

    # Write to file
    with open("ARTIFACTS/system/stage-completion-signal.json", "w") as f:
        json.dump(signal, f, indent=2)

    return signal
```

### Usage Examples

```python
# Product Manager completion
write_stage_completion_signal(
    agent="product_manager",
    stage="requirements",
    status="completed",
    output_artifacts=["ARTIFACTS/product-manager/product-requirements-packet.json"],
    next_agent="system_architect",
    human_approval_required=True,
    notes="Requirements documented. Awaiting approval."
)

# Backend Engineer completion
write_stage_completion_signal(
    agent="backend_engineer",
    stage="backend_implementation",
    status="completed",
    output_artifacts=["ARTIFACTS/backend-engineer/backend-implementation-report.json"],
    next_agent="orchestrator",
    validation_results={
        "schema_valid": True,
        "quality_checks_passed": True
    },
    performance_metrics={
        "duration_seconds": 3600,
        "tokens_used": 45000
    }
)

# QA blocked with P1 bugs
write_stage_completion_signal(
    agent="qa_engineer",
    stage="qa_testing",
    status="blocked",
    output_artifacts=["ARTIFACTS/qa-engineer/qa-test-report.json"],
    blocking_issues=[
        {
            "description": "Critical security vulnerability",
            "severity": "critical",
            "resolution_required": True
        }
    ],
    next_agent="backend_engineer",
    notes="P1 bug found. Returning to implementation."
)
```

---

## Common Mistakes

### Missing timestamp

```json
// WRONG
{
  "agent": "product_manager",
  "stage": "requirements",
  "status": "completed"
}

// CORRECT
{
  "agent": "product_manager",
  "stage": "requirements",
  "status": "completed",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### Invalid agent name

```json
// WRONG
{
  "agent": "pm",
  ...
}

// CORRECT
{
  "agent": "product_manager",
  ...
}
```

### Invalid status

```json
// WRONG
{
  "status": "done",
  ...
}

// CORRECT
{
  "status": "completed",
  ...
}
```

### Blocked without blocking_issues

```json
// WRONG
{
  "status": "blocked"
  // No blocking_issues array
}

// CORRECT
{
  "status": "blocked",
  "blocking_issues": [
    {
      "description": "What is blocking",
      "severity": "high",
      "resolution_required": true
    }
  ]
}
```

---

## References

- [stage-completion-signal-schema.json](../contracts/stage-completion-signal-schema.json) — Full schema
- [orchestration.md](./orchestration.md) — How signals are processed
- [controller-orchestrator.md](../../L2%20-%20Orchestration%20&%20Governance/controller-orchestrator.md) — Orchestrator handling

---

**END OF GUIDE**
