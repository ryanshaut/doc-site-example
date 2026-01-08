# Migrating Naming Conventions

Organizations evolve their CI naming conventions over time. This guide shows you how to update CI names across your CMDB while maintaining referential integrity and minimizing disruption.

## Common Scenarios

### Scenario 1: Change Naming Pattern

**Old**: `server-prod-01`, `server-prod-02`  
**New**: `prod-server-01`, `prod-server-02`

### Scenario 2: Add Environment Prefix

**Old**: `webserver-01`, `appserver-01`  
**New**: `prd-webserver-01`, `prd-appserver-01`

### Scenario 3: Standardize Case

**Old**: `WebServer-01`, `WEB-SERVER-02`, `web_server_03`  
**New**: `web-server-01`, `web-server-02`, `web-server-03`

### Scenario 4: Include Region

**Old**: `db-01`, `db-02`  
**New**: `us-east-db-01`, `us-east-db-02`

## Prerequisites

Before starting:

- [ ] Document current naming convention
- [ ] Define new naming convention with examples
- [ ] Test migration in non-production environment
- [ ] Back up the database
- [ ] Schedule maintenance window (if needed)

## Migration Strategy

### Step 1: Define the New Convention

Create a specification document:

```markdown
# New Naming Convention

**Format**: `{env}-{type}-{region}-{number}`

**Components**:
- env: prd, stg, dev (3 chars, lowercase)
- type: app, web, db, cache (descriptive, lowercase)
- region: use1, usw2, euc1 (AWS region shorthand)
- number: 01-99 (zero-padded)

**Examples**:
- Production web server in us-east-1: `prd-web-use1-01`
- Staging database in eu-central-1: `stg-db-euc1-01`
- Dev app server in us-west-2: `dev-app-usw2-01`

**Rules**:
- All lowercase
- Hyphens as separators (no underscores)
- Numbers zero-padded to 2 digits
```

### Step 2: Generate Mapping

Create a mapping file showing old → new names:

#### Using a Script

```python
#!/usr/bin/env python3
import csv
import re

# Fetch all CIs
cis = [
    {"name": "webserver-prod-01", "environment": "Production", "region": "us-east-1"},
    {"name": "appserver-prod-01", "environment": "Production", "region": "us-east-1"},
    {"name": "db-prod-01", "environment": "Production", "region": "us-west-2"},
    # ... fetch from API in reality
]

# Region mapping
region_map = {
    "us-east-1": "use1",
    "us-west-2": "usw2",
    "eu-central-1": "euc1"
}

# Environment mapping
env_map = {
    "Production": "prd",
    "Staging": "stg",
    "Development": "dev"
}

# Generate new names
mapping = []
for ci in cis:
    old_name = ci["name"]

    # Extract type from old name
    if "web" in old_name:
        type_code = "web"
    elif "app" in old_name:
        type_code = "app"
    elif "db" in old_name:
        type_code = "db"
    else:
        type_code = "srv"

    # Extract number
    number_match = re.search(r'(\d+)$', old_name)
    number = number_match.group(1) if number_match else "01"

    # Build new name
    env_code = env_map.get(ci["environment"], "unk")
    region_code = region_map.get(ci["region"], "unk")
    new_name = f"{env_code}-{type_code}-{region_code}-{number}"

    mapping.append({"old_name": old_name, "new_name": new_name})

# Save to CSV
with open("rename-mapping.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["old_name", "new_name"])
    writer.writeheader()
    writer.writerows(mapping)

print(f"Generated mapping for {len(mapping)} CIs")
```

Run:

```bash
python3 generate-mapping.py
```

Output `rename-mapping.csv`:

```csv
old_name,new_name
webserver-prod-01,prd-web-use1-01
appserver-prod-01,prd-app-use1-01
db-prod-01,prd-db-usw2-01
```

### Step 3: Validate Mapping

Check for issues before applying:

#### Check for Duplicates

```python
#!/usr/bin/env python3
import csv
from collections import Counter

with open("rename-mapping.csv") as f:
    reader = csv.DictReader(f)
    new_names = [row["new_name"] for row in reader]

duplicates = [name for name, count in Counter(new_names).items() if count > 1]

if duplicates:
    print(f"ERROR: Duplicate new names found:")
    for dup in duplicates:
        print(f"  - {dup}")
    exit(1)
else:
    print("✓ No duplicate new names")
```

#### Check Name Format

```python
#!/usr/bin/env python3
import csv
import re

pattern = re.compile(r'^[a-z]{3}-[a-z]{2,10}-[a-z]{4}-\d{2}$')

with open("rename-mapping.csv") as f:
    reader = csv.DictReader(f)
    for row in reader:
        if not pattern.match(row["new_name"]):
            print(f"ERROR: Invalid format: {row['new_name']}")
            exit(1)

print("✓ All new names match convention")
```

### Step 4: Test in Staging

Apply migration to staging environment first:

```bash
curl -u admin:changeme \
  -X POST \
  -F "file=@rename-mapping.csv" \
  -F "preview=true" \
  https://staging-cmdb.example.com/api/v1/admin/bulk-rename
```

Review preview results:

```json
{
  "total_renames": 247,
  "successful_validations": 247,
  "errors": [],
  "warnings": [
    {
      "old_name": "legacy-server-01",
      "message": "CI has 15 relationships that will be updated"
    }
  ]
}
```

### Step 5: Perform Migration (Production)

#### Create Migration Job

```bash
curl -u admin:changeme \
  -X POST \
  -F "file=@rename-mapping.csv" \
  -F "preview=false" \
  -F "update_relationships=true" \
  -F "create_aliases=true" \
  http://localhost:8080/api/v1/admin/bulk-rename
```

Parameters:

- `update_relationships=true`: Update all relationships automatically
- `create_aliases=true`: Old names still work (for grace period)

#### Monitor Progress

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/admin/jobs/job_20260107_001"
```

Response:

```json
{
  "job_id": "job_20260107_001",
  "status": "running",
  "type": "bulk_rename",
  "progress": {
    "total": 247,
    "completed": 198,
    "failed": 0,
    "percent": 80
  },
  "eta": "2026-01-07T10:15:00Z"
}
```

Wait for `"status": "completed"`.

### Step 6: Verify Migration

#### Check Sample Renames

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/cis/prd-web-use1-01"
```

Should return the CI with new name.

#### Verify Old Names (Aliases)

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/cis/webserver-prod-01"
```

Should redirect to `prd-web-use1-01` with HTTP 301:

```json
{
  "status": "redirect",
  "old_name": "webserver-prod-01",
  "new_name": "prd-web-use1-01",
  "message": "CI renamed. Update your references.",
  "ci": { ... }
}
```

#### Verify Relationships

Check that relationships updated:

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/cis/prd-web-use1-01/relationships"
```

Confirm `source_ci` and `target_ci` fields use new names.

### Step 7: Update Integrations

Update all systems that reference old names:

#### Discovery Configuration

```yaml
# /etc/nexus/discovery.yaml
naming_convention:
  format: "{env}-{type}-{region}-{number}"
  components:
    env: ["prd", "stg", "dev"]
    type: ["web", "app", "db", "cache"]
    region: ["use1", "usw2", "euc1"]
```

#### Monitoring Scripts

```python
# Before
ci = api.get_ci("webserver-prod-01")

# After
ci = api.get_ci("prd-web-use1-01")
```

#### Documentation

Update runbooks, diagrams, and documentation with new names.

### Step 8: Remove Aliases

After grace period (30-60 days), remove aliases:

```bash
curl -u admin:changeme \
  -X DELETE \
  "http://localhost:8080/api/v1/admin/aliases?created_before=2026-02-07"
```

This removes all aliases older than specified date.

## Rollback Procedure

If migration fails:

### Step 1: Cancel Job

```bash
curl -u admin:changeme \
  -X POST \
  "http://localhost:8080/api/v1/admin/jobs/job_20260107_001/cancel"
```

### Step 2: Reverse Mapping

Swap columns in CSV:

```python
import csv

with open("rename-mapping.csv") as f:
    reader = csv.DictReader(f)
    rows = list(reader)

with open("reverse-mapping.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["old_name", "new_name"])
    writer.writeheader()
    for row in rows:
        writer.writerow({"old_name": row["new_name"], "new_name": row["old_name"]})
```

### Step 3: Apply Reverse

```bash
curl -u admin:changeme \
  -X POST \
  -F "file=@reverse-mapping.csv" \
  http://localhost:8080/api/v1/admin/bulk-rename
```

## Partial Migration

Migrate in phases to reduce risk:

### Phase 1: Production Servers

```bash
# Filter mapping to only production
grep "^prd-" rename-mapping.csv > prd-mapping.csv

curl -u admin:changeme \
  -X POST \
  -F "file=@prd-mapping.csv" \
  http://localhost:8080/api/v1/admin/bulk-rename
```

### Phase 2: Staging Servers

```bash
grep "^stg-" rename-mapping.csv > stg-mapping.csv
# Apply stg-mapping.csv
```

### Phase 3: Development Servers

```bash
grep "^dev-" rename-mapping.csv > dev-mapping.csv
# Apply dev-mapping.csv
```

## Troubleshooting

### Rename Fails with "Name Already Exists"

**Error**: `CI with name 'prd-web-use1-01' already exists`

**Cause**: Duplicate in new naming scheme

**Solution**:

1. Identify the conflict:

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/cis/prd-web-use1-01"
```

2. Manually resolve:
   - If it's the same CI, skip rename
   - If different CI, adjust new name (e.g., `prd-web-use1-01a`)

### Relationships Not Updating

**Symptom**: Relationships still reference old names

**Solution**: Force relationship update:

```bash
curl -u admin:changeme \
  -X POST \
  "http://localhost:8080/api/v1/admin/relationships/update-names"
```

### Performance Issues During Migration

**Symptom**: Migration takes too long or times out

**Solution**: Batch the migration:

```bash
# Process in batches of 50
split -l 50 rename-mapping.csv batch-

for batch in batch-*; do
  echo "Processing $batch..."
  curl -u admin:changeme \
    -X POST \
    -F "file=@$batch" \
    http://localhost:8080/api/v1/admin/bulk-rename
  sleep 5
done
```

## Best Practices

### Planning Phase

- ✅ Document new convention with examples
- ✅ Get stakeholder buy-in
- ✅ Test in non-production first
- ✅ Plan for 30-day grace period with aliases

### Execution Phase

- ✅ Migrate during low-traffic period
- ✅ Enable aliases for backward compatibility
- ✅ Monitor for errors
- ✅ Communicate changes to all teams

### Post-Migration

- ✅ Update all documentation
- ✅ Enforce new convention in discovery
- ✅ Add validation rules for new format
- ✅ Remove aliases after grace period

## Enforcing New Convention

After migration, prevent old patterns:

### Add Validation Rule

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "rule_name": "enforce_naming_convention",
    "applies_to": "Server",
    "validation": {
      "field": "name",
      "pattern": "^(prd|stg|dev)-(web|app|db|cache)-(use1|usw2|euc1)-\\d{2}$",
      "error_message": "Name must follow convention: {env}-{type}-{region}-{number}"
    },
    "severity": "error",
    "enabled": true
  }' \
  http://localhost:8080/api/v1/validation-rules
```

Now creating CIs with old format fails:

```bash
curl -u admin:changeme \
  -X POST \
  -d '{"name": "webserver-prod-01", ...}' \
  http://localhost:8080/api/v1/cis

# Returns 400 Bad Request:
{
  "error": "Validation failed",
  "message": "Name must follow convention: {env}-{type}-{region}-{number}"
}
```

## See Also

- [Renaming CI Classes](rename-ci-class.md): Rename CI types
- [Batch Operations](batch-operations.md): Other bulk update operations
- [Validation Rules Reference](../reference/validation-rules.md): Enforce data quality
