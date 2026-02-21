# CWE Roadmap

## Completed: v0.4.0a → v0.5.0

### v0.5.1 — Hook Hardening + Delegator Skill
- Delegator skill: Multi-agent request coordination with wave-based parallel dispatch
- Hook hardening: shared `_lib.sh` for all hook scripts
- ARCHITECTURE.md, statusline template, doc fixes

### v0.5.0 — Statusline + Polish
- Statusline: Python-based status bar with context usage, cost (EUR/USD/GBP/CHF), time, lines changed
- Currency configuration via `/cwe:init` stored in `.claude/cwe-settings.yml`
- Hook fixes: PreCompact changed from prompt to command, Stop prompt hook removed
- Documentation-standards softened for conditional memory usage
- Obsolete plan docs deleted

### v0.4.4 — Cleanup + New Skills
- cwe-memory-mcp removed entirely (Serena memory replaces it)
- Screenshot command: Multi-OS clipboard capture (WSL2, macOS, Wayland, X11)
- Web Research skill: SearXNG + Firecrawl/trafilatura local search
- Stop hook reordering: command hooks before prompt hook
- Consistency fixes: version refs, agent lists, domain counts

### v0.4.3 — Documentation
- USER-GUIDE.md, README rewrite, SVG assets

### v0.4.2 — Memory System v2 (Phase 1)
- Daily Logs (`memory/YYYY-MM-DD.md`) replace sessions.md
- Context Injection: session-start.sh reads MEMORY.md + today + yesterday
- Auto-Seeding: `/cwe:init` detects tech stack

### v0.4.1 — Native Alignment (all 10 phases)

### Vision

Align CWE with Claude Code's native architecture (v2.1.x).
Eliminate duplication, leverage native primitives, focus on what CWE uniquely provides:
**Spec-driven workflow orchestration with specialized agents and full project lifecycle management.**

---

## v0.4.1 — Native Alignment + Project Standards Release

### Guiding Principle

> CWE should do what Claude Code can't, and delegate what Claude Code already does.
> Every project managed by CWE looks professional, is well-documented, and is safe to publish.

---

### Phase 1: CLAUDE.md Radical Slim-Down ✅

**Status:** Completed — 231 → 72 lines.
**Goal:** ~230 lines → ~80 lines. Stop duplicating what Progressive Disclosure handles.

| Remove | Reason |
|--------|--------|
| Plugin catalog tables (superpowers, serena, feature-dev, etc.) | Skills Progressive Disclosure loads name+description automatically |
| Agent-Plugin Mapping table | Moves to agent frontmatter `skills:` field |
| Full installed plugins section | Redundant with plugin system |
| Detailed command tables | Available via `/cwe:help` |

| Keep | Reason |
|------|--------|
| 5 Core Principles | CWE identity — not available natively |
| Auto-Delegation flow (Intent → Agent/Skill) | CWE's core routing — not native |
| Decision Flow diagram | Unique orchestration logic |
| Quick Reference (examples) | Onboarding, low token cost |
| Idea Capture keywords | Hook integration reference |

**Files changed:** `CLAUDE.md`

---

### Phase 2: Standards System Overhaul (inspired by Agent-OS) ✅

**Status:** Completed — 7 rules + _index.yml created, paths format fixed to YAML list.
**Goal:** Migrate to `.claude/rules/`, add Discovery + Indexing (Agent-OS' best features).

#### 2a: Standards Migration

| Old (CWE Skill) | New (Native Rule) | Paths Glob |
|------------------|--------------------|------------|
| `skills/global-standards/` | `.claude/rules/global-standards.md` | `**/*` |
| `skills/api-standards/` | `.claude/rules/api-standards.md` | `**/api/**, **/routes/**, **/controllers/**` |
| `skills/frontend-standards/` | `.claude/rules/frontend-standards.md` | `**/*.tsx, **/*.vue, **/components/**` |
| `skills/database-standards/` | `.claude/rules/database-standards.md` | `**/migrations/**, **/db/**, **/*.sql` |
| `skills/devops-standards/` | `.claude/rules/devops-standards.md` | `**/docker*, **/.github/**, **/terraform/**` |
| `skills/testing-standards/` | `.claude/rules/testing-standards.md` | `**/*.test.*, **/test_*, **/*_test.*` |
| `skills/agent-standards/` | `.claude/rules/agent-standards.md` | `**/agents/**, **/skills/**` |

#### 2b: Standards Discovery (NEW, inspired by Agent-OS)

`/cwe:guide discover` — Guide Agent analyzes codebase and interviews user:

1. Scans codebase for patterns (naming conventions, error handling, API design, etc.)
2. Identifies opinionated/unique patterns vs. generic defaults
3. Interviews user: "I noticed you always use X pattern. Why? Should this be a standard?"
4. Generates `.claude/rules/<domain>-<pattern>.md` with `paths` frontmatter
5. Updates standards index (see 2c)

Uses `$ARGUMENTS`: `/cwe:guide discover` (full scan) or `/cwe:guide discover api` (domain-scoped)

#### 2c: Standards Index with Detection Rules (NEW, inspired by Agent-OS)

`/cwe:guide index` — Generates `.claude/rules/_index.yml`:

```yaml
standards:
  - file: api-standards.md
    paths: ["**/api/**", "**/routes/**"]
    keywords: ["endpoint", "REST", "GraphQL", "controller"]
    auto_inject: true
  - file: frontend-standards.md
    paths: ["**/*.tsx", "**/components/**"]
    keywords: ["component", "UI", "layout", "style"]
    auto_inject: true
  - file: error-handling.md
    paths: ["**/*"]
    keywords: ["try", "catch", "error", "exception"]
    auto_inject: false  # Only when explicitly relevant
```

The auto-delegation skill reads this index to inject standards contextually,
not just by file path but also by task keywords.

**Files changed:** 7 skills deleted, 7+ rules created, new `_index.yml`,
guide agent updated, auto-delegation skill updated, `/cwe:init` updated

---

### Phase 3: Agent Frontmatter Modernization ✅

**Status:** Completed — all 10 agents updated with skills: and memory: project.
**Goal:** Use Claude Code v2.1.x frontmatter fields. Remove prose-based plugin references.

Add to each agent:
- `skills: [relevant-skills]` — auto-loads skills (replaces "Plugin Integration" sections)
- `hooks:` — agent-scoped lifecycle hooks where needed
- `memory: project` — persistent memory per project
- `model:` — where appropriate (e.g., `haiku` for fast read-only agents)

Remove from each agent:
- "Plugin Integration" sections (replaced by `skills:` field)
- "MCP Tools Usage" sections (tools already in frontmatter `tools:`)
- "Collaboration" sections (redundant with orchestration docs)

**Files changed:** All 10 agents (`agents/*.md`)

---

### Phase 4: Memory & Idea System Overhaul ✅

**Status:** Completed — JSONL per-project, Hub-and-Spoke memory, session logging, .toon migration.
**Goal:** Replace custom persistence (.toon, hooks) with Claude Code's native memory.
Fix critical bug: ideas are currently global, not project-scoped (40+ ideas shown in every project).

#### 4a: Memory Architecture (Hub-and-Spoke + Project-Scoped)

MEMORY.md is limited to 200 lines. CWE uses it ONLY as an index.
Detail files are read on-demand by Claude via file tools.

**Per-project memory (native Claude Code):**
```
~/.claude/projects/<project>/memory/
├── MEMORY.md              ← INDEX ONLY (200 lines max, auto-managed)
│                            Summarizes: idea count, last session, current focus
│                            Points to detail files for on-demand loading
├── YYYY-MM-DD.md          ← Daily logs (auto-created by hooks)
├── ideas.md               ← Curated idea backlog for THIS project
├── decisions.md           ← Project-level ADRs
├── patterns.md            ← Recognized work patterns (Homunculus-inspired)
└── project-context.md     ← Tech stack, priorities, current sprint
```

**MEMORY.md template (stays under 200 lines):**
```markdown
# CWE Memory: <project-name>

## Current Focus
<1-2 lines: what we're working on right now>

## Ideas: X captured, Y exploring, Z planned
Details: → memory/ideas.md | Raw: → ~/.claude/cwe/ideas/<project-slug>.jsonl

## Last Session
<date>: <1-line summary of what happened>

## Key Decisions
<numbered list of most recent 5, full details → memory/decisions.md>

## Patterns
<recognized work patterns, details → memory/patterns.md>

## Project Context
Stack: <tech stack> | Phase: <workflow phase>
Details: → memory/project-context.md
```

#### 4b: Idea System v2 (Project-Scoped, JSONL, Curated)

**Critical fix:** Ideas stored globally in `~/.claude/cwe/idea-observations.toon`.
All 40+ ideas appear in every project. This is wrong.

**New architecture:**
```
~/.claude/cwe/ideas/                        ← Raw captures (JSONL, per-project)
├── _global.jsonl                            ← Ideas without project context
├── oidanice-inkonnect.jsonl                 ← Only ideas from this project
├── claude-workflow-engine.jsonl
└── oidanice-coach.jsonl

Per project: workflow/ideas.md               ← Curated backlog (only own ideas)
Per project: memory/ideas.md                 ← Memory-integrated summary
```

**Flow:**
```
User prompt with idea keywords
  → idea-observer.sh (reads $CLAUDE_PROJECT_DIR)
  → JSONL to ~/.claude/cwe/ideas/<project-slug>.jsonl
  → Innovator Agent reads ONLY current project's .jsonl
  → Curates to workflow/ideas.md
  → Updates memory/ideas.md summary
```

**Innovator Agent modes:**
- `/cwe:innovator` → ideas for CURRENT project only
- `/cwe:innovator all` → cross-project overview (inspiration/transfer)
- `/cwe:innovator review` → interactive triage of new observations
- `/cwe:innovator develop <idea>` → deep-dive on specific idea

**JSONL format (replaces .toon):**
```json
{"ts":"2025-02-13T14:30:00Z","prompt":"was wäre wenn GraphQL...","project":"oidanice-inkonnect","keywords":["was wäre wenn"],"status":"raw"}
```

#### 4c: Session Continuity

- `session-start.sh` → reads MEMORY.md + daily logs for resume context
- `session-stop.sh` → appends session-end entry to daily log
- `idea-flush.sh` → counts ONLY current project's ideas

#### 4d: Pattern Recognition (Homunculus-inspired, future)

Designed for post-v0.4.1:
- Track agent usage per project
- Detect repeated task types
- Suggest workflow optimizations via guide agent
- Store in `memory/patterns.md`

**Migration:** idea-observer.sh detects old `.toon`, converts to per-project JSONL, moves to `.toon.bak`.

**Files changed:** 4 hook scripts, `agents/innovator.md`, `commands/innovator.md`,
new `templates/memory/` directory

| Old | New | Purpose |
| `~/.claude/cwe/idea-observations.toon` | `~/.claude/cwe/ideas/<project>.jsonl` | Project-scoped raw captures |
| (global, all projects mixed) | `workflow/ideas.md` | Curated project backlog |
| No session tracking | `memory/YYYY-MM-DD.md` (daily logs) | Session continuity |
| No decision tracking | `memory/decisions.md` | ADRs |
| No pattern tracking | `memory/patterns.md` | Work patterns (future) |

---

### Phase 5: Delete Redundant Skills ✅

**Status:** Completed — 10 skills deleted, 3 remain (auto-delegation, agent-detection, quality-gates).
**Goal:** Remove skills that duplicate Claude Code native capabilities.

| Skill | Reason for Deletion |
|-------|---------------------|
| `skills/cwe-principles/` | Content integrated into CLAUDE.md |
| `skills/mcp-usage/` | Already deleted (v0.4.0a cleanup) |
| `skills/planning/` | `EnterPlanMode` is a native tool |
| `skills/global-standards/` | Migrated to `.claude/rules/` |
| `skills/api-standards/` | Migrated to `.claude/rules/` |
| `skills/frontend-standards/` | Migrated to `.claude/rules/` |
| `skills/database-standards/` | Migrated to `.claude/rules/` |
| `skills/devops-standards/` | Migrated to `.claude/rules/` |
| `skills/testing-standards/` | Migrated to `.claude/rules/` |
| `skills/agent-standards/` | Migrated to `.claude/rules/` |

**Remaining skills after v0.4.1 (7 total):**
- `skills/auto-delegation/` — CWE's core routing logic
- `skills/agent-detection/` — Build-phase task routing
- `skills/quality-gates/` — Multi-stage gate enforcement (unique to CWE)
- `skills/project-docs/` — **NEW** Standardized documentation (Phase 7)
- `skills/safety-gate/` — **NEW** Pre-commit safety (Phase 8)
- `skills/git-standards/` — **NEW** Conventional commits + branch naming (Phase 9)
- `skills/health-dashboard/` — **NEW** Project health metrics + scoring (Phase 10)

**Files changed:** 10 skill directories deleted

---

### Phase 6: Hooks Modernization ✅

**Status:** Completed — SubagentStop hook added, all 4 existing hooks modernized in Phase 4.
PreToolUse hooks for Safety Gate (Phase 8) and Git Standards (Phase 9) prepared but not yet implemented.
**Goal:** Leverage new hook events, frontmatter hooks, and memory integration.

| Hook | Change |
|------|--------|
| `UserPromptSubmit` (idea-observer) | Output JSONL to memory/ideas.md |
| `SessionStart` | Read MEMORY.md + daily logs, show resume context |
| `Stop` (session-stop) | Append session-end entry to daily log |
| `Stop` (idea-flush) | Simplified — just notify count from memory/ideas.md |
| **NEW:** `SubagentStop` | Log agent results for observability |
| **NEW:** `PreToolUse` on `Bash(git commit*)` | Safety gate (Phase 8) |
| **NEW:** `PreToolUse` on `Bash(git push*)` | Safety gate (Phase 8) |

**Files changed:** `hooks/hooks.json`, all scripts in `hooks/scripts/`

---

### Phase 7: Spec System + Project Documentation ✅

**Status:** Completed — Spec folder templates, Shape-Spec Interview, docs/ scaffolding, project-docs skill, VERSION SSOT.
**Goal:** Better specs (Agent-OS inspired) + consistent, auto-maintained documentation.

#### 7a: Spec Folder Structure (inspired by Agent-OS)

Specs are no longer single files but complete folders with full context:

```
workflow/specs/
├── 2025-02-13-1430-user-auth/
│   ├── plan.md          ← The implementation plan / task breakdown
│   ├── shape.md         ← Scope, decisions, constraints, context
│   ├── references.md    ← Similar code, patterns, prior art
│   ├── standards.md     ← Snapshot of relevant standards at spec time
│   └── visuals/         ← Mockups, diagrams, screenshots
└── 2025-02-14-0900-payment-flow/
    ├── plan.md
    ├── shape.md
    └── ...
```

Folder naming: `YYYY-MM-DD-HHMM-<feature-slug>/` (auto-generated)
Specs become project history — discoverable and referenceable months later.

#### 7b: Shape-Spec Interview (inspired by Agent-OS)

The Architect Agent gains a structured spec-shaping interview:

`/cwe:architect shape` or auto-triggered during `/cwe:start` Spec Phase:

1. **Read context:** Load `workflow/product/mission.md` + tech stack
2. **Inject standards:** Read `_index.yml`, inject relevant standards for the feature
3. **Interview:** Ask targeted questions via AskUserQuestion:
   - "What's the scope? What's explicitly OUT of scope?"
   - "Which existing components are affected?"
   - "Are there security/performance concerns?"
   - "What does 'done' look like?"
4. **Generate:** Create spec folder with all artifacts
5. **Handoff:** Enter Plan Mode with spec context loaded

This replaces the current approach where `/cwe:start` jumps directly to spec writing.

#### 7c: Documentation Structure

`/cwe:init` scaffolds:

```
docs/
├── README.md              ← Project overview (auto-generated, auto-updated)
├── ARCHITECTURE.md        ← System design, component overview, data flow
├── API.md                 ← Endpoint documentation (if applicable)
├── SETUP.md               ← Installation, dev environment, dependencies
└── decisions/             ← Architecture Decision Records
    └── _template.md       ← ADR template

VERSION                    ← Single Source of Truth (e.g. "0.5.0")
CHANGELOG.md               ← Keep-a-Changelog format, references VERSION
DEVLOG.md                  ← Chronological developer journal
```

**VERSION file rules:**
- Plain text, single line, semver (e.g. `0.5.0`)
- ALL other references (plugin.json, package.json, CHANGELOG, README, etc.) read from here
- `/cwe:devops release patch|minor|major` bumps VERSION and cascades everywhere
- Never hardcode version strings anywhere else

#### 7d: Auto-README with GitHub HTML + SVG

New skill `skills/project-docs/SKILL.md`:

- Generates `README.md` with project metadata from `workflow/product/mission.md`
- Produces a GitHub-optimized HTML version with:
  - Custom SVG header banner (project name, logo, version badge)
  - Tech stack badges (auto-detected from package.json, Dockerfile, etc.)
  - Status badges (build, coverage, license)
  - Table of contents
  - Mermaid architecture diagram
- `docs/assets/` folder for SVGs and images
- Auto-updates README when:
  - `workflow/product/mission.md` changes
  - `VERSION` changes
  - New specs are added
  - Tech stack changes detected

#### 7e: Documentation Agents

The **researcher** agent gains documentation responsibilities:
- `docs update` → scans codebase, updates all docs
- `docs check` → validates docs are current vs codebase
- `docs adr` → creates new ADR from discussion

The **devops** agent gains release documentation:
- `release` → bumps VERSION, updates CHANGELOG, generates release notes
- Validates CHANGELOG format (Keep-a-Changelog)
- Auto-generates release notes from conventional commits

**Files changed:** New skill, updated agents, `/cwe:init` updated

---

### Phase 8: Pre-Commit Safety Gate ✅

**Status:** Completed — safety-gate.sh, PreToolUse hook, safety-gate skill.
**Goal:** Nothing dangerous gets committed or pushed. Ever.

#### 8a: Safety Scan Script

New `hooks/scripts/safety-gate.sh`:

**Scans for:**
| Category | Patterns |
|----------|----------|
| **API Keys** | `sk-`, `pk-`, `api_key=`, `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, AWS patterns |
| **Passwords** | `password=`, `passwd=`, `secret=`, credential patterns |
| **Private Keys** | `-----BEGIN.*PRIVATE KEY-----`, `.pem`, `.key` files |
| **Environment Files** | `.env`, `.env.local`, `.env.production` (must be in .gitignore) |
| **SSH Keys** | `id_rsa`, `id_ed25519`, `.ssh/` |
| **Certificates** | `.crt`, `.pfx`, `.p12` |
| **Personal Data** | Email patterns in code (not config), IP addresses (private ranges) |
| **Database URLs** | `postgres://`, `mongodb://`, `mysql://` with credentials |
| **Tokens** | `ghp_`, `gho_`, `github_pat_`, `xoxb-`, `xoxp-` |

**Validates .gitignore includes:**
- `.env*` (all environment files)
- `*.pem`, `*.key`, `*.pfx` (certificates/keys)
- `node_modules/`, `__pycache__/`, `.venv/` (dependencies)
- `.claude/` local settings
- `_backup/` (CWE backups)
- OS files (`.DS_Store`, `Thumbs.db`)
- IDE files (`.vscode/settings.json`, `.idea/`)

**Hook integration:**
```json
{
  "PreToolUse": [{
    "matcher": "Bash",
    "hooks": [{
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/safety-gate.sh",
      "timeout": 30
    }]
  }]
}
```

- Triggers on `git commit`, `git push`, `git add -A`
- Exit 2 = blocks commit with detailed report
- Exit 0 = safe to proceed
- Reports: which files, which patterns, which line numbers

#### 8b: Safety Skill

New `skills/safety-gate/SKILL.md`:
- Describes the safety scanning rules
- Invoked PROACTIVELY when user says "commit", "push", "publish"
- Provides remediation guidance (how to clean up secrets)

**Files changed:** New hook script, `hooks/hooks.json`, new skill

---

### Phase 9: Git Workflow Standards ✅

**Status:** Completed — git-standards skill, commit-format.sh, branch-naming.sh, PreToolUse hooks.
**Goal:** Consistent git practices across all CWE-managed projects.

#### 9a: Conventional Commits

New `skills/git-standards/SKILL.md`:

**Enforced format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:** `feat`, `fix`, `chore`, `docs`, `style`, `refactor`, `test`, `perf`, `ci`, `build`, `revert`

**Enforcement:** PreToolUse hook on `Bash(git commit*)`:
- Parses commit message
- Exit 2 if format invalid, with example of correct format
- Allows `--no-verify` bypass for emergencies (logged)

#### 9b: Branch Naming

**Enforced patterns:**
| Pattern | Purpose |
|---------|---------|
| `main` | Production |
| `develop` | Integration |
| `feature/<ticket>-<description>` | New features |
| `fix/<ticket>-<description>` | Bug fixes |
| `hotfix/<description>` | Urgent production fixes |
| `chore/<description>` | Maintenance |
| `release/<version>` | Release prep |

**Enforcement:** PreToolUse hook on `Bash(git checkout -b*)`, `Bash(git switch -c*)`:
- Validates branch name format
- Exit 2 with suggestion if invalid

#### 9c: Auto-Generated Release Notes

Triggered by `/cwe:devops release`:
1. Reads VERSION, bumps it
2. Parses git log since last tag for conventional commits
3. Groups by type (Features, Fixes, Chores, etc.)
4. Generates CHANGELOG.md entry
5. Generates GitHub-flavored release notes
6. Creates git tag `v<VERSION>`

**Files changed:** New skill, hook scripts, devops agent updated

---

### Phase 10: Project Health & Intelligence ✅

**Status:** Completed — health-dashboard skill, quality health mode, CODEOWNERS generation spec.
**Goal:** Know the state of your project at a glance.

#### 10a: Health Dashboard Skill

New `skills/health-dashboard/SKILL.md`:

Invoked via `/cwe:quality health` or PROACTIVELY at session start:

```markdown
## Project Health: <project-name> v<VERSION>

### Code Quality
- Test Coverage: 82% (↑2% from last check)
- Complexity: 9.2 avg (target: <10) ✅
- TODO/FIXME count: 14 (↓3)
- Type coverage: 91%

### Dependencies
- Total: 47 (12 dev)
- Outdated: 3 (minor), 1 (major)
- Vulnerable: 0 ✅
- License issues: 0 ✅

### Documentation
- README: ✅ current
- ARCHITECTURE.md: ⚠️ last updated 14 days ago
- API.md: ✅ current
- CHANGELOG: ✅ matches VERSION
- ADRs: 5 total, 0 superseded

### Git Health
- Branch: feature/v0.4.1-overhaul
- Uncommitted changes: 3 files
- Last commit: 2h ago
- Conventional commits: 98% compliant

### Security
- .gitignore: ✅ complete
- Secrets scan: ✅ clean
- Last audit: 3 days ago
```

#### 10b: Dependency Health

Integrated into quality agent:
- `npm outdated` / `pip list --outdated` detection
- CVE scanning via `npm audit` / `pip-audit`
- License compatibility check against project license
- Alerts for major version bumps with breaking changes

#### 10c: Code Ownership

Auto-generate `CODEOWNERS` from git history:
- Analyze `git log --format='%aN' -- <path>` per directory
- Map most active contributors to paths
- Output GitHub-compatible `CODEOWNERS` format
- Update on `/cwe:devops` or `/cwe:guide` request

**Files changed:** New skills, quality + devops + guide agents updated

---

## Phase Summary & Priority

| Phase | Name | Status | Impact |
|-------|------|--------|--------|
| 1 | CLAUDE.md slim-down | ✅ Done | High (token savings) |
| 2 | Standards overhaul + Discovery + Index | ✅ Done | Very High (Agent-OS best features) |
| 3 | Agent modernization | ✅ Done | High (features) |
| 4 | Memory & Idea System overhaul | ✅ Done | High (project-scoped fix) |
| 5 | Delete redundant skills | ✅ Done | Medium (cleanup) |
| 6 | Hooks modernization | ✅ Done | Medium (foundation) |
| 7 | Spec system + Project docs | ✅ Done | Very High (spec-driven core) |
| 8 | Safety gate | ✅ Done | Very High (security) |
| 9 | Git standards | ✅ Done | High (consistency) |
| 10 | Health dashboard | ✅ Done | High (visibility) |

---

## Post v0.4.1 — Future Considerations

### v0.4.2 — Agent Teams Integration
- Evaluate Claude Code Agent Teams (currently research preview)
- Replace/augment Wave Execution with native team coordination
- Shared task lists via `TodoRead`/`TodoWrite`

### v0.4.2 — Observability
- Session-level audit trail (which agents ran, what they produced)
- Metrics: token usage per agent, delegation accuracy

### v0.5.0 — Profile Templates (inspired by Agent-OS)

Lightweight version of Agent-OS' profile inheritance:

```
/cwe:init          → Interactive menu: "What type of project?"
/cwe:init api       → API template ($ARGUMENTS = "api")
/cwe:init pwa       → PWA template
/cwe:init fullstack  → Full-stack template
```

Each template pre-selects:
- Relevant `.claude/rules/` standards
- Appropriate agent configurations
- Matching `docs/` structure (API docs for api, component docs for pwa)
- Tech-stack defaults in `workflow/product/tech-stack.md`

Templates stored in CWE plugin: `templates/profiles/api/`, `templates/profiles/pwa/`, etc.
Users can create custom templates that inherit from defaults.

### v0.4.6 — Community Templates
- Community template marketplace
- Template sharing via git repos
- `templates/profiles/custom/` for user overrides

### v0.4.7 — Multi-Project Support
- Monorepo awareness (per-package workflow/)
- Cross-project dependency tracking
- Shared standards library

---

## Design Decisions Log

### DD-001: "test" keyword routes to quality, not builder
- **Date:** 2025-02-13
- **Context:** Keyword conflict between auto-delegation and agent-detection
- **Decision:** "test" always → quality. Quality delegates to builder for implementation.
- **Rationale:** Quality is the gatekeeper. Builder writes tests as part of TDD, not as standalone task.

### DD-002: Standards migrate from Skills to .claude/rules/
- **Date:** 2025-02-13
- **Context:** Claude Code v2.1.x supports `.claude/rules/` with `paths` frontmatter
- **Decision:** Move all domain-specific standards to native rules system
- **Rationale:** Native loading is more token-efficient (paths-based on-demand vs skill description matching). CWE shouldn't replicate what Claude Code does natively.

### DD-003: Separate auto-delegation and agent-detection (Option B)
- **Date:** 2025-02-13
- **Context:** Two skills with overlapping keyword tables but different scopes
- **Decision:** Keep both with sharp scope boundaries. Auto-delegation = user intent routing. Agent-detection = build-phase task routing.
- **Rationale:** Separation of concerns. Different input types (free text vs structured tasks) warrant different handling, even with shared keyword vocabulary.

### DD-004: Remove Greptile references
- **Date:** 2025-02-13
- **Context:** Greptile MCP not installed, referenced in security agent and mcp-usage skill
- **Decision:** Remove all Greptile references, replace with Serena tools where applicable
- **Rationale:** Don't reference capabilities that aren't available. Security agent gains serena:search_for_pattern and serena:find_symbol instead.

### DD-005: Idea capture migrates from .toon to memory system
- **Date:** 2025-02-13
- **Context:** Custom .toon format is fragile, Claude Code now has native memory
- **Decision:** Use memory/ideas.md with JSONL format
- **Rationale:** Native memory persists across sessions, is discoverable by Claude, and doesn't require custom parsing.

### DD-006: VERSION file as Single Source of Truth
- **Date:** 2025-02-13
- **Context:** Version strings hardcoded in multiple places (plugin.json, CLAUDE.md, session-start.sh, README)
- **Decision:** Plain-text `VERSION` file at project root. All other files reference or read from it.
- **Rationale:** One place to bump, zero drift. Release automation reads VERSION and cascades to all consumers.

### DD-007: Pre-commit safety gate as blocking hook
- **Date:** 2025-02-13
- **Context:** Risk of committing secrets, PII, or unignored sensitive files
- **Decision:** PreToolUse hook on git commit/push that scans staged files and validates .gitignore
- **Rationale:** Defense in depth. Even with .gitignore, staged files can bypass it. Hook exit code 2 blocks the commit with actionable feedback.

### DD-008: Conventional Commits enforced via hook
- **Date:** 2025-02-13
- **Context:** Inconsistent commit messages make auto-generated changelogs unreliable
- **Decision:** PreToolUse hook validates commit message format. Emergency bypass via `--no-verify` (logged).
- **Rationale:** Conventional commits enable auto-generated release notes and meaningful changelogs. The hook educates rather than just blocks.

### DD-009: Standardized docs/ structure for all projects
- **Date:** 2025-02-13
- **Context:** Every project has ad-hoc documentation (or none)
- **Decision:** `/cwe:init` scaffolds a standard `docs/` folder with README, ARCHITECTURE, API, SETUP, and decisions/
- **Rationale:** Consistent documentation structure means CWE agents know where to find and update information. The researcher agent can reliably maintain docs because paths are predictable.

### DD-011: Ideas must be project-scoped, not global
- **Date:** 2025-02-13
- **Context:** Current idea-observer.sh writes ALL ideas to a single global file (~/.claude/cwe/idea-observations.toon). With 40+ ideas across multiple projects, the innovator shows irrelevant ideas in every project.
- **Decision:** Ideas captured per-project using $CLAUDE_PROJECT_DIR. Stored as JSONL in ~/.claude/cwe/ideas/<project-slug>.jsonl. Innovator defaults to current project, `/cwe:innovator all` for cross-project view.
- **Rationale:** Project isolation is a core CWE principle. Ideas without project context go to _global.jsonl. Cross-project inspiration is opt-in, not forced.

### DD-012: MEMORY.md as index only (Hub-and-Spoke)
- **Date:** 2025-02-13
- **Context:** Claude Code's auto-memory MEMORY.md is limited to 200 lines. CWE needs to persist ideas, sessions, decisions, patterns — far more than 200 lines.
- **Decision:** MEMORY.md contains ONLY a concise index with counts and 1-line summaries. Detail files (ideas.md, sessions.md, decisions.md, patterns.md, project-context.md) are read on-demand by Claude.
- **Rationale:** 200 lines is enough for an index. Claude's file tools can read detail files when needed. This scales to any project size without hitting the limit.

### DD-013: Standards Discovery via Guide Agent (inspired by Agent-OS)
- **Date:** 2025-02-13
- **Context:** CWE requires manually written standards. Agent-OS v3.0 auto-discovers patterns from codebase and interviews the user to document them.
- **Decision:** `/cwe:guide discover` analyzes codebase patterns, interviews user, generates `.claude/rules/` files. Uses `$ARGUMENTS` for domain scoping (`/cwe:guide discover api`).
- **Rationale:** Manual standard authoring doesn't scale. Discovery makes standards a living system that evolves with the codebase. Guide Agent is the natural owner ("workflow, process, pattern, improve, optimize").

### DD-014: Standards Index with keyword-based Detection Rules
- **Date:** 2025-02-13
- **Context:** `.claude/rules/` `paths` frontmatter is static file-glob matching. Agent-OS uses `index.yml` with detection rules for intelligent injection.
- **Decision:** `.claude/rules/_index.yml` maps standards to both file paths AND task keywords. Auto-delegation reads this index for contextual injection.
- **Rationale:** Path-based matching misses intent. A user working on "error handling" in any file should get error-handling standards, not just files matching `**/errors/**`.

### DD-015: Spec folders replace single spec files (inspired by Agent-OS)
- **Date:** 2025-02-13
- **Context:** CWE stores specs as single markdown files in `workflow/specs/`. Agent-OS uses spec folders with plan.md, shape.md, references.md, and standards.md.
- **Decision:** Specs become folders: `workflow/specs/YYYY-MM-DD-HHMM-<slug>/` containing plan.md, shape.md, references.md, standards.md, and visuals/.
- **Rationale:** A spec is more than a plan. Capturing scope decisions, related code references, and the standards snapshot at spec time makes specs self-contained historical records. Months later, anyone can understand not just *what* was planned but *why*.

### DD-016: Architect Agent interviews before spec writing
- **Date:** 2025-02-13
- **Context:** `/cwe:start` Spec Phase jumps directly into spec writing. Agent-OS `/shape-spec` interviews the user with targeted questions first.
- **Decision:** `/cwe:architect shape` conducts a structured interview (scope, affected components, constraints, definition of done), injects relevant standards, then generates the spec folder.
- **Rationale:** Better specs = better builds. Asking "what's OUT of scope?" prevents scope creep. Injecting standards ensures the spec respects existing patterns. The interview takes 2 minutes but saves hours of implementation rework.

### DD-017: Slash commands use $ARGUMENTS, not flags
- **Date:** 2025-02-13
- **Context:** Claude Code slash commands don't support `--flag` syntax. Agent-OS uses separate commands for each action.
- **Decision:** CWE uses `$ARGUMENTS` positional args: `/cwe:guide discover`, `/cwe:innovator all`, `/cwe:init pwa`. Interactive AskUserQuestion menu when no argument provided.
- **Rationale:** Cleaner UX than creating dozens of separate commands. `$ARGUMENTS` is native Claude Code behavior. Menu fallback means no arg = guided experience, with arg = power-user shortcut.

### DD-010: GitHub-optimized README with SVG generation
- **Date:** 2025-02-13
- **Context:** GitHub is the primary publishing platform. Plain markdown lacks visual impact.
- **Decision:** Auto-generate README with custom SVG header banner, tech badges, and mermaid diagrams
- **Rationale:** Professional presentation matters. SVGs render natively on GitHub without external services. The banner encodes project identity (name, version, description) visually.
