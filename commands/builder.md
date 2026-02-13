---
description: Delegate to builder agent - implementation, bug fixes, code changes
allowed-tools: ["Task", "AskUserQuestion"]
---

# Builder

Delegate to the **builder** agent for implementation work.

**Usage:** `/cwe:builder [task]`

## Interactive Mode (no task provided)

If user runs `/cwe:builder` without a task, use AskUserQuestion:

```
Question: "What type of work?"
Header: "Task Type"
Options:
  1. "Fix a bug" - Debug and fix an issue
  2. "Implement feature" - Build new functionality
  3. "Refactor code" - Improve existing code
  4. "Write tests" - Add test coverage
```

Then based on selection:

### If "Fix a bug":
```
Question: "How would you describe the bug?"
Header: "Bug Type"
Options:
  1. "Error/Exception" - Code throws an error
  2. "Wrong behavior" - Works but incorrect result
  3. "Performance issue" - Too slow
  4. "UI/Display issue" - Visual problem
```

### If "Implement feature":
```
Question: "What kind of feature?"
Header: "Feature"
Options:
  1. "API endpoint" - Backend route/handler
  2. "UI component" - Frontend element
  3. "Data model" - Database/schema change
  4. "Integration" - External service
```

### If "Refactor code":
```
Question: "What's the goal?"
Header: "Refactor Goal"
Options:
  1. "Simplify" - Make code cleaner
  2. "Extract" - Split into smaller pieces
  3. "Consolidate" - Merge duplicates
  4. "Modernize" - Update patterns/syntax
```

### If "Write tests":
```
Question: "What type of tests?"
Header: "Test Type"
Options:
  1. "Unit tests" - Test individual functions
  2. "Integration tests" - Test components together
  3. "E2E tests" - Test full user flows
  4. "Missing coverage" - Find untested code
```

After selection, ask for specifics:
```
Question: "Describe what needs to be done:"
Header: "Details"
Options:
  1. "Show me the code first" - Explore before deciding
  2. "I'll describe it" - (User types via Other)
```

## Direct Mode (task provided)

If user provides a task like `/cwe:builder fix the login bug`, skip the menus and delegate directly.

## Process

Delegate using the Task tool:

```
subagent_type: builder
prompt: [constructed or provided task]
```

## Plugin Integration

The builder agent automatically uses:
- **superpowers:test-driven-development** - For new features
- **superpowers:systematic-debugging** - For bug fixes
- **superpowers:verification-before-completion** - Before finishing
- **frontend-design** - For UI work
- **code-simplifier** - For refactoring
- **serena** - For semantic code manipulation
