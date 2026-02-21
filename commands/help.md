---
description: Show CWE documentation and available commands
allowed-tools: ["Read"]
---

# CWE Help

Display comprehensive help for CWE and all installed plugins.

## Output

```markdown
# CWE - Code Workspace Engine v0.5.1

Natural language orchestration for spec-driven development.

## 6 Core Principles

1. **Agent-First** - All work delegated to specialized agents
2. **Auto-Delegation** - Intent recognition maps requests to agents/skills
3. **Spec-Driven** - Features: specs → tasks → implementation
4. **Context Isolation** - Agent work returns only summaries
5. **Plugin Integration** - Agents leverage installed plugin skills
6. **Always Document** - Every change updates memory, CHANGELOG, and docs

## CWE Commands

| Command | Purpose |
|---------|---------|
| `/cwe:init` | Initialize project + install missing plugins |
| `/cwe:plugins` | Check and install plugin + MCP dependencies |
| `/cwe:start` | Guided workflow (phase detection) |
| `/cwe:help` | This help |
| `/cwe:ask` | Questions, discussions (READ-ONLY) |
| `/cwe:builder` | Implementation, fixes |
| `/cwe:architect` | Design, ADRs, spec shaping |
| `/cwe:devops` | CI/CD, Docker, releases |
| `/cwe:security` | Audits, OWASP |
| `/cwe:researcher` | Docs, analysis |
| `/cwe:explainer` | Explanations |
| `/cwe:quality` | Tests, coverage, health dashboard |
| `/cwe:innovator` | Brainstorming, idea backlog (4 modes) |
| `/cwe:guide` | Process improvement, standards discovery |
| `/cwe:screenshot` | Clipboard screenshot capture + analysis |
| `/cwe:web-research` | Web search + scraping (SearXNG, Firecrawl) |

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
| "build auth with tests" | delegator + builder + quality |

**Override:** Say "manual" to disable.

## Standards System

Standards loaded automatically via `.claude/rules/` with `paths` frontmatter.
8 domains: global, api, frontend, database, devops, testing, agent, documentation.

- `/cwe:guide discover` — auto-discover patterns → generate rules
- `/cwe:guide index` — regenerate `_index.yml` with keyword detection

## Safety Gate

Pre-commit scanning via PreToolUse hook:
- Scans for secrets, API keys, credentials, PII
- Validates .gitignore completeness
- Blocks dangerous commits with remediation guidance
- Triggers on: `git commit`, `git push`, `git add -A`

## Git Standards

Enforced via PreToolUse hooks:
- **Conventional Commits** — `type(scope): subject` format
- **Branch Naming** — `feature/`, `fix/`, `hotfix/`, `chore/`, `release/`
- Auto-generated release notes from commit history

## Idea Capture

Ideas auto-captured per-project via hooks:
- Keywords: idea, what if, could we, alternative, improvement
- Stored: `~/.claude/cwe/ideas/<project-slug>.jsonl`
- Review: `/cwe:innovator` (default | all | review | develop)

## Memory System

Daily Logs + MEMORY.md index, auto-injected at session start:
- `memory/MEMORY.md` — Curated index (max 200 lines, always loaded)
- `memory/YYYY-MM-DD.md` — Daily logs (today + yesterday injected)
- `memory/decisions.md` — Project ADRs
- `memory/patterns.md` — Recognized work patterns
- `memory/project-context.md` — Tech stack, priorities (auto-seeded)
- Memory via Serena (`write_memory`, `read_memory`, `list_memories`) when available

## Workflow Phases

1. **Plan** - `workflow/product/mission.md`
2. **Spec** - `workflow/specs/<feature>/` (Shape-Spec Interview)
3. **Tasks** - Break into implementable tasks
4. **Build** - Implement with agents (parallel wave execution)
5. **Review** - Quality gates + safety verification

## Quick Start

1. `/cwe:init` - Set up project
2. Edit `workflow/product/mission.md`
3. `/cwe:start` - Begin guided workflow
```
