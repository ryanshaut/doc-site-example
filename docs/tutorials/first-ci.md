# Creating Your First CI

In this tutorial, you'll learn the fundamentals of Nexus CMDB by creating your first configuration item (CI). By the end, you'll have a working Nexus installation and a server record tracked in the database.

!!! tip "What You'll Build"
    A CI representing a web server with attributes like hostname, IP address, operating system, and environment designation.

**Time Required**: 15 minutes  
**Difficulty**: Beginner  
**Prerequisites**: Docker installed on your machine

---

## Installation

### Step 1: Pull the Nexus CMDB Image

Nexus CMDB runs as a Docker container for easy setup:

```bash
docker pull nexus/cmdb:latest
```

### Step 2: Start the Container

Run Nexus with default configuration:

```bash
docker run -d \
  --name nexus-cmdb \
  -p 8080:8080 \
  -e NEXUS_ADMIN_PASSWORD=changeme \
  nexus/cmdb:latest
```

This starts Nexus on `http://localhost:8080` with the admin password `changeme`.

### Step 3: Verify Installation

Wait about 30 seconds for Nexus to initialize, then check the health endpoint:

```bash
curl http://localhost:8080/api/v1/health
```

You should see:

```json
{
  "status": "healthy",
  "version": "1.2.0",
  "database": "connected"
}
```

---

## Understanding CIs

Before creating your first CI, let's understand what it is.

A **Configuration Item** (CI) represents any component in your IT infrastructure:

- Physical servers
- Virtual machines
- Applications
- Network devices
- Databases
- Cloud resources

Each CI has:

- A **CI class** (its type, like "Server" or "Application")
- **Attributes** (properties like hostname, IP, owner)
- **Relationships** to other CIs (dependencies, hosting, etc.)

---

## Creating Your First CI

### Step 1: Log In to the UI

Open your browser to `http://localhost:8080` and log in:

- **Username**: `admin`
- **Password**: `changeme`

You'll see the Nexus dashboard.

### Step 2: Navigate to CI Creation

1. Click **CIs** in the left sidebar
2. Click the **+ New CI** button in the top right
3. Select **Server** as the CI class

### Step 3: Fill in Basic Attributes

Enter the following information:

| Field | Value |
|-------|-------|
| **Name** | web-server-01 |
| **Hostname** | web-server-01.example.com |
| **IP Address** | 10.0.1.42 |
| **Operating System** | Ubuntu 22.04 LTS |
| **Environment** | Production |
| **Owner** | Platform Team |

### Step 4: Add Optional Attributes

Scroll down to optional fields and add:

| Field | Value |
|-------|-------|
| **CPU Cores** | 4 |
| **Memory (GB)** | 16 |
| **Location** | us-east-1a |

### Step 5: Save the CI

Click **Create CI** at the bottom of the form.

You'll see a confirmation: "CI web-server-01 created successfully!"

---

## Viewing Your CI

### In the UI

Your CI now appears in the CI list. Click on **web-server-01** to see its detail page:

- **Attributes**: All the data you entered
- **Relationships**: Empty for now (we'll add these in later tutorials)
- **History**: A record showing when the CI was created
- **Tags**: None yet

### Via API

You can also retrieve your CI using the REST API:

```bash
curl -u admin:changeme http://localhost:8080/api/v1/cis/web-server-01
```

Response:

```json
{
  "ci_id": "ci_a9f8e7d6c5b4a3",
  "name": "web-server-01",
  "ci_class": "Server",
  "attributes": {
    "hostname": "web-server-01.example.com",
    "ip_address": "10.0.1.42",
    "operating_system": "Ubuntu 22.04 LTS",
    "environment": "Production",
    "owner": "Platform Team",
    "cpu_cores": 4,
    "memory_gb": 16,
    "location": "us-east-1a"
  },
  "created_at": "2026-01-07T10:30:00Z",
  "updated_at": "2026-01-07T10:30:00Z"
}
```

---

## What You Learned

Congratulations! You've:

- ✅ Installed Nexus CMDB using Docker
- ✅ Understood what a CI represents
- ✅ Created your first CI (a server) with attributes
- ✅ Viewed the CI in both the UI and API

---

## Next Steps

Now that you've created a CI, you're ready to:

- **[Model Infrastructure Assets](modeling-infrastructure.md)**: Build a complete infrastructure model with multiple CIs
- **[Design Relationships](advanced-relationships.md)**: Connect CIs to represent dependencies
- Explore the [CI Classes reference](../reference/ci-classes.md) to see all available types

---

## Troubleshooting

### Container Won't Start

If the Docker container fails to start:

```bash
docker logs nexus-cmdb
```

Common issues:

- Port 8080 already in use: Change `-p 8081:8080` to use a different port
- Insufficient memory: Ensure Docker has at least 2GB RAM allocated

### Can't Create CI

If you get a validation error:

- Check that **Name** contains no spaces (use hyphens instead)
- Ensure **IP Address** is in valid format (e.g., `10.0.1.42`)
- Verify **Environment** is one of: Development, Staging, Production

### API Returns 401 Unauthorized

Make sure you're passing credentials:

```bash
curl -u admin:changeme http://localhost:8080/api/v1/cis/web-server-01
```

The `-u` flag provides Basic Authentication.
