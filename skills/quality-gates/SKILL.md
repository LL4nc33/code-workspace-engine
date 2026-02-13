---
name: quality-gates
description: >
  Use PROACTIVELY when: completing tasks, before merging, after implementation,
  checking acceptance criteria. Provides quality gate checkpoints.
---

# Quality Gates Skill

This skill provides quality gate checklists for critical workflow transitions.

## Gate Overview

| Gate | When | Who Reviews | Purpose |
|------|------|-------------|---------|
| Pre-Implementation | After spec, before coding | architect | Design review |
| Post-Implementation | After coding, before merge | quality | Code review |
| Pre-Release | Before deployment | security | Security audit |

## Pre-Implementation Gate

**Trigger:** Before starting implementation

**Reviewer:** architect

### Checklist

- [ ] Spec is architecturally sound
- [ ] Dependencies identified
- [ ] Tech stack aligned
- [ ] Scope is realistic
- [ ] No security anti-patterns
- [ ] Data flow considered

### On Failure

1. Pause and report to user
2. User can override
3. Or: Revise spec

---

## Post-Implementation Gate

**Trigger:** After implementation complete

**Reviewer:** quality agent or `superpowers:requesting-code-review`

### Checklist

- [ ] All acceptance criteria met
- [ ] Tests passing
- [ ] Coverage adequate (>80%)
- [ ] No linting errors
- [ ] Documentation updated
- [ ] No obvious tech debt

### On Failure

1. Create remediation tasks
2. Fix issues
3. Re-run gate

---

## Pre-Release Gate

**Trigger:** Before deployment/merge

**Reviewer:** security, then user

### Security Checks
- [ ] No new vulnerabilities
- [ ] Secrets not exposed
- [ ] Dependency CVEs addressed
- [ ] GDPR compliance verified

### User Checks
- [ ] Acceptance criteria fulfilled
- [ ] Manual review completed

### On Failure

1. Create security remediation tasks
2. Main chat coordinates fixes
3. Re-run gate

---

## Using Gates with Superpowers

CWE quality gates integrate with superpowers:

| Gate | Superpowers Skill |
|------|-------------------|
| Pre-Implementation | `superpowers:brainstorming` |
| Post-Implementation | `superpowers:verification-before-completion` |
| Code Review | `superpowers:requesting-code-review` |

## Quick Reference

```
Before coding → Check design with architect
After coding  → Verify with quality/superpowers
Before merge  → Security audit + user approval
```
