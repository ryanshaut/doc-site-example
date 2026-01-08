# CMDB Anti-Patterns

Configuration Management Databases fail more often than they succeed. According to industry surveys, 60-70% of CMDB initiatives are abandoned within three years. This failure rate isn't inevitable—it's usually the result of predictable anti-patterns.

## Anti-Pattern 1: The "Perfect Data" Trap

### Description

Refusing to launch the CMDB until every CI is perfectly cataloged, every attribute filled in, every relationship mapped.

### Manifestation

```
Year 1: "We can't go live until we have 100% accuracy"
Year 2: "We're still working on the data quality initiative"
Year 3: "We're pivoting to a new CMDB tool"
Year 4: Project canceled, team disbanded
```

### Why It Fails

- Perfect data is impossible in dynamic environments
- Infrastructure changes faster than you can document it
- Teams lose motivation when launch date keeps slipping
- Perfect becomes the enemy of good

### The Better Approach

**Launch with 70% coverage and iterate**:

1. Start with highest-value CIs (production critical systems)
2. Launch with imperfect but useful data
3. Improve incrementally based on actual usage
4. Automate discovery to maintain accuracy

### Example

Instead of:

```
Goal: Document all 10,000 servers before launch
Timeline: 18 months
Result: Still not done, teams stopped trying
```

Do this:

```
Phase 1 (Month 1): 50 critical production servers → Launch
Phase 2 (Month 2): 200 production servers → Expand
Phase 3 (Month 3): Enable discovery automation → Scale
Phase 4 (Months 4-12): Continuous improvement
```

---

## Anti-Pattern 2: The "Ivory Tower" CMDB

### Description

A central team owns the CMDB and manually enters all data. Other teams submit tickets to request updates.

### Manifestation

```
Engineer: "I need to add a new server to the CMDB"
CMDB Team: "Submit a ticket, we'll process it in 3-5 business days"
Engineer: "My server's already deployed and in production"
CMDB Team: "Sorry, that's our SLA"
```

Result: The CMDB is always out of date. Teams work around it.

### Why It Fails

- Central team becomes bottleneck
- Data is stale by the time it's entered
- Engineers bypass the CMDB entirely
- CMDB team burns out trying to keep up

### The Better Approach

**Federated ownership model**:

- Teams own their services' CIs
- Direct API access for automation
- Self-service UI for manual changes
- Central team provides governance, not data entry

### Example

```yaml
Ownership Model:
  - Platform Team: Owns all server CIs
  - Network Team: Owns network device CIs
  - Engineering Teams: Own application CIs
  - Data Team: Owns database CIs
  - SRE Team: Owns monitoring CIs

CMDB Team Role:
  - Define standards and schemas
  - Provide tools and APIs
  - Monitor data quality
  - Support and training
  - NOT: Data entry
```

---

## Anti-Pattern 3: The "Discovery Tool IS the CMDB"

### Description

Believing that running a discovery tool automatically gives you a CMDB.

### Manifestation

```
CIO: "We bought ServiceNow Discovery, so we have a CMDB now, right?"
Reality: Discovery tool finds infrastructure
         But doesn't understand business context
         Or relationships
         Or why things exist
```

### Why It Fails

- Discovery finds **what exists**, not **why it exists**
- Can't discover business relationships (app depends on service)
- Can't capture human knowledge (this server is decommissioned next month)
- Over-discovers noise (temporary VMs, test infrastructure)

### The Better Approach

**Discovery + Human Curation**:

1. Use discovery for base layer (servers, networks, cloud resources)
2. Humans add business context (applications, services, ownership)
3. Humans model relationships (dependencies, hosting)
4. Validation rules prevent discovered data from polluting CMDB

### Example

```
Discovery Tool Output:
  - Found: 1,247 VMs
  - Found: 3,421 network connections
  - Found: 89 load balancers

Human Curation:
  - Exclude: 847 VMs (CI/CD ephemeral instances)
  - Meaningful VMs: 400 (tagged with business context)
  - Model: Application-to-VM hosting relationships
  - Model: Service-to-database dependencies
  - Add: 25 applications (not discoverable)
```

---

## Anti-Pattern 4: The "Everything is a CI"

### Description

Modeling every possible thing as a CI, creating noise and complexity.

### Manifestation

```yaml
CIs in the CMDB:
  - Servers: 500
  - Keyboards: 500
  - Monitors: 1,200
  - Mouse devices: 500
  - Cables: 3,000
  - Power supplies: 800
  - Paperclips: 12,000
```

The CMDB becomes an unusable junk drawer.

### Why It Fails

- Signal-to-noise ratio plummets
- Queries return too many irrelevant results
- Maintenance overhead explodes
- Real CIs get lost in the clutter

### The Better Approach

**Model only operationally significant CIs**:

Ask: "Do operations need to query or track this?"

| Item | CI? | Rationale |
|------|-----|-----------|
| Production server | ✅ Yes | Critical for operations |
| Application | ✅ Yes | Needed for impact analysis |
| Database | ✅ Yes | Dependency tracking |
| Keyboard | ❌ No | Not operationally significant |
| Cable | ❌ No | Track at network segment level instead |
| Power supply | ❌ No | Part of server, not separate CI |

### Example

Instead of:

```json
{
  "ci_name": "Keyboard-Model-K120-Serial-123456",
  "ci_class": "PeripheralDevice",
  "connected_to": "server-01",
  "keys": 104,
  "color": "black"
}
```

Just track:

```json
{
  "ci_name": "server-01",
  "ci_class": "Server",
  "peripherals": "standard"
}
```

---

## Anti-Pattern 5: The "Set and Forget"

### Description

Launching the CMDB, then never maintaining it.

### Manifestation

```
Year 1: CMDB launched with great fanfare
Year 2: No one updates it
Year 3: Data is 80% inaccurate
Year 4: "The CMDB is useless, let's buy a new tool"
```

### Why It Fails

- Infrastructure changes constantly
- Without maintenance, CMDB decays
- Teams lose trust in stale data
- Becomes waste of money and effort

### The Better Approach

**Continuous maintenance is non-negotiable**:

1. **Automate**: Discovery, API integrations, CI/CD hooks
2. **Validate**: Regular data quality scans
3. **Incentivize**: Make CMDB useful so teams want to maintain it
4. **Monitor**: Track accuracy metrics
5. **Govern**: Regular audits and cleanup

### Example

```yaml
Maintenance Schedule:

  Daily:
    - Automated discovery runs
    - API sync from IaC tools
    - Validation rules check

  Weekly:
    - Orphaned relationship cleanup
    - Duplicate CI detection
    - Data quality dashboard review

  Monthly:
    - Team-level data audits
    - Decommission stale CIs
    - Schema updates based on needs

  Quarterly:
    - Major data quality initiative
    - Process improvement review
    - Training refreshers
```

---

## Anti-Pattern 6: The "Tool Will Save Us"

### Description

Believing that buying an expensive CMDB tool solves all problems.

### Manifestation

```
Executive: "We spent $500K on ServiceNow/BMC/Jira"
Executive: "Why isn't the CMDB working?"
Team: "The tool is fine, but we have no processes"
Executive: "Should we try a different tool?"
```

### Why It Fails

- Tools enable processes, they don't create them
- Without governance, any tool fills with garbage
- Expensive tools don't enforce discipline
- Tool migration wastes more time and money

### The Better Approach

**Process first, tool second**:

1. Define what you need to track (and why)
2. Establish ownership model
3. Create maintenance processes
4. **Then** choose a tool that supports your processes
5. Start simple (even a spreadsheet) before buying enterprise tools

### Example

```
Bad Sequence:
  1. Buy expensive CMDB tool
  2. Try to figure out what to put in it
  3. Fail
  4. Blame the tool

Good Sequence:
  1. Define CMDB goals (support change management, impact analysis)
  2. Identify critical CIs (production servers, applications)
  3. Establish ownership (teams own their services)
  4. Pilot with simple tools (CSV, Git, basic database)
  5. Prove value
  6. Evaluate and select appropriate tooling
```

---

## Anti-Pattern 7: The "Compliance Theater"

### Description

CMDB exists only for audits, not for actual operations.

### Manifestation

```
Normal Day: CMDB ignored, no one updates it
Audit Period: Frantic data cleanup for 2 weeks
Post-Audit: CMDB ignored again
Next Audit: Repeat cycle
```

### Why It Fails

- CMDB isn't integrated into workflows
- Teams see it as checkbox exercise
- Data quality oscillates between terrible and mediocre
- No operational value delivered

### The Better Approach

**Make CMDB operationally useful first**:

- Integrate with change management
- Use for impact analysis during incidents
- Feed monitoring and alerting systems
- Support capacity planning
- Enable cost allocation

When it's useful operationally, compliance becomes a side benefit.

### Example

```yaml
Integration Points:

  Change Management:
    - Require CI identification for changes
    - Automatic impact analysis before approval
    - Update CMDB when change executes

  Incident Management:
    - Link incidents to affected CIs
    - Query CMDB for dependency information
    - Track MTTR per CI type

  Monitoring:
    - Auto-create CIs when monitoring activates
    - CMDB feeds monitoring configuration
    - Bidirectional sync

  Cost Management:
    - Tag CIs with cost centers
    - Track TCO per application
    - Chargeback reporting
```

---

## Anti-Pattern 8: The "Mega Schema"

### Description

Designing an enormous, complex schema that attempts to model every possible thing in every possible way.

### Manifestation

```yaml
Server CI Class:
  Required Fields: 47
  Optional Fields: 213
  Nested Objects: 18
  Enumerated Types: 89
  Validation Rules: 156

Result: No one can use it
```

### Why It Fails

- Overwhelming complexity
- Impossible to populate all fields
- Data entry becomes painful
- Teams circumvent the CMDB

### The Better Approach

**Start minimal, expand based on actual need**:

```yaml
Server CI (Minimal):
  Required:
    - name
    - ip_address
    - environment
  Optional:
    - owner
    - datacenter
  Custom: (allow teams to extend)

Expand later based on usage patterns
```

See [Schema Flexibility vs Strictness](schema-tradeoffs.md) for details.

---

## Anti-Pattern 9: The "No Governance"

### Description

Opposite of Ivory Tower: Complete chaos, everyone does whatever they want.

### Manifestation

```
Team A names servers: web-prod-01
Team B names servers: WEBSERVER_PRODUCTION_001
Team C names servers: srv-prd-web-1
Team D names servers: WebServerProductionTierOne

Query for production web servers: Returns inconsistent mess
```

### Why It Fails

- No standardization = unusable data
- Can't write reliable queries
- Can't build automation
- Integration impossible

### The Better Approach

**Light governance**:

- Define naming conventions
- Require minimal standard fields
- Enforce via validation rules
- Allow flexibility within guardrails

```yaml
Governance:
  Naming Convention: "{env}-{type}-{region}-{number}"
  Required Fields: ["name", "ci_class", "environment"]
  Validation: Automated rules
  Freedom: Custom attributes allowed
```

---

## Warning Signs Your CMDB Is Failing

### Red Flags

- ⚠️ Engineers say "the CMDB is always wrong"
- ⚠️ Last update was 6+ months ago
- ⚠️ Duplicate CIs everywhere
- ⚠️ No one knows who owns data quality
- ⚠️ Discovery runs but no one reviews results
- ⚠️ Executives ask "what's the ROI of this?"
- ⚠️ Teams maintain parallel spreadsheets
- ⚠️ CMDB never consulted during incidents

### Green Flags (Healthy CMDB)

- ✅ Daily updates from automation
- ✅ Teams reference CMDB in runbooks
- ✅ Integrated with change management
- ✅ Used during incident response
- ✅ Data quality >85% and improving
- ✅ Clear ownership model
- ✅ Teams ask for new features

---

## Recovery Strategies

If your CMDB is failing:

### Short-Term (Stabilize)

1. **Freeze scope**: Stop adding new CI types
2. **Focus on critical**: Identify 50-100 most important CIs
3. **Get those right**: Fix data quality for critical CIs only
4. **Prove value**: Use CMDB for one concrete use case
5. **Communicate**: Show the value to stakeholders

### Medium-Term (Rebuild Trust)

1. **Automate**: Integrate discovery and IaC tools
2. **Federate**: Give teams ownership
3. **Integrate**: Connect to change/incident management
4. **Validate**: Implement data quality rules
5. **Maintain**: Establish regular cleanup processes

### Long-Term (Scale)

1. **Expand coverage**: Add more CI types
2. **Model relationships**: Enable impact analysis
3. **Advanced automation**: Self-healing data quality
4. **Analytics**: Use CMDB data for insights
5. **Culture**: Make CMDB a habit, not a chore

---

## Conclusion

CMDB failure is avoidable. Most failures result from:

- Perfectionism (waiting for perfect data)
- Centralization (ivory tower model)
- Over-automation (discovery-only approach)
- Over-modeling (everything is a CI)
- Under-maintenance (set and forget)
- Tool worship (believing tools solve problems)
- Compliance theater (not operationally useful)
- Poor governance (chaos or rigidity)

Success requires:

- **Pragmatism**: Launch with good enough, iterate
- **Federation**: Teams own their data
- **Balance**: Discovery + human curation
- **Focus**: Model only what matters
- **Maintenance**: Continuous improvement
- **Process**: Define before tooling
- **Usefulness**: Operational value first
- **Governance**: Light touch, clear guardrails

Learn from others' failures. Build a CMDB that actually works.

## See Also

- [Design Philosophy](design-philosophy.md): Nexus's approach to avoiding these anti-patterns
- [Why Relationship Modeling Matters](relationship-modeling.md): Understanding a key success factor
- [Schema Flexibility vs Strictness](schema-tradeoffs.md): Finding the right balance
