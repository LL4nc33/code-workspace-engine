---
description: Delegate to explainer agent - explanations, code walkthroughs, learning
allowed-tools: ["Task", "AskUserQuestion"]
---

# Explainer

Delegate to the **explainer** agent for explanations and learning.

**Usage:** `/cwe:explainer [question]`

## Interactive Mode (no question provided)

If user runs `/cwe:explainer` without a question, use AskUserQuestion:

```
Question: "What would you like explained?"
Header: "Explain"
Options:
  1. "Code walkthrough" - Step through code
  2. "Concept explanation" - Explain a pattern/technique
  3. "Error understanding" - What does this error mean?
  4. "Comparison" - Difference between X and Y
```

### If "Code walkthrough":
```
Question: "What should I walk through?"
Header: "Walkthrough"
Options:
  1. "Specific file" - One file in detail
  2. "Feature flow" - End-to-end feature
  3. "Entry point" - Where execution starts
  4. "Recent changes" - What changed recently
```

Then:
```
Question: "How detailed?"
Header: "Depth"
Options:
  1. "High-level" - Quick overview
  2. "Detailed" - Line by line
  3. "Educational" - Explain patterns and why
```

### If "Concept explanation":
```
Question: "What concept?"
Header: "Concept"
Options:
  1. "Design pattern" - Pattern used in code
  2. "Framework feature" - How framework X works
  3. "Language feature" - Syntax or language concept
  4. "Something else" - (User types via Other)
```

### If "Error understanding":
```
Question: "Describe the error:"
Header: "Error"
Options:
  1. "Paste error message" - (User types via Other)
  2. "It's in the logs" - I'll find recent errors
  3. "Test failure" - A test is failing
```

### If "Comparison":
```
Question: "Compare what?"
Header: "Compare"
Options:
  1. "Two approaches" - Implementation options
  2. "Two files" - Differences between files
  3. "Before/after" - What changed
  4. "Concepts" - (User types via Other)
```

## Direct Mode (question provided)

If user provides a question like `/cwe:explainer how does auth work?`, skip the menus and delegate directly.

## Process

Delegate using the Task tool:

```
subagent_type: explainer
prompt: [constructed or provided question]
```

## Plugin Integration

The explainer agent has:
- READ-ONLY access
- **serena** MCP tools for code navigation
- **feature-dev:code-explorer** for deep analysis
- Patient, educational approach
- Progressive disclosure (summary first, then details)

## Output Style

Explanations include:
- Summary first (1-2 sentences)
- Detailed breakdown on request
- Code snippets with annotations
- Diagrams when helpful (Mermaid)
