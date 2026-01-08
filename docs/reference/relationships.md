# Relationships

Relationships define connections between configuration items. They provide semantic meaning beyond simple foreign key references, enabling impact analysis, dependency tracking, and operational intelligence.

## Relationship Types

### depends_on

**Semantics**: Source CI requires target CI to function properly.

**Direction**: Unidirectional (source → target)

**Example**: `web-server-01 depends_on database-01`

**Implication**: If database-01 fails, web-server-01 is affected.

**Use Cases**:

- Application depends on database
- Service depends on API
- Process depends on configuration file

---

### hosts

**Semantics**: Source CI provides runtime environment for target CI.

**Direction**: Unidirectional (source → target)

**Example**: `vm-prod-01 hosts application-backend`

**Implication**: If vm-prod-01 reboots, application-backend is disrupted.

**Use Cases**:

- Server hosts application
- Container host runs containers
- VM runs services

---

### connects_to

**Semantics**: Source CI communicates with target CI.

**Direction**: Unidirectional (source → target)

**Example**: `web-server-01 connects_to cache-server-01`

**Implication**: Network path between CIs must be available.

**Use Cases**:

- Server connects to network switch
- Application connects to message queue
- Service connects to external API

---

### backed_by

**Semantics**: Source CI distributes load across multiple target CIs.

**Direction**: Bidirectional (creates inverse "backs" relationship)

**Example**: `load-balancer-01 backed_by [web-01, web-02, web-03]`

**Implication**: Source relies on availability of target pool.

**Use Cases**:

- Load balancer backed by web servers
- DNS backed by multiple name servers
- Service mesh backed by microservice instances

---

### member_of

**Semantics**: Source CI belongs to target group/cluster.

**Direction**: Unidirectional (source → target)

**Example**: `node-01 member_of kubernetes-cluster-prod`

**Implication**: Source shares fate with other cluster members.

**Use Cases**:

- Node member of cluster
- Server member of auto-scaling group
- Service member of service mesh

---

### parent_of / child_of

**Semantics**: Hierarchical relationship.

**Direction**: Bidirectional (automatically creates inverse)

**Example**: `organization parent_of department`

**Implication**: Organizational or compositional hierarchy.

**Use Cases**:

- Organizational units
- Resource hierarchies
- Component composition

---

## Relationship Metadata

Relationships can carry metadata for additional context:

### Criticality

Indicates importance of the relationship.

```json
{
  "source_ci": "app-prod-01",
  "target_ci": "db-prod-01",
  "relationship_type": "depends_on",
  "metadata": {
    "criticality": "high",
    "sla_impact": "critical"
  }
}
```

**Values**: `low`, `medium`, `high`, `critical`

---

### Connection Details

Technical information about the connection.

```json
{
  "source_ci": "app-prod-01",
  "target_ci": "postgres-prod-01",
  "relationship_type": "connects_to",
  "metadata": {
    "protocol": "postgresql",
    "port": 5432,
    "connection_pool_size": 20,
    "timeout_seconds": 30
  }
}
```

---

### Weight

Numeric weight for load distribution or priority.

```json
{
  "source_ci": "load-balancer-01",
  "target_ci": "web-prod-01",
  "relationship_type": "backed_by",
  "metadata": {
    "weight": 33
  }
}
```

**Use Case**: Load balancer distributes 33% of traffic to this backend.

---

### Temporal Information

Time-bounded relationships.

```json
{
  "source_ci": "license-server-01",
  "target_ci": "application-prod",
  "relationship_type": "licenses",
  "metadata": {
    "valid_from": "2026-01-01T00:00:00Z",
    "valid_until": "2026-12-31T23:59:59Z"
  }
}
```

---

## Relationship Schema

### Core Fields

```json
{
  "relationship_id": "rel_a1b2c3d4",
  "source_ci_id": "ci_123456",
  "source_ci_name": "web-prod-01",
  "target_ci_id": "ci_789012",
  "target_ci_name": "app-prod-01",
  "relationship_type": "depends_on",
  "created_at": "2026-01-07T10:30:00Z",
  "created_by": "automation@example.com",
  "metadata": {
    "criticality": "high"
  }
}
```

### Computed Fields

- `relationship_id`: Auto-generated unique identifier
- `created_at`: Timestamp of creation
- `updated_at`: Timestamp of last modification

---

## Querying Relationships

### Get Downstream Dependencies

**Question**: "What does this CI depend on?"

```bash
GET /api/v1/cis/{ci_id}/dependencies?direction=downstream&depth=3
```

**Response**:

```json
{
  "ci": "web-prod-01",
  "dependencies": [
    {
      "ci_name": "app-prod-01",
      "relationship": "depends_on",
      "depth": 1
    },
    {
      "ci_name": "db-prod-01",
      "relationship": "depends_on",
      "depth": 2
    }
  ]
}
```

---

### Get Upstream Dependencies

**Question**: "What depends on this CI?"

```bash
GET /api/v1/cis/{ci_id}/dependencies?direction=upstream&depth=3
```

**Response**:

```json
{
  "ci": "db-prod-01",
  "upstream": [
    {
      "ci_name": "app-prod-01",
      "relationship": "depends_on",
      "depth": 1
    },
    {
      "ci_name": "web-prod-01",
      "relationship": "depends_on",
      "depth": 2
    }
  ]
}
```

---

### Get All Relationships

```bash
GET /api/v1/cis/{ci_id}/relationships
```

Returns all relationships (both directions) for a CI.

---

## Relationship Validation

### Prevent Circular Dependencies

Nexus detects circular dependencies:

```
A depends_on B
B depends_on C
C depends_on A  ← Error: Creates cycle!
```

**Validation**: Rejected at creation time with error.

---

### Relationship Constraints

- **Source and target must exist**: Can't create relationship to non-existent CI
- **Type-specific constraints**: Some relationship types only valid between certain CI classes
- **Uniqueness**: Can't create duplicate relationships (same source, target, type)

---

## Relationship Lifecycle

### Creation

```bash
POST /api/v1/relationships
Content-Type: application/json

{
  "source_ci": "web-prod-01",
  "target_ci": "app-prod-01",
  "type": "depends_on",
  "metadata": {"criticality": "high"}
}
```

---

### Update

```bash
PATCH /api/v1/relationships/{relationship_id}
Content-Type: application/json

{
  "metadata": {"criticality": "critical"}
}
```

---

### Deletion

```bash
DELETE /api/v1/relationships/{relationship_id}
```

**Cascade Behavior**: When CI is deleted:

- `cascade=true`: Delete all relationships automatically
- `cascade=false`: Fail if relationships exist
- Default: Configured system-wide

---

## Best Practices

### Model Operationally Significant Relationships

✅ **Good**:

```
Application depends_on Database (affects availability)
Server hosts Application (affects deployment)
Load Balancer backed_by Web Servers (affects capacity)
```

❌ **Bad** (too granular):

```
Process-123 connects_to Socket-456
File-A references File-B
Thread-X waits_for Thread-Y
```

---

### Use Appropriate Relationship Types

Match semantics to reality:

- **depends_on**: Functional dependency (A needs B to work)
- **hosts**: Runtime environment (A provides platform for B)
- **connects_to**: Network communication (A talks to B)

Don't use generic "related_to"—be specific.

---

### Add Meaningful Metadata

Enrich relationships with context:

```json
{
  "metadata": {
    "criticality": "high",
    "protocol": "https",
    "port": 443,
    "purpose": "user_authentication",
    "fallback": "ldap_server_02"
  }
}
```

This metadata enables better automation and troubleshooting.

---

## See Also

- [CI Classes](ci-classes.md): CIs that relationships connect
- [Designing Advanced Relationships](../tutorials/advanced-relationships.md): Tutorial on relationship modeling
- [Why Relationship Modeling Matters](../discussions/relationship-modeling.md): Conceptual discussion
