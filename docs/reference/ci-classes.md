# CI Classes

CI Classes define types of configuration items that can be tracked in Nexus CMDB. Each class has a schema specifying required attributes, optional attributes, and validation rules.

## Built-in CI Classes

### Server

Physical or virtual compute instances.

#### Schema

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | ✅ | Unique identifier (3-128 chars) |
| ci_class | enum | ✅ | Always "Server" |
| ip_address | ipv4 | ✅ | Primary IP address |
| operating_system | string | ✅ | OS name and version |
| environment | enum | ✅ | Production, Staging, or Development |
| hostname | string | ❌ | Fully qualified domain name |
| cpu_cores | integer | ❌ | Number of CPU cores (min: 1) |
| memory_gb | integer | ❌ | RAM in gigabytes (min: 1) |
| storage_gb | integer | ❌ | Disk storage in gigabytes |
| owner | string | ❌ | Owning team or individual |
| datacenter | string | ❌ | Physical datacenter location |
| location | string | ❌ | Cloud region or availability zone |
| status | enum | ❌ | Active, Maintenance, Decommissioned |

#### Example

```json
{
  "name": "web-prod-01",
  "ci_class": "Server",
  "ip_address": "10.0.1.42",
  "operating_system": "Ubuntu 22.04 LTS",
  "environment": "Production",
  "hostname": "web-prod-01.example.com",
  "cpu_cores": 8,
  "memory_gb": 32,
  "storage_gb": 500,
  "owner": "Platform Team",
  "location": "us-east-1a",
  "status": "Active"
}
```

---

### Application

Software applications or services.

#### Schema

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | ✅ | Unique identifier |
| ci_class | enum | ✅ | Always "Application" |
| environment | enum | ✅ | Production, Staging, or Development |
| version | string | ❌ | Application version |
| owner | string | ❌ | Owning team |
| language | string | ❌ | Primary programming language |
| framework | string | ❌ | Application framework |
| repository | string | ❌ | Git repository URL |
| status | enum | ❌ | Active, Deprecated, Retired |

#### Example

```json
{
  "name": "ShopSphere",
  "ci_class": "Application",
  "environment": "Production",
  "version": "2.4.0",
  "owner": "Engineering Team",
  "language": "Python 3.11",
  "framework": "Django 4.2",
  "repository": "github.com/example/shopsphere",
  "status": "Active"
}
```

---

### Database

Database management systems and instances.

#### Schema

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | ✅ | Unique identifier |
| ci_class | enum | ✅ | Always "Database" |
| db_type | enum | ✅ | PostgreSQL, MySQL, MongoDB, etc. |
| environment | enum | ✅ | Production, Staging, or Development |
| version | string | ❌ | Database version |
| port | integer | ❌ | Listening port |
| owner | string | ❌ | Owning team |
| max_connections | integer | ❌ | Maximum connection pool size |

#### Example

```json
{
  "name": "postgres-prod-01",
  "ci_class": "Database",
  "db_type": "PostgreSQL",
  "environment": "Production",
  "version": "15.2",
  "port": 5432,
  "owner": "Data Team",
  "max_connections": 200
}
```

---

### Network Device

Routers, switches, load balancers, firewalls.

#### Schema

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | ✅ | Unique identifier |
| ci_class | enum | ✅ | Always "Network Device" |
| device_type | enum | ✅ | Router, Switch, LoadBalancer, Firewall |
| environment | enum | ✅ | Production, Staging, or Development |
| ip_address | ipv4 | ❌ | Management IP address |
| vendor | string | ❌ | Hardware/software vendor |
| model | string | ❌ | Device model |
| firmware_version | string | ❌ | Current firmware version |

---

### Container

Docker containers, Kubernetes pods.

#### Schema

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | ✅ | Unique identifier |
| ci_class | enum | ✅ | Always "Container" |
| image | string | ✅ | Container image name |
| environment | enum | ✅ | Production, Staging, or Development |
| image_tag | string | ❌ | Image version/tag |
| registry | string | ❌ | Container registry URL |
| port_mappings | array | ❌ | Port bindings |

---

## Custom CI Classes

Organizations can define custom CI classes. See [How to Define Custom CI Classes](../how-to/define-custom-ci-class.md).

### Example: Custom Class

```json
{
  "class_name": "SaaSSubscription",
  "description": "External SaaS service subscriptions",
  "required_attributes": [
    {"name": "name", "type": "string"},
    {"name": "vendor", "type": "string"},
    {"name": "monthly_cost", "type": "float"}
  ],
  "optional_attributes": [
    {"name": "renewal_date", "type": "datetime"},
    {"name": "license_count", "type": "integer"}
  ]
}
```

---

## CI Class Inheritance

Some CI classes inherit from others:

```
Server
├── PhysicalServer
└── VirtualServer
    ├── EC2Instance
    └── AzureVM
```

Child classes inherit parent attributes and can add their own.

---

## Enumerated Values

### Environment

- `Production`
- `Staging`
- `Development`

### Status

- `Active`: In use
- `Maintenance`: Temporarily offline
- `Decommissioned`: Scheduled for removal
- `Retired`: No longer in use

### Database Types

- `PostgreSQL`
- `MySQL`
- `MongoDB`
- `Redis`
- `Oracle`
- `MSSQL`
- `Cassandra`

---

## Validation

CI classes enforce validation automatically:

- Required fields must be present
- Type checking (string, integer, etc.)
- Enum values must match allowed list
- Custom validation rules can be added

See [Validation Rules](validation-rules.md) for details.
