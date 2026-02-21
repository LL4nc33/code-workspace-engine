# CWE Architecture

## Overview

Code Workspace Engine (CWE) is a Claude Code plugin that provides agent-based orchestration for spec-driven development. It extends Claude Code with 10 specialized agents, automated workflows, and cross-session memory.

## Plugin Structure

```
code-workspace-engine/
├── plugin.json              # Plugin manifest (name, version, discovery paths)
├── CLAUDE.md                # Injected into every Claude Code session
├── agents/                  # 10 specialized agent definitions
│   ├── architect.md         # System design, ADRs, spec shaping
│   ├── ask.md               # Discussion, Q&A (READ-ONLY)
│   ├── builder.md           # Implementation, bug fixes
│   ├── devops.md            # CI/CD, Docker, releases
│   ├── explainer.md         # Code explanations, walkthroughs
│   ├── guide.md             # Process improvement, standards
│   ├── innovator.md         # Brainstorming, idea backlog
│   ├── quality.md           # Testing, coverage, health
│   ├── researcher.md        # Documentation, analysis
│   └── security.md          # Audits, OWASP, GDPR
├── commands/                # Slash commands (/cwe:*)
│   ├── init.md              # Project initialization
│   ├── start.md             # Guided workflow
│   ├── help.md              # Documentation
│   ├── plugins.md           # Dependency management
│   ├── screenshot.md        # Screenshot capture
│   └── web-research.md      # Web search + scraping
├── skills/                  # Proactive skills (auto-activated)
│   ├── auto-delegation/     # Routes requests to agents
│   ├── agent-detection/     # Assigns agents to tasks
│   ├── git-standards/       # Conventional Commits enforcement
│   ├── safety-gate/         # Secret scanning pre-commit
│   ├── quality-gates/       # Coverage/complexity checks
│   ├── health-dashboard/    # Project health overview
│   └── project-docs/        # Documentation maintenance
├── hooks/                   # Event-driven automation
│   ├── hooks.json           # Hook event registrations
│   └── scripts/             # Shell scripts for hooks
├── .claude/rules/           # Auto-loaded coding standards
│   ├── global-standards.md
│   ├── api-standards.md
│   ├── frontend-standards.md
│   └── ...                  # 8 domain-specific rule files
├── templates/               # Templates for /cwe:init
│   ├── docs/                # Documentation templates
│   ├── memory/              # Memory file templates
│   ├── specs/               # Spec templates
│   └── statusline.py        # Statusline script
└── docs/                    # Plugin documentation
```

## Agent Architecture

Each agent is a Markdown file with YAML frontmatter defining:
- **name** — Agent identifier
- **description** — When to use (matched by auto-delegation)
- **tools** — Allowed tool access (principle of least privilege)
- **skills** — Skills the agent can invoke
- **memory** — Memory access level

### Auto-Delegation Flow

```
User sends natural language request
    ↓
auto-delegation skill activates
    ↓
Keyword matching against Intent → Agent table
    ↓
Agent spawned via Task tool with subagent_type
    ↓
Agent works with its allowed tools
    ↓
Compact summary returned to main context
```

### Agent Isolation

Agents run as subagents (Task tool) with:
- **Scoped tools** — Each agent only gets the tools it needs
- **Context isolation** — Work happens outside the main context window
- **Summary return** — Only a compact result comes back

## Hook System

Hooks are event-driven shell scripts registered in `hooks/hooks.json`.

### Hook Events

| Event | Trigger | Scripts |
|-------|---------|---------|
| `UserPromptSubmit` | User sends a message | `idea-observer.sh` — captures ideas to JSONL |
| `SessionStart` | Session begins | (cleared via hook) |
| `Stop` | Session ends | `session-stop.sh` — daily log entry, cleanup |
| `SubagentStop` | Agent completes | `subagent-stop.sh` — logs agent execution |
| `PreToolUse` | Before tool execution | `safety-gate` (prompt-based) — scans for secrets |

### Hook Data Flow

```
Event triggered by Claude Code
    ↓
hooks.json maps event → script or prompt
    ↓
Script receives JSON on stdin
    ↓
Script returns JSON on stdout:
  {"systemMessage": "..."} — injected into conversation
  {} or exit 0 — no action
```

## Skill System

Skills are proactive Markdown files in named directories under `skills/`. They activate automatically when their trigger conditions are met.

### Skill Types

- **Routing skills** — `auto-delegation`, `agent-detection` — route work to agents
- **Guard skills** — `safety-gate`, `git-standards` — enforce standards
- **Quality skills** — `quality-gates`, `health-dashboard` — verify quality
- **Coordination skills** — `delegator` — decompose + dispatch multi-agent requests
- **Utility skills** — `project-docs`, `web-research` — support workflows

### Skill Activation

Skills are loaded by Claude Code's skill system. Each skill's `description` field contains trigger phrases. When the system detects a match, the skill content is injected into the conversation.

## Memory System

CWE provides two memory strategies:

### CWE Memory (memory/ directory)
- `MEMORY.md` — Hub file (max 200 lines), always injected at session start
- `YYYY-MM-DD.md` — Daily logs, auto-created by hooks
- `decisions.md`, `patterns.md`, `project-context.md` — Structured knowledge

### Serena Memory (alternative)
- If the Serena plugin is installed, its `write_memory`/`read_memory` tools can be used instead
- `/cwe:init` asks the user which system to use

## Standards System

8 rule files in `rules/` with `paths:` frontmatter for auto-loading:
- Rules load automatically when editing files matching their path patterns
- `global-standards.md` — Always active
- Domain-specific rules activate per file type (API, frontend, database, etc.)

## Workflow Phases

```
Plan → Spec → Tasks → Build → Review
```

1. **Plan** — Product vision in `workflow/product/mission.md`
2. **Spec** — Shape-Spec Interview creates spec folder
3. **Tasks** — Break spec into tasks with dependencies
4. **Build** — Wave execution (up to 3 parallel agents)
5. **Review** — Quality gates before release
