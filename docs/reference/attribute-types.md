# Attribute Types

Attribute types define the data types available for CI attributes in Nexus CMDB. Each type has validation rules, formatting requirements, and serialization behavior.

## Primitive Types

### String

UTF-8 text data.

**Validation**:

- Min length: 0 (configurable)
- Max length: 65,535 characters
- Encoding: UTF-8

**Example**:

```json
{
  "hostname": "web-server-01.example.com",
  "description": "Production web server for ShopSphere"
}
```

---

### Integer

Whole numbers.

**Range**: -2,147,483,648 to 2,147,483,647 (32-bit signed)

**Example**:

```json
{
  "cpu_cores": 8,
  "port": 8080,
  "max_connections": 200
}
```

---

### Float

Decimal numbers.

**Precision**: Double-precision (64-bit)

**Example**:

```json
{
  "monthly_cost": 459.99,
  "cpu_utilization": 67.3,
  "latency_ms": 12.456
}
```

---

### Boolean

True or false values.

**Allowed Values**: `true`, `false`

**Example**:

```json
{
  "is_production": true,
  "monitoring_enabled": false,
  "auto_scaling": true
}
```

---

### Datetime

Timestamps for dates and times.

**Format**: ISO 8601 (RFC 3339)

**Example**:

```json
{
  "created_at": "2026-01-07T10:30:00Z",
  "last_patched": "2026-01-01T02:00:00Z",
  "expiration_date": "2027-12-31T23:59:59Z"
}
```

**Timezone**: Always stored in UTC. Client-side conversion recommended.

---

## Specialized Types

### IPv4 Address

Internet Protocol version 4 address.

**Format**: Dotted decimal notation (e.g., `192.168.1.1`)

**Validation**: Must be valid IPv4 address

**Example**:

```json
{
  "ip_address": "10.0.1.42",
  "gateway": "10.0.1.1",
  "dns_server": "8.8.8.8"
}
```

---

### IPv6 Address

Internet Protocol version 6 address.

**Format**: Colon-hexadecimal notation

**Example**:

```json
{
  "ipv6_address": "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
}
```

---

### Email

Email address.

**Validation**: RFC 5322 compliant

**Example**:

```json
{
  "owner_email": "platform-team@example.com",
  "alert_contact": "ops@example.com"
}
```

---

### URL

Uniform Resource Locator.

**Validation**: Valid URL format with scheme

**Example**:

```json
{
  "repository": "https://github.com/example/repo",
  "api_endpoint": "https://api.example.com/v1",
  "documentation": "https://docs.example.com"
}
```

---

## Collection Types

### Array

Ordered list of values.

**Syntax**: `array<type>`

**Example**:

```json
{
  "tags": ["production", "monitored", "critical"],
  "ip_addresses": ["10.0.1.10", "10.0.1.11"],
  "ports": [80, 443, 8080]
}
```

---

### Object

Nested JSON object.

**Example**:

```json
{
  "metadata": {
    "cost_center": "CC-1001",
    "project": "ShopSphere",
    "environment_details": {
      "region": "us-east-1",
      "availability_zone": "us-east-1a"
    }
  }
}
```

---

## Enumerated Types

### Enum

Predefined set of allowed values.

**Definition**:

```json
{
  "environment": {
    "type": "enum",
    "values": ["Production", "Staging", "Development"]
  }
}
```

**Usage**:

```json
{
  "environment": "Production"
}
```

**Validation**: Value must exactly match one of the allowed values (case-sensitive).

---

## Type Coercion

Nexus performs automatic type coercion where unambiguous:

| Input | Declared Type | Coerced To | Valid? |
|-------|---------------|------------|--------|
| `"42"` | integer | `42` | ✅ Yes |
| `"3.14"` | float | `3.14` | ✅ Yes |
| `"true"` | boolean | `true` | ✅ Yes |
| `42` | string | `"42"` | ✅ Yes |
| `"not-a-number"` | integer | (error) | ❌ No |

---

## Null Values

Attributes can be `null` unless explicitly marked as required.

**Example**:

```json
{
  "name": "server-01",
  "owner": null,  // Allowed if owner is optional
  "cpu_cores": null  // Allowed if cpu_cores is optional
}
```

**API Behavior**:

- Omitted fields: Treated as `null`
- Explicit `null`: Clears existing value
- Empty string `""`: Different from `null`

---

## Custom Validation

Beyond type checking, validation rules can enforce:

- **Min/Max Values**: `cpu_cores >= 1`, `memory_gb <= 1024`
- **String Patterns**: `name =~ /^[a-z0-9-]+$/`
- **Value Dependencies**: `if production then owner required`
- **Range Checking**: `port between 1 and 65535`

See [Validation Rules](validation-rules.md) for configuration.

---

## Type Conversion Examples

### String to Integer

```bash
# Input (JSON)
{"cpu_cores": "8"}

# Stored As
{"cpu_cores": 8}
```

### Integer to String

```bash
# Input
{"name": 12345}

# Stored As
{"name": "12345"}
```

### Boolean Conversion

```bash
# Input: Multiple representations
{"active": "true"}
{"active": "1"}
{"active": 1}
{"active": true}

# All stored as
{"active": true}
```

---

## API Representation

Types are represented consistently across all API responses:

```json
{
  "ci_id": "ci_a1b2c3",
  "name": "web-prod-01",  // string
  "ci_class": "Server",  // enum (as string)
  "ip_address": "10.0.1.42",  // ipv4 (as string)
  "cpu_cores": 8,  // integer
  "memory_gb": 32,  // integer
  "monthly_cost": 459.99,  // float
  "monitoring_enabled": true,  // boolean
  "created_at": "2026-01-07T10:30:00Z",  // datetime (ISO 8601 string)
  "tags": ["production", "critical"],  // array<string>
  "metadata": {  // object
    "cost_center": "CC-1001"
  }
}
```

---

## See Also

- [CI Classes](ci-classes.md): Schema definitions using these types
- [Validation Rules](validation-rules.md): Enforcing type constraints
- [API Conventions](api-conventions.md): How types are serialized in APIs
