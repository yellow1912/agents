# Standard Workflow Definition

**Version**: 1.0
**Last Updated**: 2025-12-02

---

## Purpose

This document defines the **standard workflow** for AI-native development, mapping:

- Project types to required agents
- Execution modes to stage configurations
- Stage sequences and parallelization
- Gate requirements

This is the authoritative reference for how workflows execute.

---

## Project Type to Agent Mapping

### Full-Stack Web App (`full_stack_web_app`)

**Default for**: New web applications with frontend and backend

| Agent | Required | Notes |
|-------|----------|-------|
| Product Manager | Yes | Always first |
| System Architect | Yes | Full architecture |
| Frontend Engineer | Yes | UI implementation |
| Backend Engineer | Yes | API implementation |
| AI Engineer | Optional | If AI features in requirements |
| QA Engineer | Yes | Full testing |
| DevOps Engineer | Yes | Deployment |

**Stages**: requirements → architecture → [frontend, backend, ai?] → qa → deployment

---

### API-Only Backend (`api_only_backend`)

**Default for**: Backend services, microservices, APIs without frontend

| Agent | Required | Notes |
|-------|----------|-------|
| Product Manager | Yes | Always first |
| System Architect | Yes | API design focus |
| Frontend Engineer | No | Skipped |
| Backend Engineer | Yes | Primary implementer |
| AI Engineer | Optional | If AI features |
| QA Engineer | Yes | API testing |
| DevOps Engineer | Yes | Deployment |

**Stages**: requirements → architecture → [backend, ai?] → qa → deployment

---

### Static Website (`static_website`)

**Default for**: Marketing sites, documentation, landing pages

| Agent | Required | Notes |
|-------|----------|-------|
| Product Manager | Yes | Lightweight requirements |
| System Architect | No | Simple architecture |
| Frontend Engineer | Yes | Primary implementer |
| Backend Engineer | No | Skipped |
| AI Engineer | No | Skipped |
| QA Engineer | Yes | Visual/functional testing |
| DevOps Engineer | Yes | Static deployment |

**Stages**: requirements → frontend → qa → deployment

---

### AI Feature (`ai_feature`)

**Default for**: Adding AI capabilities to existing system

| Agent | Required | Notes |
|-------|----------|-------|
| Product Manager | Yes | AI requirements focus |
| System Architect | Optional | If integration complex |
| Frontend Engineer | Optional | If UI changes needed |
| Backend Engineer | Yes | Integration layer |
| AI Engineer | Yes | Primary implementer |
| QA Engineer | Yes | AI-specific testing |
| DevOps Engineer | Optional | If deployment changes |

**Stages**: requirements → architecture? → [ai, backend, frontend?] → qa → deployment?

---

### Infrastructure (`infrastructure`)

**Default for**: DevOps, CI/CD, monitoring, scaling

| Agent | Required | Notes |
|-------|----------|-------|
| Product Manager | Yes | Infrastructure requirements |
| System Architect | Optional | If complex design |
| Frontend Engineer | No | Skipped |
| Backend Engineer | No | Skipped |
| AI Engineer | No | Skipped |
| QA Engineer | Yes | Smoke tests, validation |
| DevOps Engineer | Yes | Primary implementer |

**Stages**: requirements → architecture? → devops → qa → (deployment is the work)

---

### Mobile App (`mobile_app`)

**Default for**: iOS/Android applications

| Agent | Required | Notes |
|-------|----------|-------|
| Product Manager | Yes | Mobile-focused requirements |
| System Architect | Yes | Mobile architecture |
| Frontend Engineer | Yes | Mobile UI (adapt spec) |
| Backend Engineer | Yes | API backend |
| AI Engineer | Optional | If AI features |
| QA Engineer | Yes | Mobile testing |
| DevOps Engineer | Yes | App store deployment |

**Stages**: requirements → architecture → [frontend, backend, ai?] → qa → deployment

---

### CLI Tool (`cli_tool`)

**Default for**: Command-line applications

| Agent | Required | Notes |
|-------|----------|-------|
| Product Manager | Yes | CLI requirements |
| System Architect | Optional | If complex |
| Frontend Engineer | No | Skipped |
| Backend Engineer | Yes | CLI implementation |
| AI Engineer | Optional | If AI features |
| QA Engineer | Yes | CLI testing |
| DevOps Engineer | Yes | Package distribution |

**Stages**: requirements → architecture? → backend → qa → deployment

---

### Library (`library`)

**Default for**: Reusable packages, SDKs

| Agent | Required | Notes |
|-------|----------|-------|
| Product Manager | Yes | API design requirements |
| System Architect | Yes | Library architecture |
| Frontend Engineer | No | Skipped |
| Backend Engineer | Yes | Library implementation |
| AI Engineer | Optional | If AI library |
| QA Engineer | Yes | Comprehensive testing |
| DevOps Engineer | Yes | Package publishing |

**Stages**: requirements → architecture → backend → qa → deployment

---

## Execution Mode Configurations

### Full System Mode (`full_system`)

**When to use**:
- New projects (greenfield)
- Major redesigns
- No existing architecture packet

**Stage Configuration**:

```
┌─────────────────┐
│  Requirements   │ ← Human approval gate
│ (Product Manager)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Architecture  │ ← Human selection gate (choose option)
│(System Architect)│
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│         Implementation              │
│  ┌──────────┬──────────┬─────────┐  │
│  │ Frontend │ Backend  │   AI    │  │ ← Parallel execution
│  │ Engineer │ Engineer │Engineer │  │
│  └──────────┴──────────┴─────────┘  │
└────────────────┬────────────────────┘
                 │ (sync point: all must complete)
                 ▼
┌─────────────────┐
│   QA Testing    │
│  (QA Engineer)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Deployment    │ ← Human approval gate
│(DevOps Engineer)│
└─────────────────┘
```

**Human Gates**:
1. Requirements approval (mandatory)
2. Architecture option selection (mandatory)
3. Deployment approval (mandatory)

**Safety/Governance Gates**:
1. Requirements stage: Full review (all projects)
2. Later stages: Risk-based

---

### Fast Feature Mode (`fast_feature`)

**When to use**:
- Adding features to existing project
- Bug fixes
- Incremental development
- Existing architecture packet available

**Stage Configuration**:

```
┌─────────────────┐
│  Requirements   │ ← Human approval gate
│ (Product Manager)│ ← Lightweight packet
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Architecture  │ ← Assessment only (no options)
│   Assessment    │ ← Auto-proceed if minor impact
└────────┬────────┘
         │
         ├── impact = "major" ──→ Switch to full_system
         │
         ▼
┌─────────────────────────────────────┐
│         Implementation              │
│  (Only affected engineers)          │ ← Parallel if multiple
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────┐
│   QA Testing    │ ← Targeted testing
│  (QA Engineer)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Deployment    │ ← Human approval gate
│(DevOps Engineer)│
└─────────────────┘
```

**Human Gates**:
1. Requirements approval (mandatory)
2. Architecture selection: NOT required (auto-proceed)
3. Deployment approval (mandatory)

**Safety/Governance Gates**:
1. Requirements stage: Automated check (low risk) or full review (high risk)
2. Later stages: Based on assessed risk level

---

## Stage Definitions

### Requirements Stage

| Property | Value |
|----------|-------|
| Agent | `product_manager` |
| Input | User idea, project config |
| Output | `product-requirements-packet.json` |
| Human Gate | Yes (approval required) |
| Safety Review | Yes (all projects) |
| Governance Review | Yes (all projects) |
| Next Stage | `architecture` |

**Completion Criteria**:
- Valid `product-requirements-packet.json`
- Human approval received
- Safety review passed
- Governance review passed

---

### Architecture Stage

| Property | Full System | Fast Feature |
|----------|-------------|--------------|
| Agent | `system_architect` | `system_architect` |
| Input | Requirements packet | Requirements + existing architecture |
| Output | `architecture-handover-packet.json` | `architecture-assessment.json` |
| Human Gate | Yes (option selection) | No (auto-proceed if minor) |
| Safety Review | Risk-based | Risk-based |
| Next Stage | Implementation (parallel) | Implementation |

**Completion Criteria (full_system)**:
- Valid `architecture-handover-packet.json`
- Human selected architecture option
- Safety review passed (if required)

**Completion Criteria (fast_feature)**:
- Valid `architecture-assessment.json`
- Impact assessment: none/minor → proceed, major → switch to full_system

---

### Implementation Stage

| Property | Value |
|----------|-------|
| Agents | `frontend_engineer`, `backend_engineer`, `ai_engineer` |
| Execution | Parallel (all required agents run simultaneously) |
| Input | Architecture packet/assessment |
| Output | `*-implementation-report.json` per agent |
| Human Gate | No |
| Safety Review | Risk-based (high+ risk) |
| Sync Point | All parallel agents must complete |
| Next Stage | `qa_testing` |

**Completion Criteria**:
- All required implementation reports valid
- All parallel agents completed
- Safety review passed (if required)

---

### QA Testing Stage

| Property | Value |
|----------|-------|
| Agent | `qa_engineer` |
| Input | All implementation reports, requirements |
| Output | `qa-test-report.json` |
| Human Gate | Conditional (if needs_fixes with P2/P3 bugs) |
| Safety Review | No (testing is verification) |
| Next Stage | `deployment` (if approved) or back to implementation |

**Completion Criteria**:
- Valid `qa-test-report.json`
- Recommendation: `approve_for_deployment`
- OR: Human override for P2/P3 bugs

**Recommendation Handling**:

| Recommendation | Action |
|----------------|--------|
| `approve_for_deployment` | Proceed to deployment |
| `needs_fixes` (P1 bugs) | Block, return to implementation |
| `needs_fixes` (P2/P3 only) | Human decides: fix or proceed |
| `major_issues` | Block, requires significant rework |

---

### Deployment Stage

| Property | Value |
|----------|-------|
| Agent | `devops_engineer` |
| Input | QA approval, implementation reports |
| Output | `deployment-report.json` |
| Human Gate | Yes (production approval) |
| Safety Review | Pre-deployment security checklist |
| Next Stage | Workflow complete |

**Completion Criteria**:
- Human approval received
- Valid `deployment-report.json`
- Deployment successful
- Health checks passing

---

### Safety Review Stage

| Property | Value |
|----------|-------|
| Agent | `safety_agent` |
| Input | Stage artifacts, project config |
| Output | `safety-review-report.json` |
| Human Gate | No (blocks workflow if issues found) |
| When Invoked | After requirements (always), other stages (risk-based) |
| Next Stage | Continues current workflow stage |

**Completion Criteria**:
- Valid `safety-review-report.json`
- Decision: `approved` or `approved_with_conditions`
- Blocking findings resolved

---

### Governance Review Stage

| Property | Value |
|----------|-------|
| Agent | `governance_agent` |
| Input | Stage artifacts, project config |
| Output | `governance-review-report.json` |
| Human Gate | No (blocks workflow if issues found) |
| When Invoked | After requirements (always), other stages (risk-based) |
| Next Stage | Continues current workflow stage |

**Completion Criteria**:
- Valid `governance-review-report.json`
- Decision: `approved` or `approved_with_conditions`
- Compliance issues resolved

---

### Code Health Assessment Stage

| Property | Value |
|----------|-------|
| Agent | `code_health_agent` |
| Input | Codebase, implementation reports |
| Output | `code-health-report.json` |
| Human Gate | No |
| When Invoked | After architecture (recommended), after implementation (optional) |
| Next Stage | Continues current workflow stage |

**Completion Criteria**:
- Valid `code-health-report.json`
- Health rating meets project threshold (from `quality_gates.code_health_minimum`)

---

## Parallel Execution Rules

### Which Stages Run in Parallel

| Parallel Group | Agents | Sync Condition |
|----------------|--------|----------------|
| Implementation | frontend, backend, ai | All must complete (or be skipped) |

### Parallel Execution Flow

```
1. Orchestrator receives architecture completion
2. Determine which implementation agents needed (from project config)
3. Invoke all required agents simultaneously
4. Track completion of each independently
5. Wait at sync point until ALL complete
6. If any fail/block → workflow blocks
7. If all complete → proceed to QA
```

### Partial Completion Handling

| Scenario | Action |
|----------|--------|
| All complete | Proceed to QA |
| Some complete, some in progress | Wait |
| Some complete, some blocked | Workflow blocks, notify user |
| Some complete, some failed | Workflow blocks, notify user |

---

## Gate Enforcement Matrix

| Gate | Requirements | Architecture | Implementation | QA | Deployment |
|------|--------------|--------------|----------------|-----|------------|
| Human Approval | Always | full_system only | Never | Conditional | Always |
| Safety Review | Always | Risk-based | Risk-based | Never | Checklist |
| Governance Review | Always | Risk-based | Never | Never | Never |
| Schema Validation | Always | Always | Always | Always | Always |
| Code Health | Optional | Recommended | Optional | N/A | N/A |

### Gate Stages and Agents

| Gate Stage | Agent | Blocking Behavior |
|------------|-------|-------------------|
| `safety_review` | `safety_agent` | Blocks on `critical` or `high` findings |
| `governance_review` | `governance_agent` | Blocks on compliance violations |
| `code_health_assessment` | `code_health_agent` | Blocks if below `quality_gates.code_health_minimum` |

---

## Workflow State Transitions

### Valid Transitions

```
[init] → requirements
requirements → safety_review → governance_review → architecture
architecture → code_health_assessment (optional) → implementation
architecture → frontend_implementation (parallel start)
architecture → backend_implementation (parallel start)
architecture → ai_implementation (parallel start)
[all implementation] → code_health_assessment (optional) → qa_testing (sync point)
qa_testing → deployment
qa_testing → [implementation] (if needs_fixes)
deployment → completed
deployment → rolled_back (on failure)
[any] → paused (on block/human gate)
[any] → failed (on critical failure)
[any main stage] → safety_review (risk-based)
[any main stage] → governance_review (risk-based)
```

### Invalid Transitions (Error)

```
requirements → qa_testing (skip architecture)
requirements → deployment (skip everything)
architecture → deployment (skip implementation/QA)
qa_testing → requirements (backward)
```

---

## Configuration Resolution

### Agent Selection Algorithm

```python
def resolve_agents(project_config):
    # Start with project type defaults
    defaults = PROJECT_TYPE_DEFAULTS[project_config.project_type]

    # Apply explicit configuration
    required = project_config.agents.required or defaults.required
    optional = project_config.agents.optional or defaults.optional
    excluded = project_config.agents.excluded or []

    # Remove excluded from required/optional
    required = [a for a in required if a not in excluded]
    optional = [a for a in optional if a not in excluded]

    return {
        "required": required,
        "optional": optional
    }
```

### Execution Mode Selection

```python
def select_execution_mode(project_config, user_request):
    # Explicit user request wins
    if user_request.execution_mode:
        return user_request.execution_mode

    # Check for existing architecture
    if project_config.existing_codebase.has_existing_architecture:
        return "fast_feature"

    # Use project default
    return project_config.execution_mode_default or "full_system"
```

### Stage Inclusion Rules

```python
def should_include_stage(stage, project_config, execution_mode):
    agent = STAGE_TO_AGENT[stage]

    # Check if agent is required or optional
    if agent not in project_config.agents.required + project_config.agents.optional:
        return False

    # Check if agent is excluded
    if agent in project_config.agents.excluded:
        return False

    # Architect stage special handling
    if stage == "architecture":
        if execution_mode == "fast_feature":
            return True  # Assessment mode
        return agent in project_config.agents.required

    return True
```

---

## References

- [project-config-schema.json](../contracts/project-config-schema.json) — Configuration schema
- [orchestration.md](./orchestration.md) — Orchestration logic
- [controller-orchestrator.md](../../L2%20-%20Orchestration%20&%20Governance/controller-orchestrator.md) — Orchestrator spec
- [claude.md](../../L0%20-%20Meta%20Layer/claude.md) — System principles

---

**END OF WORKFLOW DEFINITION**
