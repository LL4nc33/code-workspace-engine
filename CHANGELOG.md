# Changelog

All notable changes to the Claude Workflow Engine (CWE) will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

### Planned — Phase 8: Pre-Commit Safety Gate
- safety-gate.sh: secrets, PII, .gitignore validation
- PreToolUse hook on git commit/push/add -A

### Planned — Phase 9: Git Workflow Standards
- Conventional Commits enforcement
- Branch naming enforcement
- Auto-generated release notes

### Planned — Phase 10: Project Health Dashboard
- Coverage, complexity, dependencies, docs, git health, security

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
