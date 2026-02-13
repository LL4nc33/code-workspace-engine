---
name: agent-detection
description: >
  Use during Build phase to assign agents to structured tasks from tasks.md.
  Maps task metadata and keywords to specialized agents.
  NOT for interactive user requests — see auto-delegation for that.
---

# Agent Detection

Assign the right agent to structured tasks during the Build phase.

**Scope:** Task-to-agent assignment in `/cwe:start` Build phase and parallel orchestration.
**Not for:** Free-text user requests in chat (→ use `auto-delegation`).

## Detection Logic

```
Task from tasks.md
    ↓
1. metadata.agent set? → Use explicit agent
    ↓ no
2. metadata.skill set? → Infer agent from skill
    ↓ no
3. Keyword scan (subject + description) → First match wins
    ↓ no match
4. Fallback → builder
```

## Keyword → Agent Mapping

Priority order (first match wins):

| Priority | Agent | Keywords |
|----------|-------|----------|
| 1 | **builder** | implement, fix, build, create, code, feature, bug, refactor |
| 2 | **quality** | test, write tests, coverage, quality, validate, assert, metrics, flaky, gate |
| 3 | **devops** | deploy, docker, ci, cd, release, kubernetes, k8s, terraform |
| 4 | **security** | security, audit, vulnerability, scan, gdpr, owasp, cve |
| 5 | **explainer** | explain, how, why, what, understand |
| 6 | **architect** | design, architecture, adr, api, schema |
| 7 | **researcher** | analyze, document, research, compare |
| 8 | **innovator** | brainstorm, idea, ideas, what if, alternative, explore |
| 9 | **guide** | workflow, process, pattern, improve, optimize, optimization |

**Fallback:** `builder` (if no keywords match)

## Metadata Override

Tasks in `tasks.md` can specify agent and skill explicitly:

```yaml
metadata:
  agent: security      # Skip keyword detection
  skill: systematic-debugging  # Specific skill to invoke
  priority: 1          # Execution order (lower = first)
```

`metadata.agent` always takes precedence over keyword detection.

## "test" Routing in Tasks

Tasks with "test" keywords are assigned to **quality**.
Quality agent decides execution:
- Coverage gaps, metrics, validation → handles directly
- Writing implementation tests → delegates to builder via subagent
- CI/pipeline test config → delegates to devops via subagent

## Integration with Parallel Execution

During wave execution in `/cwe:start`:

1. Pending tasks filtered by `blockedBy` status
2. Up to 3 unblocked tasks selected per wave (sorted by `metadata.priority`)
3. Each task assigned an agent via this detection logic
4. Agents spawned in parallel via `Task` tool

## Examples

```yaml
# Explicit agent (metadata override)
- subject: "Audit auth endpoints"
  metadata:
    agent: security
  → security (explicit)

# Keyword detection
- subject: "Implement user profile API"
  → builder (keyword: implement)

# Test task
- subject: "Write integration tests for payments"
  → quality (keyword: test)

# No match
- subject: "Update the README"
  → builder (fallback)
```
