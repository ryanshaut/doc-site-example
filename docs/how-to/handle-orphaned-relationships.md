# Handling Orphaned Relationships

Orphaned relationships occur when a relationship points to a CI that no longer exists. This guide shows you how to detect, clean up, and prevent orphaned relationships.

## What Are Orphaned Relationships?

An **orphaned relationship** exists when:

- Source CI exists, but target CI was deleted
- Target CI exists, but source CI was deleted
- Both CIs were deleted, but relationship persists (rare)

## Why They Happen

Common causes:

1. **CI Deleted Without Cascade**
   - CI removed but `cascade_delete=false` was set
   - Manual database deletion bypassed referential integrity

2. **Failed Deletion**
   - Partial transaction commit
   - Service crashed during deletion
   - Database timeout

3. **Import/Export Issues**
   - Importing relationships without corresponding CIs
   - Export didn't include related CIs

4. **Database Corruption**
   - Very rare, but possible with hardware failure

## Detecting Orphaned Relationships

### Using the Built-in Scanner

Navigate to **Tools** → **Data Quality** → **Orphaned Relationships**:

1. Click **Scan for Orphans**
2. Review results

Example output:

```
Found 23 orphaned relationships:

Source Missing (12):
- Relationship ID: rel_abc123 → Target: web-prod-01
- Relationship ID: rel_def456 → Target: app-prod-02
...

Target Missing (11):
- Relationship ID: rel_ghi789, Source: lb-prod-01 → (deleted)
- Relationship ID: rel_jkl012, Source: web-prod-03 → (deleted)
...
```

### Using SQL Query

```sql
SELECT
  r.relationship_id,
  r.source_ci_name,
  r.target_ci_name,
  r.relationship_type,
  CASE
    WHEN s.ci_id IS NULL THEN 'Source Missing'
    WHEN t.ci_id IS NULL THEN 'Target Missing'
    ELSE 'Both Missing'
  END as orphan_type
FROM relationships r
LEFT JOIN cis s ON r.source_ci_id = s.ci_id
LEFT JOIN cis t ON r.target_ci_id = t.ci_id
WHERE s.ci_id IS NULL OR t.ci_id IS NULL;
```

Run in **Tools** → **Query Console**.

### Using the API

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/admin/orphaned-relationships"
```

Response:

```json
{
  "total_orphaned": 23,
  "source_missing": 12,
  "target_missing": 11,
  "both_missing": 0,
  "relationships": [
    {
      "relationship_id": "rel_abc123",
      "source_ci": null,
      "target_ci": "web-prod-01",
      "type": "depends_on",
      "orphan_reason": "source_deleted"
    },
    ...
  ]
}
```

## Cleaning Up Orphaned Relationships

### Option 1: Delete All Orphans

!!! danger "Destructive Operation"
    This permanently deletes orphaned relationships. Cannot be undone.

```bash
curl -u admin:changeme \
  -X DELETE \
  "http://localhost:8080/api/v1/admin/orphaned-relationships"
```

Response:

```json
{
  "deleted": 23,
  "failed": 0
}
```

### Option 2: Delete Specific Orphans

Delete by relationship ID:

```bash
curl -u admin:changeme \
  -X DELETE \
  "http://localhost:8080/api/v1/relationships/rel_abc123"
```

### Option 3: Selective Cleanup with Filters

Delete only orphans where source is missing:

```bash
curl -u admin:changeme \
  -X DELETE \
  "http://localhost:8080/api/v1/admin/orphaned-relationships?filter=source_missing"
```

Delete only specific relationship types:

```bash
curl -u admin:changeme \
  -X DELETE \
  "http://localhost:8080/api/v1/admin/orphaned-relationships?type=depends_on"
```

### Option 4: Export Before Deleting

Save orphan records for audit:

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/admin/orphaned-relationships?format=json" \
  > orphaned-relationships-2026-01-07.json
```

Review the file, then delete:

```bash
curl -u admin:changeme \
  -X DELETE \
  "http://localhost:8080/api/v1/admin/orphaned-relationships"
```

## Bulk Cleanup

### Using a Script

Create `cleanup-orphans.sh`:

```bash
#!/bin/bash

# Get all orphaned relationships
ORPHANS=$(curl -s -u admin:changeme \
  "http://localhost:8080/api/v1/admin/orphaned-relationships")

# Parse and delete each one
echo "$ORPHANS" | jq -r '.relationships[].relationship_id' | while read rel_id; do
  echo "Deleting $rel_id..."
  curl -s -u admin:changeme \
    -X DELETE \
    "http://localhost:8080/api/v1/relationships/$rel_id"
  sleep 0.1  # Rate limiting
done

echo "Cleanup complete"
```

Run:

```bash
chmod +x cleanup-orphans.sh
./cleanup-orphans.sh
```

### Using the Maintenance API

Schedule automatic cleanup:

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "task": "cleanup_orphaned_relationships",
    "schedule": "0 2 * * *",
    "enabled": true,
    "notify_on_completion": true,
    "email": "ops@example.com"
  }' \
  http://localhost:8080/api/v1/admin/maintenance-tasks
```

This runs cleanup daily at 2 AM.

## Recovering from Accidental Deletion

### If CI Was Recently Deleted

Check soft-delete table (if enabled):

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/admin/soft-deleted-cis"
```

Restore a CI:

```bash
curl -u admin:changeme \
  -X POST \
  "http://localhost:8080/api/v1/admin/soft-deleted-cis/ci_12345/restore"
```

This automatically restores associated relationships.

### If Relationships Were Exported

Restore from backup:

```bash
curl -u admin:changeme \
  -X POST \
  -F "file=@relationships-backup.json" \
  "http://localhost:8080/api/v1/relationships/import"
```

## Preventing Orphaned Relationships

### Enable Cascade Delete (Recommended)

Configure Nexus to automatically delete relationships when CIs are deleted:

```yaml
# /etc/nexus/config.yaml
database:
  cascade_delete:
    enabled: true
    relationships: true  # Delete relationships when CI deleted
```

Restart Nexus:

```bash
systemctl restart nexus
```

### Use Soft Delete

Instead of hard deleting, mark CIs as deleted:

```yaml
# /etc/nexus/config.yaml
deletion:
  soft_delete:
    enabled: true
    retention_days: 30  # Keep for 30 days before purging
```

When you delete a CI:

```bash
curl -u admin:changeme \
  -X DELETE \
  "http://localhost:8080/api/v1/cis/web-prod-01"
```

The CI is marked as deleted but not removed. Relationships remain intact. After 30 days, hard deletion happens automatically.

### Enable Referential Integrity Checks

Add pre-delete validation:

```yaml
# /etc/nexus/config.yaml
validation:
  referential_integrity:
    enabled: true
    block_delete_with_relationships: false  # Warn but allow
    require_cascade_flag: true  # Force user to specify cascade behavior
```

Now deleting a CI with relationships requires explicit flag:

```bash
curl -u admin:changeme \
  -X DELETE \
  "http://localhost:8080/api/v1/cis/web-prod-01?cascade=true"
```

### Run Periodic Scans

Schedule weekly orphan detection:

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "task": "scan_orphaned_relationships",
    "schedule": "0 3 * * 0",
    "enabled": true,
    "notify_if_found": true,
    "email": "ops@example.com"
  }' \
  http://localhost:8080/api/v1/admin/maintenance-tasks
```

Runs every Sunday at 3 AM. Sends email if orphans found.

## Monitoring and Alerting

### Create a Dashboard Widget

Add to your monitoring dashboard:

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/metrics/orphaned_relationships_count"
```

Returns:

```json
{
  "metric": "orphaned_relationships_count",
  "value": 0,
  "timestamp": "2026-01-07T10:00:00Z"
}
```

Graph this over time to detect spikes.

### Set Up Alerts

Configure alert when orphans exceed threshold:

```yaml
# /etc/nexus/alerts.yaml
alerts:
  - name: orphaned_relationships_high
    condition: orphaned_relationships_count > 10
    severity: warning
    notify:
      - slack: "#ops-alerts"
      - email: "ops@example.com"
```

## Troubleshooting

### Cleanup Fails with "Permission Denied"

**Error**: `User does not have permission to delete relationships`

**Solution**: Use admin credentials or grant permission:

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "user": "data_cleaner",
    "permissions": ["delete_relationships", "view_orphaned_relationships"]
  }' \
  http://localhost:8080/api/v1/admin/permissions
```

### Scanner Shows 0 Orphans, But Query Finds Some

**Cause**: Scanner cache out of date

**Solution**: Force refresh:

```bash
curl -u admin:changeme \
  -X POST \
  "http://localhost:8080/api/v1/admin/cache/clear?scope=relationships"
```

Then re-run scan.

### Orphans Reappear After Cleanup

**Cause**: CI is being deleted and recreated repeatedly (e.g., by discovery)

**Solution**:

1. Identify the pattern:

```sql
SELECT
  target_ci_name,
  COUNT(*) as orphan_count
FROM orphaned_relationships
GROUP BY target_ci_name
ORDER BY orphan_count DESC
LIMIT 10;
```

2. Fix the root cause:
   - Update discovery to reconcile instead of delete/create
   - Fix automation that's churning CIs

### Performance Degradation During Cleanup

**Symptom**: Cleanup of large orphan counts (>1000) causes slowness

**Solution**: Batch the cleanup:

```bash
# Delete in batches of 100
curl -u admin:changeme \
  -X DELETE \
  "http://localhost:8080/api/v1/admin/orphaned-relationships?batch_size=100"
```

## Best Practices

### Regular Maintenance

- ✅ Run orphan scans weekly
- ✅ Clean up immediately when found
- ✅ Export orphan records before deletion
- ✅ Monitor orphan count metrics

### Deletion Workflow

- ✅ Always use cascade delete for CIs with relationships
- ✅ Enable soft delete for grace period
- ✅ Review relationships before CI deletion
- ✅ Document why CIs are being removed

### Preventive Measures

- ✅ Enable referential integrity checks
- ✅ Use soft delete with retention period
- ✅ Train users on proper deletion procedures
- ✅ Automate cleanup with scheduled tasks

## See Also

- [Fixing Duplicate CIs](fix-duplicate-cis.md): Merge CIs properly to avoid orphans
- [Batch Operations](batch-operations.md): Bulk delete CIs safely
- [Data Lifecycle Reference](../reference/data-lifecycle.md): Understand CI and relationship lifecycle
