# Renaming CI Classes

CI classes define types of configuration items (like "Server", "Application", "Database"). This guide shows how to safely rename a CI class without breaking relationships or integrations.

## When to Rename

Common reasons to rename CI classes:

- Standardizing terminology across teams
- Aligning with ITIL or industry standards
- Fixing naming mistakes from initial setup
- Merging similar classes (e.g., "VirtualMachine" → "Server")

!!! warning "Breaking Change"
    Renaming CI classes affects:

    - Existing CIs using that class
    - API consumers filtering by class name
    - Automation scripts
    - Reports and dashboards
    - Discovery rules

    Plan carefully and communicate changes.

## Prerequisites

Before renaming:

- [ ] Document all systems using the CI class
- [ ] Test in a non-production environment
- [ ] Schedule maintenance window
- [ ] Notify affected teams
- [ ] Back up the database

## Step-by-Step Rename

### Example: Rename "VirtualServer" to "Server"

You have a CI class called `VirtualServer` that you want to rename to `Server`.

### Step 1: Assess Impact

Check how many CIs use this class:

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/cis?ci_class=VirtualServer&count_only=true"
```

Response:

```json
{
  "count": 247
}
```

Find all relationships involving this class:

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/relationships?source_class=VirtualServer"
```

### Step 2: Create Migration Plan

Document the rename:

```yaml
migration:
  class_rename:
    old_name: VirtualServer
    new_name: Server
  affected_cis: 247
  affected_relationships: 1,523
  rollback_plan: yes
  estimated_downtime: 5 minutes
```

### Step 3: Communicate Changes

Send notification to stakeholders:

```markdown
**CMDB Maintenance Notice**

Date: 2026-01-15 02:00-02:30 UTC
Impact: CI class rename
Action Required: Update API filters, scripts, and queries

Old: `VirtualServer`
New: `Server`

All existing CIs will be automatically updated.

Update your code:
- API queries: Change `?ci_class=VirtualServer` to `?ci_class=Server`
- Scripts: Update class name references
- Reports: Refresh dashboard filters
```

### Step 4: Perform the Rename

#### Using the API

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "old_name": "VirtualServer",
    "new_name": "Server",
    "update_relationships": true,
    "update_validation_rules": true,
    "create_alias": true
  }' \
  http://localhost:8080/api/v1/admin/ci-classes/rename
```

#### What Happens

The API automatically:

1. Renames the CI class definition
2. Updates all CIs using `VirtualServer` → `Server`
3. Updates relationships referencing this class
4. Updates validation rules
5. Creates an alias so `VirtualServer` still works (temporary compatibility)
6. Records the change in audit log

### Step 5: Monitor Progress

Check rename status:

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/admin/migrations/status"
```

Response:

```json
{
  "migration_id": "mig_2026-01-15_001",
  "status": "in_progress",
  "type": "ci_class_rename",
  "progress": {
    "cis_updated": 247,
    "relationships_updated": 1523,
    "validation_rules_updated": 3
  },
  "estimated_completion": "2026-01-15T02:05:00Z"
}
```

Wait for `"status": "completed"`.

### Step 6: Verify the Rename

#### Check CI Class Exists

```bash
curl -u admin:changeme \
  http://localhost:8080/api/v1/ci-classes/Server
```

Should return the class definition.

#### Verify Old Name No Longer Exists

```bash
curl -u admin:changeme \
  http://localhost:8080/api/v1/ci-classes/VirtualServer
```

Returns:

```json
{
  "status": "alias",
  "redirects_to": "Server",
  "message": "VirtualServer is an alias for Server. Use Server in new integrations."
}
```

#### Check Sample CIs

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/cis?ci_class=Server&limit=5"
```

Verify `ci_class` field shows `Server` for all results.

### Step 7: Update Integrations

Update all systems that reference the old class name:

#### Discovery Configuration

```yaml
# /etc/nexus/discovery.yaml
mappings:
  - source: "vmware_vm"
    target_class: "Server"  # Changed from VirtualServer
```

#### API Clients

```python
# Before
servers = api.get_cis(ci_class="VirtualServer")

# After
servers = api.get_cis(ci_class="Server")
```

#### Reports

Update dashboard filters:

1. Open each dashboard
2. Edit filter: `CI Class = VirtualServer` → `CI Class = Server`
3. Save

### Step 8: Remove Alias (Optional)

After all integrations are updated, remove the temporary alias:

```bash
curl -u admin:changeme \
  -X DELETE \
  "http://localhost:8080/api/v1/admin/ci-classes/aliases/VirtualServer"
```

!!! danger "Wait Before Removing"
    Keep the alias for at least 30 days to allow gradual migration.

## Rollback

If something goes wrong:

### Step 1: Stop the Migration

```bash
curl -u admin:changeme \
  -X POST \
  "http://localhost:8080/api/v1/admin/migrations/mig_2026-01-15_001/cancel"
```

### Step 2: Reverse the Rename

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "old_name": "Server",
    "new_name": "VirtualServer"
  }' \
  http://localhost:8080/api/v1/admin/ci-classes/rename
```

### Step 3: Verify Rollback

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/cis?ci_class=VirtualServer&limit=1"
```

Should return CIs successfully.

## Advanced: Merge Two CI Classes

If you want to combine two similar classes:

### Example: Merge "PhysicalServer" and "VirtualServer" into "Server"

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "source_classes": ["PhysicalServer", "VirtualServer"],
    "target_class": "Server",
    "add_discriminator_attribute": true,
    "discriminator_name": "server_type",
    "mappings": {
      "PhysicalServer": "physical",
      "VirtualServer": "virtual"
    }
  }' \
  http://localhost:8080/api/v1/admin/ci-classes/merge
```

This:

1. Creates `Server` class (if it doesn't exist)
2. Migrates all `PhysicalServer` CIs to `Server` with `server_type=physical`
3. Migrates all `VirtualServer` CIs to `Server` with `server_type=virtual`
4. Creates aliases for backward compatibility

## Troubleshooting

### Rename Fails with "Class Name Conflict"

**Error**: `CI class 'Server' already exists`

**Solution**:

If `Server` exists but has different schema:

```bash
# Check schema differences
curl -u admin:changeme \
  http://localhost:8080/api/v1/ci-classes/Server/schema

# Merge schemas before renaming
curl -u admin:changeme -X POST \
  -d '{"merge_schemas": true}' \
  http://localhost:8080/api/v1/admin/ci-classes/rename
```

### Relationships Not Updating

**Error**: Some relationships still reference old class

**Solution**: Force relationship update:

```bash
curl -u admin:changeme \
  -X POST \
  "http://localhost:8080/api/v1/admin/relationships/reindex"
```

### API Returns 404 After Rename

**Symptom**: API calls to `VirtualServer` fail after rename

**Solution**:

1. Verify alias exists:

```bash
curl -u admin:changeme \
  http://localhost:8080/api/v1/admin/ci-classes/aliases
```

2. If alias missing, recreate:

```bash
curl -u admin:changeme -X POST \
  -d '{"alias": "VirtualServer", "target": "Server"}' \
  http://localhost:8080/api/v1/admin/ci-classes/aliases
```

## Best Practices

### Before Rename

- ✅ Test in staging environment first
- ✅ Back up database
- ✅ Document all affected systems
- ✅ Create rollback procedure
- ✅ Schedule during low-usage period

### During Rename

- ✅ Create alias for backward compatibility
- ✅ Monitor migration progress
- ✅ Keep communication channels open
- ✅ Be ready to rollback

### After Rename

- ✅ Update documentation
- ✅ Notify all stakeholders
- ✅ Update training materials
- ✅ Monitor error logs for issues
- ✅ Remove alias after 30-60 days

## Alternative: Use Aliases Permanently

Instead of renaming, create an alias:

```bash
curl -u admin:changeme \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "alias": "VM",
    "target_class": "VirtualServer",
    "permanent": true
  }' \
  http://localhost:8080/api/v1/admin/ci-classes/aliases
```

Now both `VM` and `VirtualServer` work in queries:

```bash
# Both return same results
curl http://localhost:8080/api/v1/cis?ci_class=VirtualServer
curl http://localhost:8080/api/v1/cis?ci_class=VM
```

Benefits:

- No breaking changes
- Multiple names for same class
- Gradual migration possible

Drawbacks:

- Confusion about "correct" name
- Aliases clutter the namespace

## See Also

- [Migrating Naming Conventions](migrate-naming-conventions.md): Rename individual CIs
- [CI Classes Reference](../reference/ci-classes.md): All available CI classes
- [Schema Tradeoffs Discussion](../discussions/schema-tradeoffs.md): When to use strict vs flexible schemas
