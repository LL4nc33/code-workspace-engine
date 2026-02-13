# CWE - Claude Workflow Engine v0.4.1

Natural language orchestration for spec-driven development and project lifecycle management.

## Installation

```bash
# 1. Clone the plugin
git clone https://github.com/LL4nc33/claude-workflow-engine.git

# 2. Set up the alias (add to ~/.bashrc or ~/.zshrc)
alias cwe='claude --plugin-dir /path/to/claude-workflow-engine --dangerously-skip-permissions'

# 3. Start CWE in any project
cd your-project
cwe
```

After adding the alias, restart your terminal or run `source ~/.bashrc`.

## Quick Start

```bash
cwe               # Start CWE in current directory
/cwe:init         # Initialize project + install plugins + MCP servers
/cwe:start        # Guided workflow with interactive menus
/cwe:help         # Documentation
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
- **Standards System** — `.claude/rules/` with path-scoped auto-loading + discovery
- **Memory System** — Hub-and-Spoke: MEMORY.md index + on-demand detail files
- **Idea Capture** — project-scoped idea observation via JSONL

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
| `/cwe:architect` | Design, ADRs, spec shaping |
| `/cwe:devops` | CI/CD, Docker, releases |
| `/cwe:security` | Audits, OWASP |
| `/cwe:researcher` | Docs, analysis |
| `/cwe:explainer` | Explanations |
| `/cwe:quality` | Tests, coverage |
| `/cwe:innovator` | Brainstorming, idea backlog (4 modes) |
| `/cwe:guide` | Process improvement, standards discovery |

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
├── workflow/
│   ├── config.yml          # CWE configuration
│   ├── ideas.md            # Curated idea backlog
│   ├── product/
│   │   └── mission.md      # Product vision
│   ├── specs/              # Feature specifications (folder per spec)
│   └── standards/          # Project-specific standards
├── memory/
│   ├── MEMORY.md           # Index (200-line max, Hub-and-Spoke)
│   ├── ideas.md            # Idea backlog summary
│   ├── sessions.md         # Session continuity log
│   ├── decisions.md        # Project ADRs
│   ├── patterns.md         # Recognized work patterns
│   └── project-context.md  # Tech stack, priorities
└── .claude/
    └── rules/              # Native Claude Code rules (paths-scoped)
```

## Workflow Phases

1. **Plan** — Define product vision
2. **Spec** — Write feature specifications (Shape-Spec Interview)
3. **Tasks** — Break into implementable tasks
4. **Build** — Implement with agents (parallel wave execution)
5. **Review** — Quality verification + safety gates

## Version History

See [CHANGELOG.md](CHANGELOG.md) for full history.
See [ROADMAP.md](ROADMAP.md) for planned features and design decisions.

- **0.4.1** (current) — Native alignment, memory system, idea system v2
- **0.4.0a** — Plugin integration, skill cleanup, roadmap
- **0.3.1** — Simplified commands, superpowers integration
- **0.3.0** — Plugin structure created
- **0.2.9a** — Last CLI-focused version

## License

MIT

## Author

[LL4nc33](https://github.com/LL4nc33)
