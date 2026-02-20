---
description: Initialize CWE in current project - creates workflow structure and checks plugin dependencies
allowed-tools: ["Write", "Bash", "Read", "Glob", "AskUserQuestion"]
---

# Initialize CWE Project

Create the workflow structure for spec-driven development and ensure all recommended plugins are installed.

## Step 1: Check Plugin Dependencies

CWE works best with these plugins installed:

| Plugin | Purpose | Required |
|--------|---------|----------|
| superpowers | TDD, debugging, planning, code review | **Yes** |
| serena | Semantic code analysis via LSP | Recommended |
| feature-dev | 7-phase feature development | Recommended |
| frontend-design | Production-grade UI components | Optional |
| code-simplifier | Code cleanup and refactoring | Optional |
| claude-md-management | CLAUDE.md maintenance | Optional |
| plugin-dev | Plugin creation tools | Optional |

### Check installed plugins

Run this command to get installed plugins:
```bash
claude plugin list --json 2>/dev/null || echo '[]'
```

### Compare with required plugins

Required: `superpowers`
Recommended: `serena`, `feature-dev`
Optional: `frontend-design`, `code-simplifier`, `claude-md-management`, `plugin-dev`

### If plugins are missing

Use AskUserQuestion to ask the user:

**Question:** "Some recommended plugins are missing. Would you like to install them?"

**Options:**
1. "Install all missing" - Install all missing plugins
2. "Install required only" - Install only superpowers (if missing)
3. "Skip" - Continue without installing

### Install missing plugins

For each plugin to install, run:
```bash
claude plugin install <plugin-name>
```

Show progress for each installation.

## Step 1b: Check MCP Server Dependencies

CWE and its agents work best with these MCP servers:

| MCP Server | Purpose | Level |
|------------|---------|-------|
| playwright | Browser automation, E2E testing, screenshots | Recommended |
| context7 | Up-to-date library docs via Context7 | Recommended |
| github | GitHub API integration (PRs, issues, repos) | Recommended |
| filesystem | Direct filesystem access for agents | Optional |
| sequential-thinking | Step-by-step reasoning for complex tasks | Optional |

### Check installed MCP servers

Run this command to list currently configured MCP servers:
```bash
claude mcp list 2>/dev/null || echo 'No MCP servers configured'
```

### Compare with recommended servers

Check which of the recommended servers are already configured.

### If MCP servers are missing

Use AskUserQuestion to ask the user:

**Question:** "Some recommended MCP servers are missing. Install them?"

**Options:**
1. "Install all recommended" - Install playwright, context7, github
2. "Install all (recommended + optional)" - Install all 5 servers
3. "Let me pick" - Choose which to install
4. "Skip" - Continue without MCP servers

### Detect platform

Before installing, detect the platform:
```bash
uname -s  # Linux, Darwin, MINGW/MSYS (Windows)
```

### Install commands per platform

**Linux / macOS (default):**
```bash
claude mcp add playwright -- npx @playwright/mcp@latest --isolated --headless --no-sandbox
claude mcp add context7 -- npx @upstash/context7-mcp
claude mcp add github -- npx @modelcontextprotocol/server-github
claude mcp add filesystem -- npx @modelcontextprotocol/server-filesystem
claude mcp add sequential-thinking -- npx @modelcontextprotocol/server-sequential-thinking
```

**Windows (MINGW/MSYS/WSL with Windows host):**
```bash
# Playwright: remove --isolated --headless --no-sandbox flags (not supported on Windows)
claude mcp add playwright -- npx @playwright/mcp@latest
claude mcp add context7 -- npx @upstash/context7-mcp
claude mcp add github -- npx @modelcontextprotocol/server-github
claude mcp add filesystem -- npx @modelcontextprotocol/server-filesystem
claude mcp add sequential-thinking -- npx @modelcontextprotocol/server-sequential-thinking
```

Show progress for each installation. If a server fails to install, warn but continue with the rest.

## Step 1c: Detect Serena Plugin (Memory Strategy)

If the **serena** plugin is installed, Serena provides its own memory system (`write_memory`, `read_memory`, `list_memories`). In that case, the CWE `memory/` directory is **redundant**.

Check if serena is installed (from Step 1 results). If serena IS installed, use AskUserQuestion:

**Question:** "Serena plugin detected — it has its own memory system. Create CWE memory/ directory anyway?"

**Options:**
1. "Skip memory/ (use Serena)" — Do NOT create `memory/` directory. Set `SKIP_MEMORY=true`.
2. "Create memory/ anyway" — Create `memory/` as usual (both systems coexist).

Store the decision. If `SKIP_MEMORY=true`:
- Do NOT create `memory/` directory or any files within it
- Do NOT add `memory/` to `.gitignore`
- Do NOT seed project-context.md or daily logs
- Session hooks will gracefully skip memory operations (they already check for `memory/` existence)

---

## Step 1d: Configure Statusline Currency

Use AskUserQuestion to ask:

**Question:** "Which currency for the statusline cost display?"

**Options:**
1. "EUR" — Euro (default)
2. "USD" — US Dollar
3. "GBP" — British Pound
4. "CHF" — Swiss Franc

Save the choice to `.claude/cwe-settings.yml`:

```yaml
# CWE Project Settings
# Set during /cwe:init

currency: EUR
```

If the file already exists, update just the `currency:` line. If not, create it.

---

## Step 1e: Install Statusline

CWE provides a live statusline for Claude Code showing context usage, cost, and session time.

### Copy statusline script

```bash
cp "${CLAUDE_PLUGIN_ROOT}/templates/statusline.py" "$HOME/.claude/statusline.py"
chmod +x "$HOME/.claude/statusline.py"
```

### Configure Claude Code settings

Add the statusline to the user's Claude Code `settings.json`:

```bash
claude config set --global status_line 'python3 ~/.claude/statusline.py'
```

If it fails or the user declines, skip — the statusline is optional but recommended.

---

## Step 2: Check existing workflow setup

Check if `workflow/` already exists:
- If exists: Ask user if they want to reinitialize
- If not: Proceed with creation

## Step 3: Create structure

Create the following structure (skip `memory/` section if `SKIP_MEMORY=true`):

```
workflow/
├── README.md              # Overview of workflow system
├── config.yml             # Project configuration
├── ideas.md               # Curated ideas backlog (per-project)
├── product/
│   ├── README.md          # What goes here
│   └── mission.md         # Product vision template
├── specs/
│   └── README.md          # How to write specs (folder-per-spec)
└── standards/
    └── README.md          # Project-specific standards (optional)

memory/                    # ONLY if SKIP_MEMORY is not true
├── MEMORY.md              # Index (200-line max, Hub-and-Spoke)
├── YYYY-MM-DD.md          # Daily logs (auto-created at session start/stop)
├── ideas.md               # Curated idea backlog
├── decisions.md           # Project ADRs
├── patterns.md            # Recognized work patterns
└── project-context.md     # Tech stack, priorities

docs/
├── README.md              # Project overview (auto-maintained)
├── ARCHITECTURE.md        # System design, component overview
├── API.md                 # Endpoint documentation (if applicable)
├── SETUP.md               # Installation, dev environment
├── DEVLOG.md              # Chronological developer journal
└── decisions/
    └── _template.md       # ADR template

VERSION                    # Single Source of Truth for version (semver)
```

Copy templates from `${CLAUDE_PLUGIN_ROOT}/templates/memory/` for all memory files (SKIP if `SKIP_MEMORY=true`).
Copy templates from `${CLAUDE_PLUGIN_ROOT}/templates/docs/` for all docs files.
Copy `${CLAUDE_PLUGIN_ROOT}/templates/docs/VERSION` to project root.

## Step 3b: Auto-Seed Project Memory

**SKIP this entire step if `SKIP_MEMORY=true`** (Serena handles memory).

After creating the memory structure, detect the project's tech stack and populate memory files.

### Tech-Stack Detection

Check for these files in the project root:

| File | Stack |
|------|-------|
| `package.json` | Node.js — read `dependencies`/`devDependencies` for framework (React, Vue, Next.js, Express, etc.) |
| `tsconfig.json` | TypeScript (additional to package.json) |
| `Cargo.toml` | Rust — read `[dependencies]` for key crates |
| `go.mod` | Go — read module name |
| `pyproject.toml` | Python — read `[project.dependencies]` or `[tool.poetry.dependencies]` |
| `requirements.txt` | Python — list major packages |
| `composer.json` | PHP — read `require` for framework (Laravel, Symfony, etc.) |
| `Gemfile` | Ruby — read gems for framework (Rails, Sinatra, etc.) |
| `pom.xml` | Java — read dependencies |
| `build.gradle` / `build.gradle.kts` | Java/Kotlin — read dependencies |
| `Dockerfile` | Docker — note presence |
| `.github/workflows/` | GitHub Actions CI — note presence |

### Populate memory/project-context.md

Replace the `(not configured)` placeholders with detected values:

```markdown
# Project Context

## Tech Stack
- Language: [detected language(s)]
- Framework: [detected framework(s)]
- Build: [detected build tool]
- CI: [detected if present]

## Current Phase
init

## Priorities
(not set — update after /cwe:start)

## Team
(not set)
```

### Populate memory/MEMORY.md

Replace template placeholders:
- `{{project-name}}` → actual directory name
- `Stack: (not configured)` → detected tech stack summary
- `Phase: init` → `Phase: init (just initialized)`

### Create first daily log

Create `memory/YYYY-MM-DD.md` (using today's date) with:

```markdown
# YYYY-MM-DD

## HH:MM — Project Initialized
- CWE initialized with /cwe:init
- Stack: [detected tech stack]
- Phase: init
```

**VERSION file rules:**
- Plain text, single line, semver (e.g. `0.1.0`)
- ALL other version references (plugin.json, package.json, CHANGELOG, README) read from here
- `/cwe:devops release patch|minor|major` bumps VERSION and cascades
- Never hardcode version strings anywhere else

## Step 3c: Patch .gitignore

CWE-generated files (memory/, workflow/, docs/) should NOT be committed to the target project's repo by default. After creating the structure, patch the project's `.gitignore`.

### Check and append

Read the existing `.gitignore` (or create one if missing). Append the following block **only if the CWE marker comment is not already present**:

```bash
grep -q '# CWE (Code Workspace Engine)' .gitignore 2>/dev/null
```

If the marker is NOT found, append (omit `memory/` line if `SKIP_MEMORY=true`):

```
# CWE (Code Workspace Engine)
memory/
workflow/
VERSION
```

**Important:**
- Do NOT add `docs/` — users may want to commit their project documentation
- Do NOT add `.claude/` — that's managed by Claude Code itself
- If `.gitignore` doesn't exist, create it with the CWE block
- Inform the user: "Added memory/ and workflow/ to .gitignore — CWE session data won't be committed."

## File contents

### workflow/README.md
```markdown
# Workflow

This directory contains your project's workflow artifacts.

## Structure

- `config.yml` - Project configuration
- `ideas.md` - Ideas backlog for future development
- `product/` - Product vision, goals, roadmap
- `specs/` - Feature specifications
- `standards/` - Project-specific coding standards (optional)

## Quick Start

Run `/cwe:start` to begin guided development.

## Learn More

Run `/cwe:help` for full documentation.
```

### workflow/config.yml
```yaml
# CWE Project Configuration
version: "1.0"

project:
  name: "{{PROJECT_NAME}}"

workflow:
  phases:
    - plan      # Define product vision
    - spec      # Write feature specifications
    - tasks     # Break into implementable tasks
    - build     # Implement with agents
    - review    # Quality gates and verification
```

### workflow/ideas.md
```markdown
# Ideas Backlog

Curated ideas for this project. Raw observations in `~/.claude/cwe/ideas/<project-slug>.jsonl`.

## Status Legend

- **new** — Just captured, not yet reviewed
- **exploring** — Being discussed/developed
- **planned** — Approved for implementation
- **rejected** — Decided against

---

## Ideas

<!-- Ideas will be added here by the innovator agent -->
```

### workflow/product/README.md
```markdown
# Product

Define your product's vision, goals, and constraints here.

## Files

- `mission.md` - Core vision and goals (required)
- `roadmap.md` - Feature roadmap (optional)
- `constraints.md` - Technical/business constraints (optional)
```

### workflow/product/mission.md
```markdown
# Product Mission

## Vision

[What problem does this product solve? Who is it for?]

## Goals

- [ ] Primary goal
- [ ] Secondary goal

## Non-Goals

- What this product will NOT do

## Success Metrics

- How will you measure success?
```

### workflow/specs/README.md
```markdown
# Specifications

Feature specifications live here. Each feature gets its own folder.

## Structure

```
specs/
├── YYYY-MM-DD-HHMM-feature-slug/
│   ├── plan.md          # Implementation plan + task breakdown
│   ├── shape.md         # Scope, decisions, constraints
│   ├── references.md    # Similar code, patterns, prior art
│   ├── standards.md     # Standards snapshot at spec time
│   └── visuals/         # Mockups, diagrams, screenshots
```

Folder naming is auto-generated: `YYYY-MM-DD-HHMM-<feature-slug>/`

## Creating a Spec

- Run `/cwe:start` → Spec Phase → "Shape-Spec Interview" (recommended)
- Or run `/cwe:architect shape` directly
```

### workflow/standards/README.md
```markdown
# Project Standards

Add project-specific coding standards here.

CWE loads built-in standards automatically via `.claude/rules/` with `paths` frontmatter.
8 domains: global, api, frontend, database, devops, testing, agent, documentation.

Use `/cwe:guide discover` to auto-discover patterns from your codebase.
Use `/cwe:guide index` to regenerate the standards index.

## Adding Custom Standards

Create `.claude/rules/your-standard.md` with `paths:` frontmatter for auto-loading.
Or add to `workflow/standards/` for project-specific conventions.
```

## Step 4: Success message

Show completion summary:

```
CWE initialized successfully!

Plugins:
  superpowers (installed)
  serena (installed)
  feature-dev (installed)
  frontend-design (skipped)
  ...

Workflow structure created:
  workflow/
  ├── config.yml
  ├── ideas.md
  ├── product/mission.md
  └── specs/

Memory:
  memory/ created (CWE memory)
  — OR —
  memory/ skipped (using Serena memory)

Documentation structure created:
  docs/
  ├── README.md, ARCHITECTURE.md
  ├── API.md, SETUP.md, DEVLOG.md
  └── decisions/_template.md
  VERSION (0.1.0)

MCP servers configured:
  playwright (installed)
  context7 (installed)
  github (installed)
  filesystem (skipped)
  sequential-thinking (skipped)

Next steps:
1. Edit workflow/product/mission.md with your product vision
2. Run /cwe:start to begin guided development
3. Use /cwe:architect shape for your first feature spec
```

Adjust the plugin status based on what was actually installed/skipped.
