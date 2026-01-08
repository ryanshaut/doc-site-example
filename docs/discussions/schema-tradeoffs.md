# Schema Flexibility vs Strictness

How rigid should your CMDB schema be? This fundamental design question affects everything from data quality to operational agility. Nexus CMDB takes a **pragmatic middle path** between rigid, strongly-typed schemas and fully flexible, schemaless designs.

## The Spectrum

```
├─────────────────────────────────────────────────────────────┤
Rigid                    Nexus                         Flexible
(Strongly Typed)    (Pragmatic Hybrid)          (Schemaless)
```

### Rigid Schema (Left Side)

**Philosophy**: Define everything upfront. Enforce strictly.

**Characteristics**:

- Every CI class has predefined, mandatory attributes
- Attribute types strictly enforced (string, integer, date)
- Enumerated values for categorical fields
- Foreign key constraints everywhere
- Changes require schema migration

**Example**:

```sql
CREATE TABLE servers (
  id INTEGER PRIMARY KEY,
  hostname VARCHAR(255) NOT NULL,
  ip_address INET NOT NULL CHECK (ip_address::text ~ '^(\d{1,3}\.){3}\d{1,3}$'),
  os_type VARCHAR(50) NOT NULL CHECK (os_type IN ('Linux', 'Windows', 'AIX')),
  memory_gb INTEGER NOT NULL CHECK (memory_gb > 0),
  environment VARCHAR(20) NOT NULL CHECK (environment IN ('Production', 'Staging', 'Development'))
);
```

**Benefits**:

- ✅ High data quality (garbage can't get in)
- ✅ Strong consistency guarantees
- ✅ Easy to write queries (know exactly what fields exist)
- ✅ Clear data contracts for integrations

**Drawbacks**:

- ❌ Slow to adapt to change
- ❌ Requires schema migrations for new attributes
- ❌ Can't model heterogeneous environments
- ❌ Forces everything into predefined boxes

### Flexible Schema (Right Side)

**Philosophy**: Let data evolve organically. Validate at read-time.

**Characteristics**:

- CIs are JSON documents with arbitrary structure
- No predefined attributes (except maybe name/id)
- Any attribute can be added anytime
- Type checking optional or none
- No migrations needed

**Example**:

```json
{
  "name": "server-01",
  "whatever_you_want": "any value",
  "nested": {
    "arbitrary": {
      "structure": true
    }
  },
  "new_field_added_today": "no problem"
}
```

**Benefits**:

- ✅ Extremely agile
- ✅ Easy to onboard new data sources
- ✅ No schema migrations
- ✅ Handles heterogeneous data naturally

**Drawbacks**:

- ❌ Poor data quality (garbage easily gets in)
- ❌ Inconsistent data across CIs
- ❌ Hard to write reliable queries
- ❌ Difficult to build integrations (no contract)

## Nexus's Pragmatic Hybrid

Nexus combines the strengths of both approaches:

### Core Principles

1. **Required Core Attributes**: Every CI has `name`, `ci_class`, `created_at`, `updated_at`
2. **Class-Specific Required Attributes**: Each CI class defines mandatory fields
3. **Optional Extensible Attributes**: Any CI can have additional custom attributes
4. **Type Hints with Flexibility**: Attributes have types, but enforcement is configurable
5. **Validation Rules**: Enforce quality without schema rigidity

### Example: Server CI Class

**Core Schema** (required):

```yaml
ci_class: Server
required_attributes:
  - name: string (unique, 3-128 chars)
  - ci_class: enum (always "Server")
  - ip_address: ipv4 (valid IP format)
  - operating_system: string (non-empty)
  - environment: enum (Production, Staging, Development)
```

**Recommended Attributes** (optional but validated if present):

```yaml
recommended_attributes:
  - cpu_cores: integer (min: 1, max: 256)
  - memory_gb: integer (min: 1)
  - owner: string
  - datacenter: string
```

**Extensible Attributes** (completely flexible):

```yaml
custom_attributes:
  - anything: any_type
  - your_team: can_add
  - no_schema: required
```

### Real-World Example

All valid Server CIs in Nexus:

```json
// Minimal (only required fields)
{
  "name": "minimal-server-01",
  "ci_class": "Server",
  "ip_address": "10.0.1.10",
  "operating_system": "Ubuntu 22.04",
  "environment": "Production"
}

// Recommended fields included
{
  "name": "standard-server-01",
  "ci_class": "Server",
  "ip_address": "10.0.1.11",
  "operating_system": "RHEL 8",
  "environment": "Production",
  "cpu_cores": 8,
  "memory_gb": 32,
  "owner": "Platform Team"
}

// Custom extensions
{
  "name": "extended-server-01",
  "ci_class": "Server",
  "ip_address": "10.0.1.12",
  "operating_system": "Windows Server 2022",
  "environment": "Production",
  "cpu_cores": 16,
  "memory_gb": 64,
  // Custom attributes your organization added:
  "cost_center": "CC-1001",
  "backup_policy": "daily-retain-30",
  "compliance_zone": "PCI-DSS",
  "patch_window": "Sunday 02:00-06:00 UTC",
  "monitoring_profile": "high-availability"
}
```

## When to Use Each Approach

### Use Rigid Schema When

**Regulatory Requirements**

If you're in healthcare (HIPAA), finance (SOX), or other regulated industries:

- Auditors require well-defined data structures
- Compliance reports need consistent field names
- Missing data can mean non-compliance

**Integration-Heavy Environments**

If many systems consume your CMDB:

- API consumers need stable contracts
- Changes break downstream integrations
- Versioned APIs are complex to maintain

**Homogeneous Infrastructure**

If your environment is standardized:

- All servers look similar
- Limited technology diversity
- Standard operating procedures apply uniformly

### Use Flexible Schema When

**Rapid Innovation**

If your organization moves fast:

- Weekly infrastructure changes
- Frequent new technology adoption
- Experimentation is common

**Heterogeneous Environments**

If you have diverse infrastructure:

- Multiple cloud providers
- Bare metal + VMs + containers + serverless
- Legacy and modern tech coexisting
- Acquired companies with different standards

**Early-Stage CMDB**

If you're just starting:

- Don't know what you need to track yet
- Learning through trial and error
- Requirements evolve quickly

### Use Nexus's Hybrid When

**Most Organizations** (the pragmatic middle):

- Need some consistency (required fields)
- Need some flexibility (custom extensions)
- Balance stability with agility
- Have diverse but not chaotic environments

This is the sweet spot for most enterprises.

## Managing Flexibility in Nexus

### Set Validation Rules

Control data quality without schema rigidity:

```bash
curl -u admin:changeme \
  -X POST \
  -d '{
    "rule_name": "enforce_memory_minimum",
    "applies_to": "Server",
    "validation": {
      "field": "memory_gb",
      "condition": "value >= 2",
      "error_message": "Servers must have at least 2 GB RAM"
    },
    "severity": "error"
  }' \
  http://localhost:8080/api/v1/validation-rules
```

Now `memory_gb` is optional, but if provided, must be ≥ 2.

### Use Custom Attributes Wisely

**Good Use Cases**:

- Team-specific metadata
- Temporary tracking during migrations
- Organization-specific fields
- Integration-specific identifiers

**Example**:

```json
{
  "name": "web-prod-01",
  "ci_class": "Server",
  // Standard fields...
  "ip_address": "10.0.1.10",
  "operating_system": "Ubuntu 22.04",
  "environment": "Production",
  // Custom: Your team tracks these
  "chef_node_id": "node-a1b2c3d4",
  "servicenow_id": "cmdb_ci_12345",
  "terraform_resource": "aws_instance.web_prod[0]",
  "cost_allocation_tag": "team-platform"
}
```

**Bad Use Cases**:

- Duplicating standard attributes with different names
- Storing ephemeral data (use separate time-series DB)
- Embedding large blobs (use object storage + reference)

### Standardize Gradually

Start flexible, standardize over time:

1. **Month 1-3**: Collect data flexibly, see what patterns emerge
2. **Month 4-6**: Identify common attributes, create recommendations
3. **Month 7-9**: Add validation rules for important fields
4. **Month 10-12**: Promote frequent custom attributes to standard schema

This bottom-up approach prevents premature standardization.

## Trade-offs in Practice

### Data Quality vs Agility

**Rigid Schema**:

```
┌─────────────────────────────────────┐
│ High Data Quality                   │
│ ████████████████████████ 95%        │
│                                     │
│ Low Agility                         │
│ ███ 15%                             │
└─────────────────────────────────────┘
```

**Flexible Schema**:

```
┌─────────────────────────────────────┐
│ Low Data Quality                    │
│ ████ 20%                            │
│                                     │
│ High Agility                        │
│ ███████████████████████ 92%         │
└─────────────────────────────────────┘
```

**Nexus Hybrid**:

```
┌─────────────────────────────────────┐
│ Good Data Quality                   │
│ ████████████████ 70%                │
│                                     │
│ Good Agility                        │
│ ████████████████ 70%                │
└─────────────────────────────────────┘
```

You trade some perfection for practical balance.

### Query Complexity

**Rigid Schema** (easy queries):

```sql
SELECT * FROM servers
WHERE environment = 'Production'
  AND memory_gb >= 64
  AND datacenter = 'us-east-1';
```

**Flexible Schema** (complex queries):

```sql
SELECT * FROM cis
WHERE attributes->>'environment' = 'Production'
  AND (attributes->>'memory_gb')::integer >= 64
  AND attributes->>'datacenter' = 'us-east-1';
```

**Nexus Hybrid** (balanced):

```sql
-- Required fields are first-class columns
SELECT * FROM cis
WHERE environment = 'Production'  -- Easy
  AND custom_attributes->>'memory_gb'::integer >= 64  -- Flexible
  AND location = 'us-east-1';  -- Easy if location promoted to standard
```

### Integration Stability

**Rigid Schema**: Stable, but changes require migrations

```python
# API response never changes structure
server = api.get_ci("web-01")
assert "ip_address" in server  # Always present
assert isinstance(server["memory_gb"], int)  # Always integer
```

**Flexible Schema**: Unstable, defensive programming needed

```python
# API response varies
server = api.get_ci("web-01")
ip = server.get("ip_address") or server.get("ipAddress") or server.get("ip")
memory = int(server.get("memory_gb", 0)) if server.get("memory_gb") else None
```

**Nexus Hybrid**: Core fields stable, extensions flexible

```python
# Core fields guaranteed
server = api.get_ci("web-01")
assert "ip_address" in server  # Always present
assert "environment" in server  # Always present

# Custom fields optional
cost_center = server.get("cost_center")  # May or may not exist
```

## Common Mistakes

### Over-Engineering the Schema

**Mistake**: Defining 200 fields upfront, most never used

**Example**:

```yaml
server_schema:
  required_fields: 87  # Way too many!
  optional_fields: 143
  enum_values: 2,341
  validation_rules: 156
```

**Result**: Nobody uses the CMDB because data entry is painful.

**Better**: Start with 5-10 required fields, let custom attributes emerge.

### No Schema at All

**Mistake**: "Just put everything in JSON, we'll figure it out later"

**Example**:

```json
{"srv": "web01", "ip": "10.0.1.10", "os": "linux"}
{"server_name": "WEB-02", "IP_ADDRESS": "10.0.1.11", "OperatingSystem": "Linux"}
{"name": "web-03", "address": "10.0.1.12", "platform": "Ubuntu"}
```

**Result**: Queries don't work, data is inconsistent, teams lose trust.

**Better**: Define at least `name`, `ci_class`, and a few core fields.

### Premature Standardization

**Mistake**: Standardizing before understanding needs

**Example**:

```yaml
# Month 1: Define rigid schema
server_required:
  - purchase_date
  - warranty_expiration
  - vendor
  - service_tag

# Month 3: Realize most servers are cloud VMs, these fields don't apply
```

**Better**: Collect data flexibly for 3-6 months, then standardize based on actual usage.

## Evolution Strategy

### Phase 1: Discovery (Months 1-3)

- Minimal required fields
- Encourage custom attributes
- Document emerging patterns

### Phase 2: Standardization (Months 4-6)

- Identify common custom attributes
- Promote to recommended fields
- Add validation rules

### Phase 3: Enforcement (Months 7-12)

- Require important fields
- Deprecate inconsistent custom attributes
- Establish data quality metrics

### Phase 4: Maturity (Ongoing)

- Continuous improvement
- Regular schema reviews
- Balance stability with evolution

## Conclusion

There's no perfect answer to "how rigid should the schema be?" It depends on:

- Your organizational maturity
- Rate of change in your environment
- Regulatory requirements
- Integration needs
- Cultural factors (move fast vs. measure twice)

Nexus CMDB's hybrid approach offers:

- **Enough structure** for consistency and quality
- **Enough flexibility** for agility and evolution
- **Configurable enforcement** to match your needs

Start flexible, standardize based on evidence, and evolve continuously.

## See Also

- [Validation Rules Reference](../reference/validation-rules.md): Technical details on enforcing quality
- [CI Classes Reference](../reference/ci-classes.md): Standard schema definitions
- [Design Philosophy](design-philosophy.md): Core principles behind Nexus's design
