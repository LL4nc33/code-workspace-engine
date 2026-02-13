---
description: Ask questions about the project, discuss ideas (READ-ONLY)
allowed-tools: ["Task", "AskUserQuestion"]
---

# CWE Ask

Answer questions and discuss ideas about the project.

**Usage:** `/cwe:ask [question]`

## Interactive Mode (no question provided)

If user runs `/cwe:ask` without a question, use AskUserQuestion:

```
Question: "What would you like to know?"
Header: "Topic"
Options:
  1. "Code understanding" - How does X work?
  2. "Architecture" - System design questions
  3. "Discuss an idea" - Think through options
  4. "General question" - (User types via Other)
```

### If "Code understanding":
```
Question: "What aspect?"
Header: "Code"
Options:
  1. "Specific function/class" - Explain a symbol
  2. "Data flow" - How data moves through system
  3. "Control flow" - Execution path
  4. "Dependencies" - What uses what
```

### If "Architecture":
```
Question: "What level?"
Header: "Level"
Options:
  1. "High-level overview" - System structure
  2. "Component interaction" - How parts connect
  3. "Design decisions" - Why it's built this way
  4. "Patterns used" - Architectural patterns
```

### If "Discuss an idea":
```
Question: "What kind of idea?"
Header: "Idea Type"
Options:
  1. "New feature" - Something to add
  2. "Improvement" - Make something better
  3. "Alternative approach" - Different way to do X
  4. "General thought" - (User types via Other)
```

Then:
```
Question: "Describe your question or idea:"
Header: "Details"
Options:
  1. "Point me to relevant code first" - Explore, then discuss
  2. "I'll describe it" - (User types via Other)
```

## Direct Mode (question provided)

If user provides a question like `/cwe:ask how does auth work?`, skip the menus and delegate directly.

## Process

Delegate using the Task tool:

```
subagent_type: ask
prompt: [constructed or provided question]
```

## Behavior

1. **READ-ONLY** - No code changes
2. Answer questions about codebase, architecture, patterns
3. Discuss ideas without implementing
4. Uses serena for code navigation

## Plugin Integration

The ask agent has:
- READ-ONLY access
- **serena** MCP tools for code navigation
- Patient, thoughtful responses
- No implementation actions

## Note

Ideas mentioned in conversation are automatically captured by the idea-observer hook.
Use `/cwe:innovator` to review and develop collected ideas.
