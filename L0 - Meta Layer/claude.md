# **Claude Meta Layer - AI-Native Development System**

**Version**: 1.0
**Last Updated**: 2025-11-20

---

## **Mission**

This system enables **AI-native software development** through a structured team of specialized agents that collaborate to build products from concept to deployment.

**Core Philosophy**: Treat AI agents as a cross-functional team with clear roles, responsibilities, contracts, and collaboration protocols — not as a single monolithic prompt.

---

## **1. System Principles**

### 1.1 Separation of Concerns

Each agent has a **single, clear responsibility**:
- Product Manager: WHAT and WHY
- System Architect: HOW (architecture)
- Engineers: IMPLEMENTATION (code)
- QA: VALIDATION (testing)
- DevOps: OPERATIONS (deployment)

**Never cross boundaries**: PMs don't write code. Engineers don't define requirements. Architects don't implement.

### 1.2 Contract-Driven Collaboration

All agent communication happens through **JSON contracts** (schemas in [L3/contracts](../L3%20-%20Workflows%20&%20Contracts/contracts/)):
- Explicit input/output formats
- Schema validation before handoff
- No ambiguous natural language handoffs
- Versioned contracts for compatibility

### 1.3 Human-in-the-Loop at Critical Gates

Humans decide on:
- **Requirements approval** (PM → Architect)
- **Architecture decisions** (when multiple options exist)
- **Deployment to production** (QA → DevOps)
- **Conflict resolution** (agent disagreements)

Humans **do not** micromanage implementation details.

### 1.4 Safety & Governance by Design

Every workflow includes:
- **Safety review** (harmful outputs, privacy, misuse)
- **Governance review** (compliance, regulations, ethics)
- **Risk-based gating** (high-risk = more scrutiny, low-risk = automated)

Safety and governance are **collaborators, not blockers** — they can be challenged with rationale.

### 1.5 Fail Fast, Fail Safely

- Validate schemas at every stage boundary
- Block progression on critical failures
- Document all blocking issues
- Provide clear rollback mechanisms

---

## **2. System Architecture**

### Layer 0 (Meta Layer)
**Purpose**: Global rules, principles, and project configuration
**Files**:
- `claude.md` (this file)
- `project-config.json` (project-specific settings) — see [template](./project-config.template.json) and [schema](../L3%20-%20Workflows%20&%20Contracts/contracts/project-config-schema.json)

### Layer 1 (Specialist Agents)
**Purpose**: Core specialist agents that do the work
**Agents**:
- [product-manager.md](../L1%20-%20Specialist%20Agents/product-manager.md)
- [system-architect.md](../L1%20-%20Specialist%20Agents/system-architect.md)
- [frontend-engineer.md](../L1%20-%20Specialist%20Agents/frontend-engineer.md)
- [backend-engineer.md](../L1%20-%20Specialist%20Agents/backend-engineer.md)
- [ai-engineer.md](../L1%20-%20Specialist%20Agents/ai-engineer.md)
- [qa-engineer.md](../L1%20-%20Specialist%20Agents/qa-engineer.md)
- [devops-engineer.md](../L1%20-%20Specialist%20Agents/devops-engineer.md)

### Layer 2 (Orchestration & Governance)
**Purpose**: Coordinate agents, enforce quality, ensure safety
**Agents**:
- [Controller Orchestrator](../L2%20-%20Orchestration%20&%20Governance/controller-orchestrator.md): Workflow state management, agent invocation, validation
- [Safety Agent](../L2%20-%20Orchestration%20&%20Governance/safety-agent.md): Content safety, privacy, misuse prevention
- [Governance Agent](../L2%20-%20Orchestration%20&%20Governance/governance-agent.md): Compliance, regulations, ethics
- [Code Health Agent](../L2%20-%20Orchestration%20&%20Governance/code-health-agent.md): Technical debt, quality metrics
- Feedback Agent: Continuous improvement (to be defined)

### Layer 3 (Workflows & Contracts)
**Purpose**: Define workflows and agent communication contracts
**Contents**:
- `contracts/` - JSON schemas for all agent outputs
- `workflows/` - Workflow definitions and operational logic
  - [standard-workflow.md](../L3%20-%20Workflows%20&%20Contracts/workflows/standard-workflow.md): Project types, execution modes, stage mapping
  - [architecture.md](../L3%20-%20Workflows%20&%20Contracts/workflows/architecture.md): Architecture conventions and standards
  - [orchestration.md](../L3%20-%20Workflows%20&%20Contracts/workflows/orchestration.md): Workflow state machine and orchestration logic
  - [stage-completion-guide.md](../L3%20-%20Workflows%20&%20Contracts/workflows/stage-completion-guide.md): How to write and validate completion signals

---

## **3. Execution Modes**

### Full System Mode (`execution_mode: "full_system"`)

**Use when**:
- Building a new product from scratch
- Major redesign or refactoring
- Greenfield projects

**Characteristics**:
- All stages executed (requirements → architecture → implementation → QA → deployment)
- Full requirements documentation
- Multiple architecture options evaluated
- Comprehensive testing

**Duration**: Days to weeks

---

### Fast Feature Mode (`execution_mode: "fast_feature"`)

**Use when**:
- Adding a feature to existing product
- Bug fixes or enhancements
- Iterative development

**Characteristics**:
- Lightweight requirements (inherit from existing)
- Architecture assessment (not full redesign)
- Incremental implementation
- Targeted testing

**Duration**: Hours to days

---

## **4. Workflow Stages**

### Stage 1: Requirements (Product Manager)
- **Input**: User idea, business goals, constraints
- **Output**: [product-requirements-packet.json](../L3%20-%20Workflows%20&%20Contracts/contracts/pm-output-schema.json)
- **Human Gate**: ✅ Approval required before architecture
- **Safety Review**: ✅ Full manual review (all projects)

### Stage 2: Architecture (System Architect)
- **Input**: Product requirements packet
- **Output**: [architecture-handover-packet.json](../L3%20-%20Workflows%20&%20Contracts/contracts/architect-output-schema.json)
- **Human Gate**: ✅ Architecture option selection (full_system mode)
- **Safety Review**: Risk-based (automated for low-risk)

### Stage 3: Implementation (Engineers)
- **Agents**: Frontend, Backend, AI (can run in parallel)
- **Output**: Implementation reports from each engineer
- **Human Gate**: ❌ No approval needed (trust but verify)
- **Safety Review**: Risk-based (automated for low-risk)

### Stage 4: QA Testing (QA Engineer)
- **Input**: All implementation reports + requirements
- **Output**: [qa-test-report.json](../L3%20-%20Workflows%20&%20Contracts/contracts/qa-output-schema.json)
- **Human Gate**: Review of test results, especially if `recommendation != "approve_for_deployment"`

### Stage 5: Deployment (DevOps Engineer)
- **Input**: QA approval
- **Output**: [deployment-report.json](../L3%20-%20Workflows%20&%20Contracts/contracts/devops-output-schema.json)
- **Human Gate**: ✅ Production deployment approval
- **Safety Review**: Pre-deployment security checklist

---

## **5. Agent Communication Protocol**

### 5.1 Stage Completion Signal

Every agent MUST signal completion via [stage-completion-signal.json](../L3%20-%20Workflows%20&%20Contracts/contracts/stage-completion-signal-schema.json):

```json
{
  "agent": "agent_name",
  "stage": "stage_name",
  "status": "completed | failed | blocked",
  "timestamp": "2025-01-15T10:30:00Z",
  "output_artifacts": ["path/to/artifact.json"],
  "blocking_issues": [],
  "next_agent_required": "agent_name | none"
}
```

**Note**: `timestamp` is required (ISO 8601 format).

### 5.2 Workflow State Management

Controller Orchestrator maintains [workflow-state.json](../L3%20-%20Workflows%20&%20Contracts/contracts/workflow-state-schema.json):
- Current stage
- Status of all stages
- Blocking issues
- Human interactions log

### 5.3 Handoff Rules

1. **Sequential handoff**: PM → Architect → Engineers → QA → DevOps
2. **Parallel execution**: Frontend, Backend, AI engineers can work simultaneously
3. **Blocking on failure**: If any stage fails, halt and require human intervention
4. **Schema validation**: All outputs validated against schemas before handoff

---

## **6. Human Interaction Points**

### Required Human Approvals

1. **Requirements Approval** (PM stage)
   - Human confirms requirements are correct before architecture
   - Prevents building the wrong thing

2. **Architecture Selection** (Architect stage, full_system mode only)
   - Human chooses between architecture options
   - Involves cost/complexity trade-offs

3. **Production Deployment** (DevOps stage)
   - Human confirms production deployment
   - Final safety checkpoint

### Optional Human Interactions

- **Clarification Questions** (PM stage) - Human answers 1-3 questions
- **Bug Fix Decisions** (QA stage) - Human decides if P2/P3 bugs block release
- **Conflict Resolution** - Human mediates if agents disagree (e.g., Safety vs PM)

---

## **7. Safety & Governance Framework**

### 7.1 Intelligent Risk-Based Gating

**At Requirements Stage** (ALL projects):
- Safety Agent: Full manual review
- Governance Agent: Full manual review
- **Output**: Risk assessment (low/medium/high/critical)

**At Later Stages** (risk-based):
- **Low risk** (UI changes, docs): Automated validation only
- **Medium risk** (standard features): Automated + spot checks
- **High risk** (AI, payments, auth): Manual review maintained
- **Critical risk** (health, finance, children): Full manual review at ALL stages

**Why this works**:
- 80% of safety/governance issues caught at requirements (cheapest stage)
- Resources focused on high-risk features
- Low-risk changes don't get bogged down in bureaucracy

### 7.2 Safety Agent Responsibilities

- Content safety (harmful outputs, toxicity)
- Privacy protection (PII handling, data minimization)
- Misuse prevention (jailbreaks, prompt injection)
- Bias detection and mitigation

### 7.3 Governance Agent Responsibilities

- Regulatory compliance (GDPR, HIPAA, etc.)
- AI policy adherence
- Ethical considerations
- Legal risk assessment

### 7.4 Conflict Resolution

If Safety/Governance blocks and PM disagrees:
1. PM writes rationale in `pm-position.json`
2. Controller mediates based on severity
3. Human makes final decision if unresolved

---

## **8. Adaptive Reasoning vs Rigid Enforcement Philosophy**

### Product Manager: RIGID (Human-in-the-Loop Gates)

**Why**: Requirements are the foundation. Getting them wrong wastes everything downstream.

**Rules**:
- MUST ask clarification questions (no assumptions)
- MUST wait for human approval
- CANNOT skip safety/governance review
- CANNOT proceed without explicit confirmation

### All Other Agents: ADAPTIVE (Trust but Verify)

**Why**: Implementation details benefit from AI flexibility and problem-solving.

**Rules**:
- CAN make technical decisions within scope
- CAN adapt to unexpected issues
- MUST stay within architecture boundaries
- MUST signal if blocked or uncertain

**Balance**: Rigid gates where it matters (requirements, deployment), adaptive execution where AI adds value (implementation).

---

## **9. Project Types & Agent Selection**

### Full-Stack Web App (Default)
**Agents**: PM, Architect, Frontend, Backend, QA, DevOps
**Optional**: AI (if requirements include AI features)

### API-Only Backend
**Agents**: PM, Architect, Backend, QA, DevOps
**Skip**: Frontend, AI (unless needed)

### Static Website / Documentation
**Agents**: PM, Frontend, QA, DevOps
**Skip**: Architect (simple), Backend, AI

### AI Feature Addition
**Agents**: PM, AI, Backend (integration), QA
**Skip**: Frontend (unless UI changes), DevOps (if no deployment changes)

### Infrastructure / DevOps Project
**Agents**: PM (requirements), DevOps, QA (smoke tests)
**Skip**: Architect, Engineers

**Configuration**: Use `project-config.json` to specify required agents

---

## **10. Quality Standards**

### Code Quality (All Engineers)
- Strong typing (TypeScript, Python type hints, etc.)
- Linting configured and passing
- No hardcoded secrets
- Meaningful names and documentation

### Testing (QA + Engineers)
- Minimum 80% coverage for critical paths
- All acceptance criteria validated
- Edge cases tested
- Performance benchmarks met

### Security (All Stages)
- Authentication & authorization implemented
- Input validation on all endpoints
- Secrets in environment variables
- OWASP Top 10 compliance

### Performance (Architect + Engineers)
- Latency targets met (from requirements)
- Database queries optimized
- Caching implemented where appropriate
- Scaling strategy defined

---

## **11. Continuous Improvement Loop**

### Feedback Collection

Sources:
- User feedback
- Telemetry data
- QA bug reports
- Performance metrics
- Incident reports

### Feedback Agent Responsibilities

1. Synthesize feedback into insights
2. Generate `new-requirement-packet.json`
3. Present to PM: "Should we initiate an update cycle?"
4. If yes → restart workflow

### Iteration Cycle

- **Minor updates**: Fast feature mode
- **Major changes**: Full system mode
- **Bug fixes**: Direct to engineering (skip PM if trivial)

---

## **12. Error Handling & Recovery**

### Schema Validation Failure
- Agent regenerates output
- Controller provides specific validation errors
- Block progression until valid

### Agent Blocking Issue
- Agent signals `status: "blocked"`
- Controller logs issue in workflow state
- Human notified for intervention

### Deployment Failure
- Automatic rollback to previous version
- DevOps generates incident report
- Post-mortem conducted

### Safety/Governance Block
- Hard stop on workflow
- PM can challenge with rationale
- Human makes final decision

---

## **13. File Naming Conventions**

**Standard**: `kebab-case` for all files

- Agent specs: `product-manager.md`, `system-architect.md`
- JSON artifacts: `product-requirements-packet.json`, `workflow-state.json`
- Schemas: `pm-output-schema.json`, `architect-output-schema.json`

**Folders**:
- Top-level: `PascalCase` (e.g., `ARTIFACTS`, `System`)
- Nested: `kebab-case` (e.g., `product-manager/`, `system-architect/`)

---

## **14. Artifact Storage**

**Location**: [ARTIFACTS/](../../ARTIFACTS/)

**Structure**:
```
ARTIFACTS/
├── product-manager/
│   ├── product-requirements-packet.json
│   ├── pm-clarification-questions.json
│   └── pm-human-approval.json
├── system-architect/
│   ├── architecture-handover-packet.json
│   └── architecture-assessment.json
├── frontend-engineer/
│   └── frontend-implementation-report.json
├── backend-engineer/
│   └── backend-implementation-report.json
├── ai-engineer/
│   └── ai-implementation-report.json
├── qa-engineer/
│   └── qa-test-report.json
├── devops-engineer/
│   └── deployment-report.json
└── system/
    ├── workflow-state.json
    ├── stage-completion-signal.json
    └── pm-position.json (if conflicts arise)
```

---

## **15. Extensibility**

### Adding New Agents

1. Create agent spec in `L1/` following template
2. Define output schema in `L3/contracts/`
3. Update `workflow-state-schema.json` to include new stage
4. Update Controller orchestrator to invoke new agent

### Adding New Workflows

1. Create workflow definition in `L3/workflows/`
2. Specify required agents and stages
3. Define stage ordering and parallelization
4. Add human approval gates

### Adding New Project Types

1. Create `project-config.json` template
2. Define which agents are required/optional
3. Specify technology preferences
4. Document in this meta layer

---

## **16. Success Metrics**

### Product Quality
- Requirements clarity (fewer change requests)
- Architecture soundness (fewer refactors)
- Code quality (test coverage, linting)
- Deployment success rate

### Efficiency
- Time from idea to deployment
- Number of human interventions needed
- Cost per workflow execution
- Reuse of components/patterns

### Safety & Governance
- Safety issues caught at requirements stage
- Zero critical vulnerabilities in production
- Compliance violations prevented
- Incident response time

---

## **17. Getting Started**

### For New Projects

1. Copy this agent system to your project
2. Create `project-config.json` with your preferences
3. Run PM agent with your idea: "I want to build [X]"
4. PM will ask clarification questions
5. Approve requirements when satisfied
6. System executes through deployment

### For Existing Projects

1. Run PM in "fast_feature" mode with feature request
2. PM assesses against existing requirements
3. Architect evaluates architecture changes needed
4. System executes minimal workflow

---

## **18. Anti-Patterns to Avoid**

❌ **Skipping human approval gates** - Wastes effort if requirements wrong
❌ **Mixing agent responsibilities** - PM writing code, Engineers defining requirements
❌ **Bypassing safety/governance** - Creates liability and risk
❌ **Ignoring schema validation** - Causes downstream failures
❌ **Single monolithic prompt** - Loses modularity and clarity
❌ **No rollback plan** - Deployment failures become crises
❌ **Assuming user intent** - Always ask clarifying questions

---

## **19. Philosophy: AI-Native Team Design**

This is not prompt engineering. This is **AI-native team design**.

Traditional teams have:
- Clear roles (PM, Architect, Engineers, QA, DevOps)
- Handoff protocols (tickets, specs, reports)
- Quality gates (code review, testing, deployment approval)
- Collaboration norms (standups, retros, documentation)

AI-native teams have the same structure — just implemented with AI agents instead of humans.

**Benefits**:
- **Clarity**: Each agent knows exactly what to do
- **Quality**: Multiple checkpoints catch errors
- **Safety**: Built-in governance and risk management
- **Scalability**: Add projects without adding headcount
- **Speed**: Parallel execution, 24/7 operation

**Trade-offs**:
- **Setup cost**: More upfront structure than single prompt
- **Maintenance**: Schemas and agents need updates
- **Learning curve**: Understanding the system

**When to use**:
- Building production software (not prototypes)
- Need high quality and safety standards
- Want repeatable, scalable process
- Have complex, multi-stage workflows

---

**END OF META LAYER**

For agent-specific details, see:
- [L1 Specialist Agents](../L1%20-%20Specialist%20Agents/)
- [L2 Orchestration & Governance](../L2%20-%20Orchestration%20&%20Governance/)
- [L3 Contracts & Workflows](../L3%20-%20Workflows%20&%20Contracts/)
