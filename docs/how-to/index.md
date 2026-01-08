# How-To Guides

These practical guides help you solve specific problems and accomplish common tasks with Nexus CMDB. Unlike tutorials, these assume you already understand the basics and need direct, action-oriented solutions.

## When to Use These Guides

Use how-to guides when you:

- Have a specific problem to solve
- Need to fix an issue or error
- Want to accomplish a particular task
- Already understand CMDB concepts but need implementation steps

## Available Guides

### Data Quality & Maintenance

<div class="grid cards" markdown>

-   **[Fixing Duplicate CIs](fix-duplicate-cis.md)**

    Identify, merge, and prevent duplicate configuration items in your CMDB. Includes detection queries and merge strategies.

-   **[Handling Orphaned Relationships](handle-orphaned-relationships.md)**

    Find and clean up relationships pointing to deleted or non-existent CIs. Includes automated cleanup scripts.

-   **[Batch Operations](batch-operations.md)**

    Update, tag, or modify multiple CIs at once using bulk operations, scripts, and the batch API.

</div>

### Schema & Structure Changes

<div class="grid cards" markdown>

-   **[Renaming CI Classes](rename-ci-class.md)**

    Safely rename a CI class without breaking relationships or losing data. Step-by-step migration process.

-   **[Migrating Naming Conventions](migrate-naming-conventions.md)**

    Update CI names across your CMDB to match new naming standards. Includes validation and rollback procedures.

</div>

## How These Differ from Tutorials

| Tutorials | How-To Guides |
|-----------|---------------|
| Learning-oriented | Problem-oriented |
| Step-by-step teaching | Direct solutions |
| Safe practice environment | Real production scenarios |
| Build understanding | Accomplish tasks |
| Complete from start | Assumes existing knowledge |

## Quick Links

### Common Tasks

- [Merge duplicate server records](fix-duplicate-cis.md#merging-duplicate-servers)
- [Delete orphaned relationships in bulk](handle-orphaned-relationships.md#bulk-cleanup)
- [Rename multiple CIs with a script](batch-operations.md#batch-rename)
- [Change a CI class name](rename-ci-class.md#step-by-step-rename)
- [Update naming convention organization-wide](migrate-naming-conventions.md#migration-strategy)

### Common Issues

- [CI appears twice in search results](fix-duplicate-cis.md)
- [Relationship points to non-existent CI](handle-orphaned-relationships.md)
- [Need to update 100+ CI attributes](batch-operations.md)
- [Renamed a class, broke integrations](rename-ci-class.md#rollback)

## Need Something Else?

- **Learning the basics?** → See [Tutorials](../tutorials/)
- **Understanding concepts?** → See [Discussions](../discussions/)
- **Looking up specifications?** → See [Reference](../reference/)

Browse all guides below or use the search to find specific tasks.
