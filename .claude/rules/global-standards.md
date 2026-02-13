---
paths:
  - "**/*"
---

# Global Standards

## Naming Conventions
- Files: lowercase, hyphenated (`user-service.ts`)
- Agent files: `{role}.md`
- Skills: `SKILL.md` in named directories
- Code identifiers: language-appropriate casing
- API endpoints: plural nouns, kebab-case
- Environment vars: `OIDANICE_{COMPONENT}_{SETTING}`

## Tech Stack
- Agent System: Claude Code with specialized agents
- Infrastructure: GitHub Actions, Docker, Terraform
- Cloud: EU-compliant (eu-central-1 or Hetzner)
- Compliance: GDPR, no PII in code, zero-retention option

