# Claude Workflow Engine (CWE) v0.4.1

Natural language orchestration for spec-driven development.

## 5 Core Principles

| # | Principle | Description |
|---|-----------|-------------|
| 1 | **Agent-First** | All work delegated to specialized agents |
| 2 | **Auto-Delegation** | Intent recognition maps requests to agents/skills |
| 3 | **Spec-Driven** | Features: specs → tasks → implementation |
| 4 | **Context Isolation** | Agent work returns only compact summaries |
| 5 | **Plugin Integration** | Agents leverage installed plugin skills |

---

## Auto-Delegation

Just say what you need. CWE routes to the right agent or skill.

### Intent → Agent

| Keywords | Agent |
|----------|-------|
| implement, build, create, fix, code, feature, bug, refactor | **builder** |
| question, discuss, think about | **ask** |
| explain, how, what, why, understand | **explainer** |
| test, coverage, quality, validate, assert, metrics, gate | **quality** |
| security, audit, vulnerability, scan, gdpr, owasp, cve | **security** |
| deploy, docker, ci, cd, release, kubernetes, k8s, terraform | **devops** |
| design, architecture, adr, api, schema | **architect** |
| analyze, document, research, compare | **researcher** |
| brainstorm, idea, ideas, what if, alternative, explore | **innovator** |
| workflow, process, pattern, improve, optimize | **guide** |

### Decision Flow

```
User request
    ↓
Explicit command? → Execute command
    ↓ no
Plugin skill matches? → Invoke skill
    ↓ no
CWE agent matches? → Delegate to agent
    ↓ no
Multi-step task? → Orchestrate with subagents
    ↓ no
Unclear? → Ask (max 2 questions)
```

**Override:** Say "manual" to disable auto-delegation.

---

## Idea Capture

Auto-captured via UserPromptSubmit hook when these keywords appear:
idea, what if, could we, maybe, alternative, improvement,
idee, was wäre wenn, könnte man, vielleicht, alternativ, verbesserung

Stored in `~/.claude/cwe/idea-observations.toon` → Review with `/cwe:innovator`

---

## Quick Reference

```
"Fix the login bug"           → builder
"Build a user profile page"   → builder
"Explain how auth works"      → explainer
"What if we used GraphQL?"    → innovator
"Review my changes"           → quality
"Plan the refactoring"        → architect
"Simplify this function"      → builder (refactor)
"Set up Docker"               → devops
"Check for vulnerabilities"   → security
"Document the API"            → researcher
"Improve our workflow"        → guide
```

Run `/cwe:help` for full documentation, commands, and plugin details.
