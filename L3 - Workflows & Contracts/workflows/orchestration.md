# Orchestration Logic

**Version**: 1.0
**Last Updated**: 2025-12-02

---

## Purpose

This document defines the **operational logic** for workflow orchestration. It complements [controller-orchestrator.md](../../L2%20-%20Orchestration%20&%20Governance/controller-orchestrator.md) (the role spec) by providing:

- State machine definition
- Transition rules
- Validation procedures
- Gate enforcement logic
- Failure handling procedures
- Example flows

---

## State Machine Definition

### Stages

| Stage | Agent | Description |
|-------|-------|-------------|
| `requirements` | product_manager | Define what to build |
| `architecture` | system_architect | Define how to build |
| `frontend_implementation` | frontend_engineer | Build UI |
| `backend_implementation` | backend_engineer | Build APIs/data |
| `ai_implementation` | ai_engineer | Build AI features |
| `qa_testing` | qa_engineer | Validate quality |
| `deployment` | devops_engineer | Deploy to production |
| `safety_review` | safety_agent | Review for security/safety risks |
| `governance_review` | governance_agent | Review for compliance/legal |
| `code_health_assessment` | code_health_agent | Assess code quality metrics |

### Stage Statuses

| Status | Meaning |
|--------|---------|
| `pending` | Not yet started |
| `in_progress` | Agent currently working |
| `completed` | Successfully finished |
| `blocked` | Cannot proceed, awaiting resolution |
| `skipped` | Not required for this workflow |
| `rolled_back` | Deployment was rolled back |

### Workflow Statuses

| Status | Meaning |
|--------|---------|
| `requirements` | In requirements stage |
| `architecture` | In architecture stage |
| `frontend_implementation` | In frontend implementation |
| `backend_implementation` | In backend implementation |
| `ai_implementation` | In AI implementation |
| `qa_testing` | In QA testing |
| `deployment` | In deployment |
| `safety_review` | In safety review |
| `governance_review` | In governance review |
| `code_health_assessment` | In code health assessment |
| `completed` | Workflow finished successfully |
| `failed` | Workflow failed, requires intervention |
| `paused` | Awaiting human input |

---

## Allowed Transitions

### Sequential Flow

```
requirements → architecture → implementation → qa_testing → deployment → completed
```

### Transition Matrix

| From Stage | To Stage(s) | Condition |
|------------|-------------|-----------|
| `requirements` | `architecture` | Human approval received |
| `architecture` | `frontend_implementation`, `backend_implementation`, `ai_implementation` | Human selection (full_system) OR auto (fast_feature) |
| `architecture` | `frontend_implementation`, `backend_implementation` | AI not required |
| `frontend_implementation` | `qa_testing` | All parallel stages complete |
| `backend_implementation` | `qa_testing` | All parallel stages complete |
| `ai_implementation` | `qa_testing` | All parallel stages complete |
| `qa_testing` | `deployment` | `recommendation = approve_for_deployment` |
| `qa_testing` | `frontend_implementation` / `backend_implementation` | `recommendation = needs_fixes` |
| `deployment` | `completed` | Deployment successful |
| `deployment` | `rolled_back` | Deployment failed |

### Invalid Transitions (BLOCKED)

- `requirements` → `qa_testing` (must go through architecture)
- `architecture` → `deployment` (must go through implementation + QA)
- Any stage → previous stage (no backward transitions except QA → implementation for fixes)

---

## Initialization

### Default Workflow State

```json
{
  "workflow_id": "<generated UUID>",
  "product_name": "<from user input>",
  "execution_mode": "full_system | fast_feature",
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
      "human_approval_required": "<true if full_system>",
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
      "status": "<pending | skipped>",
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
      "status": "<pending | skipped>",
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
    "created_by": "orchestrator",
    "project_name": "<from config>",
    "tags": []
  },
  "created_at": "<ISO 8601>",
  "updated_at": "<ISO 8601>"
}
```

### Execution Mode Selection

| Trigger | Mode | Rationale |
|---------|------|-----------|
| "Build new product..." | `full_system` | Greenfield, needs full architecture |
| "Add feature to existing..." | `fast_feature` | Incremental, assess impact |
| "Fix bug in..." | `fast_feature` | Targeted change |
| "Redesign the..." | `full_system` | Major change |
| Project config specifies | As configured | Explicit override |

### Required Agents by Project Type

| Project Type | Required Agents | Optional |
|--------------|-----------------|----------|
| Full-Stack Web App | PM, Architect, FE, BE, QA, DevOps | AI |
| API-Only Backend | PM, Architect, BE, QA, DevOps | - |
| Static Website | PM, FE, QA, DevOps | - |
| AI Feature Addition | PM, AI, BE, QA | FE, DevOps |
| Infrastructure | PM, DevOps, QA | - |

Mark non-required stages as `skipped` during initialization.

---

## Agent Invocation Logic

### Next Agent Resolution

```
FUNCTION resolve_next_agent(completion_signal, workflow_state):

  current_stage = completion_signal.stage

  IF completion_signal.status IN ["failed", "blocked"]:
    RETURN null  # Do not proceed

  IF completion_signal.parallel_agents IS NOT EMPTY:
    RETURN completion_signal.parallel_agents  # Invoke all in parallel

  IF completion_signal.next_agent_required IS NOT null:
    RETURN [completion_signal.next_agent_required]

  # Default progression
  SWITCH current_stage:
    CASE "requirements":
      RETURN ["system_architect"]

    CASE "architecture":
      parallel_set = []
      IF stages.frontend_implementation.status != "skipped":
        parallel_set.append("frontend_engineer")
      IF stages.backend_implementation.status != "skipped":
        parallel_set.append("backend_engineer")
      IF stages.ai_implementation.status != "skipped":
        parallel_set.append("ai_engineer")
      RETURN parallel_set

    CASE "frontend_implementation", "backend_implementation", "ai_implementation":
      IF all_parallel_stages_complete(workflow_state):
        RETURN ["qa_engineer"]
      ELSE:
        RETURN null  # Wait for others

    CASE "qa_testing":
      # Read recommendation from QA test report artifact (not completion signal)
      qa_report = load_json(completion_signal.output_artifacts[0])  # qa-test-report.json
      IF qa_report.recommendation == "approve_for_deployment":
        RETURN ["devops_engineer"]
      ELSE:
        RETURN null  # Needs fixes, handled by handle_qa_recommendation()

    CASE "deployment":
      RETURN null  # Workflow complete
```

### Parallel Stage Completion Check

```
FUNCTION all_parallel_stages_complete(workflow_state):
  parallel_set = ["frontend_implementation", "backend_implementation", "ai_implementation"]

  FOR stage IN parallel_set:
    status = workflow_state.stages[stage].status
    IF status NOT IN ["completed", "skipped"]:
      RETURN false

  RETURN true
```

### Sequencing Rules

1. **Requirements always first** — No stage can start before requirements complete
2. **Architecture before implementation** — Engineers need specs
3. **All implementation before QA** — QA tests the complete system
4. **QA approval before deployment** — Quality gate
5. **Human approval where required** — Cannot bypass gates

### Timeout Policy

| Stage | Default Timeout | Extendable |
|-------|-----------------|------------|
| requirements | 60 minutes | Yes |
| architecture | 60 minutes | Yes |
| implementation (each) | 120 minutes | Yes |
| qa_testing | 90 minutes | Yes |
| deployment | 30 minutes | No |

**On timeout**:
1. Mark stage as `blocked`
2. Log timeout event
3. Notify user
4. Await decision: retry, extend, or abort

### Retry Policy

| Failure Type | Max Retries | Backoff |
|--------------|-------------|---------|
| Validation failure | 3 | None |
| Agent error | 2 | 30 seconds |
| Timeout | 1 | None (user decides) |

After max retries → escalate to user.

---

## Validation Rules

### Artifact-to-Schema Mapping

| Stage | Artifact | Schema | Validation Point |
|-------|----------|--------|------------------|
| requirements | `product-requirements-packet.json` | `pm-output-schema.json` | Before architecture |
| architecture (full) | `architecture-handover-packet.json` | `architect-output-schema.json` | Before implementation |
| architecture (fast) | `architecture-assessment.json` | `architecture-assessment-schema.json` | Before implementation |
| frontend_implementation | `frontend-implementation-report.json` | `frontend-output-schema.json` | Before QA sync |
| backend_implementation | `backend-implementation-report.json` | `backend-output-schema.json` | Before QA sync |
| ai_implementation | `ai-implementation-report.json` | `ai-engineer-output-schema.json` | Before QA sync |
| qa_testing | `qa-test-report.json` | `qa-output-schema.json` | Before deployment |
| deployment | `deployment-report.json` | `devops-output-schema.json` | Before completion |
| (all stages) | `stage-completion-signal.json` | `stage-completion-signal-schema.json` | Every handoff |

### Validation Procedure

```
FUNCTION validate_artifact(artifact_path, schema_path):

  # 1. Load files
  artifact = load_json(artifact_path)
  schema = load_json(schema_path)

  # 2. Validate
  errors = jsonschema_validate(artifact, schema)

  # 3. Return result
  IF errors IS EMPTY:
    RETURN {
      "valid": true,
      "artifact": artifact_path,
      "schema": schema_path
    }
  ELSE:
    RETURN {
      "valid": false,
      "artifact": artifact_path,
      "schema": schema_path,
      "errors": errors
    }
```

### Validation Commands

**Using jsonschema (Python)**:
```bash
pip install jsonschema
jsonschema -i artifact.json schema.json
```

**Using ajv (Node.js)**:
```bash
npm install -g ajv-cli
ajv validate -s schema.json -d artifact.json
```

**Fallback (manual check)**:
```bash
# Check required fields exist
jq 'has("field1") and has("field2")' artifact.json
```

### Block Conditions

Validation blocks progression if:
- Required fields missing
- Field type mismatch
- Enum value invalid
- Array constraints violated
- Nested object validation fails

### Validation Failure Handling

1. **Log failure**:
   ```json
   {
     "event_type": "validation_failed",
     "timestamp": "<ISO 8601>",
     "artifact": "artifact-name.json",
     "schema": "schema-name.json",
     "errors": ["error 1", "error 2"]
   }
   ```

2. **Notify agent**:
   ```json
   {
     "type": "validation_failure",
     "artifact": "artifact-name.json",
     "errors": ["specific errors"],
     "action": "regenerate_artifact"
   }
   ```

3. **Do not update workflow state** — Keep at current stage

4. **Increment retry counter**

5. **If max retries exceeded** → Escalate to user

---

## Gate Enforcement

### Human Approval Flow

```
FUNCTION enforce_human_gate(stage, workflow_state):

  IF NOT stage.human_approval_required:
    RETURN true  # No gate

  IF stage.human_approval_received:
    RETURN true  # Already approved

  # Gate active - pause workflow
  workflow_state.current_stage = "paused"

  # Notify user
  notify_user({
    "type": "approval_required",
    "stage": stage.name,
    "artifacts": stage.output_artifacts,
    "options": ["approve", "reject", "request_changes"]
  })

  # Log interaction
  workflow_state.human_interactions.append({
    "timestamp": now(),
    "stage": stage.name,
    "interaction_type": "approval_requested",
    "details": "Awaiting human approval"
  })

  RETURN false  # Block until approval
```

### Human Approval Receipt

```
FUNCTION receive_human_approval(stage, decision, workflow_state):

  workflow_state.human_interactions.append({
    "timestamp": now(),
    "stage": stage,
    "interaction_type": decision,  # "approval" | "rejection" | "feedback"
    "details": "<user comments>"
  })

  IF decision == "approve":
    workflow_state.stages[stage].human_approval_received = true
    workflow_state.current_stage = stage  # Resume
    invoke_next_agent()

  ELSE IF decision == "reject":
    workflow_state.stages[stage].status = "blocked"
    workflow_state.blocking_issues.append({
      "issue_id": generate_id(),
      "stage": stage,
      "description": "Human rejected stage output",
      "severity": "high",
      "resolution_required_before_proceeding": true
    })

  ELSE IF decision == "request_changes":
    # Re-invoke agent with feedback
    workflow_state.stages[stage].status = "in_progress"
    invoke_agent(stage, with_feedback=true)
```

### Safety/Governance Gate Flow

```
FUNCTION enforce_safety_gate(stage, workflow_state):

  risk_level = workflow_state.safety_and_governance.risk_level

  # Determine if review needed
  review_required = SWITCH risk_level:
    CASE "low": false  # Automated only
    CASE "medium": stage == "requirements"  # Spot check at start
    CASE "high": true  # Always review
    CASE "critical": true  # Always review
    DEFAULT: true  # Unknown = review

  IF NOT review_required:
    RETURN true  # Pass through

  # Invoke Safety Agent
  safety_result = invoke_safety_agent(stage, workflow_state)

  IF safety_result.status == "passed":
    workflow_state.safety_and_governance.safety_review_status = "passed"
    RETURN true

  ELSE IF safety_result.status == "blocked":
    workflow_state.safety_and_governance.safety_review_status = "blocked"
    workflow_state.blocking_issues.append(safety_result.issues)
    RETURN false  # Hard stop
```

### QA Recommendation Handling

The QA recommendation is read from `qa-test-report.json` (the QA output artifact), not from the completion signal. The completion signal only indicates stage completion; the actual test results and recommendation are in the artifact.

```
FUNCTION handle_qa_recommendation(qa_report, workflow_state):
  # qa_report is loaded from qa-test-report.json (output artifact)
  # Schema: qa-output-schema.json

  recommendation = qa_report.recommendation

  SWITCH recommendation:
    CASE "approve_for_deployment":
      # Proceed to deployment
      RETURN ["devops_engineer"]

    CASE "needs_fixes":
      # Check bug severity
      p1_bugs = filter(qa_report.bugs, severity == "P1")

      IF p1_bugs IS NOT EMPTY:
        # Block - P1 bugs must be fixed
        workflow_state.stages.qa_testing.status = "blocked"
        RETURN null

      ELSE:
        # P2/P3 bugs - human decides
        notify_user({
          "type": "qa_decision_required",
          "bugs": qa_report.bugs,
          "options": ["fix_bugs", "deploy_anyway", "abort"]
        })
        RETURN null  # Await decision

    CASE "major_issues":
      # Block - cannot deploy
      workflow_state.stages.qa_testing.status = "blocked"
      notify_user({
        "type": "qa_blocked",
        "issues": qa_report.blocking_issues
      })
      RETURN null
```

---

## Failure Handling

### Failure Types and Responses

| Failure Type | Response | Escalation |
|--------------|----------|------------|
| Validation failure | Retry up to 3x | User after 3 |
| Agent timeout | Notify user | User decides |
| Agent error | Retry up to 2x | User after 2 |
| Safety block | Hard stop | User + Safety Agent |
| Deployment failure | Auto-rollback | User + DevOps |

### Rollback Procedure

```
FUNCTION rollback_deployment(workflow_state, reason):

  # 1. Signal DevOps to rollback
  invoke_devops_agent({
    "action": "rollback",
    "reason": reason,
    "target_version": workflow_state.metadata.previous_version
  })

  # 2. Update workflow state
  workflow_state.stages.deployment.status = "rolled_back"
  workflow_state.current_stage = "failed"

  # 3. Log incident
  workflow_state.blocking_issues.append({
    "issue_id": generate_id(),
    "stage": "deployment",
    "description": "Deployment rolled back: " + reason,
    "severity": "critical",
    "resolved": false
  })

  # 4. Notify user
  notify_user({
    "type": "deployment_rolled_back",
    "reason": reason,
    "action_required": "Review and decide next steps"
  })

  # 5. Generate incident report
  generate_incident_report(workflow_state, reason)
```

### Escalation Paths

| Issue | First Escalation | Final Escalation |
|-------|------------------|------------------|
| Repeated validation failures | Originating agent | User |
| Agent timeout | User | Abort workflow |
| Safety/Governance block | PM (can challenge) | User |
| Agent disagreement | Controller mediation | User |
| Deployment failure | DevOps (rollback) | User |

---

## Stage Completion Processing

### Required Fields in Completion Signal

| Field | Required | Type | Validation |
|-------|----------|------|------------|
| `agent` | Yes | string | Must match stage agent |
| `stage` | Yes | string | Must match current_stage |
| `status` | Yes | enum | completed/completed_with_warnings/failed/blocked |
| `timestamp` | Yes | ISO 8601 | Must be valid datetime |
| `output_artifacts` | No | array | Paths must exist |
| `blocking_issues` | No | array | Required if status=blocked |
| `next_agent_required` | No | string | Valid agent name |
| `parallel_agents` | No | array | Valid agent names |

### Processing Procedure

```
FUNCTION process_completion_signal(signal, workflow_state):

  # 1. Validate signal schema
  validation = validate_artifact(signal, "stage-completion-signal-schema.json")
  IF NOT validation.valid:
    RETURN error("Invalid completion signal")

  # 2. Verify agent/stage match
  expected_agent = workflow_state.stages[signal.stage].agent
  IF signal.agent != expected_agent:
    RETURN error("Agent mismatch")

  IF signal.stage != workflow_state.current_stage:
    # Check if parallel stage
    IF signal.stage NOT IN get_active_parallel_stages(workflow_state):
      RETURN error("Stage mismatch")

  # 3. Validate output artifacts
  FOR artifact IN signal.output_artifacts:
    schema = get_schema_for_artifact(artifact)
    validation = validate_artifact(artifact, schema)
    IF NOT validation.valid:
      RETURN validation  # Reject with errors

  # 4. Update workflow state
  workflow_state.stages[signal.stage].status = signal.status
  workflow_state.stages[signal.stage].completed_at = signal.timestamp
  workflow_state.stages[signal.stage].output_artifacts = signal.output_artifacts

  IF signal.blocking_issues:
    workflow_state.blocking_issues.extend(signal.blocking_issues)

  # 5. Check gates
  IF NOT check_gates(signal.stage, workflow_state):
    RETURN  # Paused at gate

  # 5b. Special handling for QA stage - read recommendation from artifact
  IF signal.stage == "qa_testing":
    qa_report = load_json(signal.output_artifacts[0])  # qa-test-report.json
    next_agents = handle_qa_recommendation(qa_report, workflow_state)
  ELSE:
    # 6. Resolve and invoke next agent(s)
    next_agents = resolve_next_agent(signal, workflow_state)

  IF next_agents:
    invoke_agents(next_agents, workflow_state)

  # 7. Update timestamps
  workflow_state.updated_at = now()

  # 8. Persist state
  save_workflow_state(workflow_state)
```

### Merging into Workflow State

```
FUNCTION merge_completion_into_state(signal, workflow_state):

  stage = signal.stage

  # Update stage record
  workflow_state.stages[stage].status = signal.status
  workflow_state.stages[stage].completed_at = signal.timestamp
  workflow_state.stages[stage].output_artifacts = signal.output_artifacts

  IF signal.warnings:
    workflow_state.stages[stage].warnings = signal.warnings

  IF signal.blocking_issues:
    FOR issue IN signal.blocking_issues:
      issue.issue_id = generate_id()
      issue.stage = stage
      workflow_state.blocking_issues.append(issue)

  IF signal.performance_metrics:
    workflow_state.stages[stage].performance_metrics = signal.performance_metrics

  IF signal.validation_results:
    workflow_state.stages[stage].validation_results = signal.validation_results

  # Update current stage
  IF signal.status == "completed":
    next = resolve_next_agent(signal, workflow_state)
    IF next:
      workflow_state.current_stage = get_stage_for_agent(next[0])
    ELSE IF all_stages_complete(workflow_state):
      workflow_state.current_stage = "completed"

  ELSE IF signal.status IN ["blocked", "failed"]:
    workflow_state.current_stage = "paused"

  workflow_state.updated_at = now()
```

---

## Example Flows

### Full System Mode

```
1. INITIALIZE
   - Create workflow_state with execution_mode="full_system"
   - Set current_stage="requirements"
   - Mark ai_implementation as "pending" (needed)

2. REQUIREMENTS STAGE
   - Invoke product_manager
   - Receive completion signal
   - Validate product-requirements-packet.json against pm-output-schema.json
   - Invoke safety_agent and governance_agent for review
   - PAUSE: Await human approval
   - Human approves
   - Update state: requirements.status="completed"

3. ARCHITECTURE STAGE
   - Invoke system_architect
   - Receive completion signal with 2-3 options
   - Validate architecture-handover-packet.json
   - PAUSE: Await human selection
   - Human selects option B
   - Update state: architecture.status="completed"

4. IMPLEMENTATION STAGE (PARALLEL)
   - Invoke frontend_engineer, backend_engineer, ai_engineer simultaneously
   - Receive completions independently:
     - Frontend completes first → validate, update stage
     - Backend completes second → validate, update stage
     - AI completes third → validate, update stage
   - All complete → proceed

5. QA STAGE
   - Invoke qa_engineer
   - Receive completion signal
   - Validate qa-test-report.json
   - recommendation="approve_for_deployment"
   - Update state: qa_testing.status="completed"

6. DEPLOYMENT STAGE
   - PAUSE: Await human deployment approval
   - Human approves
   - Invoke devops_engineer
   - Receive completion signal
   - Validate deployment-report.json
   - Update state: deployment.status="completed"

7. COMPLETE
   - Set current_stage="completed"
   - Generate summary
   - Notify user
```

### Fast Feature Mode

```
1. INITIALIZE
   - Create workflow_state with execution_mode="fast_feature"
   - Set current_stage="requirements"
   - Check if ai_implementation needed → "skipped"

2. REQUIREMENTS STAGE
   - Invoke product_manager (lightweight mode)
   - Receive completion signal
   - Validate product-requirements-packet.json
   - Safety/governance: automated check only (low risk)
   - PAUSE: Await human approval
   - Human approves

3. ARCHITECTURE STAGE
   - Invoke system_architect
   - Architect produces architecture-assessment.json (not full handover)
   - Validate against architecture-assessment-schema.json
   - architecture_impact="minor"
   - NO human gate (fast feature)
   - Proceed automatically

4. IMPLEMENTATION STAGE (PARALLEL)
   - Invoke frontend_engineer, backend_engineer
   - (ai_engineer skipped)
   - Both complete → proceed

5. QA STAGE
   - Invoke qa_engineer (targeted testing)
   - recommendation="approve_for_deployment"

6. DEPLOYMENT STAGE
   - Human approval still required (production)
   - Human approves
   - Deploy

7. COMPLETE
```

### Failure and Recovery

```
1. SCENARIO: Validation failure at implementation

   - Backend engineer submits completion
   - Validation fails: missing required field "api_endpoints_implemented"
   - Orchestrator:
     - Logs validation failure
     - Does NOT update workflow state
     - Notifies backend_engineer with specific errors
     - Increments retry counter (1/3)

   - Backend engineer resubmits
   - Validation passes
   - Proceed normally

2. SCENARIO: QA blocks with P1 bugs

   - QA submits completion with recommendation="needs_fixes"
   - P1 bug found: "Authentication bypass vulnerability"
   - Orchestrator:
     - Blocks workflow
     - Notifies user with bug details
     - Does NOT allow deployment option

   - User decides: "Fix the bugs"
   - Orchestrator:
     - Reverts backend_implementation to "in_progress"
     - Re-invokes backend_engineer with bug context

   - Backend fixes and resubmits
   - QA re-tests
   - QA approves
   - Proceed to deployment

3. SCENARIO: Deployment failure

   - DevOps deploys to production
   - Health checks fail
   - DevOps signals status="failed"
   - Orchestrator:
     - Triggers rollback procedure
     - DevOps executes rollback
     - Updates deployment.status="rolled_back"
     - Generates incident report
     - Notifies user

   - User reviews incident
   - Decides: "Investigate and fix"
   - New workflow initiated for bug fix
```

---

## References

- [controller-orchestrator.md](../../L2%20-%20Orchestration%20&%20Governance/controller-orchestrator.md) — Role specification
- [workflow-state-schema.json](../contracts/workflow-state-schema.json) — State schema
- [stage-completion-signal-schema.json](../contracts/stage-completion-signal-schema.json) — Signal schema
- [claude.md](../../L0%20-%20Meta%20Layer/claude.md) — System principles, project types
- [architecture.md](./architecture.md) — Architecture conventions

---

**END OF ORCHESTRATION LOGIC**
