# HMCTS DevOps Technical Test

## Overview

This repository contains my solution for the HMCTS DevOps Technical Test.

The objective of this exercise was to take the provided Spring Boot application and prepare it for production by:

- Connecting the application to PostgreSQL
- Containerising the application using Docker
- Creating a GitHub Actions CI/CD pipeline
- Defining Azure infrastructure using Terraform
- Documenting the solution

No Java application code was modified. All changes are infrastructure, configuration and deployment related.

---

# Architecture

The solution consists of:

- Spring Boot application
- PostgreSQL database
- Docker Compose for local development
- GitHub Actions CI pipeline
- Azure infrastructure defined with Terraform
- Azure Key Vault for secret management
- Azure Container Apps for container hosting

---

# Running Locally

## Prerequisites

- Java 21
- Docker Desktop
- Docker Compose

Clone the repository:

```bash
git clone <repository-url>
cd hmcts-dev-test-backend
```

Copy the example environment file:

```bash
cp .env.example .env
```

Update the database password if required.

Start the application:

```bash
docker compose up --build
```

The application will be available at:

```
http://localhost:4000
```

Useful endpoints:

```
GET /
GET /get-example-case
GET /health
GET /health/readiness
```

Stop the stack:

```bash
docker compose down
```

---

# Database Configuration

The application has been configured to use PostgreSQL via environment variables.

Datasource configuration is supplied through:

- DB_HOST
- DB_PORT
- DB_NAME
- DB_USER_NAME
- DB_PASSWORD

No credentials are hardcoded in the repository.

---

# Docker

The backend uses a multi-stage Docker build.

Stage 1

- Builds the application using Gradle
- Produces the executable Spring Boot JAR

Stage 2

- Uses a lightweight JRE image
- Copies only the runnable JAR
- Runs the application as a non-root user

Benefits:

- Smaller image
- Better security
- Faster deployments

---

# Docker Compose

Docker Compose provides:

- Spring Boot application
- PostgreSQL database
- Persistent database volume
- Container health checks
- Environment variable configuration

The application waits until PostgreSQL is healthy before starting.

---

# Health Checks

Spring Boot Actuator has been configured to expose:

```
/health
```

and

```
/health/readiness
```

Database connectivity is included in the readiness group.

---

# CI/CD Pipeline

GitHub Actions executes the following stages.

## 1. Build & Test

- Checkout source
- Install Java 21
- Restore Gradle cache
- Compile the application
- Execute tests
- Execute Checkstyle

## 2. Terraform Validation

- terraform fmt -check
- terraform init -backend=false
- terraform validate

## 3. Container Build

Builds the Docker image using the Dockerfile.

Image tags use:

```
branch-shortSHA
```

Example:

```
feature-healthcheck-a31b6c9f8123
```

This provides:

- immutable builds
- easy traceability
- simple rollback

## 4. Security Scan

The image is scanned using Trivy.

Pipeline behaviour:

- HIGH vulnerabilities are reported
- CRITICAL vulnerabilities fail the pipeline

---

# Azure Infrastructure

Terraform provisions:

- Resource Group
- PostgreSQL Flexible Server
- PostgreSQL Database
- Azure Key Vault
- User Assigned Managed Identity
- Log Analytics Workspace
- Azure Container Apps Environment
- Azure Container App

The application receives:

- database host
- database port
- database name
- username

through environment variables.

The database password is retrieved securely from Azure Key Vault.

---

# Secrets Management

Database passwords are never stored in source control.

Terraform:

- generates the password
- stores it in Azure Key Vault

The application accesses the secret using a User Assigned Managed Identity.

---

# Terraform State

For local validation the backend configuration is intentionally commented out.

In a production deployment I would store Terraform state in:

- Azure Storage Account
- Blob Container
- AzureRM Backend

Benefits:

- shared state
- state locking
- versioning
- secure access via Azure RBAC

---

# Assumptions

- Azure Container Apps was selected because the application is stateless and containerised.
- PostgreSQL Flexible Server was chosen as the managed database service.
- GitHub Actions is the CI/CD platform.
- Java 21 is required by the Gradle toolchain.

---

# Trade-offs

To keep the exercise focused:

- Public database access was enabled for simplicity.
- Networking was not restricted using private endpoints.
- No deployment stage was included because the assessment only requires build and validation.

---

# Future Improvements

With additional time I would:

- Add deployment stages for development and production.
- Push Docker images to Azure Container Registry.
- Use GitHub Environments for deployment approvals.
- Add Terraform Plan to the pipeline.
- Deploy using immutable image digests.
- Configure private networking between Container Apps and PostgreSQL.
- Enable Dependabot for dependency updates.
- Pin GitHub Actions to commit SHAs.
- Add monitoring dashboards and alerts using Azure Monitor.

---

# Verification

Application

```bash
docker compose up --build
```

Health

```bash
curl http://localhost:4000/health
```

Terraform

```bash
terraform fmt -check -recursive infrastructure
terraform -chdir=infrastructure validate
```

CI

Push any commit to GitHub to execute the GitHub Actions workflow.

