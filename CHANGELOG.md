# Changelog

All notable changes to the Code Workspace Engine (CWE) will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.5.0] — 2026-02-19

### Added
- **Statusline**: Python-based status bar showing context usage, session cost, time, and lines changed — configurable via `python3 ~/.claude/statusline.sh`
- **Currency configuration**: `/cwe:init` now asks for preferred currency (EUR, USD, GBP, CHF) — stored in `.claude/cwe-settings.yml`
- **Project settings file**: `.claude/cwe-settings.yml` — per-project configuration (first setting: currency)
- **Statusline features**: color-coded context bar (green/yellow/red), token count, cost conversion, session duration, lines added/removed, project directory name

### Changed
- `commands/init.md`: Added Step 1d (currency selection) to initialization flow
- `hooks/hooks.json`: PreCompact hook changed from prompt-type to command-type (`session-stop.sh`) — eliminates "JSON validation failed" errors
- `.claude/rules/documentation-standards.md`: Softened wording — documentation updates now conditional on `memory/` directory existence
- Version bump: 0.4.4 → 0.5.0 across all files

### Removed
- Stop hook prompt: Removed the "Session is ending, update documentation" prompt hook that caused errors on every session end
- `docs/plans/`: Deleted obsolete design documents (memory-mcp server design, phase 2 plan, memory-system-v2 design)

### Fixed
- Stop hook "JSON validation failed" error: caused by aggressive prompt hook enforcing documentation updates
- Statusline showing `Context: --` instead of actual usage: replaced bash/jq script with Python for broader compatibility

---

## [0.4.4] — 2026-02-19

### Added
- `commands/screenshot.md`: Multi-OS screenshot from clipboard (WSL2, macOS, Wayland, X11)
- `skills/web-research/SKILL.md`: Local web search via SearXNG + scraping via Firecrawl/trafilatura

### Removed
- `cwe-memory-mcp/`: Entire MCP server removed (replaced by Serena memory system)
- `.mcp.json`: cwe-memory server entry removed
- `docs/plans/2026-02-13-memory-mcp-server-design.md`: Obsolete design doc
- `docs/plans/2026-02-13-memory-mcp-phase2-plan.md`: Obsolete design doc

### Fixed
- Stop hook order: command hooks now run before prompt hook (prevents "No assistant message" error)
- Stop hook prompt: shortened and made more resilient for short sessions
- `session-start.sh`: Agent delegation list now includes ask and guide agents
- `subagent-stop.sh`: Fixed logic error — no longer tries to write daily log when memory/ doesn't exist
- `commands/init.md`: Fixed domain count from 7 to 8 (documentation was missing)
- `commands/help.md`: Replaced Memory MCP Server reference with Serena memory

### Changed
- Version bump: 0.4.3 → 0.4.4 across all files (plugin.json, CLAUDE.md, help.md, session-start.sh, README, USER-GUIDE)
- All cwe-memory references removed from README, CHANGELOG, ROADMAP, USER-GUIDE, .gitignore

---

## [0.4.3] — 2026-02-13

### Added — Documentation
- `docs/USER-GUIDE.md`: comprehensive user documentation (~1000 lines, 15 sections)
- `docs/assets/cwe-logo.svg`: minimalist CWE logo (indigo/violet gradient)
- `docs/assets/cwe-header.svg`: GitHub README banner (800x200, dark-mode compatible)
- `README.md`: complete rewrite with HTML design, SVG header, shields.io badges, collapsible sections
- `commands/help.md`: updated to v0.4.3 with 6th principle, memory search, safety gate, git standards

---

## [0.4.2] — 2026-02-13 (Memory System v2 — Phase 1)

### Added — Daily Logs
- Daily log files (`memory/YYYY-MM-DD.md`): append-only session context per day
- `session-start.sh`: injects MEMORY.md + today + yesterday daily logs as systemMessage (max 8000 chars)
- Auto-seeding: `/cwe:init` detects tech stack and populates memory/project-context.md + MEMORY.md
- Daily log template: `templates/memory/daily-log.md` (format reference)
- First daily log created automatically at `/cwe:init`
- Old daily logs auto-cleaned after 30 days

### Changed — Memory System
- `session-stop.sh`: writes to daily logs instead of sessions.md
- Stop hook prompt: references daily logs instead of sessions.md
- PreCompact hook prompt: references daily logs instead of sessions.md
- `documentation-standards.md`: daily log added to required memory updates checklist
- `MEMORY.md` template: references daily logs, added Daily Logs section

### Deprecated
- `sessions.md`: replaced by daily logs (kept for backward compatibility)

---

## [0.4.1] — 2026-02-13 (Native Alignment Release)

### Changed — Native Alignment (Phase 1-3)
- CLAUDE.md radical slim-down (~230 → ~72 lines)
- Standards migration from Skills to `.claude/rules/` with `paths` frontmatter (YAML list format)
- Agent frontmatter modernization (`skills:`, `memory: project` fields)
- Rules paths format: corrected to YAML list per Claude Code docs

### Changed — Memory & Idea System (Phase 4)
- Idea system v2: project-scoped via `$CLAUDE_PROJECT_DIR`, JSONL format
- idea-observer.sh: writes to `~/.claude/cwe/ideas/<project-slug>.jsonl`
- idea-flush.sh: counts only current project's ideas
- session-start.sh: reads memory/sessions.md for resume context, shows idea count
- session-stop.sh: logs sessions to memory/sessions.md, keeps last 50
- Migration: old `.toon` → per-project JSONL on first run
- Memory templates: MEMORY.md, ideas.md, sessions.md, decisions.md, patterns.md, project-context.md
- commands/innovator.md: 4 modes (default/all/review/develop)

### Removed — Redundant Skills (Phase 5)
- 10 skills deleted: 7 standards (→ .claude/rules/), cwe-principles (→ CLAUDE.md), planning (→ native), mcp-usage (obsolete)
- Remaining: auto-delegation, agent-detection, quality-gates

### Added — Hooks Modernization (Phase 6)
- SubagentStop hook for agent execution observability
- subagent-stop.sh: logs agent completions to memory/sessions.md

### Changed — Documentation Consistency
- README.md: v0.4.1, memory system, standards system, idea capture documented
- commands/help.md: v0.4.1, standards system, memory system, idea JSONL
- commands/init.md: memory/ scaffolding, updated ideas.md template, standards reference
- commands/start.md: Shape-Spec Interview option, spec folder structure
- auto-delegation skill: context injection updated from Skills to .claude/rules/
- plugin.json: version 0.4.1, simplified description
- ROADMAP.md: Phase 1-6 marked as completed, summary table updated

### Added — Spec System + Project Documentation (Phase 7)
- Spec folder templates: `templates/specs/` (plan.md, shape.md, references.md, standards.md)
- Shape-Spec Interview: `/cwe:architect shape` with structured interview flow
- docs/ templates: `templates/docs/` (README, ARCHITECTURE, API, SETUP, DEVLOG, decisions/_template)
- VERSION file template as Single Source of Truth for version strings
- `skills/project-docs/SKILL.md`: README generation, docs freshness check, VERSION cascade
- commands/architect.md: shape mode with 5-step interview + spec folder generation
- commands/researcher.md: `docs update|check|adr` modes
- commands/devops.md: `release patch|minor|major` mode with VERSION cascade
- commands/init.md: docs/ scaffolding + VERSION in project structure
- agents/researcher.md: expanded docs responsibilities with project-docs skill
- agents/devops.md: release flow with VERSION SSOT + project-docs skill

### Added — Pre-Commit Safety Gate (Phase 8)
- `hooks/scripts/safety-gate.sh`: scans for secrets, API keys, PII, credentials, dangerous file types
- PreToolUse hook on Bash: triggers safety-gate.sh on git commit/push/add -A
- `skills/safety-gate/SKILL.md`: describes scanning rules + remediation guidance
- .gitignore validation (required entries: .env, *.pem, *.key, node_modules/, .DS_Store)

### Added — Git Workflow Standards (Phase 9)
- `skills/git-standards/SKILL.md`: Conventional Commits format + branch naming conventions
- `hooks/scripts/commit-format.sh`: validates commit message format on git commit -m
- `hooks/scripts/branch-naming.sh`: validates branch names on git checkout -b / git switch -c
- PreToolUse hooks for commit-format.sh and branch-naming.sh
- Auto-generated release notes spec (via /cwe:devops release)

### Added — Project Health Dashboard (Phase 10)
- `skills/health-dashboard/SKILL.md`: project health metrics (code quality, deps, docs, git, security)
- Health score calculation (0-100) with rating system
- CODEOWNERS auto-generation from git history
- `/cwe:quality health` command mode
- Quality agent: health dashboard integration
- Guide agent: health insights for process improvement suggestions

### Added — Always Document Principle
- 6th Core Principle: "Always Document" — every change updates memory, CHANGELOG, docs
- `.claude/rules/documentation-standards.md`: always-active rule with documentation checklist
- Stop hook (prompt-based): forces memory/MEMORY.md + sessions.md update before session end
- PreCompact hook (prompt-based): forces memory save before context compaction
- MCP server installation in `/cwe:init` (playwright, context7, github, filesystem, sequential-thinking)

---

## [0.4.0a] — 2025-02-13

### Changed
- **Skill overlap resolved:** `auto-delegation` and `agent-detection` now have sharp scope boundaries
  - `auto-delegation` = interactive user-request routing (natural language)
  - `agent-detection` = build-phase task-to-agent assignment (structured tasks)
- **Keyword tables synchronized** across auto-delegation, agent-detection, and CLAUDE.md
  - "test" consistently routes to **quality** agent (was inconsistent)
  - Unified canonical keyword list for all 10 agents
- **Greptile references removed** — replaced with Serena tools
- **Version consistency fixed** — `session-start.sh` updated from v0.3.1 to v0.4.0a

### Added
- `CHANGELOG.md` — this file
- `ROADMAP.md` — v0.4.1 planning and design decisions
- `_backup/` — pre-change backup of modified files

---

## [0.4.0a] — Initial Plugin Release

### Added
- Full plugin structure (`.claude-plugin/plugin.json`)
- 10 specialized agents: ask, architect, builder, devops, explainer, guide, innovator, quality, researcher, security
- 13 commands: 3 core (init, start, help) + 10 agent commands
- 13 skills: auto-delegation, agent-detection, quality-gates, planning, cwe-principles, mcp-usage, and 7 domain standards
- Plugin integration: superpowers, serena, feature-dev, frontend-design, code-simplifier, claude-md-management, plugin-dev
- Idea capture system via UserPromptSubmit hook
- Session hooks (start, stop, idea-flush)
- Interactive menus via AskUserQuestion in all commands
- Wave execution algorithm for parallel task orchestration

---

## [0.3.1] — Pre-Plugin Version

### Changed
- Simplified to 12 commands, auto-delegation, superpowers integration

---

## [0.3.0] — Plugin Structure Created

### Added
- Initial plugin directory structure

---

## [0.2.9a] — Last CLI-Focused Version

### Changed
- Final version before plugin migration
