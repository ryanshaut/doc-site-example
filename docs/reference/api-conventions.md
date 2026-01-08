# API Conventions

Nexus CMDB follows RESTful design principles for its HTTP API. This document describes patterns, authentication, error handling, and best practices.

## Base URL

```
https://nexus-cmdb.example.com/api/v1
```

## Authentication

### Basic Authentication

```bash
curl -u username:password https://nexus-cmdb.example.com/api/v1/cis
```

### Bearer Token

```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  https://nexus-cmdb.example.com/api/v1/cis
```

### API Keys

```bash
curl -H "X-API-Key: your-api-key-here" \
  https://nexus-cmdb.example.com/api/v1/cis
```

---

## HTTP Methods

| Method | Purpose | Idempotent |
|--------|---------|------------|
| GET | Retrieve resources | ✅ Yes |
| POST | Create new resource | ❌ No |
| PUT | Replace entire resource | ✅ Yes |
| PATCH | Update partial resource | ❌ No |
| DELETE | Remove resource | ✅ Yes |

---

## Response Formats

### Success Response

```json
{
  "ci_id": "ci_a1b2c3",
  "name": "web-prod-01",
  "ci_class": "Server",
  ...
}
```

### Error Response

```json
{
  "error": "validation_failed",
  "message": "CI name must be unique",
  "field": "name",
  "provided_value": "web-prod-01",
  "documentation_url": "https://docs.nexus-cmdb.io/reference/validation-rules/"
}
```

---

## HTTP Status Codes

### Success Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 200 OK | Success | GET, PATCH, PUT |
| 201 Created | Resource created | POST |
| 204 No Content | Success, no body | DELETE |

### Client Error Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 400 Bad Request | Invalid request body | Validation errors |
| 401 Unauthorized | Authentication required | Missing credentials |
| 403 Forbidden | Insufficient permissions | Authorization failure |
| 404 Not Found | Resource doesn't exist | Invalid CI ID |
| 409 Conflict | Resource conflict | Duplicate name |
| 422 Unprocessable Entity | Semantic error | Business logic violation |

### Server Error Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 500 Internal Server Error | Unexpected error | Bug or system failure |
| 503 Service Unavailable | Temporary outage | Maintenance mode |

---

## Pagination

For list endpoints returning multiple items:

### Request

```bash
GET /api/v1/cis?limit=50&offset=100
```

### Response

```json
{
  "data": [...],
  "pagination": {
    "total": 500,
    "limit": 50,
    "offset": 100,
    "has_more": true
  },
  "links": {
    "self": "/api/v1/cis?limit=50&offset=100",
    "next": "/api/v1/cis?limit=50&offset=150",
    "prev": "/api/v1/cis?limit=50&offset=50"
  }
}
```

---

## Filtering

### Query Parameters

```bash
GET /api/v1/cis?environment=Production&ci_class=Server&owner=Platform+Team
```

### Operators

```bash
# Greater than
GET /api/v1/cis?cpu_cores__gt=8

# Less than
GET /api/v1/cis?memory_gb__lt=64

# Contains
GET /api/v1/cis?name__contains=prod

# In list
GET /api/v1/cis?environment__in=Production,Staging
```

---

## Sorting

```bash
# Ascending
GET /api/v1/cis?sort=name

# Descending
GET /api/v1/cis?sort=-created_at

# Multiple fields
GET /api/v1/cis?sort=environment,name
```

---

## Field Selection

Request only specific fields:

```bash
GET /api/v1/cis?fields=name,ip_address,environment
```

Response:

```json
{
  "data": [
    {
      "name": "web-prod-01",
      "ip_address": "10.0.1.42",
      "environment": "Production"
    }
  ]
}
```

---

## Rate Limiting

Nexus enforces rate limits:

| Tier | Requests/Hour | Burst |
|------|---------------|-------|
| Anonymous | 100 | 10 |
| Authenticated | 5,000 | 100 |
| Enterprise | 50,000 | 1,000 |

### Rate Limit Headers

```
X-RateLimit-Limit: 5000
X-RateLimit-Remaining: 4723
X-RateLimit-Reset: 1641571200
```

### Rate Limit Exceeded

```json
{
  "error": "rate_limit_exceeded",
  "message": "Rate limit exceeded. Retry after 300 seconds.",
  "retry_after": 300
}
```

HTTP Status: `429 Too Many Requests`

---

## Versioning

API version specified in URL:

```
/api/v1/cis     ← Version 1
/api/v2/cis     ← Version 2 (future)
```

### Version Deprecation

- New versions announced 6 months in advance
- Old versions supported for 12 months after new version release
- Deprecation warnings in response headers:

```
X-API-Deprecation: true
X-API-Sunset: 2027-01-01T00:00:00Z
Link: </api/v2/cis>; rel="alternate"
```

---

## Idempotency

### Idempotent Operations

**GET, PUT, DELETE**: Safe to retry

**POST**: Not idempotent by default

### Idempotency Keys

For safe POST retries:

```bash
POST /api/v1/cis
Idempotency-Key: unique-key-12345
Content-Type: application/json

{...}
```

If request repeated with same key:

- First request: Creates CI, returns `201 Created`
- Subsequent requests: Returns same CI, returns `200 OK`

---

## Bulk Operations

### Batch Create

```bash
POST /api/v1/cis/batch
Content-Type: application/json

{
  "cis": [
    {"name": "server-01", ...},
    {"name": "server-02", ...}
  ]
}
```

### Batch Update

```bash
PATCH /api/v1/cis/batch-update
Content-Type: application/json

{
  "filter": {"environment": "Development"},
  "updates": {"owner": "Dev Team"}
}
```

---

## Webhooks

Subscribe to events:

```bash
POST /api/v1/webhooks
Content-Type: application/json

{
  "url": "https://yourapp.com/webhook",
  "events": ["ci.created", "ci.updated", "ci.deleted"],
  "secret": "webhook-secret"
}
```

Webhook payload:

```json
{
  "event": "ci.created",
  "timestamp": "2026-01-07T10:30:00Z",
  "ci_id": "ci_a1b2c3",
  "data": {...}
}
```

---

## Error Handling

### Retry Logic

Implement exponential backoff:

```python
import time
import requests

def api_call_with_retry(url, max_retries=3):
    for attempt in range(max_retries):
        response = requests.get(url)
        if response.status_code == 200:
            return response.json()
        elif response.status_code in [500, 503]:
            time.sleep(2 ** attempt)  # Exponential backoff
        else:
            raise Exception(f"API error: {response.status_code}")
    raise Exception("Max retries exceeded")
```

### Timeout Configuration

Set reasonable timeouts:

```python
requests.get(url, timeout=(5, 30))  # Connect timeout: 5s, Read timeout: 30s
```

---

## Best Practices

### Use HTTPS

Always use encrypted connections in production.

### Authenticate Requests

Don't use anonymous access for production workloads.

### Handle Rate Limits

Respect `X-RateLimit-*` headers and implement backoff.

### Check HTTP Status First

```python
if response.status_code != 200:
    handle_error(response)
else:
    process_data(response.json())
```

### Log Request IDs

Response header `X-Request-ID` helps with debugging:

```
X-Request-ID: req_abc123xyz
```

Include in support requests.

---

## See Also

- [CI Classes](ci-classes.md): Resource schemas
- [Data Lifecycle](data-lifecycle.md): CRUD operation details
- [Relationships](relationships.md): Relationship API endpoints
