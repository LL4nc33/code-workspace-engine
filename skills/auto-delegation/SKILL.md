---
name: auto-delegation
description: >
  Use PROACTIVELY when user sends a free-text request (not a /command).
  Routes natural language to the right agent or plugin skill.
  NOT for Build-phase task assignment — see agent-detection for that.
---

# Auto-Delegation

Route free-text user requests to agents and plugin skills.

**Scope:** Interactive user requests (natural language in chat).
**Not for:** Structured task assignment during Build phase (→ use `agent-detection`).

## Decision Flow

```
User request
    ↓
Explicit /command? → Execute command
    ↓ no
Plugin skill matches? → Invoke skill
    ↓ no
CWE agent matches? → Delegate to agent
    ↓ no
Multi-step task? → Delegate to subagents (via delegator skill)
    ↓ no
Unclear? → Ask (max 2 questions)
```

**Override:** Say "manual" or "no delegation" to disable.

## Intent → Agent

| Intent | Agent | Keywords |
|--------|-------|----------|
| Write/fix code | **builder** | implement, fix, build, create, code, feature, bug, refactor |
| Questions/discussion | **ask** | question, discuss, think about |
| Explain code/concepts | **explainer** | explain, how, what, why, understand |
| Testing/quality | **quality** | test, write tests, coverage, quality, validate, assert, metrics, flaky, gate |
| Security audit | **security** | security, audit, vulnerability, scan, gdpr, owasp, cve |
| Infrastructure | **devops** | deploy, docker, ci, cd, release, kubernetes, k8s, terraform |
| System design | **architect** | design, architecture, adr, api, schema |
| Research/docs | **researcher** | analyze, document, research, compare |
| Brainstorming | **innovator** | brainstorm, idea, ideas, what if, alternative, explore |
| Process improvement | **guide** | workflow, process, pattern, improve, optimize, optimization |

### "test" Routing

"test" and related keywords always route to **quality** first.
Quality decides next steps:
- Coverage analysis, metrics, review → quality handles directly
- Writing new tests (TDD, regression) → quality delegates to builder
- CI pipeline tests → quality delegates to devops

## Intent → Plugin Skill

Plugin skills take priority over agent routing when matched.

| Keywords | Skill | Plugin |
|----------|-------|--------|
| UI, frontend, component, page | `frontend-design` | frontend-design |
| simplify, cleanup, refactor | `code-simplifier` | code-simplifier |
| debug, investigate bug | `systematic-debugging` | superpowers |
| write plan, planning | `writing-plans` | superpowers |
| review code | `requesting-code-review` | superpowers |
| TDD, test first | `test-driven-development` | superpowers |
| update CLAUDE.md | `claude-md-improver` | claude-md-management |
| create plugin, hook, command | plugin-dev skills | plugin-dev |
| develop feature | `/feature-dev` | feature-dev |

## Multi-step Detection

Before routing to a single agent, check if the request requires **multiple agents**:

### Triggers (invoke `delegator` skill)

- Keywords match **2+ different agents** (e.g., "build" + "test" + "document")
- Conjunctions across domains: "implement X **and** write tests **and** update docs"
- Completeness keywords: "full", "complete", "end-to-end", "komplett", "mit allem"
- Compound verbs: "implement, test, and deploy"
- Feature-level implicit: "Add user authentication" (code + tests + docs)

### NOT Multi-step (stay with single agent)

- One verb, one domain: "Fix login bug" → builder
- Question across topics: "Explain auth and caching" → explainer
- Vague: "Look at the API" → ask (clarify first)

### Examples

```
"Build auth with tests and docs"     → delegator (builder + quality + researcher)
"Fix bug and add regression test"    → delegator (builder + quality)
"Implement, test, and deploy"        → delegator (builder + quality + devops)
```

When multi-step is detected, invoke the `delegator` skill for decomposition and wave-based dispatch.

## Context Injection (Automatic)

Standards are auto-loaded via `.claude/rules/` with `paths` frontmatter.
The `_index.yml` maps standards to both file paths AND task keywords.

| Task Keywords | Rules Loaded |
|---------------|-------------|
| **All files** | `.claude/rules/global-standards.md` (always) |
| **api, endpoint, REST** | `.claude/rules/api-standards.md` |
| **component, UI, frontend** | `.claude/rules/frontend-standards.md` |
| **migration, schema, database** | `.claude/rules/database-standards.md` |
| **docker, deploy, CI/CD** | `.claude/rules/devops-standards.md` |
| **test, coverage, TDD** | `.claude/rules/testing-standards.md` |
| **agent, skill, hook** | `.claude/rules/agent-standards.md` |

## Rules

1. **Never guess** — ask when unclear (max 2 questions)
2. **Respect explicit commands** — /cwe:builder, /feature-dev etc. bypass this
3. **Context isolation** — agent result is summary, not full context
4. **Plugin skills first** — check plugin skill match before agent match

## Examples

```
"Fix login bug"           → builder
"How does auth work?"     → explainer
"Audit the API"           → security
"Create release"          → devops
"Write tests for auth"    → quality (may delegate to builder)
"What if we used GraphQL" → innovator
"Look at this"            → ASK: "Fix, explain, or analyze?"
"Build auth with tests and docs" → delegator (builder + quality + researcher)
"Fix bug and add regression test" → delegator (builder + quality)
```
