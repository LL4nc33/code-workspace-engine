---
name: devops-standards
description: DevOps and infrastructure standards specialist. Use PROACTIVELY when working on CI/CD pipelines, Docker, Kubernetes, Terraform, cloud infrastructure, or deployment workflows.
allowed-tools: Read, Grep, Glob, Bash
context: fork
agent: Explore
---

# DevOps Standards

## Instructions

Apply DevOps standards from the project's workflow/standards/devops/ directory when:
- Creating or modifying CI/CD pipelines
- Writing Dockerfiles or docker-compose configurations
- Defining Kubernetes manifests
- Setting up Infrastructure as Code (Terraform, Pulumi)
- Configuring cloud resources

## Key Standards

### CI/CD
- Fail fast: lint -> test -> build -> security-scan -> deploy
- Pin action versions to SHA
- Tag images with git SHA, never `latest`
- Include rollback mechanisms

### Containers
- Multi-stage builds, Alpine base, non-root user
- HEALTHCHECK required
- Scan images before push
- Set resource limits

### Infrastructure
- EU-compliant: eu-central-1 primary
- IaC for everything, remote state
- Encryption at rest and in transit
- Monitoring: Prometheus + Grafana + OpenTelemetry

## Reference Files
- @workflow/standards/devops/ci-cd.md
- @workflow/standards/devops/containerization.md
- @workflow/standards/devops/infrastructure.md
