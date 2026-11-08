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

For each plugin to install, run (the official marketplace `claude-plugins-official` is auto-added on first interactive start):
```bash
claude plugin install <plugin-name>@claude-plugins-official
```
If the official marketplace isn't present yet (e.g. a non-interactive setup), add it first:
```bash
claude plugin marketplace add anthropics/claude-plugins-official
```
Inside a session you can instead use the interactive installer: `/plugin install <plugin-name>@claude-plugins-official` (or `/plugin` alone to browse).

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

## Step 1e: Install Statusline

CWE provides a live statusline for Claude Code showing context usage, rate-limit windows, and session time (no cost/currency tracking — keep it compact).

### Check for existing statusline

```bash
test -f "$HOME/.claude/statusline.py" && echo "EXISTS" || echo "MISSING"
```

**If EXISTS:** Do NOT overwrite — the user may have a customized statusline. Skip to configuring Claude Code settings.

**If MISSING:** Copy the template:

```bash
cp "${CLAUDE_PLUGIN_ROOT}/templates/statusline.py" "$HOME/.claude/statusline.py"
chmod +x "$HOME/.claude/statusline.py"
```

### Configure Claude Code settings

Merge a `statusLine` block into the user's global settings at `~/.claude/settings.json` (merge — do NOT overwrite the file):

```json
{
  "statusLine": {
    "type": "command",
    "command": "python3 ~/.claude/statusline.py",
    "padding": 2
  }
}
```

On native Windows (no `python3`), use `python` in the command instead. There is no `claude config set` key for the statusline; `/statusline` is the interactive alternative. If the user declines, skip — the statusline is optional but recommended.

## Step 1f: Configure Web Research (optional)

CWE's `/cwe:web-research` command uses local self-hosted services for web search and scraping.

Ask the user with AskUserQuestion:

```
Question: "Hast du SearXNG und/oder Firecrawl lokal laufen?"
Header: "Web Research"
Options:
  1. "Ja, beides" - SearXNG + Firecrawl sind erreichbar
  2. "Nur SearXNG" - Nur Metasearch, Scraping via trafilatura
  3. "Nein, überspringen" - Web Research wird nicht konfiguriert (Recommended)
```

### If "Ja, beides" or "Nur SearXNG":

Ask for URLs (defaults: SearXNG `http://localhost:4000`, Firecrawl `http://localhost:3002`).

Write or update `.claude/cwe-settings.yml`:

```yaml
searxng_url: http://localhost:4000
firecrawl_url: http://localhost:3002
```

### Quick connectivity test:

```bash
curl -s --max-time 3 "${SEARXNG_URL:-http://localhost:4000}/search?q=test&format=json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'SearXNG OK — {len(d.get(\"results\",[]))} results')" 2>/dev/null || echo "SearXNG nicht erreichbar"
```

---

## Step 1g: Configure Transcript Service (optional)

CWE's `/cwe:transcript` command supports Instagram/TikTok/Podcast URLs via a user-provided self-hosted faster-whisper API. YouTube always works via tubetranscript fallback (no config needed).

Ask the user with AskUserQuestion:

```
Question: "Hast du einen faster-whisper-Server fuer Instagram/TikTok/Podcast Transkripte?"
Header: "Transcript"
Options:
  1. "Ja, Whisper-Server-URL eintragen" - User gibt eigene URL an
  2. "Nein, nur YouTube" - tubetranscript Fallback, skip Whisper server
```

### If "Ja":

Ask for URL (example: `https://scribe.example.com` or `http://localhost:8000`).

Write/update `.claude/cwe-settings.yml`:
```yaml
tscribe_url: <user-url>
```

## Step 1h: Configure Document Tools (optional)

### Stirling PDF (for /cwe:pdf)

CWE's `/cwe:pdf` command reads PDFs by converting pages to images via [Stirling PDF API](https://github.com/Stirling-Tools/Stirling-PDF) (local, open-source). Without it, `/cwe:pdf` is disabled.

```
Question: "Hast du einen Stirling PDF Server fuer /cwe:pdf?"
Header: "PDF Reader"
Options:
  1. "Ja, URL eintragen" - Stirling ist erreichbar
  2. "Nein, spaeter" - /cwe:pdf wird nicht funktionieren bis konfiguriert
  3. "Docker starten?" - Start stirlingtools/stirling-pdf via Docker
```

### If "Ja" — ask for URL (default: `http://localhost:8080`).

Write/update `.claude/cwe-settings.yml`:
```yaml
stirling_pdf_url: http://localhost:8080
```

### If "Docker starten" — suggest:
```bash
docker run -d --name stirling-pdf -p 8080:8080 stirlingtools/stirling-pdf:latest
```
Then write the URL as `http://localhost:8080`.

## Step 1i: Configure Media Generation (optional)

CWE's media skills (`/cwe:image`, `/cwe:video`, `/cwe:faceswap`, `/cwe:headswap`, `/cwe:upscale`) require API keys.

```
Question: "Media-Generation-Tools einrichten?"
Header: "Media Tools"
Options:
  1. "Ja, API-Keys eintragen" - OpenRouter + MagicHour keys setup
  2. "Nur OpenRouter (Image only)" - Nur /cwe:image funktioniert
  3. "Nein, spaeter" - Skills installiert aber bis zur Konfiguration nicht nutzbar
```

### If configuring keys:

Check if `${CLAUDE_PLUGIN_ROOT}/scripts/media-keys.sh` already exists. If yes, ask before overwriting.

Ask for keys (without echoing to terminal — use masked input if possible):
- **OpenRouter** (for `/cwe:image`): Sign up at https://openrouter.ai/settings/keys
- **MagicHour** (for video/faceswap/etc.): Sign up at https://magichour.ai/

Write to `${CLAUDE_PLUGIN_ROOT}/scripts/media-keys.sh`:
```bash
#!/usr/bin/env bash
# Media Tools API Keys — NEVER COMMIT (already in .gitignore)
export OPENROUTER_API_KEY="<user-input>"
export MAGICHOUR_API_KEY="<user-input>"
```

Set file permissions: `chmod 600 scripts/media-keys.sh`.

## Step 1j: Configure Remotion (optional, for /cwe:motion)

```
Question: "Remotion-Projekt fuer /cwe:motion konfigurieren?"
Header: "Motion Graphics"
Options:
  1. "Bestehendes Projekt nutzen" - Pfad zu Remotion-Projekt angeben
  2. "Neues Projekt anlegen" - npx create-video@latest in ./remotion/
  3. "Nein, spaeter" - /cwe:motion wird nicht funktionieren bis konfiguriert
```

### If existing:
```yaml
remotion_project_dir: /path/to/remotion-project
```

### If new:
```bash
npx create-video@latest remotion
```
Then:
```yaml
remotion_project_dir: ./remotion
```

## Step 1k: Configure Gitea Mirror (optional)

`/cwe:gitea` pushes to a private Gitea mirror. Credentials live in `$HOME/.claude/cwe.local.md` (not in `cwe-settings.yml`, to keep secrets out of project config).

```
Question: "Gitea-Mirror fuer /cwe:gitea einrichten?"
Header: "Gitea"
Options:
  1. "Ja, jetzt konfigurieren" - Guide user to create $HOME/.claude/cwe.local.md
  2. "Nein, spaeter" - Skip (Docs in commands/gitea.md)
```

### If yes:

Show the Gitea-only block and ask the user to fill it in. Merge this block into `$HOME/.claude/cwe.local.md` — create the file with a YAML frontmatter section if missing, or append the `gitea:` key to the existing frontmatter. Do NOT add any `bookstack:` section here (that is Step 1l).

```yaml
# $HOME/.claude/cwe.local.md
---
gitea:
  url: https://<your-gitea-host>
  user: <username>
  password: <token-or-app-password>
  ssh_host: <your-gitea-host>
  ssh_port: 22
---
```

## Step 1l: Configure BookStack (optional)

BookStack is used by docs-oriented workflows for publishing notes/pages to a self-hosted knowledge base. Credentials live in the same `$HOME/.claude/cwe.local.md` as Gitea, under a separate `bookstack:` block.

```
Question: "BookStack fuer Notizen/Wissensbasis einrichten?"
Header: "BookStack"
Options:
  1. "Ja, jetzt konfigurieren" - Add bookstack: block to $HOME/.claude/cwe.local.md
  2. "Nein, spaeter" - Skip
```

### If yes:

Show the BookStack-only block and ask the user to fill it in. Merge this block into `$HOME/.claude/cwe.local.md` under the same frontmatter section (add alongside `gitea:` if present; do NOT replace it).

```yaml
# $HOME/.claude/cwe.local.md
---
bookstack:
  url: https://<your-bookstack-host>
  token_id: <token-id>
  token_secret: <token-secret>
---
```

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
- `{{project-name}}` → actual directory name (`basename "$PWD"`)
- `{{project-slug}}` → lowercased, hyphenated directory name (`basename "$PWD" | tr '[:upper:] ' '[:lower:]-'`)
- `Stack: (not configured)` → detected tech stack summary
- `Phase: init` → `Phase: init (just initialized)`

### Placeholder Substitution (applies to all copied templates)

After copying templates, run these substitutions on the freshly-created files. **Two kinds of placeholders exist:**

**Auto-filled by this command** (must be substituted before presenting files to the user):

| Placeholder | Value | Files |
|-------------|-------|-------|
| `{{PROJECT_NAME}}` | `basename "$PWD"` | docs/README.md, docs/SETUP.md, docs/API.md, docs/DEVLOG.md, workflow/config.yml |
| `{{project-name}}` | `basename "$PWD"` | memory/MEMORY.md |
| `{{project-slug}}` | `basename "$PWD" \| tr '[:upper:] ' '[:lower:]-'` | memory/MEMORY.md, memory/ideas.md, workflow/ideas.md |
| `{{DATE}}` | `date +%Y-%m-%d` | docs/DEVLOG.md, memory/<today>.md |

Example substitution block (run after templates are copied, skip memory/ lines if `SKIP_MEMORY=true`):

```bash
PROJECT_NAME="$(basename "$PWD")"
PROJECT_SLUG="$(basename "$PWD" | tr '[:upper:] ' '[:lower:]-')"
TODAY="$(date +%Y-%m-%d)"

# docs/
sed -i "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" docs/README.md docs/SETUP.md docs/API.md docs/DEVLOG.md 2>/dev/null || true
sed -i "s/{{DATE}}/${TODAY}/g" docs/DEVLOG.md 2>/dev/null || true

# workflow/
sed -i "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" workflow/config.yml 2>/dev/null || true
sed -i "s/{{project-slug}}/${PROJECT_SLUG}/g" workflow/ideas.md 2>/dev/null || true

# memory/ (skip if SKIP_MEMORY=true)
if [ "$SKIP_MEMORY" != "true" ]; then
  sed -i "s/{{project-name}}/${PROJECT_NAME}/g" memory/MEMORY.md 2>/dev/null || true
  sed -i "s/{{project-slug}}/${PROJECT_SLUG}/g" memory/MEMORY.md memory/ideas.md 2>/dev/null || true
fi
```

**User-filled** (left as natural-language hints like `[e.g. npm install, ...]` — the user edits these when populating their project). These are NOT placeholders to substitute; they are inline prompts. Do not run sed on them.

Examples intentionally left for the user to edit: install/dev/test/lint commands in README.md and SETUP.md, license, repo URL, API base URL, ADR title/deciders/number.

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

## Step 3d: Multi-Terminal Development (optional)

Use AskUserQuestion:

**Question:** "Multi-Terminal Parallel Development einrichten?"
**Header:** "Multi-Terminal"

**Options:**
1. "2 Terminals (Dev + QA)" — Preset A
2. "3 Terminals (Frontend + Backend + QA)" — Preset B
3. "4 Terminals (Frontend + Backend + Infra + QA)" — Preset C
4. "Custom (eigene Rollen)" — User defines roles
5. "Nein, später" — Skip

### If "Nein, später": Skip to Step 4.

### Preset Configuration

| Preset | Branches | Handoff Files |
|--------|----------|---------------|
| A (2T) | `t1-dev`, `t2-qa` | `dev-qa.md` |
| B (3T) | `t1-frontend`, `t2-backend`, `t3-qa` | `frontend-backend.md`, `frontend-qa.md`, `backend-qa.md` |
| C (4T) | `t1-frontend`, `t2-backend`, `t3-infra`, `t4-qa` | `frontend-backend.md`, `frontend-qa.md`, `backend-qa.md`, `backend-infra.md`, `infra-qa.md` |
| D | User-defined | Generated from role pairs |

### For Custom (D): Ask the user
- "Wie viele Terminals?" (2-6)
- For each: "Rolle für Terminal {N}?" (e.g., api, worker, mobile)

### Setup Steps (for any preset)

1. **Create branches:**
```bash
# For each terminal:
git branch t{N}-{role}
```

2. **Create worktrees:**
```bash
mkdir -p .trees
# For each terminal:
git worktree add .trees/t{N}-{role} t{N}-{role}
```

3. **Create shared handoff directory:**
```bash
mkdir -p shared/handoff
```

4. **Generate handoff files** from `${CLAUDE_PLUGIN_ROOT}/templates/multi-terminal/handoff-template.md`:
Replace `{{SOURCE_ROLE}}`, `{{TARGET_ROLE}}`, `{{SOURCE_NUM}}`, `{{TARGET_NUM}}` placeholders.

5. **Copy handoff README:**
```bash
cp "${CLAUDE_PLUGIN_ROOT}/templates/multi-terminal/README.md" shared/handoff/README.md
```

6. **Generate terminal prompts** from `${CLAUDE_PLUGIN_ROOT}/templates/multi-terminal/terminal-prompt.md`:
```bash
mkdir -p terminal-prompts
```
Replace `{{NUM}}`, `{{ROLE}}`, `{{ROLE_SLUG}}`, `{{AGENT_LIST}}` placeholders.

Agent mapping for `{{AGENT_LIST}}`:
- Frontend: `builder, quality, architect, explainer`
- Backend: `builder, devops, architect, security`
- QA: `quality, security, researcher, ask`
- Infra: `devops, security, architect, researcher`
- Dev (generic): `builder, quality, architect, devops`

7. **Add to .gitignore:**
```
.trees/
```

8. **Initial commit on each branch:**
```bash
# For each terminal branch:
git checkout t{N}-{role}
git add shared/ terminal-prompts/
git commit -m "chore: initialize multi-terminal structure for t{N}-{role}"
git checkout main
```

9. **Show setup summary:**
```
Multi-Terminal Development initialized!

Terminals:
  T1: {role} → .trees/t1-{role}/
  T2: {role} → .trees/t2-{role}/
  ...

To start a terminal:
  cd .trees/t{N}-{role} && claude

Commands:
  /cwe:autopilot      — Autonomous task loop
  /cwe:coordinate     — Team-lead coordination
  /cwe:check-handoff  — Check pending handoffs
  /cwe:handoff        — Send work to another terminal
  /cwe:qa-merge       — QA-verified merge to main
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
