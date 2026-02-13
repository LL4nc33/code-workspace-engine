---
name: cwe-principles
description: >
  CWE Core Principles - Use PROACTIVELY at session start or when unsure about
  workflow, delegation, or how components interact. Core operating manual.
---

# CWE Core Principles

## 5 Key Principles

| # | Principle | Description |
|---|-----------|-------------|
| 1 | Agent-First | All code work is delegated to specialized agents |
| 2 | Auto-Delegation | Intent recognition maps user requests to agents |
| 3 | Spec-Driven | Features start with specs, then tasks, then implementation |
| 4 | Context Isolation | Agent work stays in agent context (returns summary) |
| 5 | Plugin Integration | Agents leverage installed plugin skills (superpowers, serena, feature-dev, etc.) |

## Workflow Overview

```
User says something
    ↓
[Intent Recognition] → Matches agent? → Delegate to agent
    ↓
[Agent Works] → Isolated context, full tool access
    ↓
[Result Summary] → Compact result back to main chat
```

## When Which Agent

| Situation | Agent | What happens |
|-----------|-------|--------------|
| User wants to code | builder | Implements with TDD |
| User wants to understand | explainer | Explains code/concepts |
| User wants to discuss/ask | ask | Questions, discussions (READ-ONLY) |
| User wants to design | architect | Creates ADRs, designs |
| User wants to deploy | devops | CI/CD, Docker, K8s |
| User wants security audit | security | OWASP review |
| User wants docs | researcher | Analysis, documentation |
| User wants ideas | innovator | Brainstorming, idea backlog |
| User wants quality check | quality | Coverage, metrics |
| User wants process help | guide | Workflow optimization |

## How CWE Saves Tokens

1. **Context Isolation** - Agent work stays with agent
2. **Selective Standards** - Only relevant standards injected
3. **Compact Skills** - Quick reference tables, not prose

## Autonomous Behavior

### The system automatically:

- Recognizes intent from user messages
- Delegates to appropriate agent
- Injects relevant standards
- Returns compact summaries

### The user only needs to:

- State intent clearly ("fix bug", "explain X")
- Answer clarifying questions (max 2)
- Review results

## Quick Reference

```
Code work   → builder (automatic)
Explain     → explainer (automatic)
Plan        → EnterPlanMode (automatic)
Deploy      → devops (automatic)
Audit       → security (automatic)
```

## Error Handling

| Problem | Solution |
|---------|----------|
| Wrong agent chosen | Say "manual" or use explicit /agent command |
| Need more context | Agent will ask or read files |
| Complex task | Main Chat coordinates multiple agents |

## Harmonious Interaction

```
┌────────────────────────────────────────────────────────────────┐
│                    USER INTERACTION                             │
│  "fix bug" / "explain X" / "plan feature" / "deploy"           │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│ INTENT RECOGNITION (Skills via Description-Keywords)           │
│                                                                 │
│  Intent recognized?                                             │
│  ├─ Code work    → auto-delegation → builder                   │
│  ├─ Explanation  → auto-delegation → explainer                 │
│  ├─ Planning     → planning → EnterPlanMode                    │
│  ├─ Security     → auto-delegation → security                  │
│  └─ Deployment   → auto-delegation → devops                    │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│ AGENT EXECUTION (Isolated Context)                              │
│                                                                 │
│  Agent receives:                                                │
│  ├─ User request                                                │
│  ├─ Relevant standards (auto-injected)                         │
│  └─ Full tool access (per agent definition)                    │
│                                                                 │
│  Agent returns:                                                 │
│  └─ Compact summary (not full work context)                    │
└────────────────────────────────────────────────────────────────┘

## Intuitive User Flow

1. **Just say what you want** - CWE recognizes intent
2. **Get guided** - CWE asks if unclear (max 2 questions)
3. **Work is delegated** - Agent works in isolated context
4. **Result comes back** - Compact summary, not full context
5. **Iterate** - Continue with next request
```
