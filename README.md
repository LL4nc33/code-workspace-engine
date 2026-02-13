# CWE - Claude Workflow Engine v0.4.0a

Natural language orchestration for spec-driven development and project lifecycle management.

## Installation

```bash
claude plugin install cwe
# Or local development:
claude --plugin-dir /path/to/claude-workflow-engine
```

## Quick Start

```bash
/cwe:init     # Initialize project + install recommended plugins
/cwe:start    # Guided workflow with interactive menus
/cwe:help     # Documentation
```

Or just say what you need:

```
"Fix the login bug"           → builder + systematic-debugging
"Build a user profile page"   → builder + frontend-design
"Explain how auth works"      → explainer + serena
"What if we used GraphQL?"    → innovator + brainstorming
```

## What is CWE?

CWE is a **project lifecycle manager** built as a Claude Code plugin. It provides:

- **10 Specialized Agents** — ask, architect, builder, devops, quality, security, researcher, explainer, innovator, guide
- **Auto-Delegation** — describe what you need, CWE picks the right agent
- **Spec-Driven Workflow** — Plan → Spec → Tasks → Build → Review
- **Project Standards** — consistent docs, safety gates, git conventions
- **Plugin Orchestration** — coordinates superpowers, serena, feature-dev, and more

## 5 Core Principles

1. **Agent-First** — All work delegated to specialized agents
2. **Auto-Delegation** — Intent recognition maps requests to agents/skills
3. **Spec-Driven** — Features: specs → tasks → implementation
4. **Context Isolation** — Agent work returns only compact summaries
5. **Plugin Integration** — Agents leverage installed plugin skills

## Commands

### Workflow
| Command | Purpose |
|---------|---------|
| `/cwe:init` | Initialize project + install recommended plugins |
| `/cwe:start` | Guided workflow (phase detection) |
| `/cwe:help` | Full documentation |

### Agents
| Command | Purpose |
|---------|---------|
| `/cwe:ask` | Questions, discussions (READ-ONLY) |
| `/cwe:builder` | Implementation, fixes |
| `/cwe:architect` | Design, ADRs |
| `/cwe:devops` | CI/CD, Docker, releases |
| `/cwe:security` | Audits, OWASP |
| `/cwe:researcher` | Docs, analysis |
| `/cwe:explainer` | Explanations |
| `/cwe:quality` | Tests, coverage |
| `/cwe:innovator` | Brainstorming, idea backlog |
| `/cwe:guide` | Process improvement |

## Plugin Dependencies

`/cwe:init` checks and offers to install:

| Plugin | Level | Purpose |
|--------|-------|---------|
| superpowers | Required | TDD, debugging, planning |
| serena | Recommended | Semantic code analysis |
| feature-dev | Recommended | 7-phase feature workflow |

## Project Structure (after `/cwe:init`)

```
your-project/
├── VERSION                 # Single Source of Truth for version
├── CHANGELOG.md            # Keep-a-Changelog format
├── DEVLOG.md               # Developer journal
├── docs/
│   ├── README.md           # Auto-generated project overview
│   ├── ARCHITECTURE.md     # System design
│   ├── API.md              # Endpoint documentation
│   ├── SETUP.md            # Installation guide
│   └── decisions/          # Architecture Decision Records
├── workflow/
│   ├── config.yml          # CWE configuration
│   ├── ideas.md            # Idea backlog
│   ├── product/
│   │   └── mission.md      # Product vision
│   ├── specs/              # Feature specifications
│   └── standards/          # Project-specific standards
└── .claude/
    └── rules/              # Native Claude Code rules (paths-scoped)
```

## Workflow Phases

1. **Plan** — Define product vision
2. **Spec** — Write feature specifications
3. **Tasks** — Break into implementable tasks
4. **Build** — Implement with agents (parallel wave execution)
5. **Review** — Quality verification + safety gates

## Version History

See [CHANGELOG.md](CHANGELOG.md) for full history.
See [ROADMAP.md](ROADMAP.md) for planned features and design decisions.

- **0.5.0** (planned) — Native alignment, project lifecycle management, safety gates
- **0.4.0a** — Plugin integration, skill cleanup, roadmap
- **0.3.1** — Simplified commands, superpowers integration
- **0.3.0** — Plugin structure created
- **0.2.9a** — Last CLI-focused version

## License

MIT

## Author

[LL4nc33](https://github.com/LL4nc33)
