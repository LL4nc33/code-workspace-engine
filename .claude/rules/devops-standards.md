---
paths:
  - "**/docker*"
  - "**/Dockerfile*"
  - "**/.github/**"
  - "**/terraform/**"
  - "**/k8s/**"
  - "**/docker-compose*.yml"
  - "**/.github/**/*.yml"
---

# DevOps Standards

## CI/CD
- Fail fast: lint → test → build → security-scan → deploy
- Pin action versions to SHA
- Tag images with git SHA, never `latest`
- Include rollback mechanisms

## Containers
- Multi-stage builds, Alpine base, non-root user
- HEALTHCHECK required
- Scan images before push
- Set resource limits

## Infrastructure
- EU-compliant: eu-central-1 primary
- IaC for everything, remote state
- Encryption at rest and in transit
- Monitoring: Prometheus + Grafana + OpenTelemetry

