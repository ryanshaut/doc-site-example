# Discussions

These conceptual discussions help you understand the **why** behind Nexus CMDB's design decisions, architecture, and philosophy. Unlike how-to guides or tutorials, discussions don't provide step-by-step instructions—they explain concepts, trade-offs, and rationale.

## When to Read These

Read discussions when you:

- Want to understand why something works the way it does
- Need to make architectural decisions about your CMDB implementation
- Are curious about the philosophy behind features
- Want to deepen your conceptual understanding
- Are evaluating whether Nexus CMDB fits your needs

## Available Discussions

<div class="grid cards" markdown>

-   **[Why Relationship Modeling Matters](relationship-modeling.md)**

    Understanding the importance of explicit relationship modeling in a CMDB, and why it's more than just foreign keys in a database.

-   **[Schema Flexibility vs Strictness](schema-tradeoffs.md)**

    Exploring the continuum between rigid, strongly-typed schemas and fully flexible, schemaless designs—and where Nexus sits on that spectrum.

-   **[CMDB Anti-Patterns](anti-patterns.md)**

    Common mistakes organizations make when implementing CMDBs, and why they lead to failure or abandonment.

-   **[Design Philosophy](design-philosophy.md)**

    The core principles guiding Nexus CMDB's architecture, API design, and feature decisions.

</div>

## How These Differ from Other Documentation

| Tutorials | How-To Guides | Discussions | Reference |
|-----------|---------------|-------------|-----------|
| Learning-oriented | Problem-oriented | Understanding-oriented | Information-oriented |
| Hands-on practice | Direct solutions | Concepts and theory | Technical specs |
| Step-by-step | Task-focused | Explanatory | Look-up |

## Topics Covered

### Architecture & Design

- Why explicit relationship modeling
- Schema design trade-offs
- API design principles
- Data modeling philosophy

### Best Practices

- What makes a good CI class
- When to use relationships vs attributes
- Balancing governance with flexibility
- CMDB maturity model

### Common Misconceptions

- CMDB is not just an asset database
- Relationships are not just foreign keys
- Discovery is not the whole picture
- CMDBs don't run themselves

## Not Finding What You Need?

- **Learning the basics?** → See [Tutorials](../tutorials/)
- **Solving a specific problem?** → See [How-To Guides](../how-to/)
- **Looking up technical details?** → See [Reference](../reference/)

These discussions assume you have some familiarity with CMDBs. If you're completely new, start with [Creating Your First CI](../tutorials/first-ci.md).
