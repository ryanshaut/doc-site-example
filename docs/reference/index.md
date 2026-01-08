# Reference Documentation

Technical specifications and detailed system documentation for Nexus CMDB. This section provides comprehensive information about CI classes, data types, relationships, APIs, and validation rules.

## Purpose

Reference documentation serves as a technical lookup guide while you're:

- Writing automation scripts
- Integrating with Nexus APIs
- Designing CI schemas
- Troubleshooting issues
- Building custom integrations

## Structure

Reference documentation is organized to mirror the system architecture:

### Data Model

<div class="grid cards" markdown>

-   **[CI Classes](ci-classes.md)**

    Complete specification of all built-in CI classes including required attributes, optional fields, and schema definitions.

-   **[Attribute Types](attribute-types.md)**

    Data types available for CI attributes, validation rules, and formatting requirements.

-   **[Relationships](relationships.md)**

    Relationship types, semantics, directionality, and metadata specifications.

</div>

### Lifecycle & Operations

<div class="grid cards" markdown>

-   **[Data Lifecycle](data-lifecycle.md)**

    How CIs and relationships are created, updated, queried, and deleted. State transitions and audit trails.

-   **[Validation Rules](validation-rules.md)**

    Schema validation, data quality rules, and constraint enforcement.

</div>

### API

<div class="grid cards" markdown>

-   **[API Conventions](api-conventions.md)**

    REST API design patterns, authentication, error handling, pagination, and versioning.

</div>

## How to Use This Section

### Quick Lookup

Looking for specific information? Use these patterns:

- **"What fields does a Server CI have?"** → [CI Classes](ci-classes.md#server)
- **"What relationship types exist?"** → [Relationships](relationships.md#relationship-types)
- **"How do I format an IP address?"** → [Attribute Types](attribute-types.md#ipv4-address)
- **"What HTTP codes does the API return?"** → [API Conventions](api-conventions.md#http-status-codes)
- **"How do I enforce uniqueness?"** → [Validation Rules](validation-rules.md#uniqueness-constraints)

### Schema Design

When designing CI schemas:

1. Review [CI Classes](ci-classes.md) for similar existing classes
2. Check [Attribute Types](attribute-types.md) for appropriate data types
3. Define [Relationships](relationships.md) to other CIs
4. Add [Validation Rules](validation-rules.md) for data quality

### Integration Development

When building integrations:

1. Start with [API Conventions](api-conventions.md) for patterns
2. Reference [CI Classes](ci-classes.md) for schema
3. Understand [Data Lifecycle](data-lifecycle.md) for CRUD operations
4. Handle [Relationships](relationships.md) appropriately

## Conventions Used

### Required vs Optional

| Marker | Meaning |
|--------|---------|
| **Required** | Must be provided when creating CI |
| **Optional** | Can be omitted; may have default value |
| **Computed** | Automatically calculated, cannot be set |

### Data Type Notation

```
string          Plain text (UTF-8)
integer         Whole number
float           Decimal number
boolean         true or false
datetime        ISO 8601 timestamp
enum[A,B,C]     One of the specified values
array<type>     List of values of specified type
object          Nested JSON object
```

### API Examples

API examples use this format:

```bash
# Request
GET /api/v1/resource HTTP/1.1
Authorization: Bearer <token>

# Response
HTTP/1.1 200 OK
Content-Type: application/json

{
  "data": {...}
}
```

## Version Information

This reference documents **Nexus CMDB version 1.2.0**.

API version: `v1`  
Schema version: `2026.1`  
Last updated: 2026-01-07

For previous versions, see the [Version Archive](https://docs.nexus-cmdb.io/versions/).

## Changelog

Recent significant changes:

### Version 1.2.0 (2026-01-07)

- Added `Container` CI class
- New relationship type: `orchestrated_by`
- Soft delete now enabled by default
- Performance improvements for graph queries

### Version 1.1.0 (2025-12-01)

- Added temporal relationship support
- Enhanced validation rule engine
- GraphQL API (beta)

See [full changelog](https://github.com/ryanshaut/doc-site-example/blob/main/CHANGELOG.md) for complete history.

## Related Documentation

- **Learning the system?** → [Tutorials](../tutorials/)
- **Solving a problem?** → [How-To Guides](../how-to/)
- **Understanding concepts?** → [Discussions](../discussions/)
