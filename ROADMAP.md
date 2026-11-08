# CWE Roadmap

Current: **v0.8.2** — Hardening pass (11 blockers + ~40 should-fixes resolved via 10-agent review).

For historical detail see `CHANGELOG.md`.

---

## Done

### v0.8.2 — Hardening Pass (2026-04-21)
- 10 parallel review agents across hooks/media/utility-scripts/agents/skills/commands/rules/templates/docs/privacy → 11 blockers + ~40 should-fixes
- Security: PowerShell injection closed in screenshot.py; env-var leak stopped in load_keys(); safety-gate no longer blocks git on self-errors
- commit-format.sh regex rewritten (was effectively broken); qa-merge glob bugs fixed; port-collision SearXNG/Stirling resolved
- 10 agents de-coupled from pre-init `@workflow/` includes; 16 skills gained `allowed-tools`; rules neutralised + indexed correctly
- USER-GUIDE v0.7.0 → v0.8.2 with Media/External-Services/Multi-Terminal sections; templates' `{{PLACEHOLDERS}}` converted to natural-language hints

### v0.8.1 — Polish & Documentation (2026-04-21)
- `/cwe:pdf` configurable via Stirling PDF
- `/cwe:screenshot` flipped to Python script (cross-platform clipboard)
- `/cwe:init` expanded with 5 optional service setup steps
- Documentation refresh (README badges, SVG header, CHANGELOG)

### v0.8.0 — Media + Content Tools (2026-04-21)
- 6 Media Generation skills (image/video/faceswap/headswap/upscale/motion)
- Shared `_media_lib.py` for OpenRouter + MagicHour APIs
- `/cwe:transcript` (renamed, supports any URL via Whisper server)
- Intent-router extended for media/content commands

### v0.7.1 — Multi-OS Portability (2026-04-20)
- macOS grep fixes (`grep -oP` → `grep -oE`)
- Version lookup no longer hardcoded
- `handoff-sync.py` throttling + systemMessage output

### v0.7.0 — Multi-Terminal Parallel Development (2026-03-11)
- 5 new commands (autopilot, coordinate, check-handoff, handoff, qa-merge)
- `multi-terminal` skill with handoff protocol
- Branch-detection guards in MT hooks
- Hook events modernized (SessionEnd, SubagentStart)

### v0.6.x — Hybrid Delegation + URL Scraper
- Intent-router hook for keyword-based agent routing
- URL auto-scraper (Firecrawl → trafilatura → curl fallback)
- Web-research skill

### v0.5.x — Statusline + Polish
- Python statusline with context/cost/time
- Currency config via `/cwe:init`
- Delegator skill for multi-agent requests

### v0.4.x — Native Alignment (10 phases)
- CLAUDE.md slim-down, `.claude/rules/` migration
- Memory system v2 (daily logs, project-scoped ideas)
- Spec folders + Shape-Spec interview
- Safety gate, git standards, health dashboard
- See CHANGELOG for detail

---

## Next

### v0.9.0 — Qdrant Memory + Skills Flip (in design)

Replace Markdown-based memory with Qdrant vector store, flip deterministic skills to Python scripts.

- Single Qdrant collection `cwe_memory` with scope/project/type payload filters
- `nomic-embed-text` embeddings via Ollama (on-prem, user-configurable)
- New commands: `/cwe:remember`, `/cwe:recall`, `/cwe:migmem` (import/export/--all)
- Layer 1: PostToolUse passive sync (auto-memory → Qdrant)
- Layer 2: SessionStart active recall (inject user + project memory)
- Layer 3: UserPromptSubmit contextual recall (semantic match on user prompt)
- `/cwe:init` offers Fat (Opus/Sonnet, full) vs Lean (Ollama/Haiku, script-heavy) modes
- Skills-Flip: `safety-gate`, `git-standards`, `quality-gates`, `health-dashboard` → Python scripts

Design + plan docs in `docs/plans/` (local, not tracked).

### v0.9.1+ — Qdrant Memory Layers (follow-up)

- Layer 4: Passive learning (Stop-hook detects decisions/patterns/feedback)
- Layer 5: Temporal decay (Qdrant payload `last_used`, recency-weighted recall)
- Layer 6: Cross-project learning (post-commit hook extracts library/pattern/fix as user-scoped)

### v1.0.0 — Production Ready (target)

- Full Skills-Flip complete (all deterministic skills in Python)
- Qdrant memory stable + backed up
- Documentation complete (API, ARCHITECTURE, USER-GUIDE refreshed)
- CI tests for hooks + scripts
- Plugin-marketplace-ready

---

## Under Evaluation (no committed version)

### Claude Code native features
Recent Claude Code releases added features that may replace CWE components:

- **Output Styles** (`/output-styles.md`): Could simplify `/cwe:researcher`
- **Checkpointing**: File + conversation rollback — could reduce Serena memory reliance
- **Routines**: Anthropic-hosted cron — could replace `/cwe:autopilot` for long-running tasks
- **Channels**: Webhook/Telegram/Discord → session push — could power event-driven research flows
- **Sandboxing**: Isolated bash — candidate for security/devops agent commands
- **Auto Mode**: Could replace `--dangerously-skip-permissions` alias

Each will be evaluated individually; CWE adopts only what adds value beyond native behavior.

### Community / Ecosystem
- Plugin marketplace publishing (requires 1.0.0)
- Community template profiles (api, pwa, fullstack)
- Monorepo support (per-package workflow/)

---

## Principles

| # | Principle | What it means for the roadmap |
|---|-----------|-------------------------------|
| 1 | **Agent-First** | Keep delegation via specialized agents — never add work to main context |
| 2 | **Scripts over Prose** | Deterministic work lives in Python scripts, LLM-reasoning in Markdown |
| 3 | **Configurable, not Hardcoded** | Every external service asked for at `/cwe:init`, saved in gitignored config |
| 4 | **Native First** | If Claude Code adds a feature that replaces a CWE component, deprecate the CWE version |
| 5 | **SemVer Discipline** | Patch = fixes, Minor = new features, Major = breaking. 1.0.0 is earned, not scheduled |
