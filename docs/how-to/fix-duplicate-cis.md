# Fixing Duplicate CIs

Duplicate configuration items occur when the same asset is registered multiple times in the CMDB. This guide shows you how to find, merge, and prevent duplicates.

## Symptoms

You might have duplicates if:

- Search returns multiple results for the same hostname
- Relationships point to different CIs representing the same asset
- Discovery creates new CIs instead of updating existing ones
- Reports show inflated CI counts

## Detecting Duplicates

### Find Duplicate Hostnames

```sql
SELECT
  name,
  COUNT(*) as duplicate_count,
  STRING_AGG(ci_id, ', ') as ci_ids
FROM cis
WHERE ci_class = 'Server'
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
```

Run this in **Tools** → **Query Console**.

### Find Duplicate IP Addresses

```sql
SELECT
  ip_address,
  COUNT(*) as duplicate_count,
  STRING_AGG(name, ', ') as ci_names
FROM cis
WHERE ip_address IS NOT NULL
GROUP BY ip_address
HAVING COUNT(*) > 1;
```

### Use the Duplicate Detector

Navigate to **Tools** → **Duplicate Detection**:

1. Select **CI Class**: Server
2. Choose **Match Criteria**:
   - ☑ Hostname
   - ☑ IP Address
   - ☐ Serial Number
3. Set **Similarity Threshold**: 95%
4. Click **Scan**

Results show potential duplicates with confidence scores.

## Understanding Why Duplicates Happen

### Common Causes

1. **Multiple Discovery Sources**
   - Agent-based discovery creates `server-01`
   - Agentless scan creates `server-01.example.com`
   - Manual entry creates `SERVER-01`

2. **Case Sensitivity**
   - `server-01` vs `Server-01` vs `SERVER-01`
   - Nexus treats these as different CIs

3. **Hostname Variations**
   - Short name: `webserver`
   - FQDN: `webserver.prod.example.com`
   - IP-based: `10-0-1-42`

4. **Re-provisioned Assets**
   - Server decomissioned but CI not deleted
   - Server reprovisioned with same name
   - Discovery creates "new" CI

## Merging Duplicate Servers

### Example Scenario

You have two CIs for the same server:

- `web-prod-01` (created by agent discovery)
- `web-prod-01.example.com` (created by manual entry)

### Step 1: Identify the Primary CI

Decide which CI to keep. Usually:

- Keep the one with more complete data
- Keep the older one (stable CI ID for history)
- Keep the one with more relationships

### Step 2: Preview the Merge

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "primary_ci": "web-prod-01",
    "duplicate_ci": "web-prod-01.example.com",
    "preview": true
  }' \
  http://localhost:8080/api/v1/cis/merge
```

Response shows what will happen:

```json
{
  "action": "merge",
  "primary_ci": "web-prod-01",
  "duplicate_ci": "web-prod-01.example.com",
  "changes": {
    "attributes_to_merge": ["hostname"],
    "relationships_to_transfer": 3,
    "tags_to_merge": ["monitored", "production"],
    "history_entries_to_transfer": 5
  },
  "duplicate_will_be_deleted": true
}
```

### Step 3: Perform the Merge

If the preview looks good:

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "primary_ci": "web-prod-01",
    "duplicate_ci": "web-prod-01.example.com",
    "merge_strategy": "prefer_primary",
    "preview": false
  }' \
  http://localhost:8080/api/v1/cis/merge
```

**Merge Strategy Options**:

- `prefer_primary`: Keep primary's attributes when conflict
- `prefer_duplicate`: Use duplicate's attributes when conflict
- `prefer_newest`: Use most recently updated value
- `prefer_most_complete`: Use the value that's not null/empty

### Step 4: Verify the Merge

Check the primary CI:

```bash
curl -u admin:changeme \
  http://localhost:8080/api/v1/cis/web-prod-01
```

Confirm:

- Attributes from both CIs are present
- Relationships transferred
- Tags merged
- History preserved

## Bulk Merge Operations

### Merge Multiple Duplicates

Create a merge plan file `merge-plan.json`:

```json
{
  "merges": [
    {
      "primary": "web-prod-01",
      "duplicate": "web-prod-01.example.com"
    },
    {
      "primary": "web-prod-02",
      "duplicate": "WEB-PROD-02"
    },
    {
      "primary": "db-prod-01",
      "duplicate": "database-prod-01"
    }
  ],
  "merge_strategy": "prefer_primary"
}
```

Execute:

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d @merge-plan.json \
  http://localhost:8080/api/v1/cis/merge/batch
```

### Use the Merge Wizard

For UI-based merging:

1. **Tools** → **Duplicate Detection** → **Scan**
2. Review detected duplicates
3. Select duplicates to merge (checkbox)
4. Click **Merge Selected**
5. Choose merge strategy
6. Review changes
7. Click **Confirm Merge**

## Preventing Future Duplicates

### Configure Discovery Reconciliation

Edit `/etc/nexus/discovery.yaml`:

```yaml
discovery:
  reconciliation:
    enabled: true
    match_by:
      - hostname
      - ip_address
      - mac_address
    normalize_hostnames: true  # Convert to lowercase
    strip_domain_suffix: false  # Keep FQDN
    update_existing: true      # Update instead of create
```

Restart discovery service:

```bash
systemctl restart nexus-discovery
```

### Enforce Naming Conventions

Create a validation rule to enforce lowercase:

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "rule_name": "lowercase_ci_names",
    "applies_to": "Server",
    "validation": {
      "field": "name",
      "pattern": "^[a-z0-9\\-\\.]+$",
      "error_message": "CI name must be lowercase alphanumeric with hyphens and dots only"
    }
  }' \
  http://localhost:8080/api/v1/validation-rules
```

### Use Unique Identifiers

When creating CIs, prefer unique identifiers:

- **Good**: `web-prod-01-i-1234567890abcdef0` (includes instance ID)
- **Bad**: `web-server` (too generic)

### Configure Auto-Deduplication

Enable automatic duplicate detection:

```yaml
# /etc/nexus/config.yaml
deduplication:
  enabled: true
  scan_interval: 1h
  auto_merge:
    enabled: false  # Require manual approval
  notify:
    - platform-team@example.com
```

## Rollback a Merge

If you merged incorrectly, you can rollback within 30 days:

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "merge_id": "merge_abc123xyz"
  }' \
  http://localhost:8080/api/v1/cis/merge/rollback
```

This:

1. Restores the deleted duplicate CI
2. Transfers relationships back
3. Reverts attribute changes
4. Removes merged tags

## Best Practices

### Before Merging

- ✅ Always preview merges first
- ✅ Back up your database
- ✅ Notify teams that own the affected CIs
- ✅ Verify in non-production first
- ✅ Document your merge strategy

### During Merging

- ✅ Merge in small batches (≤10 at a time)
- ✅ Verify each batch before proceeding
- ✅ Monitor for errors
- ✅ Keep merge logs for audit trail

### After Merging

- ✅ Update documentation referencing old CI names
- ✅ Update automation scripts with new CI IDs
- ✅ Notify monitoring systems of changes
- ✅ Review relationships for correctness

## Troubleshooting

### Merge Fails with "Relationships Conflict"

Some relationships can't be automatically merged:

```json
{
  "error": "Relationship conflict",
  "details": "Both CIs have 'depends_on' relationship to different databases"
}
```

**Solution**: Manually resolve before merging:

1. Review conflicting relationships
2. Delete incorrect relationship
3. Retry merge

### Can't Find Duplicate CI After Merge

This is expected—the duplicate is deleted. Check:

- Audit log for merge record
- Primary CI history for merge event
- Soft-delete table (if enabled)

### Merge Created Incorrect Relationships

Rollback and re-merge with different strategy:

```bash
# Rollback
curl -u admin:changeme -X POST \
  http://localhost:8080/api/v1/cis/merge/rollback/merge_abc123

# Re-merge with different strategy
curl -u admin:changeme -X POST \
  -d '{"primary": "web-01", "duplicate": "web-01-old", "merge_strategy": "prefer_duplicate"}' \
  http://localhost:8080/api/v1/cis/merge
```

## See Also

- [Batch Operations](batch-operations.md): Update multiple CIs at once
- [Handling Orphaned Relationships](handle-orphaned-relationships.md): Clean up broken relationships
- [Data Lifecycle Reference](../reference/data-lifecycle.md): Understand CI creation and deletion
