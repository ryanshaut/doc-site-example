# Validation Rules

Validation rules enforce data quality and consistency in Nexus CMDB. They can be applied at the CI class level or globally, ensuring that data meets organizational standards.

## Rule Types

### Field Validation

Enforce constraints on individual attributes.

#### Pattern Matching

```json
{
  "rule_name": "enforce_naming_convention",
  "applies_to": "Server",
  "field": "name",
  "validation": {
    "type": "pattern",
    "pattern": "^(prd|stg|dev)-(web|app|db)-[a-z0-9]{4}-\\d{2}$",
    "error_message": "Name must follow convention: {env}-{type}-{region}-{number}"
  },
  "severity": "error"
}
```

#### Range Validation

```json
{
  "rule_name": "valid_port_range",
  "applies_to": "*",
  "field": "port",
  "validation": {
    "type": "range",
    "min": 1,
    "max": 65535,
    "error_message": "Port must be between 1 and 65535"
  },
  "severity": "error"
}
```

#### Required Fields

```json
{
  "rule_name": "production_requires_owner",
  "applies_to": "*",
  "condition": "environment == 'Production'",
  "validation": {
    "type": "required",
    "fields": ["owner", "cost_center"],
    "error_message": "Production CIs must have owner and cost_center"
  },
  "severity": "error"
}
```

---

### Uniqueness Constraints

Ensure attribute values are unique across CIs.

```json
{
  "rule_name": "unique_hostname",
  "applies_to": "Server",
  "validation": {
    "type": "unique",
    "field": "hostname",
    "scope": "environment",
    "error_message": "Hostname must be unique within environment"
  },
  "severity": "error"
}
```

**Scope Options**:

- `global`: Unique across all CIs
- `environment`: Unique within same environment
- `ci_class`: Unique within same CI class

---

### Cross-Field Validation

Validate relationships between fields.

```json
{
  "rule_name": "memory_cpu_ratio",
  "applies_to": "Server",
  "validation": {
    "type": "expression",
    "expression": "memory_gb / cpu_cores >= 2",
    "error_message": "Memory-to-CPU ratio must be at least 2:1"
  },
  "severity": "warning"
}
```

---

### Enumerated Values

Restrict field to predefined set of values.

```json
{
  "rule_name": "valid_environments",
  "applies_to": "*",
  "field": "environment",
  "validation": {
    "type": "enum",
    "allowed_values": ["Production", "Staging", "Development"],
    "error_message": "Environment must be Production, Staging, or Development"
  },
  "severity": "error"
}
```

---

## Severity Levels

### Error

Validation failure prevents operation.

**Use Case**: Critical data quality requirements

**Example**: Name format, required fields

---

### Warning

Validation failure logged but operation succeeds.

**Use Case**: Best practices, recommendations

**Example**: Recommended but not required fields

---

### Info

Informational only, no blocking.

**Use Case**: Suggestions, guidelines

---

## Rule Scope

### CI Class-Specific

Rule applies only to specific CI class:

```json
{
  "applies_to": "Server"
}
```

### Global

Rule applies to all CIs:

```json
{
  "applies_to": "*"
}
```

### Conditional

Rule applies only when condition is met:

```json
{
  "applies_to": "*",
  "condition": "environment == 'Production' AND ci_class == 'Database'"
}
```

---

## Managing Validation Rules

### Create Rule

```bash
POST /api/v1/validation-rules
Content-Type: application/json

{
  "rule_name": "enforce_naming_convention",
  "applies_to": "Server",
  "field": "name",
  "validation": {
    "type": "pattern",
    "pattern": "^[a-z0-9-]+$"
  },
  "severity": "error"
}
```

### List Rules

```bash
GET /api/v1/validation-rules
```

### Update Rule

```bash
PATCH /api/v1/validation-rules/{rule_id}
```

### Delete Rule

```bash
DELETE /api/v1/validation-rules/{rule_id}
```

### Disable Rule Temporarily

```bash
PATCH /api/v1/validation-rules/{rule_id}
Content-Type: application/json

{
  "enabled": false
}
```

---

## Validation Execution

### On Write

Validation runs automatically on:

- CI creation (`POST /api/v1/cis`)
- CI update (`PUT` or `PATCH /api/v1/cis/{id}`)
- Bulk operations (`POST /api/v1/cis/batch-update`)

### On Demand

Run validation against existing CIs:

```bash
POST /api/v1/validation/scan
Content-Type: application/json

{
  "filter": {
    "ci_class": "Server",
    "environment": "Production"
  }
}
```

Returns validation errors for matching CIs.

---

## Error Response Format

When validation fails:

```json
{
  "error": "validation_failed",
  "validation_errors": [
    {
      "rule": "enforce_naming_convention",
      "field": "name",
      "severity": "error",
      "message": "Name must follow convention: {env}-{type}-{region}-{number}",
      "provided_value": "webserver-01",
      "suggestion": "prd-web-use1-01"
    }
  ]
}
```

---

## Built-in Validation

Nexus includes default validation rules:

| Rule | Description | Can Override |
|------|-------------|--------------|
| `name_required` | CI must have name | ❌ No |
| `name_length` | Name 3-128 chars | ✅ Yes |
| `ci_class_required` | CI class required | ❌ No |
| `valid_ip_format` | IP addresses must be valid | ❌ No |
| `valid_email_format` | Email addresses must be valid | ❌ No |

---

## Best Practices

### Start Lenient, Tighten Over Time

1. **Month 1**: Warnings only
2. **Month 3**: Errors for critical fields
3. **Month 6**: Comprehensive validation

### Provide Clear Error Messages

❌ **Bad**: `Validation failed`

✅ **Good**: `Name must follow convention: {env}-{type}-{region}-{number}. Example: prd-web-use1-01`

### Test Rules Before Enforcing

Use severity "warning" to test impact before changing to "error".

---

## See Also

- [CI Classes](ci-classes.md): Schema definitions
- [Attribute Types](attribute-types.md): Data type validation
- [Migrating Naming Conventions](../how-to/migrate-naming-conventions.md): Enforcing standards
