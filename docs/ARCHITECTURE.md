# CWE Architecture

> Version: v0.8.3 · Last reviewed: 2026-11-08

## Overview

Code Workspace Engine (CWE) is a Claude Code plugin that provides agent-based orchestration for spec-driven development. It extends Claude Code with 10 specialized agents, 17 skills, 25 commands, and cross-session memory.

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
│   ├── web-research.md      # Web search + scraping
│   ├── gitea.md             # Gitea Git-Mirror management (incl. SSH)
│   ├── docs.md              # BookStack documentation upload
│   ├── autopilot.md         # Multi-terminal autonomous task loop
│   ├── coordinate.md        # Multi-terminal team-lead coordination
│   ├── check-handoff.md     # Read pending handoff entries
│   ├── handoff.md           # Write handoff to another terminal
│   └── qa-merge.md          # QA-verified merge to main
├── skills/                  # Proactive skills (auto-activated)
│   ├── auto-delegation/     # Routes requests to agents
│   ├── agent-detection/     # Assigns agents to tasks
│   ├── git-standards/       # Conventional Commits enforcement
│   ├── safety-gate/         # Secret scanning pre-commit
│   ├── quality-gates/       # Coverage/complexity checks
│   ├── health-dashboard/    # Project health overview
│   ├── project-docs/        # Documentation maintenance
│   ├── web-research/        # Web search + scraping coordination
│   ├── delegator/           # Multi-agent decomposition + dispatch
│   └── multi-terminal/      # Multi-terminal parallel development
├── hooks/                   # Event-driven automation
│   ├── hooks.json           # Hook event registrations
│   └── scripts/             # Shell/Python scripts for hooks
│       ├── _lib.sh          # Shared shell utilities
│       ├── intent-router.py # Keyword-based agent routing
│       ├── url-scraper.py   # Auto-scrape URLs (Firecrawl/trafilatura/curl)
│       ├── idea-observer.sh # Capture ideas to JSONL
│       ├── transcript.sh    # Transcribe (YouTube + via Whisper server for IG/TikTok/Podcast)
│       ├── safety-gate.sh   # Secret scanning pre-commit
│       ├── commit-format.sh # Conventional Commits enforcement
│       ├── branch-naming.sh # Branch naming validation
│       ├── session-start.sh # Memory injection, version display
│       ├── session-stop.sh  # Daily log entry, cleanup (SessionEnd)
│       ├── subagent-start.sh# Agent start logging
│       ├── subagent-stop.sh # Agent execution logging
│       ├── idea-flush.sh    # Flush idea backlog
│       ├── handoff-sync.py  # Multi-terminal handoff sync
│       └── mt-session-init.py # Multi-terminal worktree detection
├── .claude/rules/           # Auto-loaded coding standards
│   ├── global-standards.md
│   ├── api-standards.md
│   ├── frontend-standards.md
│   └── ...                  # 8 domain-specific rule files
├── templates/               # Templates for /cwe:init
│   ├── docs/                # Documentation templates
│   ├── memory/              # Memory file templates
│   ├── specs/               # Spec templates
│   ├── statusline.py        # Statusline script
│   └── multi-terminal/      # MT terminal prompts, handoff templates
├── .gitattributes           # Git LFS and line-ending config
└── docs/                    # Plugin documentation
```

## Agent Architecture

Each agent is a Markdown file with YAML frontmatter defining:
- **name** — Agent identifier
- **description** — When to use (matched by auto-delegation)
- **tools** — Allowed tool access (principle of least privilege)
- **skills** — Skills the agent can invoke
- **memory** — Memory access level (`project` or `user`)
- **permissionMode** — Permission enforcement (`plan`, `acceptEdits`, `default`)
- **maxTurns** — Maximum turn limit per invocation

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
| `UserPromptSubmit` | User sends a message | `intent-router.py` — keyword-based agent routing |
| `UserPromptSubmit` | User sends a message | `url-scraper.py` — auto-scrapes non-YouTube URLs |
| `UserPromptSubmit` | User sends a message | `idea-observer.sh` — captures ideas to JSONL |
| `UserPromptSubmit` | User sends a message | `transcript.sh` — fetches YouTube transcript |
| `UserPromptSubmit` | User sends a message | `handoff-sync.py` — multi-terminal handoff sync |
| `SessionStart` | Session begins | `session-start.sh` — Memory injection, version display |
| `SessionStart` | Session begins | `mt-session-init.py` — multi-terminal worktree detection |
| `Stop` | Every turn | `idea-flush.sh` — flush idea backlog |
| `SessionEnd` | Session ends | `session-stop.sh` — daily log entry, cleanup |
| `SubagentStart` | Agent starts | `subagent-start.sh` — logs agent start |
| `SubagentStop` | Agent completes | `subagent-stop.sh` — logs agent execution |
| `PreCompact` | Before compaction | `session-stop.sh` — save daily log before compact |
| `PreToolUse` | Before Bash | `safety-gate.sh`, `commit-format.sh`, `branch-naming.sh` |

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

### Intent Router Hook

`hooks/scripts/intent-router.py` runs on every `UserPromptSubmit` event, first in the hook chain. It performs keyword matching with regex (no LLM inference) against the user's prompt and returns a `systemMessage` with a routing instruction to the correct CWE agent.

When two or more agents are matched (e.g., "build" + "test" + "document"), the hook detects a multi-agent request and triggers the delegator skill for decomposition and wave-based dispatch.

**Fallback chain:** intent-router hook → agent description matching → auto-delegation skill. If the hook finds no keyword match, it returns an empty response and Claude Code falls through to the next routing layer.

### URL Auto-Scraper

`hooks/scripts/url-scraper.py` runs on `UserPromptSubmit` when the user message contains a non-YouTube URL. It extracts page content using a three-tier fallback chain:

1. **Firecrawl** (Playwright rendering, ~3-5s timeout) — best for JS-heavy pages
2. **trafilatura** — fast article extraction, no JS
3. **curl + html.parser** — minimal fallback

Output is written to `/tmp/url-scrape-<hash>.json` and injected as a `systemMessage`. YouTube URLs are skipped (deferred to `transcript.sh`).

### Transcript Hook

`hooks/scripts/transcript.sh` runs on `UserPromptSubmit` when the user message contains a YouTube URL (`youtube.com` or `youtu.be`). It auto-detects the video ID, fetches the transcript and metadata (title, channel, duration) via tubetranscript.

The `/cwe:transcript` command additionally supports Instagram/TikTok/Podcast URLs via a user-configured self-hosted faster-whisper server (`tscribe_url` in `cwe-settings.yml`).

Output is written to `/tmp/transcript-<id>.json` and injected as a `systemMessage`.

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

## Multi-Terminal Parallel Development

CWE supports parallel development across multiple Claude Code terminals using git worktrees.

### Architecture

Each terminal operates in its own git worktree with a dedicated branch (`t{N}-{role}`). Terminals communicate via structured handoff files in `shared/handoff/`.

### Components

- **Presets** — 2T (Dev+QA), 3T (Frontend+Backend+QA), 4T (+Infra), Custom
- **Handoff Protocol** — Entry-based communication with status tracking (TODO→IN PROGRESS→DONE)
- **Sync Hook** — `handoff-sync.py` merges new entries from other branches on each prompt
- **Session Init** — `mt-session-init.py` detects worktree context and shows pending handoffs
- **Branch Detection** — All MT hooks silently skip when branch doesn't match `t\d+-` pattern

### Commands

| Command | Purpose |
|---------|---------|
| `/cwe:autopilot` | Autonomous sync→work→handoff→push loop |
| `/cwe:coordinate` | Team-lead overview and task dispatch |
| `/cwe:check-handoff` | Read pending handoffs for this terminal |
| `/cwe:handoff` | Write structured handoff entry |
| `/cwe:qa-merge` | QA-verified merge to main |
