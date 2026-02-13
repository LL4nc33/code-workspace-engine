---
name: planning
description: >
  Use PROACTIVELY when user asks to: plan, create implementation plan,
  prioritize, design architecture, scope a feature, roadmap.
  Triggers EnterPlanMode for structured planning.
---

# Planning Skill

This skill triggers Plan Mode for structured planning tasks.

## When to Use Plan Mode

### Trigger Keywords

- plan, implementation plan, planning document
- prioritize, set priorities
- design architecture, system design
- scope, define scope
- roadmap, milestones
- phase planning, sequence

## Criteria for Plan Mode

### USE EnterPlanMode when:

1. **Multi-Step Task** (>3 files affected)
   - Feature implementation
   - Refactoring across modules
   - Data/API migration

2. **Architecture Decisions**
   - New system design
   - Technology choice
   - API design

3. **Unclear Scope**
   - "Improve performance"
   - "Make it more scalable"
   - Exploratory tasks

4. **Cross-Domain Work**
   - Frontend + Backend + Database
   - Infrastructure + Code
   - Security + Implementation

### DO NOT use EnterPlanMode when:

1. **Single-File Fix**
   - Fix typo
   - Simple bug in one file
   - Small change (<50 lines)

2. **Explicit Command**
   - User used /workflow:* command
   - User says "just do it"
   - Clear, specific instruction

3. **Explanation/Question**
   - "What does this code do?"
   - "Explain X to me"
   - Pure information, no changes

## Action on Trigger

When a planning keyword is detected:

```
1. Check if Plan Mode criteria are met
2. If yes:
   → Call EnterPlanMode
   → Tell user: "This is a planning task. I'm entering Plan Mode to develop a structured approach."
3. If no:
   → Continue normally (auto-delegation)
```

## Examples

### Activate Plan Mode

```
User: "Create an implementation plan for the new auth system"
→ EnterPlanMode (Multi-Step, Architecture)

User: "How should we design the data model?"
→ EnterPlanMode (Architecture decision)

User: "Plan the TypeScript migration"
→ EnterPlanMode (Multi-Step, Cross-Domain)

User: "Prioritize the next features"
→ EnterPlanMode (Roadmap/Planning)
```

### NOT Plan Mode

```
User: "Fix the typo in README"
→ Fix directly (Single-File, trivial)

User: "/workflow:create-tasks"
→ Explicit command, no Plan Mode

User: "Explain how auth works"
→ Delegate to explainer (Explanation, no changes)
```

## Integration with Superpowers

For detailed planning, the `superpowers:writing-plans` skill provides structured plan templates. Plan Mode produces plans that can then be executed with `superpowers:executing-plans`.
