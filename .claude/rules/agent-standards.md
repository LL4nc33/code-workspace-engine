---
paths:
  - "**/agents/**"
  - "**/skills/**"
  - "**/commands/**"
  - "**/hooks/**"
---

# Agent Standards

## Agent Definition
- Frontmatter required: name, description, tools
- Include PROACTIVELY in description for auto-delegation
- Follow principle of least privilege for tool access

## Permission Levels
- READ-ONLY: Read, Grep, Glob
- TASK-DELEGATION: Task, Read, Grep, Glob
- FULL: All tools
- RESTRICTED: Specific tool subset

## Communication
- File artifacts as shared state (not direct messaging)
- Specs folder as communication channel
- Standards auto-loaded via rules system

