# Architecture Conventions & Standards

**Version**: 1.0
**Last Updated**: 2025-12-02

---

## Purpose & Scope

This document defines **how architecture work is done** in the AI-native development system. It complements [system-architect.md](../../L1%20-%20Specialist%20Agents/system-architect.md) (the role spec) by providing:

- Standards for architecture artifacts
- Conventions for component design
- Handoff requirements for downstream agents
- Validation checklists

**Where this fits in the layer model:**

```
L0 (Meta Layer)     → Global rules, principles
L1 (Specialist)     → system-architect.md defines WHO and WHEN
L3 (Workflows)      → architecture.md defines HOW and WHAT (this file)
                    → contracts/ defines the SCHEMA
```

---

## Inputs

### Required Inputs

| Input | Source | Schema |
|-------|--------|--------|
| Product Requirements | Product Manager | [pm-output-schema.json](../contracts/pm-output-schema.json) |

### Conditional Inputs (fast_feature mode)

| Input | Source | Schema |
|-------|--------|--------|
| Existing Architecture | Previous workflow | [architect-output-schema.json](../contracts/architect-output-schema.json) |
| Code Health Report | Code Health Agent | (if available) |

---

## Outputs

### full_system Mode

| Output | Location | Schema |
|--------|----------|--------|
| Architecture Handover Packet | `ARTIFACTS/system-architect/architecture-handover-packet.json` | [architect-output-schema.json](../contracts/architect-output-schema.json) |
| Stage Completion Signal | `ARTIFACTS/system/stage-completion-signal.json` | [stage-completion-signal-schema.json](../contracts/stage-completion-signal-schema.json) |

### fast_feature Mode

| Output | Location | Schema |
|--------|----------|--------|
| Architecture Assessment | `ARTIFACTS/system-architect/architecture-assessment.json` | [architecture-assessment-schema.json](../contracts/architecture-assessment-schema.json) |
| Stage Completion Signal | `ARTIFACTS/system/stage-completion-signal.json` | [stage-completion-signal-schema.json](../contracts/stage-completion-signal-schema.json) |

---

## Execution Modes

### full_system Mode

**When to use:**
- New product from scratch
- Major redesign or refactoring
- Greenfield projects
- No existing architecture to assess against

**Process outline:**
1. Read product requirements packet
2. Identify architectural drivers (NFRs, constraints, scale)
3. Design 2-3 architecture options with trade-offs
4. Present options to human for selection
5. Generate detailed architecture handover packet
6. Signal completion

**Human gate:** Required before proceeding to implementation.

### fast_feature Mode

**When to use:**
- Adding feature to existing product
- Bug fixes requiring architecture assessment
- Incremental development

**Process outline:**
1. Read product requirements packet
2. Read existing architecture handover packet
3. Assess impact: `none` | `minor` | `major`
4. Generate architecture assessment
5. Signal completion with next action

**Decision tree:**

```
architecture_impact = "none"   → Proceed to implementation
architecture_impact = "minor"  → Document changes, proceed to implementation
architecture_impact = "major"  → Switch to full_system mode
```

**Human gate:** Not required unless `architecture_impact = "major"`.

---

## Architecture Standards

### 1. Component Boundaries

Components must have clear boundaries based on responsibility:

| Layer | Responsibility | Agents |
|-------|---------------|--------|
| Frontend | UI, client state, user interaction | Frontend Engineer |
| Backend API | Business logic, data access, auth | Backend Engineer |
| AI/ML | Model inference, prompt handling, embeddings | AI Engineer |
| Data | Persistence, caching, search | Backend Engineer |
| Infrastructure | Deployment, scaling, monitoring | DevOps Engineer |

**Rules:**
- Each component has a single owner agent
- Cross-boundary communication happens via defined APIs only
- No direct database access from frontend
- AI components expose APIs, not raw model access

### 2. Component Map Convention

Document components using this structure:

```
System Components
├── Frontend
│   ├── [component-name]: [purpose]
│   └── ...
├── Backend API
│   ├── [service-name]: [purpose]
│   └── ...
├── Data Stores
│   ├── [database-name]: [type] - [purpose]
│   └── ...
├── AI/ML (if applicable)
│   ├── [model/service]: [purpose]
│   └── ...
└── External Integrations
    ├── [service]: [purpose]
    └── ...
```

**Example:**

```
System Components
├── Frontend
│   ├── web-app: React SPA for end users
│   └── admin-dashboard: Internal admin interface
├── Backend API
│   ├── api-gateway: Request routing, auth, rate limiting
│   ├── user-service: User management, profiles
│   └── order-service: Order processing, payments
├── Data Stores
│   ├── postgres-main: PostgreSQL - Primary relational data
│   ├── redis-cache: Redis - Session cache, rate limiting
│   └── s3-assets: S3 - File storage
├── AI/ML
│   └── recommendation-service: Product recommendations
└── External Integrations
    ├── stripe: Payment processing
    └── sendgrid: Email delivery
```

### 3. API Contract Conventions

All APIs must follow these conventions:

**Endpoint naming:**
- Use kebab-case: `/api/user-profiles`
- Use plural nouns for collections: `/api/orders`
- Use path params for resources: `/api/orders/{order_id}`
- Version prefix for breaking changes: `/api/v2/orders`

**Request/Response format:**
- JSON for all payloads
- Consistent error response structure:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable message",
    "details": {}
  }
}
```

**HTTP status codes:**
- 200: Success with body
- 201: Created
- 204: Success, no content
- 400: Bad request (validation)
- 401: Unauthorized
- 403: Forbidden
- 404: Not found
- 409: Conflict
- 500: Internal server error

**Authentication:**
- Document auth strategy in `security_and_privacy.authentication`
- Specify which endpoints require auth
- Define token format and expiry

### 4. Data Model Conventions

**Naming:**
- Use snake_case for field names
- Use singular nouns for model names: `User`, `Order`
- Prefix IDs with entity type: `user_id`, `order_id`

**Required fields for all models:**
- `id`: Primary identifier
- `created_at`: Timestamp of creation
- `updated_at`: Timestamp of last update

**Relationships:**
- Document explicitly: `one_to_one`, `one_to_many`, `many_to_many`
- Include foreign key field names
- Specify cascade behavior for deletes

**Example model definition:**

```json
{
  "name": "Order",
  "description": "Customer order with line items",
  "fields": [
    {"name": "id", "type": "uuid", "required": true, "description": "Primary key"},
    {"name": "user_id", "type": "uuid", "required": true, "description": "FK to User"},
    {"name": "status", "type": "enum", "required": true, "constraints": "pending|processing|shipped|delivered|cancelled"},
    {"name": "total_amount", "type": "decimal(10,2)", "required": true},
    {"name": "created_at", "type": "timestamp", "required": true},
    {"name": "updated_at", "type": "timestamp", "required": true}
  ],
  "relationships": [
    {"type": "many_to_one", "target_model": "User"},
    {"type": "one_to_many", "target_model": "OrderItem"}
  ],
  "indexes": ["user_id", "status", "created_at"]
}
```

### 5. NFR to Architecture Mapping

Translate non-functional requirements into architectural decisions:

| NFR | Architectural Decision |
|-----|----------------------|
| Latency < 200ms | CDN, edge caching, database indexes, connection pooling |
| 99.9% uptime | Multi-AZ deployment, health checks, auto-restart, circuit breakers |
| 10K concurrent users | Horizontal scaling, load balancer, stateless services |
| Data privacy (GDPR) | Encryption at rest/transit, audit logs, data residency, deletion APIs |
| Explainability | Structured logging, request tracing, decision audit trail |
| Safety | Input validation, rate limiting, content filtering, abuse detection |

Document the mapping in `architecture_overview.key_decisions`.

### 6. Security Checklist

Every architecture must address:

- [ ] Authentication strategy defined (JWT/OAuth/Session)
- [ ] Authorization model defined (RBAC/ABAC/Permissions)
- [ ] Data encryption at rest specified
- [ ] Data encryption in transit (TLS) required
- [ ] Secrets management approach (env vars, vault)
- [ ] Input validation on all endpoints
- [ ] Rate limiting strategy
- [ ] CORS configuration
- [ ] API key management (if applicable)
- [ ] Compliance requirements listed

### 7. Observability Requirements

Every architecture must include:

**Logging:**
- Structured JSON logs
- Request ID correlation
- Log levels: debug, info, warn, error

**Metrics:**
- Request latency (p50, p95, p99)
- Error rates by endpoint
- Database query performance
- Cache hit rates

**Tracing:**
- Distributed tracing for cross-service calls
- Span context propagation

**Alerting:**
- Error rate thresholds
- Latency thresholds
- Resource utilization

---

## Handoff Checklist

### What Frontend Engineer Needs

| Section | Required | Notes |
|---------|----------|-------|
| `technology_stack.frontend` | Yes | Framework, language, libraries |
| `system_components` (frontend items) | Yes | What to build |
| `api_specifications` | Yes | Endpoints to integrate |
| `data_models` | Partial | Client-side models, form schemas |
| `security_and_privacy.authentication` | Yes | Token handling, auth flows |
| `performance_and_scalability` | Partial | Caching, CDN strategy |

### What Backend Engineer Needs

| Section | Required | Notes |
|---------|----------|-------|
| `technology_stack.backend` | Yes | Framework, language, libraries |
| `technology_stack.database` | Yes | Database type, name |
| `system_components` (backend items) | Yes | Services to build |
| `api_specifications` | Yes | Endpoints to implement |
| `data_models` | Yes | Full schema definitions |
| `security_and_privacy` | Yes | Auth, authz, encryption |
| `performance_and_scalability` | Yes | Caching, indexing, pooling |

### What AI Engineer Needs

| Section | Required | Notes |
|---------|----------|-------|
| `technology_stack.ai_ml` | Yes | Models, frameworks |
| `system_components` (AI items) | Yes | Services to build |
| `api_specifications` (AI endpoints) | Yes | Inference APIs |
| `data_models` (AI-related) | Partial | Embeddings, prompts storage |
| `security_and_privacy` | Partial | Prompt injection prevention, content safety |

### What DevOps Engineer Needs

| Section | Required | Notes |
|---------|----------|-------|
| `technology_stack.infrastructure` | Yes | Cloud provider, services |
| `deployment_architecture` | Yes | Strategy, environments, scaling |
| `system_components` (all) | Yes | What to deploy |
| `performance_and_scalability` | Yes | Scaling, load balancing |
| `security_and_privacy` | Partial | Secrets management, network security |

### What QA Engineer Needs

| Section | Required | Notes |
|---------|----------|-------|
| `api_specifications` | Yes | Endpoints to test |
| `data_models` | Yes | Validation rules, constraints |
| `engineering_work_breakdown` | Yes | Scope of testing |
| `security_and_privacy` | Yes | Security test requirements |

---

## Validation Requirements

### Schema Validation

Before handoff, validate outputs against schemas:

```bash
# Validate architecture handover packet
jsonschema -i architecture-handover-packet.json architect-output-schema.json

# Validate architecture assessment
jsonschema -i architecture-assessment.json architecture-assessment-schema.json

# Validate stage completion signal
jsonschema -i stage-completion-signal.json stage-completion-signal-schema.json
```

### Required Sections (full_system)

The architecture handover packet MUST include all required sections per [architect-output-schema.json](../contracts/architect-output-schema.json):

- [ ] `execution_mode`
- [ ] `architecture_overview` (with `description`, `architecture_style`, `key_decisions`)
- [ ] `system_components` (at least one)
- [ ] `data_models` (at least one)
- [ ] `api_specifications` (at least one)
- [ ] `technology_stack` (with `frontend`, `backend`, `database`)
- [ ] `deployment_architecture` (with `strategy`, `environments`)
- [ ] `security_and_privacy` (with `authentication`, `authorization`, `data_encryption`)
- [ ] `performance_and_scalability` (with `caching_strategy`, `database_optimization`)
- [ ] `risk_assessment` (at least one risk)
- [ ] `engineering_work_breakdown` (with `frontend_tasks`, `backend_tasks`)

### Required Sections (fast_feature)

The architecture assessment MUST include all required sections per [architecture-assessment-schema.json](../contracts/architecture-assessment-schema.json):

- [ ] `feature_name`
- [ ] `architecture_impact`
- [ ] `assessment` (with `fits_existing_architecture`, `required_changes`, `affected_components`, `risk_level`)
- [ ] `recommendations` (with `approach`, `estimated_complexity`)
- [ ] `timestamp`

### Stage Completion Signal

Every completion signal MUST include:

- [ ] `agent`: "system_architect"
- [ ] `stage`: "architecture"
- [ ] `status`: "completed" | "completed_with_warnings" | "failed" | "blocked"
- [ ] `timestamp`: ISO 8601 format
- [ ] `output_artifacts`: paths to generated files
- [ ] `next_agent_required` or `parallel_agents`

---

## References

- [system-architect.md](../../L1%20-%20Specialist%20Agents/system-architect.md) - Role specification
- [architect-output-schema.json](../contracts/architect-output-schema.json) - Handover packet schema
- [architecture-assessment-schema.json](../contracts/architecture-assessment-schema.json) - Assessment schema
- [stage-completion-signal-schema.json](../contracts/stage-completion-signal-schema.json) - Completion signal schema
- [pm-output-schema.json](../contracts/pm-output-schema.json) - Input requirements schema
- [claude.md](../../L0%20-%20Meta%20Layer/claude.md) - System principles

---

**END OF ARCHITECTURE CONVENTIONS**
