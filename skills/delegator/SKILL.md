---
name: delegator
description: >
  Use PROACTIVELY when a user request requires TWO OR MORE different agents
  to complete. Decomposes multi-step requests into sub-tasks with dependency
  ordering and executes them via wave-based parallel dispatch.
  NOT for single-agent tasks (-> auto-delegation directly).
---

# Delegator — Multi-Agent Request Coordination

Decompose multi-step user requests into sub-tasks and dispatch them to specialized agents in dependency-ordered waves.

**Scope:** Requests that require 2+ different CWE agents working together.
**Not for:** Single-agent tasks (use auto-delegation), full feature workflows (use `/cwe:start`).

## When to Activate

**Both criteria must be met:**

1. Request keywords match **2+ different agents** (from the Intent → Agent keyword table)
2. User expects a **coordinated end result** (not separate answers)

### Detection Signals

- **Conjunctions across domains:** "Build X **and** write tests **and** update docs"
- **Compound verbs:** "implement, test, and deploy"
- **Feature-level implicit:** "Add user authentication" (implies code + tests + docs)
- **Completeness keywords:** "full", "complete", "end-to-end", "komplett", "mit allem"
- **Explicit sequencing:** "First X, then Y, then Z"

### NOT Multi-Step (Single Agent)

- One verb, one domain: "Fix login bug" → builder
- Question about multiple topics: "Explain auth and caching" → explainer
- Vague/unclear: "Look at the API" → ask (clarify first)

## Decomposition Algorithm

### Step 1: Identify Concerns

Scan the request for keywords that map to different agents:

| Keywords Found | Agent |
|---------------|-------|
| implement, build, create, fix, code, feature, bug, refactor | builder |
| test, write tests, coverage, quality, validate | quality |
| security, audit, vulnerability, scan | security |
| deploy, docker, ci, cd, release | devops |
| design, architecture, adr, api, schema | architect |
| analyze, document, research, compare | researcher |
| explain, how, what, why, understand | explainer |

### Step 2: Create Sub-Tasks

Create one `TaskCreate` per identified concern. Each sub-task gets:
- A clear, single-agent scope
- The relevant portion of the original request
- Context from the original request (what the user wants overall)

### Step 3: Assign Dependencies

Use default phase ordering:

| Phase | Agents | Depends On |
|-------|--------|-----------|
| 1 Design | architect | — |
| 2 Build | builder, devops | architect (if present) |
| 3 Verify | quality, security | builder (if present) |
| 4 Document | researcher | builder (if present) |

Skip phases where no agent was identified. Dependencies only apply between phases that both exist.

### Step 4: Confirm with User

Present the decomposition plan:

```
I'll split this into [N] sub-tasks:

1. [architect] Design the API schema
2. [builder] Implement the endpoints (depends on 1)
3. [quality] Write integration tests (depends on 2)
4. [researcher] Update API documentation (depends on 2)

Tasks 3 and 4 will run in parallel after task 2 completes.

Proceed?
```

**Skip confirmation** when user says "just do it", "mach einfach", or similar.

## Execution — Wave Algorithm

After confirmation, execute using the wave pattern from `/cwe:start`:

### Wave Loop

1. `TaskList` → filter for unblocked tasks (no open `blockedBy`)
2. Select up to **3 tasks** per wave
3. Dispatch each via `Task` tool with the appropriate `subagent_type`
4. Wait for all tasks in the wave to complete
5. `TaskUpdate` each as `completed`
6. Repeat until no tasks remain

### Dispatch Template

For each sub-task, dispatch with:
- `subagent_type`: The CWE agent type (e.g., `cwe:builder`)
- `prompt`: The sub-task description + relevant context from the original request
- Context isolation: Each agent gets only its portion

## Error Handling

- **Agent failed** → Pause execution, report to user, ask: retry / skip / abort
- **No auto-retry** — failures need human judgment
- **Dependency failed** → Mark dependent tasks as blocked, report which tasks are affected
- **No cascading failures** — one failure doesn't abort unrelated parallel tasks

## Documentation Reminder

After all waves complete successfully:

1. Check if any docs need updating (Principle 6: Always Document)
2. Remind about: memory/, CHANGELOG.md, docs/ updates
3. If researcher was part of the delegation, docs are likely already handled

## Common Patterns

| Pattern | Waves |
|---------|-------|
| **Feature Dev** | architect → builder → quality + researcher |
| **Bug Fix + Test** | builder → quality |
| **Refactor + Verify** | builder → quality |
| **Security Hardening** | security → builder → security |
| **Full Pipeline** | architect → builder → quality + security + researcher → devops |

## Rules

1. **Min 2 agents** — if only 1 agent identified, fall back to auto-delegation
2. **Max 5 sub-tasks** — above 5, recommend `/cwe:start` with a full spec
3. **Confirm before dispatch** (unless "just do it" / "mach einfach")
4. **Context isolation** — each agent gets only its sub-task, not the full plan
5. **No cascading failures** — independent tasks continue even if a parallel task fails
6. **Document after completion** — remind about Principle 6 updates
