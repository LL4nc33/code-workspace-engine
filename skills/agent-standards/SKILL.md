---
name: agent-standards
description: Agent system conventions and patterns. Use PROACTIVELY when creating, modifying, or reviewing agent definitions, skills, or orchestration patterns.
allowed-tools: Read, Grep, Glob
context: fork
agent: Explore
---

# Agent Standards

## Instructions

Apply agent conventions from workflow/standards/agents/ when:
- Creating new agent definitions
- Defining skills or commands
- Setting up orchestration patterns
- Reviewing agent permission models

## Key Conventions

### Agent Definition
- Frontmatter required: name, description, tools
- Include PROACTIVELY in description for auto-delegation
- Follow principle of least privilege for tool access

### Permission Levels
- READ-ONLY: Read, Grep, Glob
- TASK-DELEGATION: Task, Read, Grep, Glob
- FULL: All tools
- RESTRICTED: Specific tool subset

### Communication
- File artifacts as shared state (not direct messaging)
- Specs folder as communication channel
- Standards auto-loaded via Skills system

## Reference Files
- @workflow/standards/agents/agent-conventions.md
