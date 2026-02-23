---
description: MUSS VERWENDET WERDEN für Workflow-Optimierung, Process-Improvement, Pattern-Erkennung und Standards-Evolution. Experte für kontinuierliche Verbesserung.
allowed-tools: ["Task", "AskUserQuestion"]
---

# Guide

Delegate to the **guide** agent for process improvement and workflow optimization.

**Usage:** `/cwe:guide [topic]`

## Interactive Mode (no topic provided)

If user runs `/cwe:guide` without a topic, use AskUserQuestion:

```
Question: "What would you like to improve?"
Header: "Improve"
Options:
  1. "Workflow" - Development process
  2. "Standards" - Coding conventions
  3. "Efficiency" - Speed up development
  4. "Team practices" - Collaboration patterns
```

### If "Workflow":
```
Question: "Which aspect?"
Header: "Workflow"
Options:
  1. "CWE workflow" - This workflow system
  2. "Git workflow" - Branching, commits, PRs
  3. "Review process" - Code review practices
  4. "Release process" - Deployment workflow
```

Then:
```
Question: "What's the goal?"
Header: "Goal"
Options:
  1. "Analyze current state" - Understand what's happening
  2. "Find bottlenecks" - Identify slowdowns
  3. "Suggest improvements" - Get recommendations
  4. "Compare to best practices" - Benchmark
```

### If "Standards":
```
Question: "Standards for what?"
Header: "Standards"
Options:
  1. "Code style" - Formatting, naming
  2. "Architecture" - Design patterns
  3. "Testing" - Test conventions
  4. "Documentation" - Doc standards
```

Then:
```
Question: "What to do?"
Header: "Action"
Options:
  1. "Extract from code" - Discover existing patterns
  2. "Compare to industry" - Check best practices
  3. "Create new standard" - Define conventions
  4. "Review existing" - Check CLAUDE.md standards
```

### If "Efficiency":
```
Question: "Efficiency of what?"
Header: "Focus"
Options:
  1. "Development cycle" - Code faster
  2. "Agent usage" - Better delegation
  3. "Tool usage" - IDE, CLI, plugins
  4. "Build/test" - Faster feedback loop
```

### If "Team practices":
```
Question: "Which practice?"
Header: "Practice"
Options:
  1. "Communication" - How team communicates
  2. "Knowledge sharing" - Documentation, onboarding
  3. "Code ownership" - Who owns what
  4. "Pair/mob programming" - Collaboration
```

## Direct Mode (topic provided)

If user provides a topic like `/cwe:guide improve our git workflow`, skip the menus and delegate directly.

## Process

Delegate using the Task tool:

```
subagent_type: guide
prompt: [constructed or provided topic]
```

## Plugin Integration

The guide agent has:
- READ-ONLY access
- Pattern recognition expertise
- **claude-md-improver** for CLAUDE.md maintenance
- Workflow optimization focus
- Standards extraction capability

## Output

Guide produces:
- Current state analysis
- Identified patterns (good and bad)
- Improvement recommendations
- Priority ranking
- Implementation suggestions
