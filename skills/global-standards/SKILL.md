---
name: global-standards
description: Global project conventions including naming, tech stack, and cross-cutting standards. Use PROACTIVELY when creating new files, naming variables/functions, choosing technologies, or establishing project patterns.
allowed-tools: Read, Grep, Glob
context: fork
agent: Explore
---

# Global Standards

## Instructions

Apply global standards from workflow/standards/global/ when:
- Naming new files, directories, or code identifiers
- Choosing technologies or frameworks
- Establishing patterns that span multiple domains
- Reviewing code for naming consistency
- Setting up new project components

## Key Standards

### Naming Conventions
- Files: lowercase, hyphenated (`user-service.ts`)
- Agent files: `{role}.md`
- Skills: `SKILL.md` in named directories
- Code identifiers: language-appropriate casing (see naming.md)
- API endpoints: plural nouns, kebab-case
- Environment vars: `OIDANICE_{COMPONENT}_{SETTING}`

### Tech Stack
- Agent System: Claude Code with specialized agents
- Infrastructure: GitHub Actions, Docker, Terraform
- Cloud: EU-compliant (eu-central-1 or Hetzner)
- Compliance: GDPR, no PII in code, zero-retention option

## Application Triggers

This skill automatically applies when:
- Any new file is being created (naming check)
- Technology choices are being made
- Cross-domain patterns are established
- Project structure decisions are needed

## Reference Files
- @workflow/standards/global/naming.md
- @workflow/standards/global/tech-stack.md
