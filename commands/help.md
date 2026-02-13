---
description: Show CWE documentation and available commands
allowed-tools: ["Read"]
---

# CWE Help

Display comprehensive help for CWE and all installed plugins.

## Output

```markdown
# CWE - Claude Workflow Engine v0.4.0a

Natural language orchestration for spec-driven development.

## Core Principles

1. **Agent-First** - All work delegated to specialized agents
2. **Auto-Delegation** - Intent recognition maps requests to agents/skills
3. **Spec-Driven** - Features: specs → tasks → implementation
4. **Context Isolation** - Agent work returns only summaries
5. **Plugin Integration** - Agents leverage installed plugin skills

## CWE Commands

| Command | Purpose |
|---------|---------|
| `/cwe:init` | Initialize project + install missing plugins |
| `/cwe:start` | Guided workflow (phase detection) |
| `/cwe:help` | This help |
| `/cwe:ask` | Questions, discussions (READ-ONLY) |
| `/cwe:builder` | Implementation, fixes |
| `/cwe:architect` | Design, ADRs |
| `/cwe:devops` | CI/CD, Docker |
| `/cwe:security` | Audits, OWASP |
| `/cwe:researcher` | Docs, analysis |
| `/cwe:explainer` | Explanations |
| `/cwe:quality` | Tests, coverage |
| `/cwe:innovator` | Brainstorming, idea backlog |
| `/cwe:guide` | Process improvement |

## Plugin Commands

| Command | Plugin | Purpose |
|---------|--------|---------|
| `/feature-dev` | feature-dev | 7-phase feature workflow |
| `/create-plugin` | plugin-dev | Plugin creation |
| `/revise-claude-md` | claude-md-management | Update CLAUDE.md |
| `/brainstorm` | superpowers | Creative ideation |
| `/write-plan` | superpowers | Implementation planning |
| `/execute-plan` | superpowers | Execute plans |

## Auto-Delegation

Just say what you need:

| You Say | Routes To |
|---------|-----------|
| "fix the bug" | builder + systematic-debugging |
| "build a UI component" | builder + frontend-design |
| "explain this code" | explainer + serena |
| "what if we..." | innovator + brainstorming |
| "review my changes" | quality + code-reviewer |
| "plan the refactoring" | architect + writing-plans |
| "simplify this function" | code-simplifier |
| "create a new feature" | /feature-dev |

**Override:** Say "manual" to disable.

## Installed Plugins

### superpowers (v4.1.1)
| Skill | When to Use |
|-------|-------------|
| `brainstorming` | Before creative work |
| `test-driven-development` | Implementing features |
| `systematic-debugging` | Bugs, test failures |
| `verification-before-completion` | Before claiming done |
| `writing-plans` | Multi-step tasks |
| `requesting-code-review` | After features |

### serena (MCP)
Semantic code analysis: `find_symbol`, `find_referencing_symbols`, `get_symbols_overview`, `replace_symbol_body`

### feature-dev
`/feature-dev` command + agents: `code-explorer`, `code-architect`, `code-reviewer`

### frontend-design
`frontend-design` skill for production-grade UI

### code-simplifier
`code-simplifier` agent for refactoring

### claude-md-management
`/revise-claude-md` + `claude-md-improver` skill

### plugin-dev
`/create-plugin` + skills: command, skill, hook, agent, mcp development

## Workflow Phases

1. **Plan** - `workflow/product/mission.md`
2. **Spec** - `workflow/specs/<feature>/spec.md`
3. **Tasks** - Break into tasks
4. **Build** - Implement with agents
5. **Review** - Quality verification

## Idea Capture

Ideas auto-captured via hooks:
- Keywords: idea, what if, could we, alternative, improvement
- Review with `/cwe:innovator`
- Stored in `workflow/ideas.md`

## Quick Start

1. `/cwe:init` - Set up project + install recommended plugins
2. Edit `workflow/product/mission.md`
3. `/cwe:start` - Begin guided workflow

## Plugin Dependencies

`/cwe:init` automatically checks and offers to install:

| Plugin | Level |
|--------|-------|
| superpowers | Required |
| serena | Recommended |
| feature-dev | Recommended |
| frontend-design | Optional |
| code-simplifier | Optional |
| claude-md-management | Optional |
| plugin-dev | Optional |
```
