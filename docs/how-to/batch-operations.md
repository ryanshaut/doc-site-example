# Batch Operations

Batch operations allow you to update, tag, delete, or modify multiple CIs at once. This guide covers efficient bulk operations for maintaining your CMDB at scale.

## When to Use Batch Operations

Use batch operations when you need to:

- Update attributes across many CIs
- Add or remove tags in bulk
- Delete multiple CIs simultaneously
- Change ownership or environment designation
- Apply configuration changes organization-wide

## Batch Update

### Update Multiple CI Attributes

#### Scenario: Set Owner for All Web Servers

Update all web servers to be owned by "Platform Team":

```bash
curl -u admin:changeme \
  -X PATCH \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "ci_class": "Server",
      "tags": ["layer:web"]
    },
    "updates": {
      "owner": "Platform Team"
    }
  }' \
  http://localhost:8080/api/v1/cis/batch-update
```

Response:

```json
{
  "matched": 12,
  "updated": 12,
  "failed": 0
}
```

#### Scenario: Change Environment Designation

Move all staging CIs to production:

```bash
curl -u admin:changeme \
  -X PATCH \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "environment": "Staging",
      "tags": ["migration-ready"]
    },
    "updates": {
      "environment": "Production"
    }
  }' \
  http://localhost:8080/api/v1/cis/batch-update
```

### Update from CSV

For complex updates, use CSV format:

Create `updates.csv`:

```csv
name,owner,cost_center,support_tier
web-prod-01,Platform Team,CC-1001,Tier 1
web-prod-02,Platform Team,CC-1001,Tier 1
app-prod-01,Engineering,CC-2002,Tier 1
app-prod-02,Engineering,CC-2002,Tier 1
db-prod-01,Data Team,CC-3003,Tier 0
```

Upload:

```bash
curl -u admin:changeme \
  -X PATCH \
  -F "file=@updates.csv" \
  -F "match_by=name" \
  http://localhost:8080/api/v1/cis/batch-update
```

## Batch Tagging

### Add Tags in Bulk

#### Tag All Production CIs

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "environment": "Production"
    },
    "tags": {
      "add": ["monitored", "sla:99.9", "backup:daily"]
    }
  }' \
  http://localhost:8080/api/v1/cis/batch-tag
```

#### Remove Tags

Remove deprecated tags:

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "tags": ["legacy"]
    },
    "tags": {
      "remove": ["legacy"],
      "add": ["modernization-candidate"]
    }
  }' \
  http://localhost:8080/api/v1/cis/batch-tag
```

#### Replace Tags

Replace old tagging scheme with new:

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "tags": ["env:prod"]
    },
    "tags": {
      "remove": ["env:prod"],
      "add": ["environment:production"]
    }
  }' \
  http://localhost:8080/api/v1/cis/batch-tag
```

## Batch Delete

!!! danger "Destructive Operation"
    Batch delete permanently removes CIs. Always preview first.

### Delete with Preview

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "environment": "Development",
      "status": "Decommissioned"
    },
    "preview": true
  }' \
  http://localhost:8080/api/v1/cis/batch-delete
```

Preview response:

```json
{
  "matched_cis": 47,
  "cis_to_delete": [
    {"name": "dev-web-01", "relationships": 3},
    {"name": "dev-app-01", "relationships": 5},
    ...
  ],
  "total_relationships_affected": 127,
  "preview": true
}
```

### Execute Delete

If preview looks correct:

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "environment": "Development",
      "status": "Decommissioned"
    },
    "preview": false,
    "cascade_relationships": true
  }' \
  http://localhost:8080/api/v1/cis/batch-delete
```

### Delete from List

Delete specific CIs by name:

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "ci_names": [
      "old-server-01",
      "old-server-02",
      "temp-test-vm-01"
    ],
    "cascade_relationships": true
  }' \
  http://localhost:8080/api/v1/cis/batch-delete
```

## Batch Rename

See [Migrating Naming Conventions](migrate-naming-conventions.md) for detailed rename procedures.

Quick example:

```bash
curl -u admin:changeme \
  -X POST \
  -F "file=@rename-mapping.csv" \
  http://localhost:8080/api/v1/admin/bulk-rename
```

## Batch Relationship Management

### Create Multiple Relationships

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "relationships": [
      {"source": "web-prod-01", "target": "app-prod-01", "type": "depends_on"},
      {"source": "web-prod-02", "target": "app-prod-01", "type": "depends_on"},
      {"source": "web-prod-03", "target": "app-prod-01", "type": "depends_on"},
      {"source": "app-prod-01", "target": "db-prod-01", "type": "depends_on"}
    ]
  }' \
  http://localhost:8080/api/v1/relationships/batch
```

### Delete Relationships by Pattern

Remove all relationships of a specific type:

```bash
curl -u admin:changeme \
  -X DELETE \
  "http://localhost:8080/api/v1/relationships/batch?type=test_connection"
```

## Using Scripts for Complex Operations

### Python Script: Conditional Updates

```python
#!/usr/bin/env python3
import requests
from requests.auth import HTTPBasicAuth

NEXUS_URL = "http://localhost:8080"
AUTH = HTTPBasicAuth("admin", "changeme")

# Fetch all servers
response = requests.get(
    f"{NEXUS_URL}/api/v1/cis",
    params={"ci_class": "Server", "limit": 1000},
    auth=AUTH
)
servers = response.json()["cis"]

# Conditional logic: Update memory tier based on RAM
updates = []
for server in servers:
    memory_gb = server["attributes"].get("memory_gb", 0)

    if memory_gb >= 128:
        tier = "high-memory"
    elif memory_gb >= 32:
        tier = "standard"
    else:
        tier = "low-memory"

    updates.append({
        "ci_id": server["ci_id"],
        "attributes": {"memory_tier": tier}
    })

# Apply updates in batches of 50
for i in range(0, len(updates), 50):
    batch = updates[i:i+50]
    response = requests.patch(
        f"{NEXUS_URL}/api/v1/cis/batch-update-by-id",
        json={"updates": batch},
        auth=AUTH
    )
    print(f"Updated batch {i//50 + 1}: {response.json()}")
```

### Bash Script: Tag Geographically

```bash
#!/bin/bash

# Tag all CIs by geographic region based on location attribute

REGIONS=(
  "us-east-1:region:us-east"
  "us-west-2:region:us-west"
  "eu-central-1:region:europe"
  "ap-southeast-1:region:asia-pacific"
)

for mapping in "${REGIONS[@]}"; do
  location=$(echo $mapping | cut -d: -f1)
  tag=$(echo $mapping | cut -d: -f2,3)

  echo "Tagging $location with $tag..."

  curl -s -u admin:changeme \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{
      \"filter\": {\"location\": \"$location\"},
      \"tags\": {\"add\": [\"$tag\"]}
    }" \
    http://localhost:8080/api/v1/cis/batch-tag
done
```

## Monitoring Batch Operations

### Check Job Status

Long-running batch operations create background jobs:

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/admin/jobs"
```

Response:

```json
{
  "jobs": [
    {
      "job_id": "job_20260107_001",
      "type": "batch_update",
      "status": "running",
      "progress": {
        "total": 500,
        "completed": 327,
        "failed": 2,
        "percent": 65
      },
      "started_at": "2026-01-07T10:00:00Z",
      "eta": "2026-01-07T10:05:00Z"
    }
  ]
}
```

### View Job Details

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/admin/jobs/job_20260107_001"
```

### Cancel Running Job

```bash
curl -u admin:changeme \
  -X POST \
  "http://localhost:8080/api/v1/admin/jobs/job_20260107_001/cancel"
```

## Dry Run Mode

Most batch operations support dry-run:

```bash
curl -u admin:changeme \
  -X PATCH \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {"environment": "Production"},
    "updates": {"owner": "New Team"},
    "dry_run": true
  }' \
  http://localhost:8080/api/v1/cis/batch-update
```

Dry run returns:

```json
{
  "dry_run": true,
  "would_match": 87,
  "would_update": 87,
  "changes": [
    {
      "ci_name": "web-prod-01",
      "current_owner": "Platform Team",
      "new_owner": "New Team"
    },
    ...
  ]
}
```

Review, then execute without `dry_run: true`.

## Best Practices

### Before Batch Operations

- ✅ Always preview or dry-run first
- ✅ Back up database
- ✅ Test on staging environment
- ✅ Verify filters return expected CIs
- ✅ Document what you're changing and why

### During Execution

- ✅ Process in smaller batches (50-100 CIs)
- ✅ Monitor job progress
- ✅ Watch for errors
- ✅ Be ready to cancel if needed

### After Completion

- ✅ Verify changes applied correctly
- ✅ Check for unexpected side effects
- ✅ Update documentation
- ✅ Notify affected teams

### Safety Guidelines

- ✅ Use specific filters (avoid broad wildcards)
- ✅ Limit scope with additional conditions
- ✅ Test filters with `count_only=true` first
- ✅ Keep audit logs enabled
- ✅ Enable soft delete for critical operations

## Troubleshooting

### Batch Update Affects Wrong CIs

**Cause**: Filter too broad

**Solution**: Test filter first:

```bash
# Count matches
curl -u admin:changeme \
  "http://localhost:8080/api/v1/cis?environment=Production&count_only=true"

# List names (no updates)
curl -u admin:changeme \
  "http://localhost:8080/api/v1/cis?environment=Production&fields=name"
```

Refine filter until it matches only intended CIs.

### Batch Operation Times Out

**Cause**: Too many CIs in one batch

**Solution**: Process in smaller chunks:

```bash
# Get total count
TOTAL=$(curl -s -u admin:changeme \
  "http://localhost:8080/api/v1/cis?environment=Dev&count_only=true" \
  | jq -r '.count')

# Process in batches of 50
BATCH_SIZE=50
for ((offset=0; offset<TOTAL; offset+=BATCH_SIZE)); do
  curl -u admin:changeme \
    -X PATCH \
    -d "{\"filter\": {\"environment\": \"Dev\"}, \"updates\": {...}, \"limit\": $BATCH_SIZE, \"offset\": $offset}" \
    http://localhost:8080/api/v1/cis/batch-update
done
```

### Partial Batch Failure

**Symptom**: Some CIs update, others fail

**Solution**: Check job details for errors:

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/admin/jobs/job_20260107_001/errors"
```

Fix issues and retry failed CIs:

```bash
curl -u admin:changeme \
  -X POST \
  "http://localhost:8080/api/v1/admin/jobs/job_20260107_001/retry-failed"
```

## See Also

- [Migrating Naming Conventions](migrate-naming-conventions.md): Bulk rename operations
- [Fixing Duplicate CIs](fix-duplicate-cis.md): Bulk merge operations
- [Data Lifecycle Reference](../reference/data-lifecycle.md): Understand CRUD operations
