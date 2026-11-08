# CWE v0.8.2 User Guide

> Complete documentation for the Code Workspace Engine plugin v0.8.2.
> Last updated: 2026-04-21 (v0.8.2)

---

## Contents

1. [What is CWE?](#1-what-is-cwe)
2. [Installation & Setup](#2-installation--setup)
   - [First-Time Onboarding](#first-time-onboarding)
   - [/cwe:init Walkthrough](#cweinit-walkthrough)
3. [The 6 Core Principles](#3-the-6-core-principles)
4. [Understanding Auto-Delegation](#4-understanding-auto-delegation)
5. [The 10 Agents in Detail](#5-the-10-agents-in-detail)
6. [Workflow: From Idea to Feature](#6-workflow-from-idea-to-feature)
7. [The Memory System](#7-the-memory-system)
8. [The Standards System](#8-the-standards-system)
9. [Hooks — Behind-the-Scenes Automation](#9-hooks--behind-the-scenes-automation)
10. [The Idea System](#10-the-idea-system)
11. [Skills — Progressive Disclosure](#11-skills--progressive-disclosure)
12. [Quality Gates](#12-quality-gates)
13. [Multi-Terminal Parallel Development](#13-multi-terminal-parallel-development)
14. [Media Tools](#14-media-tools)
15. [External Services](#15-external-services)
16. [Project Structure Reference](#16-project-structure-reference)
17. [FAQ / Troubleshooting](#17-faq--troubleshooting)
18. [Lifecycle Diagram: How Everything Connects](#18-lifecycle-diagram-how-everything-connects)

---

## 1. What is CWE?

### Vision and Purpose

CWE (Code Workspace Engine) is a **Claude Code plugin** that transforms a single AI assistant into a team of 10 specialized agents. Instead of a generic prompt that handles everything, CWE automatically routes your requests to the right expert with the appropriate context.

### Why Spec-Driven Development?

Software projects rarely fail because of implementation — they fail because of unclear requirements. CWE enforces a structured workflow:

```
Idea → Plan → Spec → Tasks → Build → Review
```

Each phase has clearly defined inputs and outputs. A feature is not "just built" — it goes through a Shape-Spec Interview, receives a task breakdown, is implemented in parallel waves, and is validated through Quality Gates.

### Why 10 Specialized Agents Instead of One Generic One?

| Problem with a single agent | Solution through specialization |
|------------------------|------------------------------|
| Massive system prompt containing everything | Each agent covers only its domain |
| Context window fills up quickly | Context Isolation: Agents return summaries |
| No access control | Builder can write, Explainer is read-only |
| No standardized output | Standardized report formats per agent |
| No quality assurance | Quality Agent blocks releases below thresholds |

### CWE vs. "Just Using Claude Code"

| Feature | Claude Code (vanilla) | Claude Code + CWE |
|---------|----------------------|-------------------|
| Agent routing | Manual (you must set context) | Automatic (say what you need) |
| Standards | None | 8 domains, auto-loaded per file path |
| Memory | MEMORY.md (200 lines) | Daily Logs + Serena Memory + Hub-Spoke |
| Workflow | Ad-hoc | Plan → Spec → Tasks → Build → Review |
| Quality | You decide | Quality Gates with metrics |
| Security | No checks | Safety Gate scans every commit |
| Ideas | Get lost | Automatically captured by keyword |
| Git | Free-form | Conventional Commits + Branch Naming |

---

## 2. Installation & Setup

### Prerequisites

- **Claude Code** (CLI) installed and configured
- **Git** for version control
- **Node.js** (optional, for MCP Server)

### Installation

```bash
# 1. Clone the plugin
git clone https://github.com/LL4nc33/code-workspace-engine.git

# 2. Set up an alias (in ~/.bashrc or ~/.zshrc)
alias cwe='claude --plugin-dir /path/to/code-workspace-engine --dangerously-skip-permissions'

# 3. Restart terminal or source the file
source ~/.bashrc
```

### Plugin Dependencies

CWE works together with other Claude Code plugins. `/cwe:init` checks for and offers to install them:

| Plugin | Level | Why? |
|--------|-------|--------|
| **superpowers** | Required | TDD, Debugging, Planning, Code Review — the core skills for every agent |
| **serena** | Recommended | Semantic code analysis via Language Server Protocol (LSP) — understands symbols, references, types |
| **feature-dev** | Recommended | 7-phase feature workflow with code architecture, code explorer, and code reviewer |

### MCP Server Dependencies

| Server | Why? |
|--------|--------|
| **playwright** | Browser testing, screenshot verification for frontend work |
| **context7** | Library documentation lookup (React, Vue, etc.) |
| **github** | GitHub API integration (Issues, PRs, Actions) |

### First-Time Onboarding

Never used CWE before? This is the end-to-end story of bringing a project online.

**Prerequisites checklist**

- [ ] Claude Code CLI installed and authenticated (`claude --version` works)
- [ ] Git installed and the target project is a Git repo (or you are okay with `git init`)
- [ ] A terminal in the project root you want to initialize
- [ ] Optional: Node.js (only needed if you plan to use MCP servers via `npx`)

**Expected time**

- **~5 minutes** if you skip every optional service (plugin install + folder creation only)
- **15–30 minutes** if you configure the full stack (MCP servers, SearXNG/Firecrawl, Whisper server, Stirling PDF, media API keys, Remotion, Gitea, BookStack, Multi-Terminal)

You can always re-run `/cwe:init` later to configure any service you skipped — it is idempotent and only prompts for missing pieces.

**Decision points you will encounter**

`/cwe:init` is a guided interview. For every optional service, "Skip" is a valid and safe answer — the related command simply stays disabled until configured. The major questions, in order:

1. **Plugin installs** — Install missing Claude Code plugins? Skip = keep only what you already have (superpowers is the only true blocker).
2. **MCP servers** — Install playwright/context7/github? Skip = those integrations are unavailable; everything else still works.
3. **Serena memory** — If Serena is detected: skip `memory/` and let Serena handle it, or create `memory/` anyway (both coexist fine).
4. **Statusline** — Installs a compact statusline to `~/.claude/statusline.py`. If one already exists, it is left untouched.
5. **Web research / Transcripts / PDF / Media / Remotion / Gitea / BookStack** — Each is a separate Skip-by-default prompt. Say "later" to any you do not have running.
6. **Multi-Terminal preset** — 2T, 3T, 4T, Custom, or Skip. Skip = standard single-terminal workflow.

**Post-init verification**

Once `/cwe:init` finishes, smoke-test the installation:

- `/cwe:help` — should print the command index (confirms the plugin is loaded)
- `/cwe:plugins` — reports health of plugins, MCP servers, and optional services
- `/cwe:start` — walks you into the guided Plan → Spec → Tasks → Build → Review loop
- `/cwe:researcher` (or any other agent command) — confirms agent delegation works

You should also see: `workflow/`, `docs/`, a `VERSION` file, and (unless you skipped) `memory/` at the project root. The project's `.gitignore` should contain a `# CWE (Code Workspace Engine)` block.

**If something does not work**

- Open `.claude/cwe-settings.yml` — this holds every optional-service URL you configured. Missing keys mean the related command will refuse to run.
- Run `/cwe:plugins` for a one-shot health check of plugins, MCP, and services.
- See Section 17 (FAQ / Troubleshooting) for common issues (hooks not firing, CRLF problems on WSL, MCP install failures).
- External service URLs and setup guides are consolidated in Section 15 (External Services).

**When to re-run `/cwe:init`**

- A new optional service becomes available (you finally set up SearXNG, got a MagicHour key, stood up Stirling PDF).
- You want to add Multi-Terminal to a project that was initialized without it.
- Templates or the init flow itself gain new steps in a CWE release — re-running picks up the new prompts without overwriting existing `workflow/` or `memory/` content.

### /cwe:init Walkthrough

A concise map of the current `/cwe:init` flow. The authoritative source is [`commands/init.md`](../commands/init.md) — this subsection is a quick-reference only.

**Step 1 — Plugin dependencies**
Detects installed plugins via `claude plugin list`. `superpowers` is required; `serena` and `feature-dev` are recommended; `frontend-design`, `code-simplifier`, `claude-md-management`, `plugin-dev` are optional. Offers to install missing ones.

**Step 1b — MCP server dependencies**
Runs `claude mcp list`. Recommended: `playwright`, `context7`, `github`. Optional: `filesystem`, `sequential-thinking`. Platform-aware install commands (Linux/macOS vs Windows).

**Step 1c — Serena memory detection**
If the Serena plugin is installed, offers to skip creating `memory/` (Serena provides `write_memory`/`read_memory`/`list_memories` natively). Session hooks gracefully no-op when `memory/` is absent.

**Step 1e — Statusline**
Installs `~/.claude/statusline.py` if missing (never overwrites a customized one) and registers it with `claude config set --global status_line`. Compact format: context bar, session time, lines changed — no cost or currency.

**Step 1f — Web Research services (optional)**
SearXNG (default `http://localhost:4000`) and Firecrawl (`http://localhost:3002`) for `/cwe:web-research`. URLs saved to `.claude/cwe-settings.yml`. Skip = command stays inert.

**Step 1g — Transcript service (optional)**
faster-whisper-compatible Whisper URL for Instagram/TikTok/Podcast transcripts via `/cwe:transcript`. YouTube always works without this. Key: `tscribe_url`.

**Step 1h — Stirling PDF (optional)**
URL for the [Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF) container that backs `/cwe:pdf` (default `http://localhost:8080`). Option to print the Docker run one-liner. Key: `stirling_pdf_url`.

**Step 1i — Media generation keys (optional)**
API keys for `/cwe:image`, `/cwe:video`, `/cwe:faceswap`, `/cwe:headswap`, `/cwe:upscale`. Writes `scripts/media-keys.sh` (chmod 600, gitignored) with `OPENROUTER_API_KEY` and `MAGICHOUR_API_KEY`.

**Step 1j — Remotion project (optional)**
Point `/cwe:motion` at an existing Remotion project or scaffold a new one via `npx create-video@latest`. Key: `remotion_project_dir`.

**Step 1k — Gitea mirror (optional)**
Credentials for `/cwe:gitea` (URL, user, token, SSH host/port) stored in `$HOME/.claude/cwe.local.md` frontmatter — never in the project config.

**Step 1l — BookStack (optional)**
Publishing target for docs-oriented workflows. `bookstack:` block appended to the same `$HOME/.claude/cwe.local.md` alongside `gitea:`.

**Step 2 — Existing workflow check**
If `workflow/` already exists, asks before reinitializing.

**Step 3 — Create project structure**
Generates `workflow/` (config.yml, ideas.md, product/mission.md, specs/, standards/), `docs/` (README, ARCHITECTURE, API, SETUP, DEVLOG, decisions/_template.md), `VERSION`, and — unless Step 1c skipped it — `memory/` (MEMORY.md, today's daily log, ideas.md, decisions.md, patterns.md, project-context.md).

**Step 3b — Auto-seed memory**
Detects tech stack from `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `composer.json`, `Gemfile`, `pom.xml`, `build.gradle`, `Dockerfile`, `.github/workflows/`, etc. Substitutes `{{PROJECT_NAME}}`, `{{project-slug}}`, `{{DATE}}` placeholders. Writes today's daily log.

**Step 3c — Patch project `.gitignore`**
Appends a `# CWE (Code Workspace Engine)` block covering `memory/`, `workflow/`, `VERSION`. `docs/` and `.claude/` are intentionally **not** added.

**Step 3d — Multi-Terminal setup (optional)**
Presets: **2T** (Dev+QA), **3T** (Frontend+Backend+QA), **4T** (+Infra), **Custom** (2–6 roles), or Skip. Creates branches (`t{N}-{role}`), worktrees in `.trees/`, `shared/handoff/` files, and `terminal-prompts/` with a role-appropriate agent list. Appends `.trees/` to `.gitignore`.

**Step 4 — Success summary**
Prints what was installed, what was skipped, the created directory tree, and the suggested next steps (`edit mission.md`, `/cwe:start`, `/cwe:architect shape`).

### Statusline — Real-Time Session Dashboard

CWE provides a Python-based statusline displayed at the bottom of Claude Code, giving you real-time visibility into your session.

**What it shows (compact one-line format):**

| Element | Description |
|---------|-------------|
| Workspace | Current project identifier |
| Context usage bar | Color-coded bar showing context window usage (green/yellow/red) |
| Rate-limit windows | 5h / 7d usage percentages |
| Session time | Elapsed time since session start |

**Example:**
```
code-workspace-engine  |  ctx ━━━━──── 55% 110k/200k  |  5h/7d 16%/22%  |  t 17m01s
```

**Configuration:**
- The template lives at `templates/statusline.py` and is copied to `~/.claude/statusline.py` by `/cwe:init` (only if the file doesn't already exist — your customizations are preserved).
- `NO_COLOR=1` disables ANSI colors; colors are also auto-disabled when stdout is not a TTY.

**Benefits:**
- See context window usage before it fills up (plan compactions)
- Monitor 5h / 7d rate-limit windows at a glance
- Session duration for time tracking

**Note on cost tracking:** v0.8.2 removed the currency/cost feature — it was half-implemented in earlier versions. If cost visibility matters to your workflow, it's on the roadmap (see ROADMAP.md).

---

## 3. The 6 Core Principles

### Principle 1: Agent-First

**What:** Every task is delegated to a specialized agent. The main context stays lean.

**Why:** Claude Code has a limited context window. When an agent reads 5000 lines of code, that fills the main context. With delegation, the agent reads the code, returns a 20-line summary, and the main context remains free.

**Example:**
```
You: "Fix the login bug"
CWE: Delegates to builder agent
Builder: Reads code, debugs, fixes, tests
Builder → CWE: "Fixed: NullPointerException in AuthService.login() (line 47). Root cause: missing null check on session token."
```

### Principle 2: Auto-Delegation

**What:** CWE analyzes your natural language and automatically routes to the appropriate agent.

**Why:** You do not need to know which agent handles what. Simply say what you need.

**Example:**
```
"Fix the login bug"        → builder (Keywords: fix, bug)
"Explain how auth works"   → explainer (Keywords: explain, how)
"What if we used GraphQL?" → innovator (Keywords: what if)
"Run the test suite"       → quality (Keywords: test)
```

### Principle 3: Spec-Driven

**What:** Features always go through the cycle: Plan → Spec → Tasks → Build → Review.

**Why:** A feature without a spec is like a building without a blueprint. The Shape-Spec Interview forces you to define scope before any code is written. This prevents scope creep and makes features traceable.

**Example:**
```
/cwe:architect shape
→ Interview: "What is IN Scope? What is OUT of Scope?"
→ Interview: "Which components are affected?"
→ Interview: "What is the Definition of Done?"
→ Generates: workflow/specs/2026-02-13-1430-user-auth/
   ├── plan.md, shape.md, references.md, standards.md
```

### Principle 4: Context Isolation

**What:** Agents work in isolated contexts. Only the result (summary) is returned.

**Why:** A security audit reads 50 files and produces 2000 lines of analysis. You only need the 30-line summary. Context Isolation keeps the context window efficient.

### Principle 5: Plugin Integration

**What:** Agents use skills from installed plugins (superpowers, serena, feature-dev).

**Why:** CWE does not reinvent the wheel. superpowers has excellent TDD and debugging. serena has semantic code analysis. feature-dev has a 7-phase feature workflow. CWE orchestrates these skills.

### Principle 6: Always Document

**What:** Every non-trivial change updates: MEMORY.md, Daily Log, CHANGELOG, affected docs.

**Why:** CWE has no long-term memory without explicit documentation. If the memory files are not current, the next session starts without context. Documentation is not a nice-to-have — it is the persistence layer.

---

## 4. Understanding Auto-Delegation

### How CWE Routes Requests

```
User request
    ↓
Explicit /command? ─────────→ Execute command directly
    ↓ no
Plugin skill matches? ──────→ Invoke skill (PRIORITY)
    ↓ no
CWE agent matches? ────────→ Delegate to agent
    ↓ no
Multi-step task? ──────────→ Delegate to subagents (via delegator skill)
    ↓ no
Unclear? ──────────────────→ Ask (max 2 questions)
```

**Important:** Plugin skills take priority over agent routing. If you say "debug this", `superpowers:systematic-debugging` matches before the builder agent is activated.

### Intent → Agent Keyword Table

| Intent | Agent | Keywords |
|--------|-------|----------|
| Write/fix code | **builder** | implement, fix, build, create, code, feature, bug, refactor |
| Debug/investigate | **debug** | debug, investigate, diagnose, root cause, stack trace |
| Questions/discussion | **ask** | question, discuss, think about |
| Explain code | **explainer** | explain, how, what, why, understand |
| Testing/quality | **quality** | test, write tests, coverage, quality, validate, metrics, gate |
| Security | **security** | security, audit, vulnerability, scan, gdpr, owasp, cve |
| Infrastructure | **devops** | deploy, docker, ci, cd, release, kubernetes, terraform |
| Architecture | **architect** | design, architecture, adr, api, schema |
| Research/docs | **researcher** | analyze, document, research, compare |
| Brainstorming | **innovator** | brainstorm, idea, ideas, what if, alternative, explore |
| Process improvement | **guide** | workflow, process, pattern, improve, optimize |

### Intent → Plugin Skill

| Keywords | Skill | Plugin |
|----------|-------|--------|
| UI, frontend, component | `frontend-design` | frontend-design |
| simplify, cleanup | `code-simplifier` | code-simplifier |
| debug, investigate bug | `systematic-debugging` | superpowers |
| write plan, planning | `writing-plans` | superpowers |
| review code | `requesting-code-review` | superpowers |
| TDD, test first | `test-driven-development` | superpowers |
| create plugin, hook | plugin-dev skills | plugin-dev |
| develop feature | `/feature-dev` | feature-dev |

### "manual" Override

Say **"manual"** or **"no delegation"** to disable Auto-Delegation. CWE will then process your request directly without delegating to an agent.

### Two-Layer Routing Model

CWE uses two complementary routing layers for auto-delegation:

**Layer 1: Intent Router Hook** (keyword-based, fast, pre-LLM)
The `intent-router.py` hook runs on every `UserPromptSubmit` event before the LLM processes the message. It matches keywords against a predefined pattern table and injects a `systemMessage` routing hint. This is instant and deterministic -- no token cost.

**Layer 2: Auto-Delegation Skill** (LLM-based, context-aware, fallback)
If the intent router does not inject a routing hint, the auto-delegation skill analyzes the full prompt with LLM reasoning. This handles ambiguous requests, multi-step detection, and plugin skill matching.

```
User prompt
    ↓
Layer 1: intent-router.py (keyword match?)
    ├── yes → systemMessage hint injected → LLM follows hint
    └── no  → Layer 2: auto-delegation skill (LLM analyzes intent)
```

Layer 1 handles the common case fast. Layer 2 handles everything else with full context awareness.

### Real-World Examples

```
"Fix the login bug"
  → Keywords: fix, bug → builder
  → Builder uses: systematic-debugging + serena

"How does the auth middleware work?"
  → Keywords: how → explainer
  → Explainer uses: serena (find_symbol, get_symbols_overview)

"What if we replaced REST with GraphQL?"
  → Keywords: what if → innovator
  → Innovator uses: SCAMPER methodology, WebSearch

"Run all tests and check coverage"
  → Keywords: test, coverage → quality
  → Quality uses: Bash(npm test), quality-gates skill

"Create a Docker setup"
  → Keywords: docker → devops
  → DevOps uses: Bash(docker), Dockerfile creation

"Look at this code"
  → No clear keywords → ASK: "Would you like to fix, explain, or analyze the code?"
```

---

## 5. The 10 Agents in Detail

### 5.1 builder — The "Code Coroner"

**Identity:** Systematic, thorough, never guesses — always investigates the evidence first.

**When:** Writing code, fixing bugs, implementing features, refactoring.

**Tools:** Read, Write, Edit, Bash, Grep, Glob, all serena tools, Task (for subagents)

**Skills:** Uses superpowers (TDD, debugging), serena (symbol navigation), feature-dev (code-architect)

**Access:** Full read/write access to code

**Typical commands:**
```
"Fix the login bug"
"Implement user authentication"
"Refactor the API layer"
/cwe:builder "add input validation to the signup form"
```

**Key feature:** The Builder follows the TDD cycle (Red → Green → Refactor) when superpowers:test-driven-development is available. It never implements without tests.

---

### 5.2 architect — The Systems Thinker

**Identity:** Thinks in systems, not files. Sees the forest, not just the trees.

**When:** System design, writing ADRs, shaping feature specs (Shape-Spec Interview).

**Tools:** Read, Grep, Glob, Task, AskUserQuestion, serena (symbols + patterns)

**Access:** READ-ONLY for code, write access to workflow/specs/ and docs/

**Typical commands:**
```
"Design the authentication system"
/cwe:architect shape    → Shape-Spec Interview
/cwe:architect "write an ADR for the database choice"
```

**Key feature:** The Shape-Spec Interview is the centerpiece. The Architect asks:
1. What is IN Scope? What is OUT of Scope?
2. Which components are affected?
3. Which standards apply?
4. What is the Definition of Done?

The result is a spec folder with plan.md, shape.md, references.md, and standards.md.

---

### 5.3 ask — The Discussion Partner

**Identity:** Thoughtful, analytical, explores all angles without jumping to conclusions.

**When:** Open-ended questions, discussions, "let's think about this."

**Tools:** Read, Grep, Glob, WebSearch, WebFetch, serena (symbols)

**Access:** STRICTLY READ-ONLY — makes no changes

**Typical commands:**
```
"Discuss: Should we use microservices or monolith?"
"Think about the trade-offs of caching here"
/cwe:ask "what are the implications of upgrading to Node 22?"
```

**Key feature:** The Ask agent is the only one that explicitly takes no action. It thinks, analyzes, and presents options — the decision is yours.

---

### 5.4 explainer — The Educator

**Identity:** Patient, clear technical educator. Explains complex things simply without being condescending.

**When:** Understanding code, getting concepts explained, tracing architecture decisions.

**Tools:** Read, Grep, Glob, serena (get_symbols_overview, find_symbol)

**Access:** READ-ONLY

**Output formats:**
- **Code Explanations:** TL;DR → Step-by-step → Design Rationale
- **Concept Explanations:** Simple Terms → In This Project → Example
- **How-To:** Quick Answer → Step by Step → Watch Out For

**Typical commands:**
```
"Explain how the auth middleware works"
"What does this function do?"
/cwe:explainer "walk me through the payment flow"
```

---

### 5.5 quality — The Quality Guardian

**Identity:** Nothing ships without your approval. Thorough. Data-driven. Uncompromising on standards.

**When:** Running tests, checking coverage, code reviews, Health Dashboard.

**Tools:** Read, Grep, Glob, Bash (jest, npm test, nyc, eslint), serena

**Skills:** quality-gates, health-dashboard

**Access:** READ-ONLY + Test Commands

**Quality Gates:**

| Metric | Minimum | Target | Blocks Release |
|--------|---------|--------|----------------|
| Line Coverage | 70% | 80% | <60% |
| Branch Coverage | 65% | 75% | <55% |
| Cyclomatic Complexity | <15 | <10 | >20 |
| Test Duration | <5min | <2min | >10min warns |
| Flaky Tests | 0 | 0 | >0 |

**Typical commands:**
```
"Run tests and check coverage"
/cwe:quality health        → Full Health Dashboard
/cwe:quality "review the last commit"
```

---

### 5.6 security — The Security Auditor

**Identity:** Cautious, thorough, assumes breach. "Trust nothing, verify everything."

**When:** Security audits, vulnerability scans, OWASP checks, GDPR compliance.

**Tools:** Read, Grep, Glob, Bash (trivy, grype, semgrep, nmap, curl), serena

**Skills:** quality-gates

**Access:** RESTRICTED — Read + specific audit commands

**Audit framework:** OWASP Top 10 (2021)
- Severity Levels: Critical, High, Medium, Low, Informational
- Always with remediation recommendations
- GDPR compliance check included

**Typical commands:**
```
"Audit the API for security issues"
/cwe:security "scan dependencies for CVEs"
/cwe:security "GDPR compliance check"
```

**Key feature:** Reports never contain the value of a secret — only the location. The Security Agent reports `LOCATION: config.js:42`, never the actual key.

---

### 5.7 devops — The Infrastructure Expert

**Identity:** Automates everything. If you do it twice, script it.

**When:** Docker, CI/CD, releases, deployments, Terraform.

**Tools:** Read, Write, Edit, Bash, Grep, Glob, serena

**Access:** Full access (requires write permissions for Dockerfiles, CI configs, etc.)

**Typical commands:**
```
"Set up Docker for this project"
"Create a GitHub Actions CI pipeline"
/cwe:devops release        → VERSION bump + CHANGELOG + git tag
/cwe:devops "add staging environment"
```

**Key feature:** For `release`, the DevOps agent reads the VERSION file, bumps it, generates release notes from Conventional Commits, updates CHANGELOG.md, and creates a git tag.

---

### 5.8 researcher — The Analyst

**Identity:** Thorough, structured, citation-oriented. Every claim has evidence.

**When:** Codebase analysis, generating documentation, technology comparisons, reports.

**Tools:** Read, Grep, Glob, WebSearch, WebFetch, serena

**Skills:** project-docs

**Access:** READ-ONLY (exception: docs/ files)

**Documentation modes:**
- `docs update` → Scans the codebase, updates all docs
- `docs check` → Validates docs freshness vs. code
- `docs adr` → Creates new ADR in docs/decisions/

**Typical commands:**
```
"Analyze the codebase architecture"
"Compare React vs Vue for our use case"
/cwe:researcher docs update
/cwe:researcher "generate a dependency report"
```

---

### 5.9 innovator — The Idea Forge

**Identity:** Creative, curious, unbound by "how it's always been done."

**When:** Brainstorming, developing ideas, "What if?", managing the idea backlog.

**Tools:** Read, Write, Grep, Glob, WebSearch, WebFetch, serena

**Access:** READ-ONLY for code, WRITE for workflow/ideas.md

**4 Modes:**

| Mode | Command | What happens |
|-------|---------|-------------|
| Default | `/cwe:innovator` | Shows current project ideas |
| All | `/cwe:innovator all` | Cross-project idea overview |
| Review | `/cwe:innovator review` | Interactive triage: Keep/Develop/Reject |
| Develop | `/cwe:innovator develop <idea>` | Deep-dive on an idea (SCAMPER) |

**Ideation Methodology:** UNDERSTAND → DIVERGE (SCAMPER) → EXPLORE → CONVERGE → PRESENT

---

### 5.10 guide — The Process Whisperer

**Identity:** Sees patterns others miss. Reflective. Data-informed. Evolution-focused.

**When:** Analyzing patterns, extracting standards from code, improving workflows.

**Tools:** Read, Grep, Glob, serena (search_for_pattern, get_symbols_overview)

**Access:** READ-ONLY + write access to .claude/rules/

**2 Main modes:**
- `discover` → Scans the codebase for patterns, interviews the user, generates `.claude/rules/`
- `index` → Regenerates `.claude/rules/_index.yml` with keyword detection

**Evolution Methodology:** OBSERVE → ANALYZE → HYPOTHESIZE → PROPOSE → VALIDATE

**Typical commands:**
```
/cwe:guide discover          → Auto-discovery of all patterns
/cwe:guide discover api      → API patterns only
/cwe:guide index             → Regenerate standards index
/cwe:guide "analyze our workflow efficiency"
```

---

## 6. Workflow: From Idea to Feature

### The 5 Phases

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   Plan ──→ Spec ──→ Tasks ──→ Build ──→ Review         │
│    │         │                   │         │            │
│    │    Shape-Spec          Wave Exec   Quality         │
│    │    Interview           (parallel)   Gates          │
│    │                                      │             │
│    └──────────────────────────────────────┘             │
│                  next feature                           │
└─────────────────────────────────────────────────────────┘
```

### Phase 1: Plan

**Goal:** Define the product vision.

**File:** `workflow/product/mission.md`

Answer these questions:
- What does this product solve? For whom?
- What are the goals?
- What are the non-goals (what we deliberately do NOT do)?
- How do we measure success?

### Phase 2: Spec (Shape-Spec Interview)

**Goal:** Precisely define feature scope before any code is written.

**Trigger:** `/cwe:architect shape` or `/cwe:start` in the spec phase.

The Architect conducts a structured interview:
1. **Scope:** What is IN Scope? What is OUT of Scope?
2. **Components:** Which files/modules are affected?
3. **Constraints:** Technical/business constraints?
4. **Standards:** Which existing standards apply?
5. **Definition of Done:** When is the feature complete?

**Output:** Spec folder `workflow/specs/YYYY-MM-DD-HHMM-<slug>/`
```
├── plan.md          # Implementation plan + task breakdown
├── shape.md         # Scope, decisions, constraints
├── references.md    # Similar code, patterns, prior art
├── standards.md     # Standards snapshot at the time of the spec
└── visuals/         # Mockups, diagrams, screenshots
```

### Phase 3: Tasks

**Goal:** Break the spec down into implementable tasks.

Organization modes:
- **By Component** — Grouped by file/module
- **By Priority** — Critical first, nice-to-have last
- **By Dependency** — Build order (A before B)

### Phase 4: Build (Wave Execution)

**Goal:** Implement tasks in parallel with multiple agents.

**Wave Execution Algorithm:**
1. Load all pending tasks
2. Filter unblocked tasks (no open dependencies)
3. Form a wave: up to 3 parallel tasks
4. For each task: determine the agent, execute in parallel
5. Wait until all tasks in the wave are complete
6. Start the next wave until no tasks remain

**Example:**
```
Wave 1 (3 tasks in parallel):
  [builder] Task 1: Implement API endpoints ✓
  [devops]  Task 2: Setup Docker ✓
  [builder] Task 3: Add input validation ✓

Wave 2 (1 task, was blocked by Task 1):
  [quality] Task 4: Write integration tests ✓

All tasks completed.
```

### Phase 5: Review

**Goal:** Ensure quality before the feature ships.

Options after completion:
- **Code Review** → Quality Agent
- **Run tests** → Quality Agent
- **Create PR** → DevOps Agent
- **Add more tasks** → Back to Phase 4

---

## 7. The Memory System

### Why Memory?

**Problem:** Claude Code has no long-term memory between sessions. Every new session starts from zero — past decisions, patterns, and context are lost.

**Solution:** CWE's Memory System persists knowledge in structured files that are automatically injected at every session start.

### Serena Plugin and Memory

When the Serena plugin is installed, it provides its own symbol-level memory system for code understanding. In this case, the `memory/` directory is optional -- users can skip creating it during `/cwe:init`. Serena tracks code symbols, references, and types independently. If you still want CWE's hub-and-spoke memory (for decisions, patterns, daily logs), you can create the `memory/` directory alongside Serena.

### The Memory Architecture (Hub-and-Spoke)

```
                    ┌──────────────┐
                    │  MEMORY.md   │  ← Hub (max 200 lines, always loaded)
                    │   (Index)    │
                    └──────┬───────┘
                           │
           ┌───────┬───────┼───────┬──────────┐
           │       │       │       │          │
     ┌─────┴─┐ ┌──┴──┐ ┌──┴──┐ ┌──┴──┐ ┌────┴────┐
     │Daily  │ │deci-│ │pat- │ │ideas│ │project- │
     │Logs   │ │sions│ │terns│ │ .md │ │context  │
     │YYYY-  │ │ .md │ │ .md │ │     │ │  .md    │
     │MM-DD  │ │     │ │     │ │     │ │         │
     └───────┘ └─────┘ └─────┘ └─────┘ └─────────┘
```

### MEMORY.md — The Hub

- **Max 200 lines** (fully injected at session start)
- Contains: project name, version, current priorities, key decisions
- Updated every session
- Serves as an index: "For details see decisions.md"

### Daily Logs — Daily Protocols

**File:** `memory/YYYY-MM-DD.md`

```markdown
# 2026-02-13

## 14:30 — Session Start
- Goal: Plan Memory System Upgrade
- Context: CWE v0.4.1, all phases completed

## 14:45 — Design Decision
- Decision: Daily Logs instead of sessions.md
- Rationale: Natural time structure, no file grows unbounded

## 16:00 — Session End
- Done: Design complete, plan written
- Next: Implement Phase 1
- Files changed: hooks/hooks.json, hooks/scripts/session-start.sh
```

- **Append-only** — only new entries, never edit existing ones
- **Today + Yesterday** are injected at session start
- **Automatically cleaned up** — logs older than 30 days are deleted

### project-context.md — Tech Stack and Priorities

- Automatically seeded during `/cwe:init` (tech stack detection)
- Contains: language, framework, database, CI/CD, current priorities
- Read on demand, not at every session

### decisions.md — Architecture Decision Records

Format per entry:
```markdown
## ADR-001: JWT Instead of Session Cookies
- **Date:** 2026-02-13
- **Status:** Accepted
- **Context:** SPA needs stateless auth
- **Decision:** JWT with Refresh Token Rotation
- **Alternatives:** Session Cookies, OAuth2 PKCE
- **Consequences:** No server-side session store required
```

### patterns.md — Recognized Patterns

Code patterns discovered and documented by the Guide agent.

### Context Injection at Session Start

At every session start (via `session-start.sh`):
1. Read `memory/MEMORY.md` in full (max 200 lines)
2. Read `memory/YYYY-MM-DD.md` (today)
3. Read `memory/YYYY-MM-DD.md` (yesterday)
4. Cap everything at 8000 characters total
5. Inject as `systemMessage`

### Pre-Compact Memory Save

When the context window fills up and Claude Code compacts, the PreCompact hook saves beforehand:
- Current work to the Daily Log
- MEMORY.md update

---

## 8. The Standards System

### How Standards Work

CWE uses Claude Code's native `.claude/rules/` with `paths` frontmatter for auto-loaded standards:

```markdown
---
paths:
  - "src/api/**"
  - "routes/**"
---

# API Standards

## REST Endpoints
- Use plural nouns: /users, /posts
- Use kebab-case: /user-profiles
...
```

When you work on a file in `src/api/`, the API standards are automatically loaded.

### 8 Built-in Standards

| Standard | Paths | Domain |
|----------|-------|--------|
| `global-standards.md` | `**/*` (always) | Naming, Tech Stack |
| `api-standards.md` | `src/api/**`, `routes/**` | REST, Validation |
| `frontend-standards.md` | `src/components/**`, `pages/**` | Components, State |
| `database-standards.md` | `migrations/**`, `models/**` | Queries, Schema |
| `devops-standards.md` | `Dockerfile`, `.github/**`, `terraform/**` | CI/CD, Docker |
| `testing-standards.md` | `**/*.test.*`, `**/*.spec.*` | Coverage, Mocking |
| `agent-standards.md` | `agents/**`, `skills/**`, `hooks/**` | Agent Authoring |
| `documentation-standards.md` | `docs/**`, `memory/**` | Memory Updates |

### Standards Discovery

```
/cwe:guide discover
```

The Guide agent:
1. Scans the codebase for recurring patterns (>3x = candidate)
2. Interviews you: "I noticed you always use pattern X. Why? Should this become a standard?"
3. Generates `.claude/rules/<domain>-<pattern>.md` with correct `paths` frontmatter
4. Updates `.claude/rules/_index.yml`

### Standards Indexing

```
/cwe:guide index
```

Regenerates the `_index.yml` from all existing `.claude/rules/*.md` files:
- Extracts `paths` frontmatter
- Identifies keywords from the content
- Validates that no conflicts exist between rules

### _index.yml Structure

```yaml
- file: global-standards.md
  paths: ["**/*"]
  keywords: ["naming", "convention", "tech stack"]
  auto_inject: true
  priority: 100
- file: api-standards.md
  paths: ["src/api/**", "routes/**"]
  keywords: ["api", "endpoint", "REST", "validation"]
  auto_inject: true
  priority: 80
```

**Important:** Paths must be formatted as a YAML list, NOT as a comma-separated string.

### Creating Custom Standards

1. Create `.claude/rules/your-standard.md` with `paths:` frontmatter
2. Run `/cwe:guide index` to update the index
3. Or use `/cwe:guide discover` for automatic detection

---

## 9. Hooks — Behind-the-Scenes Automation

### What Are Hooks?

Hooks are shell scripts and prompts that automatically react to events. They run in the background — you usually do not notice them, but they hold everything together.

**Hook events in CWE:**

| Event | When | Hooks |
|-------|------|-------|
| `SessionStart` | Session begins | Context Injection |
| `Stop` | Session ends | Write Daily Log |
| `PreCompact` | Context is being compacted | Save memory |
| `UserPromptSubmit` | User writes something | Idea Observer, Intent Router, URL Scraper, Transcript |
| `SubagentStop` | Agent finishes | Agent Logging |
| `PreToolUse (Bash)` | Before Bash command | Safety Gate, Commit Format, Branch Naming |

### SessionStart: Context Injection

**Script:** `hooks/scripts/session-start.sh`

At every session start:
1. Reads MEMORY.md (max 200 lines)
2. Reads today's Daily Log
3. Reads yesterday's Daily Log
4. Caps at 8000 characters
5. Injects as `systemMessage`

This ensures you always have the current project context without manually opening files.

### Stop: Memory Flush + Daily Log

Hooks registered for the same event run in parallel, not sequentially. At session end:

**1. Prompt Hook:** Instructs Claude to update MEMORY.md and the Daily Log (documentation checklist).

**2. Script:** `hooks/scripts/session-stop.sh`
- Creates `memory/YYYY-MM-DD.md` if it does not exist
- Appends session-end timestamp
- Cleans up Daily Logs older than 30 days

**3. Script:** `hooks/scripts/idea-flush.sh`
- Counts captured ideas for the current project
- Displays the number of unreviewed ideas as systemMessage
- Reminds about `/cwe:innovator` for review

### PreCompact: Memory Save

**Prompt Hook:** When Claude's context window fills up, older messages are compacted. Before that happens, this hook saves the current state to the Daily Log.

### UserPromptSubmit: Idea Observer

**Script:** `hooks/scripts/idea-observer.sh`

Scans every user message for idea keywords:
- German: idee, was wäre wenn, könnte man, vielleicht, alternativ, verbesserung
- English: idea, what if, could we, maybe, alternative, improvement

Match → JSONL entry in `~/.claude/cwe/ideas/<project-slug>.jsonl`

### UserPromptSubmit: Intent Router

**Script:** `hooks/scripts/intent-router.py`

Keyword-based agent routing that runs before the LLM sees the prompt. Matches user input against predefined keyword patterns and injects a `systemMessage` hint for the appropriate agent. This is Layer 1 of the Two-Layer Routing Model (see [Section 4](#4-understanding-auto-delegation)).

### UserPromptSubmit: URL Scraper

**Script:** `hooks/scripts/url-scraper.py`

Automatically detects non-YouTube URLs in user messages and scrapes their content using Firecrawl (with trafilatura fallback). The scraped content is injected as `systemMessage` so Claude can reference it directly.

### UserPromptSubmit: Transcript

**Script:** `hooks/scripts/transcript.sh`

Detects YouTube URLs (`youtube.com`, `youtu.be`) in user messages and extracts the video transcript via tubetranscript. The transcript is injected as `systemMessage` for immediate use. For non-YouTube URLs (Instagram, TikTok, Podcasts), use `/cwe:transcript` which routes through a user-configured Whisper server.

### SubagentStop: Agent Logging

**Script:** `hooks/scripts/subagent-stop.sh`

Logs agent executions for observability:
- Which agent ran?
- When?
- Result status

### PreToolUse: Safety Gate

**Script:** `hooks/scripts/safety-gate.sh`

Triggers on: `git commit`, `git push`, `git add -A`

**Scans for:**
- API Keys (sk-*, AKIA*, ghp_*, xoxb-*)
- Private Keys (-----BEGIN.*PRIVATE KEY-----)
- Hardcoded Passwords (password=, secret=)
- Database URLs with credentials
- .env files
- Certificates (.pem, .key, .pfx)

**Exit Codes:** 0 = safe, 2 = BLOCKED (with report)

### PreToolUse: Commit Format

**Script:** `hooks/scripts/commit-format.sh`

Validates Conventional Commit format:
```
<type>(<scope>): <subject>
```

Allowed types: feat, fix, chore, docs, style, refactor, test, perf, ci, build, revert

### PreToolUse: Branch Naming

**Script:** `hooks/scripts/branch-naming.sh`

Validates branch name format:
- `feature/<description>`, `fix/<description>`, `hotfix/<description>`
- `chore/<description>`, `release/<version>`
- `main`, `develop` (allowed)

### How the Circle Closes

```
Session Start
    │
    ├── session-start.sh → MEMORY.md + Daily Logs injected
    │
    ▼
User works
    │
    ├── idea-observer.sh → Ideas captured
    ├── intent-router.py → Agent routing
    ├── url-scraper.py → URL content scraped
    ├── transcript.sh → Transcript fetched
    ├── safety-gate.sh → Commits checked
    ├── commit-format.sh → Format validated
    ├── branch-naming.sh → Branch validated
    ├── subagent-stop.sh → Agents logged
    │
    ▼
Context fills up
    │
    ├── PreCompact Hook → Memory saved
    │
    ▼
Session ends
    │
    ├── Stop Prompt → MEMORY.md + Daily Log updated
    ├── session-stop.sh → Timestamp + Cleanup
    │
    ▼
Next Session
    │
    └── session-start.sh → Everything injected again ← ─ ─ Cycle
```

---

## 10. The Idea System

### Automatic Capture

Every user message is scanned by the `idea-observer.sh` hook. If it contains certain keywords, an entry is automatically created:

**Keywords (DE):** idee, was wäre wenn, könnte man, vielleicht, alternativ, verbesserung
**Keywords (EN):** idea, what if, could we, maybe, alternative, improvement

### JSONL Format

Ideas are stored per project: `~/.claude/cwe/ideas/<project-slug>.jsonl`

```json
{"ts":"2026-02-13T14:30:00Z","prompt":"was wäre wenn wir GraphQL statt REST nutzen?","project":"my-app","keywords":["was wäre wenn"],"status":"raw"}
```

### 4 Modes of the Innovator Agent

| Mode | Command | Description |
|-------|---------|-------------|
| **Default** | `/cwe:innovator` | Shows new observations + backlog status for the current project |
| **All** | `/cwe:innovator all` | Cross-project overview, shows transferable ideas |
| **Review** | `/cwe:innovator review` | Interactive triage: Keep / Develop / Reject per observation |
| **Develop** | `/cwe:innovator develop <idea>` | Deep-dive with SCAMPER methodology |

### From Idea to Feature

```
Casual remark → Idea Observer captures it
    ↓
/cwe:innovator review → Triage: Keep/Develop/Reject
    ↓
/cwe:innovator develop <idea> → SCAMPER Deep-Dive
    ↓
User decides → Status: "planned"
    ↓
/cwe:architect shape → Create spec
    ↓
/cwe:start → Build Phase
```

---

## 11. Skills — Progressive Disclosure

Skills are specialized instructions that support agents with specific tasks. They are referenced in the agent frontmatter.

### auto-delegation

**File:** `skills/auto-delegation/SKILL.md`

The heart of CWE. Contains the complete decision flow, keyword tables, and context injection rules for auto-delegation of user requests to agents and plugin skills.

### agent-detection

**File:** `skills/agent-detection/SKILL.md`

Similar to auto-delegation, but for the build phase: detects which agent is responsible for a structured task (not for free-form user requests).

### quality-gates

**File:** `skills/quality-gates/SKILL.md`

Defines the 3 Quality Gates:
1. **Pre-Implementation:** Architect reviews the spec
2. **Post-Implementation:** Quality checks code, tests, coverage
3. **Pre-Release:** Security checks for vulnerabilities

### safety-gate

**File:** `skills/safety-gate/SKILL.md`

Pre-commit scanning for secrets, credentials, PII. Describes which patterns are scanned and how remediation works.

### git-standards

**File:** `skills/git-standards/SKILL.md`

Conventional Commits format, branch naming patterns, auto-generated release notes. Referenced by the PreToolUse hooks.

### health-dashboard

**File:** `skills/health-dashboard/SKILL.md`

Defines the Project Health Score (0-100) across 5 categories: Code Quality (25%), Dependencies (20%), Documentation (20%), Git Health (20%), Security (15%).

### project-docs

**File:** `skills/project-docs/SKILL.md`

Generation and maintenance of project documentation: README, ARCHITECTURE, API, SETUP. Includes tech stack auto-detection and docs freshness check.

### web-research

**File:** `skills/web-research/SKILL.md`

Web research capability using self-hosted SearXNG (meta-search engine) and Firecrawl (web scraping). Server URLs are configured per-project in `.claude/cwe-settings.yml` (`searxng_url`, `firecrawl_url`). Firecrawl is optional — trafilatura serves as always-available fallback. Used by agents that need to look up external documentation, compare technologies, or research best practices.

### delegator

**File:** `skills/delegator/SKILL.md`

Multi-agent request coordination. When a user request requires 2+ different agents (e.g., "build auth with tests and docs"), the delegator decomposes it into sub-tasks with dependency ordering and executes them via wave-based parallel dispatch. Common patterns: Feature Dev (architect → builder → quality + researcher), Bug Fix + Test (builder → quality), Full Pipeline (architect → builder → quality + security + researcher → devops).

### multi-terminal

**File:** `skills/multi-terminal/SKILL.md`

Multi-Terminal Parallel Development reference. Handoff protocol, entry format, routing, and coordination patterns for parallel terminal workflows (2T/3T/4T presets). See [Section 13](#13-multi-terminal-parallel-development).

### bookstack

**File:** `skills/bookstack/SKILL.md`

BookStack REST API wrapper for documentation uploads: pages, chapters, books. Used by `/cwe:docs`. Configure `bookstack_url` + API token in `.claude/cwe-settings.yml`.

### image

**File:** `skills/image/SKILL.md`

Text/image-to-image generation via OpenRouter (Gemini). Invokes `scripts/gemini_image.py`. Requires `OPENROUTER_API_KEY` in `scripts/media-keys.sh`.

### video

**File:** `skills/video/SKILL.md`

Text/image-to-video generation via MagicHour. Invokes `scripts/magichour_video.py`. Requires `MAGICHOUR_API_KEY`.

### faceswap

**File:** `skills/faceswap/SKILL.md`

Face swap (photo + video) via MagicHour. Invokes `scripts/magichour_faceswap.py`. Requires `MAGICHOUR_API_KEY`.

### headswap

**File:** `skills/headswap/SKILL.md`

Full head swap via MagicHour. Invokes `scripts/magichour_headswap.py`. Requires `MAGICHOUR_API_KEY`.

### upscale

**File:** `skills/upscale/SKILL.md`

Image upscaling (2x/4x) via MagicHour. Invokes `scripts/magichour_upscale.py`. Requires `MAGICHOUR_API_KEY`.

### motion

**File:** `skills/motion/SKILL.md`

Programmatic motion graphics via a Remotion (React) project. Renders animated scenes, title cards, and data visualizations declaratively.

---

## 12. Quality Gates

### Pre-Implementation Gate

**Trigger:** Before code is written.
**Agent:** Architect
**Checks:**
- Is the spec complete? (plan.md + shape.md)
- Are affected components identified?
- Is there a Definition of Done?
- Are standards referenced?

### Post-Implementation Gate

**Trigger:** After code completion.
**Agent:** Quality
**Checks:**

| Metric | Minimum | Blocks |
|--------|---------|--------|
| Line Coverage | 70% | <60% |
| Branch Coverage | 65% | <55% |
| Cyclomatic Complexity | <15 | >20 |
| Test Duration | <5min | >10min |
| Flaky Tests | 0 | >0 |

### Pre-Release Gate

**Trigger:** Before `git push` or release.
**Agent:** Security + Safety Gate Hook
**Checks:**
- No secrets in code
- No known CVEs in dependencies
- .gitignore is complete
- OWASP Top 10 compliance

### Health Score

The `/cwe:quality health` command calculates an overall score:

| Category | Weight | Scoring |
|-----------|-----------|---------|
| Code Quality | 25% | Coverage >80% = full, -2 per % below |
| Dependencies | 20% | 0 vulnerable = full, -10 per vulnerability |
| Documentation | 20% | All current = full, -5 per stale doc |
| Git Health | 20% | CC >95% + clean tree = full |
| Security | 15% | Clean scan + complete .gitignore = full |

| Score | Rating |
|-------|--------|
| 90-100 | Excellent |
| 75-89 | Good |
| 60-74 | Needs Attention |
| <60 | Critical |

---

## 13. Multi-Terminal Parallel Development

Multi-terminal (MT) parallel development (added in the v0.7 series) lets you run 2–4 Claude Code terminals concurrently in git worktrees, each on its own branch, coordinated via structured handoffs.

### Why Multi-Terminal

A single terminal processes one request at a time. With MT, a team lead in terminal 0 can dispatch frontend work to terminal 1, backend work to terminal 2, and QA to terminal 3 — all running in parallel, each with isolated context and branch.

### Presets

| Preset | Terminals | Typical roles |
|--------|-----------|---------------|
| **2T** | Dev + QA | Solo developer, paired quality |
| **3T** | Frontend + Backend + QA | Small feature team |
| **4T** | Frontend + Backend + QA + Infra | Full-stack + CI/CD work |
| **Custom** | User-defined | Any mix of roles |

Each terminal runs in its own worktree on a branch prefixed `t<N>-<role>/...` (e.g. `t1-frontend/feature-login`). MT hooks detect the prefix and silently skip when not in a worktree.

### The 5 MT Commands

| Command | Purpose |
|---------|---------|
| `/cwe:autopilot` | Autonomous task loop: sync → find TODOs → execute → commit → push |
| `/cwe:coordinate` | Team-lead coordination: fetch other terminals, review their commits, dispatch handoffs |
| `/cwe:handoff` | Write a structured handoff entry to another terminal, commit, and push |
| `/cwe:check-handoff` | Read and summarize pending handoff entries for this terminal |
| `/cwe:qa-merge` | QA-verified merge of terminal branches back to main (team lead / QA role) |

### Handoff Protocol

Handoffs are structured markdown entries written into a shared location and synced via `handoff-sync.py` (UserPromptSubmit hook). When two terminals write conflicting handoff state, the one with more entries wins (entry-count merge strategy).

See `skills/multi-terminal/SKILL.md` for the full entry format and routing rules.

---

## 14. Media Tools

CWE v0.8.0 added media generation skills that call external image/video APIs via Python scripts in `scripts/`. API keys live in `scripts/media-keys.sh` (gitignored). These are skills (not slash commands) — invoke them by intent.

### image

One-sentence purpose: text-to-image and image-to-image generation via OpenRouter's Gemini endpoint.
Example: "generate an image of a red fox in a snowy forest"
Requires: `OPENROUTER_API_KEY` in `scripts/media-keys.sh`.

### video

One-sentence purpose: text-to-video and image-to-video generation via MagicHour.
Example: "turn this photo into a 5-second cinematic pan"
Requires: `MAGICHOUR_API_KEY` in `scripts/media-keys.sh`.

### faceswap

One-sentence purpose: swap a face onto a target photo or video via MagicHour.
Example: "swap the face from source.jpg onto target.mp4"
Requires: `MAGICHOUR_API_KEY` in `scripts/media-keys.sh`.

### headswap

One-sentence purpose: swap a full head (not just face) onto a target image via MagicHour.
Example: "put the head from portrait.jpg onto the figure in scene.jpg"
Requires: `MAGICHOUR_API_KEY` in `scripts/media-keys.sh`.

### upscale

One-sentence purpose: 2x or 4x image upscaling via MagicHour.
Example: "upscale logo.png to 4x"
Requires: `MAGICHOUR_API_KEY` in `scripts/media-keys.sh`.

### motion

One-sentence purpose: programmatic motion graphics via a Remotion (React) project.
Example: "render a 10-second title card with fade-in text"
Requires: Node.js + Remotion project set up under `scripts/motion/` (see project README).

---

## 15. External Services

CWE integrates with several configurable external services. All endpoints are set per-project in `.claude/cwe-settings.yml` (gitignored) — no URLs are hardcoded.

| Service | Purpose | Settings key | Used by |
|---------|---------|--------------|---------|
| **SearXNG** | Meta-search engine (self-hosted) | `searxng_url` | `/cwe:web-research`, `web-research` skill |
| **Firecrawl** | Web scraping with JS rendering | `firecrawl_url` | `/cwe:web-research`, `url-scraper.py` hook |
| **Stirling PDF** | PDF-to-image rendering | `stirling_pdf_url` | `/cwe:pdf` |
| **Whisper server** | Video/audio transcription (faster-whisper, self-hosted) | `tscribe_url` | `/cwe:transcript` (non-YouTube URLs) |
| **OpenRouter** | LLM gateway incl. Gemini (used for image generation) | API key in `scripts/media-keys.sh` | `image` skill |
| **MagicHour** | Image/video generation APIs | API key in `scripts/media-keys.sh` | `video`, `faceswap`, `headswap`, `upscale` skills |
| **Gitea** | Private git mirror | `gitea_url`, SSH key | `/cwe:gitea` |
| **BookStack** | Self-hosted docs/wiki | `bookstack_url`, API token | `/cwe:docs`, `bookstack` skill |
| **Ollama / Qdrant** (preview, v0.9) | Local LLM + vector store | TBD in v0.9 | TBD |

### Fallback behavior

- **Firecrawl** is optional — `trafilatura` runs as always-available local fallback in `url-scraper.py`.
- **Whisper server** is optional for YouTube — `tubetranscript` serves YouTube transcripts directly without Whisper server.
- All other services are used only when the corresponding command is invoked.

### Configuration file

`.claude/cwe-settings.yml` (project-local, in `.gitignore`):

```yaml
searxng_url: http://localhost:4000
firecrawl_url: http://localhost:3002
stirling_pdf_url: http://localhost:8080
tscribe_url: http://localhost:5000
gitea_url: https://gitea.example.org
bookstack_url: https://docs.example.org
```

---

## 16. Project Structure Reference

### All 25 Slash Commands

Grouped by category. Descriptions pulled from each command's frontmatter.

**Workflow & Meta**

| Command | Description |
|---------|-------------|
| `/cwe:init` | Initialize CWE in current project — creates workflow structure and checks plugin dependencies |
| `/cwe:start` | Guided workflow — detects current phase and shows next steps |
| `/cwe:help` | Show CWE documentation and available commands |
| `/cwe:plugins` | Check and install CWE plugin dependencies, MCP servers, and verify CWE skills |

**Agents** (all marked "MUSS VERWENDET WERDEN" for forced delegation)

| Command | Description |
|---------|-------------|
| `/cwe:architect` | Systemdesign, Architekturentscheidungen, ADRs, technische Planung (READ-ONLY außer Markdown) |
| `/cwe:ask` | Fragen, Diskussionen, Ideen-Austausch — STRIKT READ-ONLY |
| `/cwe:builder` | Code-Implementierung, Bug-Fixes, Refactoring, Feature-Entwicklung (voller Dateisystem-Zugriff) |
| `/cwe:devops` | CI/CD, Docker/Kubernetes, IaC, Deployment-Automatisierung |
| `/cwe:explainer` | Code-Erklärungen, Architektur-Walkthroughs, Konzept-Vermittlung — STRIKT READ-ONLY |
| `/cwe:guide` | Workflow-Optimierung, Process-Improvement, Pattern-Erkennung, Standards-Evolution |
| `/cwe:innovator` | Brainstorming, Ideen-Entwicklung, Idea-Backlog-Review |
| `/cwe:quality` | Testing, Coverage-Analyse, Quality Gates, Code-Metriken |
| `/cwe:researcher` | Codebase-Analyse, Dokumentation, Dependency-Mapping, Wissenssynthese |
| `/cwe:security` | Security-Audits, Vulnerability-Assessments, Secrets-Erkennung, OWASP-Checks (READ-ONLY Audit-Modus) |

**Content Tools**

| Command | Description |
|---------|-------------|
| `/cwe:transcript` | Video/audio transcripts for URLs (YouTube, Instagram, TikTok, podcasts) via self-hosted Whisper server (faster-whisper) or tubetranscript fallback |
| `/cwe:pdf` | Read/analyze PDFs — converts pages to images via Stirling PDF API and reads them visually |

**Utilities**

| Command | Description |
|---------|-------------|
| `/cwe:screenshot` | Analyze a screenshot or read image from clipboard — WSL2 tested in v0.8.2; macOS/Linux Wayland/X11 paths untested, please report issues |
| `/cwe:web-research` | Local SearXNG search + Firecrawl/trafilatura scraping |
| `/cwe:gitea` | Privater Git-Mirror auf Gitea — push, list, create, delete, clone, status |
| `/cwe:docs` | BookStack Upload — Pages, Kapitel und Bücher per REST API |

**Multi-Terminal**

| Command | Description |
|---------|-------------|
| `/cwe:autopilot` | Autonomous multi-terminal task loop — sync, find TODOs, execute, commit, push |
| `/cwe:coordinate` | Team-lead coordination — fetch, review commits, dispatch handoffs across terminals |
| `/cwe:handoff` | Write a structured handoff entry to another terminal, commit and push |
| `/cwe:check-handoff` | Read and summarize pending handoff entries for this terminal |
| `/cwe:qa-merge` | QA-verified merge of terminal branches to main (team lead / QA only) |

### CWE Plugin Structure

```
code-workspace-engine/
├── agents/                     # 10 specialized agents
│   ├── ask.md                  # Discussion Partner (READ-ONLY)
│   ├── architect.md            # Systems Thinker (READ-ONLY + specs/)
│   ├── builder.md              # Code Coroner (full access)
│   ├── devops.md               # Infrastructure Expert (full access)
│   ├── explainer.md            # Educator (READ-ONLY)
│   ├── guide.md                # Process Whisperer (READ-ONLY + rules/)
│   ├── innovator.md            # Idea Forge (READ-ONLY + ideas.md)
│   ├── quality.md              # Quality Guardian (READ-ONLY + tests)
│   ├── researcher.md           # Analyst (READ-ONLY + docs/)
│   └── security.md             # Security Auditor (RESTRICTED)
│
├── commands/                   # 25 Slash Commands (see table below)
│   │  # Workflow & Meta
│   ├── init.md                 # /cwe:init — Initialize CWE in current project
│   ├── start.md                # /cwe:start — Guided workflow (phase detection)
│   ├── help.md                 # /cwe:help — Show CWE documentation
│   ├── plugins.md              # /cwe:plugins — Check/install plugin dependencies
│   │  # Agents
│   ├── architect.md            # /cwe:architect
│   ├── ask.md                  # /cwe:ask
│   ├── builder.md              # /cwe:builder
│   ├── devops.md               # /cwe:devops
│   ├── explainer.md            # /cwe:explainer
│   ├── guide.md                # /cwe:guide
│   ├── innovator.md            # /cwe:innovator
│   ├── quality.md              # /cwe:quality
│   ├── researcher.md           # /cwe:researcher
│   ├── security.md             # /cwe:security
│   │  # Content Tools
│   ├── transcript.md           # /cwe:transcript — Whisper server + tubetranscript
│   ├── pdf.md                  # /cwe:pdf — Stirling PDF rendering
│   │  # Utilities
│   ├── screenshot.md           # /cwe:screenshot — Multi-OS clipboard capture
│   ├── web-research.md         # /cwe:web-research — SearXNG + Firecrawl
│   ├── gitea.md                # /cwe:gitea — Private git mirror
│   ├── docs.md                 # /cwe:docs — BookStack upload
│   │  # Multi-Terminal
│   ├── autopilot.md            # /cwe:autopilot — Autonomous task loop
│   ├── coordinate.md           # /cwe:coordinate — Team-lead coordination
│   ├── handoff.md              # /cwe:handoff — Write handoff entry
│   ├── check-handoff.md        # /cwe:check-handoff — Summarize pending handoffs
│   └── qa-merge.md             # /cwe:qa-merge — QA-verified merge
│
├── skills/                     # 17 Skills
│   ├── agent-detection/SKILL.md
│   ├── auto-delegation/SKILL.md
│   ├── bookstack/SKILL.md
│   ├── delegator/SKILL.md
│   ├── faceswap/SKILL.md
│   ├── git-standards/SKILL.md
│   ├── headswap/SKILL.md
│   ├── health-dashboard/SKILL.md
│   ├── image/SKILL.md
│   ├── motion/SKILL.md
│   ├── multi-terminal/SKILL.md
│   ├── project-docs/SKILL.md
│   ├── quality-gates/SKILL.md
│   ├── safety-gate/SKILL.md
│   ├── upscale/SKILL.md
│   ├── video/SKILL.md
│   └── web-research/SKILL.md
│
├── hooks/                      # Automation
│   ├── hooks.json              # Hook configuration
│   └── scripts/
│       ├── _lib.sh             # Shared helper functions
│       ├── session-start.sh    # Context Injection
│       ├── session-stop.sh     # Daily Log + Cleanup
│       ├── idea-observer.sh    # Idea Capture
│       ├── idea-flush.sh       # Idea Export
│       ├── intent-router.py    # Keyword-based Agent Routing
│       ├── url-scraper.py      # Auto URL Scraping
│       ├── transcript.sh       # Transcript Extraction (YouTube + optional Whisper server)
│       ├── subagent-stop.sh    # Agent Logging
│       ├── safety-gate.sh      # Pre-Commit Scanning
│       ├── commit-format.sh    # Conventional Commits
│       └── branch-naming.sh    # Branch Validation
│
├── .claude/rules/              # 8 Standards + Index
│   ├── _index.yml              # Standard Index
│   ├── global-standards.md
│   ├── api-standards.md
│   ├── frontend-standards.md
│   ├── database-standards.md
│   ├── devops-standards.md
│   ├── testing-standards.md
│   ├── agent-standards.md
│   └── documentation-standards.md
│
├── templates/                  # Templates
│   ├── memory/                 # 6 Memory templates
│   ├── specs/                  # 4 Spec templates (plan, shape, references, standards)
│   └── docs/                   # 7 Doc templates (README, ARCHITECTURE, API, etc.)
│
├── docs/                       # Plugin documentation
│   ├── USER-GUIDE.md           # This file
│   ├── assets/
│   │   ├── cwe-logo.svg
│   │   └── cwe-header.svg
│   └── plans/                  # Design documents
│
├── .gitattributes                # Git LFS / line ending config
├── CLAUDE.md                   # Plugin configuration
├── README.md                   # GitHub README
├── CHANGELOG.md                # Version History
└── ROADMAP.md                  # Planned Features
```

### What CWE Creates at /cwe:init

In the target project:

```
your-project/
├── .claude/
│   └── cwe-settings.yml          # CWE preferences (service URLs, etc.)
├── workflow/
│   ├── config.yml              # CWE configuration
│   ├── ideas.md                # Curated idea backlog
│   ├── product/
│   │   ├── README.md           # Explanation
│   │   └── mission.md          # Product vision (YOU write this!)
│   ├── specs/
│   │   ├── README.md           # Explanation of spec structure
│   │   └── YYYY-MM-DD-HHMM-<slug>/  # Per feature
│   └── standards/
│       └── README.md           # Explanation
├── memory/
│   ├── MEMORY.md               # Index (auto-seeded)
│   ├── YYYY-MM-DD.md           # Daily Logs (auto-created)
│   ├── ideas.md                # Idea overview
│   ├── decisions.md            # ADRs
│   ├── patterns.md             # Recognized patterns
│   └── project-context.md      # Tech stack (auto-seeded!)
├── docs/
│   ├── README.md               # Project README (from template)
│   ├── ARCHITECTURE.md         # Architecture
│   ├── API.md                  # API docs
│   ├── SETUP.md                # Setup guide
│   ├── DEVLOG.md               # Developer Journal
│   └── decisions/
│       └── _template.md        # ADR template
└── VERSION                     # e.g. "0.1.0"
```

---

## 17. FAQ / Troubleshooting

### "CWE routes to the wrong agent"

**Cause:** The keywords in your message match a different agent than expected.

**Fix:**
1. Use the explicit command: `/cwe:builder "your task"` instead of Auto-Delegation
2. Say "manual" to disable Auto-Delegation
3. Check the keyword table in [Section 4](#4-understanding-auto-delegation)

### "Memory is not being injected"

**Cause:** Possible reasons:
- `memory/` directory does not exist → run `/cwe:init`
- `MEMORY.md` is empty → add content
- Session-start hook failed → check `hooks.json`

**Fix:**
1. Check whether `memory/MEMORY.md` exists and has content
2. Check whether `hooks/hooks.json` is correctly configured
3. Manual test: `bash hooks/scripts/session-start.sh < /dev/null`

### "MCP Server won't start"

**Cause:** MCP server configuration problem.

**Fix:**
1. Check server config: `claude mcp list`
2. Check whether the server command exists: `which npx`
3. Re-add the server: `claude mcp add <name> -- <command>`
4. Restart Claude Code

### "How do I reset everything?"

**Warning:** This deletes CWE configuration in the project.

```bash
# Remove only CWE structure (keeps your code):
rm -rf workflow/ memory/ docs/
rm -f VERSION CHANGELOG.md

# Then reinitialize:
/cwe:init
```

### "Safety Gate blocks my commit"

**Cause:** The pre-commit scanner found a potential secret.

**Fix:**
1. Check the report — which file, which line?
2. Remove the secret and use environment variables instead
3. If false positive: `git commit --no-verify` (this is logged!)
4. Rotate the secret if it was already committed

### "Conventional Commit is rejected"

**Format:** `type(scope): subject`

**Allowed types:** feat, fix, chore, docs, style, refactor, test, perf, ci, build, revert

**Common mistakes:**
- Capital letter at the start: ~~`Fix: bug`~~ → `fix: bug`
- Period at the end: ~~`feat: add login.`~~ → `feat: add login`
- Missing type: ~~`fixed the bug`~~ → `fix: resolve login crash`

---

## 18. Lifecycle Diagram: How Everything Connects

```
┌───────────────────────────────────────────────────────────────────┐
│                        CWE LIFECYCLE                              │
│                                                                   │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────────┐        │
│  │  SESSION  │    │    WORK      │    │    PERSIST       │        │
│  │  START    │    │              │    │                  │        │
│  │          │    │              │    │                  │        │
│  │ Memory   │───→│ User Request │───→│ Daily Log        │        │
│  │ Injection│    │      │       │    │ MEMORY.md        │        │
│  │          │    │      ▼       │    │ CHANGELOG        │        │
│  │ MEMORY.md│    │ Auto-Dele-   │    │                  │        │
│  │ + Daily  │    │ gation       │    └────────┬─────────┘        │
│  │ Logs     │    │      │       │             │                  │
│  └──────────┘    │      ▼       │             │                  │
│       ▲          │ Agent with   │             │                  │
│       │          │ Standards    │             │                  │
│       │          │      │       │             │                  │
│       │          │      ▼       │             │                  │
│       │          │ Build +      │             │                  │
│       │          │ Quality Gate │             │                  │
│       │          │      │       │             │                  │
│       │          │      ▼       │             │                  │
│       │          │ Safety Gate  │             │                  │
│       │          │ (pre-commit) │             │                  │
│       │          └──────────────┘             │                  │
│       │                                       │                  │
│       │          ┌──────────────┐             │                  │
│       │          │  SESSION     │             │                  │
│       │          │  STOP        │◄────────────┘                  │
│       │          │              │                                │
│       │          │ Daily Log    │                                │
│       │          │ Cleanup      │                                │
│       │          └──────┬───────┘                                │
│       │                 │                                        │
│       └─────────────────┘                                        │
│              Next Session                                        │
│                                                                   │
│  ┌───────────────────────────────────────────────────────┐       │
│  │  BACKGROUND (always running)                          │       │
│  │                                                       │       │
│  │  Idea Observer ──→ JSONL ──→ /cwe:innovator          │       │
│  │  Safety Gate ──→ Blocks dangerous commits             │       │
│  │  Commit Format ──→ Validates Conventional Commits     │       │
│  │  Branch Naming ──→ Validates branch patterns          │       │
│  │  Agent Logger ──→ Tracks which agents ran             │       │
│  └───────────────────────────────────────────────────────┘       │
└───────────────────────────────────────────────────────────────────┘
```

**The Lifecycle:**

1. **Session Start** → Memory injected (MEMORY.md + Daily Logs)
2. **User Request** → Auto-Delegation routes to the appropriate agent
3. **Agent works** → Standards auto-loaded, skills available
4. **Code written** → Safety Gate scans, Commit Format validated
5. **Memory updated** → Daily Log, MEMORY.md, CHANGELOG
6. **Session Stop** → Everything persisted
7. **Next Session** → Everything is back (→ Step 1)

Running permanently in the background:
- **Idea Observer** captures every idea automatically
- **Safety Gate** checks every commit
- **Agent Logger** tracks which agents ran

This is CWE: A self-documenting, security-aware, spec-driven workflow system that gets smarter with every session.
