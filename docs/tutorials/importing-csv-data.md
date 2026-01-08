# Importing Data from CSV

In this tutorial, you'll migrate existing infrastructure data into Nexus CMDB using CSV import. This is essential when onboarding an existing environment or integrating data from other systems.

!!! tip "What You'll Build"
    A complete data import pipeline that transforms a CSV inventory into Nexus CIs, including data validation, mapping, and error handling.

**Time Required**: 45 minutes  
**Difficulty**: Intermediate  
**Prerequisites**:

- Completed [Creating Your First CI](first-ci.md)
- Basic familiarity with CSV files and spreadsheets

---

## Scenario: Migrating from Spreadsheet Inventory

Your organization has been tracking infrastructure in an Excel spreadsheet. You'll import this data into Nexus CMDB to enable better automation and relationship modeling.

---

## Step 1: Prepare Your Data

### Download the Sample Dataset

Create a file named `servers.csv` with this content:

```csv
hostname,ip_address,os,environment,owner,cpu_cores,memory_gb,location,datacenter,status
app-server-01,10.10.1.50,RHEL 8.5,production,Engineering,8,32,us-west-2a,PDX-DC1,active
app-server-02,10.10.1.51,RHEL 8.5,production,Engineering,8,32,us-west-2b,PDX-DC1,active
db-server-01,10.10.2.100,Ubuntu 20.04,production,Data Engineering,32,128,us-west-2a,PDX-DC1,active
cache-server-01,10.10.3.20,Debian 11,production,Platform,4,16,us-west-2c,PDX-DC1,active
dev-web-01,10.20.1.10,Ubuntu 22.04,development,Engineering,4,8,us-east-1a,IAD-DC1,active
staging-app-01,10.20.2.15,RHEL 8.5,staging,Engineering,8,16,us-east-1b,IAD-DC1,active
monitoring-01,10.10.4.5,Ubuntu 22.04,production,SRE,8,32,us-west-2a,PDX-DC1,active
```

### Understand the Data Structure

This CSV contains 7 servers with these attributes:

| Column | Description | Required in Nexus |
|--------|-------------|-------------------|
| hostname | Server hostname | Yes (maps to `name`) |
| ip_address | IPv4 address | Yes |
| os | Operating system | Yes |
| environment | Environment type | Yes |
| owner | Owning team | Yes |
| cpu_cores | CPU count | No |
| memory_gb | RAM in GB | No |
| location | Cloud AZ | No |
| datacenter | Physical DC | No |
| status | Operational status | No |

---

## Step 2: Review Nexus CSV Requirements

Before importing, understand Nexus expectations:

### Required Fields

Every CI import must include:

- **ci_class**: The type of CI (e.g., "Server", "Application")
- **name**: Unique identifier for the CI
- At least one class-specific required attribute (varies by CI class)

### Field Mapping

Our CSV column names don't match Nexus attribute names exactly. We'll need to map:

| CSV Column | Nexus Attribute | Transformation |
|------------|-----------------|----------------|
| hostname | name | Direct mapping |
| ip_address | ip_address | Direct mapping |
| os | operating_system | Direct mapping |
| environment | environment | Capitalize first letter |
| owner | owner | Direct mapping |
| cpu_cores | cpu_cores | Convert to integer |
| memory_gb | memory_gb | Convert to integer |
| location | location | Direct mapping |
| datacenter | datacenter | Direct mapping |
| status | status | Capitalize |

### Handle Missing CI Class

Our CSV doesn't have a `ci_class` column. We'll add it during import (all rows are servers).

---

## Step 3: Transform the Data

Nexus requires a specific CSV format. Create `servers-nexus.csv`:

```csv
ci_class,name,ip_address,operating_system,environment,owner,cpu_cores,memory_gb,location,datacenter,status
Server,app-server-01,10.10.1.50,RHEL 8.5,Production,Engineering,8,32,us-west-2a,PDX-DC1,Active
Server,app-server-02,10.10.1.51,RHEL 8.5,Production,Engineering,8,32,us-west-2b,PDX-DC1,Active
Server,db-server-01,10.10.2.100,Ubuntu 20.04,Production,Data Engineering,32,128,us-west-2a,PDX-DC1,Active
Server,cache-server-01,10.10.3.20,Debian 11,Production,Platform,4,16,us-west-2c,PDX-DC1,Active
Server,dev-web-01,10.20.1.10,Ubuntu 22.04,Development,Engineering,4,8,us-east-1a,IAD-DC1,Active
Server,staging-app-01,10.20.2.15,RHEL 8.5,Staging,Engineering,8,16,us-east-1b,IAD-DC1,Active
Server,monitoring-01,10.10.4.5,Ubuntu 22.04,Production,SRE,8,32,us-west-2a,PDX-DC1,Active
```

### Changes Made

1. Added `ci_class` column with value "Server" for all rows
2. Renamed `hostname` → `name`
3. Renamed `os` → `operating_system`
4. Capitalized `environment` values (production → Production)
5. Capitalized `status` values (active → Active)

!!! tip "Automation Tip"
    For large datasets, use a script or tool like `jq`, `csvkit`, or Python pandas to transform CSVs programmatically.

---

## Step 4: Validate Before Import

Nexus provides a validation endpoint to check CSV files before import.

### Upload for Validation

```bash
curl -u admin:changeme \
  -X POST \
  -F "file=@servers-nexus.csv" \
  -F "mode=validate" \
  http://localhost:8080/api/v1/import/csv
```

### Review Validation Results

Successful validation response:

```json
{
  "status": "valid",
  "total_rows": 7,
  "valid_rows": 7,
  "errors": []
}
```

If there are errors, you'll see:

```json
{
  "status": "invalid",
  "total_rows": 7,
  "valid_rows": 5,
  "errors": [
    {
      "row": 3,
      "field": "ip_address",
      "message": "Invalid IP address format",
      "value": "10.10.2"
    },
    {
      "row": 6,
      "field": "environment",
      "message": "Must be one of: Development, Staging, Production",
      "value": "Test"
    }
  ]
}
```

Fix errors in your CSV and validate again until you get `"status": "valid"`.

---

## Step 5: Perform the Import

### Import via API

```bash
curl -u admin:changeme \
  -X POST \
  -F "file=@servers-nexus.csv" \
  -F "mode=create" \
  -F "on_conflict=skip" \
  http://localhost:8080/api/v1/import/csv
```

Parameters:

- `mode=create`: Create new CIs (use `update` to modify existing CIs)
- `on_conflict=skip`: Skip rows with duplicate names (alternatives: `update`, `fail`)

### Import via UI

Alternatively, use the web interface:

1. Navigate to **Import/Export** → **Import**
2. Click **Upload CSV**
3. Select `servers-nexus.csv`
4. Review the preview (shows first 5 rows)
5. Select **Create new CIs**
6. Choose **Skip duplicates** for conflict handling
7. Click **Start Import**

### Monitor Import Progress

The UI shows real-time progress:

```
Processing rows... 7/7 (100%)
Created: 7
Updated: 0
Skipped: 0
Errors: 0
```

---

## Step 6: Verify the Import

### Check CI Count

Navigate to **CIs** and filter by:

```
Datacenter = PDX-DC1
```

You should see 5 servers from the Portland datacenter.

### Verify Individual CI

Click on **app-server-01**. Confirm attributes:

```yaml
Name: app-server-01
IP Address: 10.10.1.50
Operating System: RHEL 8.5
Environment: Production
Owner: Engineering
CPU Cores: 8
Memory (GB): 32
Location: us-west-2a
Datacenter: PDX-DC1
Status: Active
```

### Query via API

Retrieve all imported servers:

```bash
curl -u admin:changeme \
  "http://localhost:8080/api/v1/cis?datacenter=PDX-DC1&limit=100"
```

---

## Step 7: Handle Import Errors

Imports don't always succeed perfectly. Let's simulate and fix common errors.

### Add a Problematic Row

Edit `servers-nexus.csv` and add:

```csv
Server,bad-server-01,not-an-ip,BadOS,Production,Engineering,8,32,us-west-2a,PDX-DC1,Active
```

### Run Import

```bash
curl -u admin:changeme \
  -X POST \
  -F "file=@servers-nexus.csv" \
  -F "mode=create" \
  -F "on_conflict=skip" \
  http://localhost:8080/api/v1/import/csv
```

### Review Errors

Response includes error details:

```json
{
  "status": "partial_success",
  "total_rows": 8,
  "created": 7,
  "errors": [
    {
      "row": 8,
      "message": "Invalid IP address: not-an-ip",
      "ci_name": "bad-server-01"
    }
  ]
}
```

### Fix and Re-import

1. Correct the IP address in the CSV
2. Remove successfully imported rows (rows 1-7)
3. Re-import only the fixed row

Alternatively, use `on_conflict=update` to re-import the entire file—existing CIs will be updated, not duplicated.

---

## What You Learned

Congratulations! You've:

- ✅ Prepared CSV data for Nexus import
- ✅ Mapped external data structures to Nexus attributes
- ✅ Validated data before import
- ✅ Performed bulk import via API and UI
- ✅ Handled import errors and conflicts

---

## Next Steps

Now that you can import data at scale:

- **[Design Relationships](advanced-relationships.md)**: Connect imported CIs
- **[Batch Operations](../how-to/batch-operations.md)**: Update multiple CIs at once
- Review [Data Lifecycle](../reference/data-lifecycle.md) for CRUD operations

---

## Best Practices

### Always Validate First

Never skip validation. It prevents:

- Creating malformed CIs
- Violating uniqueness constraints
- Wasting time on failed imports

### Use Version Control

Store CSV files in Git:

```bash
git add servers-nexus.csv
git commit -m "Add server inventory export 2026-01-07"
git push
```

This creates an audit trail of infrastructure changes.

### Document Transformations

If you script transformations, save the script alongside the data:

```
inventory/
├── raw/
│   └── servers.csv          # Original export
├── transformed/
│   └── servers-nexus.csv    # Ready for import
└── transform.py             # Transformation logic
```

### Import in Batches

For large datasets (>1000 rows):

- Split into batches of 500 rows
- Import sequentially
- Monitor for memory/timeout issues

---

## Troubleshooting

### CSV Encoding Issues

If you see garbled characters:

```bash
file -I servers.csv
# servers.csv: text/plain; charset=iso-8859-1

iconv -f ISO-8859-1 -t UTF-8 servers.csv > servers-utf8.csv
```

Nexus requires UTF-8 encoding.

### Import Times Out

For very large files:

1. Use the API (more stable than UI for bulk operations)
2. Increase timeout:

```bash
curl --max-time 600 -u admin:changeme ...
```

3. Consider splitting the file

### Duplicate CI Names

If import fails with "CI name already exists":

- Use `on_conflict=update` to update existing CIs
- Use `on_conflict=skip` to ignore duplicates
- Ensure `name` column contains unique values
