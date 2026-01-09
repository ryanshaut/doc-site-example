# Welcome to Nexus CMDB

**Nexus CMDB** is an enterprise-grade Configuration Management Database designed for modern infrastructure teams. It provides a single source of truth for your IT assets, their relationships, and dependencies—enabling better decision-making, automated workflows, and reduced operational risk.

---

## What is Nexus CMDB?

Nexus CMDB helps you:

- **Track configuration items (CIs)** across servers, applications, networks, and cloud resources
- **Model relationships** between CIs to understand dependencies and impact
- **Automate discovery** of infrastructure changes in real-time
- **Enforce governance** through flexible schema validation
- **Integrate seamlessly** with existing IT service management tools

---

## Getting Started

New to Nexus CMDB? Start here:

!!! tip "New to this documentation?"
    **Not sure where to start?** Learn how this documentation is organized and how to find what you need quickly.

    [:octicons-arrow-right-24: How to Use This Documentation](how-to-use-this-site.md){ .md-button .md-button--primary }

<div class="grid cards" markdown>

-   :material-school:{ .lg .middle } **Tutorials**

    ---

    Step-by-step guides to help you learn by doing

    [:octicons-arrow-right-24: Start learning](tutorials/)

-   :material-wrench:{ .lg .middle } **How-To Guides**

    ---

    Practical solutions to common problems and tasks

    [:octicons-arrow-right-24: Solve problems](how-to/)

-   :material-lightbulb:{ .lg .middle } **Discussions**

    ---

    Understand the concepts, design decisions, and philosophy

    [:octicons-arrow-right-24: Learn the why](discussions/)

-   :material-book-open:{ .lg .middle } **Reference**

    ---

    Technical specifications and detailed system documentation

    [:octicons-arrow-right-24: Look up details](reference/)

</div>

---

## Key Features

### :material-graph: Rich Relationship Modeling

Define complex relationships between CIs with support for:

- Parent-child hierarchies
- Dependencies and impacts
- Many-to-many associations
- Temporal relationships

### :material-shield-check: Flexible Schema Validation

Balance flexibility with governance:

- Define custom CI classes with inheritance
- Enforce attribute constraints and data types
- Apply validation rules at write-time
- Support for extensible attributes

### :material-sync: Real-Time Discovery

Automatically discover and update your infrastructure:

- Agent-based and agentless discovery
- Cloud provider integrations (AWS, Azure, GCP)
- Container orchestration platforms
- Network device scanning

### :material-api: RESTful API

Full-featured API for automation:

- CRUD operations on CIs and relationships
- Bulk import/export
- GraphQL query support
- Webhook notifications for changes

---

## Documentation Structure

This documentation follows the [Diátaxis framework](https://diataxis.fr/) to provide different types of content for different needs:

| Section | Purpose | When to Use |
| ------- | ------- | ----------- |
| **Tutorials** | Learning-oriented lessons | You're new and want hands-on practice |
| **How-To Guides** | Problem-solving recipes | You need to accomplish a specific task |
| **Discussions** | Understanding-oriented explanations | You want to deepen your knowledge |
| **Reference** | Information-oriented technical specs | You need to look up details |

---

## Quick Links

- [Install Nexus CMDB](tutorials/first-ci.md#installation)
- [API Documentation](reference/api-conventions.md)
- [Common Issues](how-to/fix-duplicate-cis.md)
- [Design Philosophy](discussions/design-philosophy.md)

---

## Community & Support

- :fontawesome-brands-github: [GitHub Repository](https://github.com/ryanshaut/doc-site-example)
- :material-email: [Support Email](mailto:support@nexus-cmdb.io)
- :material-chat: [Community Slack](https://nexus-cmdb.slack.com)
- :material-file-document: [Release Notes](https://github.com/ryanshaut/doc-site-example/releases)
