# Design Philosophy

Nexus CMDB's design reflects lessons learned from decades of failed CMDB implementations. Every feature, API design, and architectural decision aims to avoid common pitfalls while enabling operational excellence.

## Core Principles

### 1. Operational Value First

**Philosophy**: A CMDB exists to support operations, not compliance or documentation.

**Implications**:

- Every feature must answer: "How does this help during an incident?"
- Compliance is a side effect of operational usefulness
- Documentation that doesn't drive actions is overhead

**Examples**:

- **Relationship modeling** enables impact analysis during changes
- **Dependency graphs** show blast radius during outages
- **Change tracking** provides audit trail AND rollback capability

**Anti-Pattern We Avoid**: "Compliance theater" CMDBs that exist only for audits

---

### 2. Pragmatic, Not Perfect

**Philosophy**: Good enough data that's used beats perfect data that isn't.

**Implications**:

- Launch with 70% coverage, not 100%
- Flexible schema that evolves
- Automated discovery with human curation
- Incremental improvement over big-bang perfection

**Examples**:

- **Hybrid schema**: Required core + flexible extensions
- **Validation rules**: Enforced quality without rigidity
- **Soft delete**: Grace period instead of immediate destruction

**Quote**: "The perfect is the enemy of the good" — Voltaire

**Anti-Pattern We Avoid**: "Perfect data trap" that delays launch indefinitely

---

### 3. Federated Ownership

**Philosophy**: Teams own their services' CIs; central team provides governance and tooling.

**Implications**:

- Direct API access for automation
- Self-service UI for manual changes
- Ownership metadata on every CI
- No central bottleneck for data entry

**Ownership Model**:

```yaml
Platform Team:
  - Owns: All server CIs
  - Updates: Via Terraform + API
  - Responsibility: Keep compute layer accurate

Engineering Teams:
  - Owns: Application CIs
  - Updates: Via CI/CD pipelines
  - Responsibility: Model app dependencies

Data Team:
  - Owns: Database CIs
  - Updates: Via Ansible + API
  - Responsibility: Track data stores

CMDB Central Team:
  - Owns: Schema, standards, governance
  - Updates: Validation rules, documentation
  - Responsibility: Enable teams, not do their work
```

**Anti-Pattern We Avoid**: "Ivory tower" model where central team enters all data

---

### 4. API-First Design

**Philosophy**: Humans use the UI sometimes. Automation uses the API always.

**Implications**:

- Every UI feature has API equivalent
- API documentation is first-class
- Automation is easier than manual processes
- Breaking API changes are avoided at all costs

**Design Principle**: "If you can't API it, don't build it"

**Examples**:

```bash
# Everything is API-accessible
POST /api/v1/cis                    # Create CI
GET  /api/v1/cis/{id}               # Read CI
PATCH /api/v1/cis/{id}              # Update CI
DELETE /api/v1/cis/{id}             # Delete CI
POST /api/v1/cis/batch-update       # Bulk operations
GET  /api/v1/cis/{id}/dependencies  # Relationship queries
```

**Anti-Pattern We Avoid**: UI-only features that can't be automated

---

### 5. Relationships Are First-Class Citizens

**Philosophy**: CIs without relationships are just asset inventory. Relationships enable operational intelligence.

**Implications**:

- Relationships have metadata (criticality, connection details)
- Bidirectional querying (upstream/downstream)
- Impact analysis built-in
- Relationship validation

**Why This Matters**:

Without relationships:

```
Q: "Can I reboot db-prod-01 safely?"
A: "It's a database. I don't know what depends on it."
```

With relationships:

```
Q: "Can I reboot db-prod-01 safely?"
A: "No. 3 applications depend on it, affecting 12 services and 2,000 users."
```

See [Why Relationship Modeling Matters](relationship-modeling.md) for deep dive.

**Anti-Pattern We Avoid**: Treating CMDB as a glorified spreadsheet

---

### 6. Automation + Human Curation

**Philosophy**: Automate the toil, curate the meaning.

**What to Automate**:

- Discovery of infrastructure
- CI creation from IaC tools
- Attribute updates from monitoring
- Relationship detection from network traces

**What Requires Humans**:

- Business context (why does this exist?)
- Application modeling (logical services)
- Criticality classification
- Relationship semantics (depends vs hosts)

**Example**:

```yaml
Automated (Discovery):
  Found: 500 VMs in AWS
  Attributes: instance_id, ip_address, os, region

Human Curation:
  Exclude: 300 CI/CD ephemeral VMs
  Tag remaining 200: environment, owner, cost_center
  Model: Application-to-VM relationships
  Classify: Production vs non-production
```

**Anti-Pattern We Avoid**:

- "Discovery tool IS the CMDB" (over-automation)
- "Manual data entry only" (under-automation)

---

### 7. Fail Loudly, Recover Gracefully

**Philosophy**: Errors should be obvious. Recovery should be easy.

**Error Handling**:

- Validation errors at write-time, not read-time
- Clear error messages with remediation steps
- Failed operations don't corrupt data

**Recovery Mechanisms**:

- Soft delete with 30-day retention
- Audit log for all changes
- Rollback capability for bulk operations
- Export before destructive actions

**Example Error Message**:

```json
{
  "error": "validation_failed",
  "message": "CI name must match convention",
  "field": "name",
  "provided_value": "WEBSERVER-01",
  "expected_pattern": "^[a-z]{3}-[a-z]{2,10}-[a-z]{4}-\\d{2}$",
  "example_valid_names": [
    "prd-web-use1-01",
    "stg-app-euc1-03"
  ],
  "documentation": "https://docs.nexus-cmdb.io/how-to/migrate-naming-conventions/"
}
```

Bad error message: `Validation failed`

**Anti-Pattern We Avoid**: Silent failures, cryptic errors, irreversible mistakes

---

### 8. Consistency Without Rigidity

**Philosophy**: Standardize what matters, allow flexibility everywhere else.

**Enforced Consistency**:

- CI naming conventions
- Required core attributes
- Relationship semantics
- API contracts

**Allowed Flexibility**:

- Custom attributes
- Team-specific metadata
- Organization-specific CI classes
- Extension hooks

See [Schema Flexibility vs Strictness](schema-tradeoffs.md) for details.

**Anti-Pattern We Avoid**:

- "Mega schema" that forces everything into rigid boxes
- "No governance" chaos where nothing is standardized

---

### 9. Security and Governance, Not Gatekeeping

**Philosophy**: Control access, audit actions, but don't slow teams down.

**Security Model**:

```yaml
Permissions:
  Read: Most users (default allow)
  Create/Update: Teams own their CIs (federated)
  Delete: Requires approval (protected)
  Admin: Schema changes (restricted)

Audit:
  - Every change logged
  - Who, what, when, why
  - Immutable audit trail
  - Retention: 7 years
```

**Governance**:

- Validation rules (automated)
- Data quality dashboards (transparent)
- Regular audits (scheduled)
- Training and documentation (enablement)

**Not This**:

```yaml
Bad Governance:
  - Ticket required for every change
  - 3-day SLA for updates
  - Central team reviews all changes
  - Manual approval gates

Result: Teams bypass the CMDB entirely
```

**Anti-Pattern We Avoid**: Using security as excuse for slow processes

---

### 10. Evolutionary Architecture

**Philosophy**: Design for change, not for eternity.

**Design Decisions**:

- **Versioned APIs**: `/api/v1`, `/api/v2` (deprecate gracefully)
- **Extensible schemas**: Custom attributes, not schema migrations
- **Plugin architecture**: Extend without forking
- **Feature flags**: Roll out gradually, rollback easily

**Example Evolution**:

```
Year 1: Basic CI and relationship modeling
Year 2: Add graph querying capabilities
Year 3: Integrate ML-based relationship discovery
Year 4: Add temporal querying (CI state at any point in time)

All without breaking existing integrations
```

**Anti-Pattern We Avoid**: Designs that require rewrites for new features

---

## Design Decisions in Practice

### Why We Chose REST Over GraphQL

**Decision**: Primary API is RESTful, GraphQL available for complex queries

**Rationale**:

- REST is universally understood
- Simpler for straightforward CRUD
- GraphQL adds complexity for common cases
- Offer both: use right tool for each job

### Why We Require CI Classes

**Decision**: Every CI must have a `ci_class` (Server, Application, etc.)

**Rationale**:

- Enables schema validation
- Simplifies queries
- Provides structure without rigidity
- Alternative (everything is generic) leads to chaos

### Why Soft Delete Is Default

**Decision**: Deleted CIs are marked deleted, not immediately purged

**Rationale**:

- Accidental deletes are common
- Recovery should be easy
- Audit trail requires retention
- After 30 days, hard delete automatically

### Why We Allow Custom Attributes

**Decision**: CIs can have arbitrary custom attributes beyond schema

**Rationale**:

- Organizations have unique needs
- Premature standardization is harmful
- Custom attributes can become standard later
- Flexibility enables adoption

---

## What We Intentionally Don't Do

### We Don't Try to Be Everything

**Not a Monitoring Tool**: Integrate with Prometheus, Datadog, etc.

**Not a Ticketing System**: Integrate with Jira, ServiceNow, etc.

**Not a Secret Store**: Integrate with Vault, AWS Secrets Manager, etc.

**Philosophy**: Do one thing well (CMDB), integrate with best-of-breed for everything else.

### We Don't Abstract Away Complexity

**Bad Design**: Hide all details, make everything "simple"

**Our Approach**: Provide powerful primitives, good defaults, clear documentation

**Rationale**: Operations is complex. Hiding complexity doesn't eliminate it, it just makes it harder to debug.

### We Don't Force a Workflow

**Bad Design**: "You must use CMDB in this exact sequence of steps"

**Our Approach**: Provide flexible tools, let teams design their workflows

**Examples**:

- Some teams: IaC → CMDB (push model)
- Other teams: CMDB → IaC (pull model)
- Either works

---

## Inspiration

Nexus CMDB draws inspiration from:

- **Unix Philosophy**: Do one thing well, compose with other tools
- **REST**: Resources, not RPC; stateless, cacheable
- **Git**: Distributed ownership, audit trail, easy rollback
- **AWS**: API-first, self-service, pay-per-use
- **Kubernetes**: Declarative desired state, reconciliation loops

And learns from failures of:

- Overly complex enterprise CMDB tools
- Rigid schema-first designs
- Centralized bottleneck models
- Tools that exist only for compliance

---

## Measuring Success

A successful CMDB is:

1. **Used Daily**: Teams reference it during incidents, changes, planning
2. **Trusted**: Data quality >85%, teams rely on accuracy
3. **Automated**: >80% of updates from automation, not manual entry
4. **Fast**: API responses <100ms, UI interactions <1s
5. **Integrated**: Connected to change management, monitoring, IaC
6. **Maintained**: Daily updates, weekly audits, continuous improvement
7. **Valuable**: Measurable reduction in MTTR, change failures, costs

Nexus's design optimizes for these outcomes.

---

## Living Document

This philosophy evolves as we learn. We:

- Review design decisions quarterly
- Learn from user feedback
- Adapt to industry changes
- Maintain backward compatibility

Our commitment: Operational value first, pragmatism over perfection, enable teams without gatekeeping.

---

## See Also

- [CMDB Anti-Patterns](anti-patterns.md): What we actively avoid
- [Why Relationship Modeling Matters](relationship-modeling.md): A key design principle
- [Schema Flexibility vs Strictness](schema-tradeoffs.md): Balancing consistency and agility
