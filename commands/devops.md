---
description: MUSS VERWENDET WERDEN für CI/CD Pipelines, Docker/Kubernetes Konfiguration, Infrastructure as Code, Deployment-Automatisierung und Production Operations. Experte für DevOps mit vollem Infrastruktur-Zugriff.
allowed-tools: ["Task", "AskUserQuestion"]
---

# DevOps

Delegate to the **devops** agent for infrastructure work.

**Usage:** `/cwe:devops [task]`

## Release Mode ($ARGUMENTS starts with "release")

If user runs `/cwe:devops release <level>`:

Delegate to devops agent with release flow:
1. Read current `VERSION` file
2. Bump: `patch` (0.1.0→0.1.1), `minor` (0.1.0→0.2.0), `major` (0.1.0→1.0.0)
3. Write new VERSION, cascade to all files (project-docs skill)
4. Update CHANGELOG.md with new version section
5. Create git tag `v<new-version>`
6. Generate release notes from conventional commits

If no level provided, use AskUserQuestion:
```
Question: "What type of release?"
Header: "Release"
Options:
  1. "Patch" - Bug fixes (x.x.1)
  2. "Minor" - New features (x.1.0)
  3. "Major" - Breaking changes (1.0.0)
```

---

## Interactive Mode (no task provided)

If user runs `/cwe:devops` without a task, use AskUserQuestion:

```
Question: "What type of infrastructure work?"
Header: "DevOps Task"
Options:
  1. "Containerization" - Docker, Compose, images
  2. "CI/CD Pipeline" - GitHub Actions, GitLab CI, Jenkins
  3. "Deployment" - Kubernetes, cloud services
  4. "Release" - Version bump, changelog, tag
```

### If "Containerization":
```
Question: "What do you need?"
Header: "Docker"
Options:
  1. "Create Dockerfile" - New container setup
  2. "Docker Compose" - Multi-container setup
  3. "Optimize image" - Reduce size, improve build
  4. "Debug container" - Fix container issues
```

### If "CI/CD Pipeline":
```
Question: "Which platform?"
Header: "CI Platform"
Options:
  1. "GitHub Actions" - GitHub workflows
  2. "GitLab CI" - GitLab pipelines
  3. "Jenkins" - Jenkins pipelines
  4. "Other" - (User types via Other)
```

Then:
```
Question: "What should the pipeline do?"
Header: "Pipeline"
Options:
  1. "Build & Test" - Basic CI
  2. "Deploy" - CD to environment
  3. "Full CI/CD" - Build, test, deploy
  4. "Quality gates" - Linting, coverage, security
```

### If "Deployment":
```
Question: "Deployment target?"
Header: "Target"
Options:
  1. "Kubernetes" - K8s cluster
  2. "Cloud VM" - EC2, Compute Engine, Droplet
  3. "Serverless" - Lambda, Cloud Functions
  4. "Static hosting" - Vercel, Netlify, S3
```

### If "Release":
```
Question: "What type of release?"
Header: "Release"
Options:
  1. "Patch" - Bug fixes (x.x.1)
  2. "Minor" - New features (x.1.0)
  3. "Major" - Breaking changes (1.0.0)
  4. "Pre-release" - Alpha, beta, RC
```

After selections, confirm:
```
Question: "Ready to proceed?"
Header: "Confirm"
Options:
  1. "Yes, go ahead" - Start the work
  2. "Show me first" - Explain what will happen
  3. "I need to add details" - (User types via Other)
```

## Direct Mode (task provided)

If user provides a task like `/cwe:devops setup Docker`, skip the menus and delegate directly.

## Process

Delegate using the Task tool:

```
subagent_type: devops
prompt: [constructed or provided task]
```

## Plugin Integration

The devops agent has:
- Full filesystem access for infrastructure code
- Docker, Kubernetes, Terraform expertise
- Release management (version bumps, changelogs, tags)
- **superpowers:verification-before-completion** - Before finalizing
- **superpowers:writing-plans** - For complex deployments
