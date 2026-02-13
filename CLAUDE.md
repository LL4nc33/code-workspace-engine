# Code Workspace Engine (CWE) v0.4.3

Natural language orchestration for spec-driven development.

## 6 Core Principles

| # | Principle | Description |
|---|-----------|-------------|
| 1 | **Agent-First** | All work delegated to specialized agents |
| 2 | **Auto-Delegation** | Intent recognition maps requests to agents/skills |
| 3 | **Spec-Driven** | Features: specs → tasks → implementation |
| 4 | **Context Isolation** | Agent work returns only compact summaries |
| 5 | **Plugin Integration** | Agents leverage installed plugin skills |
| 6 | **Always Document** | Every change updates memory, CHANGELOG, and relevant docs |

### Principle 6: Always Document

After every non-trivial change, update these files so CWE remembers across sessions:

1. **memory/MEMORY.md** — Update the index (what changed, current state)
2. **memory/decisions.md** — Log any design decisions made
3. **memory/patterns.md** — Record new patterns discovered
4. **memory/project-context.md** — Update tech stack, priorities if changed
5. **CHANGELOG.md** — Add entry under current version
6. **docs/** — Update affected docs (README, ARCHITECTURE, API, SETUP)

This is not optional. If context is lost, CWE cannot resume effectively.

---

## Auto-Delegation

Just say what you need. CWE routes to the right agent or skill.

### Intent → Agent

| Keywords | Agent |
|----------|-------|
| implement, build, create, fix, code, feature, bug, refactor | **builder** |
| question, discuss, think about | **ask** |
| explain, how, what, why, understand | **explainer** |
| test, write tests, coverage, quality, validate, assert, metrics, flaky, gate | **quality** |
| security, audit, vulnerability, scan, gdpr, owasp, cve | **security** |
| deploy, docker, ci, cd, release, kubernetes, k8s, terraform | **devops** |
| design, architecture, adr, api, schema | **architect** |
| analyze, document, research, compare | **researcher** |
| brainstorm, idea, ideas, what if, alternative, explore | **innovator** |
| workflow, process, pattern, improve, optimize, optimization | **guide** |

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

Stored per-project in `~/.claude/cwe/ideas/<project-slug>.jsonl` → Review with `/cwe:innovator`

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
