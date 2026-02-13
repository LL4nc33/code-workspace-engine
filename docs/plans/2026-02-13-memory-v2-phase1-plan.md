# Memory System v2 — Phase 1 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade CWE's memory system so every session starts with real project context (MEMORY.md + Daily Logs) instead of a single line from sessions.md.

**Architecture:** OpenClaw-inspired Daily Logs (`memory/YYYY-MM-DD.md`) replace the minimalist `sessions.md`. `session-start.sh` reads and injects MEMORY.md + today + yesterday into `systemMessage`. `session-stop.sh` writes session-end entries to the daily log. Stop/PreCompact hooks reference daily logs. `/cwe:init` auto-seeds tech stack.

**Tech Stack:** Bash (hooks), Markdown (templates), YAML (commands)

**Design doc:** `docs/plans/2026-02-13-memory-system-v2-design.md`

---

### Task 1: Rewrite session-start.sh with Full Context Injection

**Files:**
- Modify: `hooks/scripts/session-start.sh` (complete rewrite)

**Step 1: Replace session-start.sh with new version**

The new script reads MEMORY.md + today's daily log + yesterday's daily log and injects them all as `systemMessage`. Character limit prevents context explosion on large memory files.

```bash
#!/usr/bin/env bash
# SessionStart Hook: Full context injection from project memory
# Reads: MEMORY.md + today's daily log + yesterday's daily log

# Consume stdin to prevent hook errors
cat > /dev/null 2>&1 &

VERSION="Claude Workflow Engine v0.4.2"

# Determine project root
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  ROOT="$CLAUDE_PROJECT_DIR"
else
  ROOT="$PWD"
fi

# Build status message
if [ -d "${ROOT}/workflow" ]; then
  STATUS="Ready"
  HINT="Run /cwe:start to continue or just describe what you need."
else
  STATUS="No project initialized"
  HINT="Run /cwe:init to start."
fi

# Check for idea count
PROJECT_SLUG=$(basename "$ROOT" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
IDEAS_FILE="$HOME/.claude/cwe/ideas/${PROJECT_SLUG}.jsonl"
IDEA_COUNT=0
if [ -f "$IDEAS_FILE" ]; then
  IDEA_COUNT=$(wc -l < "$IDEAS_FILE" | tr -d ' ')
fi

IDEA_INFO=""
if [ "$IDEA_COUNT" -gt 0 ]; then
  IDEA_INFO=" | ${IDEA_COUNT} idea(s) captured"
fi

# --- Memory Context Injection ---
MEMORY_CONTEXT=""
MAX_CHARS=8000  # Cap total injected memory to ~2000 tokens

# 1. Read MEMORY.md (curated index, max 200 lines)
MEMORY_FILE="${ROOT}/memory/MEMORY.md"
if [ -f "$MEMORY_FILE" ]; then
  MEMORY_CONTENT=$(head -200 "$MEMORY_FILE" 2>/dev/null)
  if [ -n "$MEMORY_CONTENT" ]; then
    MEMORY_CONTEXT="${MEMORY_CONTEXT}--- MEMORY.md ---\n${MEMORY_CONTENT}\n\n"
  fi
fi

# 2. Read today's daily log
TODAY=$(date +%Y-%m-%d)
TODAY_FILE="${ROOT}/memory/${TODAY}.md"
if [ -f "$TODAY_FILE" ]; then
  TODAY_CONTENT=$(cat "$TODAY_FILE" 2>/dev/null)
  if [ -n "$TODAY_CONTENT" ]; then
    MEMORY_CONTEXT="${MEMORY_CONTEXT}--- Daily Log: ${TODAY} ---\n${TODAY_CONTENT}\n\n"
  fi
fi

# 3. Read yesterday's daily log
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d 2>/dev/null)
if [ -n "$YESTERDAY" ]; then
  YESTERDAY_FILE="${ROOT}/memory/${YESTERDAY}.md"
  if [ -f "$YESTERDAY_FILE" ]; then
    YESTERDAY_CONTENT=$(cat "$YESTERDAY_FILE" 2>/dev/null)
    if [ -n "$YESTERDAY_CONTENT" ]; then
      MEMORY_CONTEXT="${MEMORY_CONTEXT}--- Daily Log: ${YESTERDAY} ---\n${YESTERDAY_CONTENT}\n\n"
    fi
  fi
fi

# Truncate if over character limit
if [ ${#MEMORY_CONTEXT} -gt $MAX_CHARS ]; then
  MEMORY_CONTEXT="${MEMORY_CONTEXT:0:$MAX_CHARS}...(truncated)"
fi

# Escape for JSON
MEMORY_JSON=""
if [ -n "$MEMORY_CONTEXT" ]; then
  # Escape backslashes, quotes, newlines for JSON
  ESCAPED=$(printf '%s' "$MEMORY_CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' '\a' | sed 's/\a/\\n/g')
  MEMORY_JSON=" | PROJECT MEMORY:\\n${ESCAPED}"
fi

# Auto-delegation reminder (compact)
DELEGATION="Auto-delegation: fix/build->builder | explain->explainer | audit->security | deploy->devops | design->architect | brainstorm->innovator"

echo "{\"systemMessage\": \"${VERSION} | ${STATUS}. ${HINT}${IDEA_INFO} | ${DELEGATION}${MEMORY_JSON}\"}"
```

**Step 2: Verify the script is valid bash**

Run: `bash -n hooks/scripts/session-start.sh`
Expected: No output (valid syntax)

**Step 3: Commit**

```bash
git add hooks/scripts/session-start.sh
git commit -m "feat(memory): upgrade session-start to inject MEMORY.md + daily logs"
git push
```

---

### Task 2: Rewrite session-stop.sh for Daily Logs

**Files:**
- Modify: `hooks/scripts/session-stop.sh` (complete rewrite)

**Step 1: Replace session-stop.sh with daily log version**

The new script creates/appends to `memory/YYYY-MM-DD.md` instead of `sessions.md`.

```bash
#!/usr/bin/env bash
# Session Stop Hook: Write session end to daily log
# Creates memory/YYYY-MM-DD.md if needed, appends session-end entry

# Consume stdin to prevent hook errors
cat > /dev/null 2>&1 &

# Determine project root
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  ROOT="$CLAUDE_PROJECT_DIR"
else
  ROOT="$PWD"
fi

# Only log if memory directory exists (project is initialized)
if [ -d "${ROOT}/memory" ] || [ -d "${ROOT}/workflow" ]; then
  mkdir -p "${ROOT}/memory"

  DATE=$(date +%Y-%m-%d)
  TIME=$(date +%H:%M)
  DAILY_LOG="${ROOT}/memory/${DATE}.md"

  # Create daily log with header if it doesn't exist
  if [ ! -f "$DAILY_LOG" ]; then
    printf "# %s\n\n" "$DATE" > "$DAILY_LOG"
  fi

  # Append session-end entry
  printf "\n## %s — Session End\n- (summary pending — will be filled by Stop hook prompt)\n" "$TIME" >> "$DAILY_LOG"

  # Clean up old daily logs (keep last 30 days)
  find "${ROOT}/memory" -maxdepth 1 -name "????-??-??.md" -type f -mtime +30 -delete 2>/dev/null
fi

echo '{"systemMessage": "Session complete. Daily log updated. Run /cwe:start next time to continue."}'
```

**Step 2: Verify the script is valid bash**

Run: `bash -n hooks/scripts/session-stop.sh`
Expected: No output (valid syntax)

**Step 3: Commit**

```bash
git add hooks/scripts/session-stop.sh
git commit -m "feat(memory): rewrite session-stop for daily logs"
git push
```

---

### Task 3: Update Stop-Hook Prompt for Daily Logs

**Files:**
- Modify: `hooks/hooks.json:29-30` (Stop hook prompt)

**Step 1: Replace the Stop hook prompt**

Change references from `sessions.md` to daily log. The new prompt:

```
BEFORE ending this session, you MUST complete this documentation checklist:

1. **memory/MEMORY.md** — Update the project index: what changed this session, current state, key decisions. Keep under 200 lines.
2. **Today's Daily Log (memory/YYYY-MM-DD.md)** — Add session summary entries with: goal, what was done, key decisions, what's next. Use ## HH:MM — Topic format.
3. **memory/decisions.md** — If any design decisions were made, log them (context, decision, rationale).
4. **memory/project-context.md** — If tech stack, priorities, or architecture changed, update it.
5. **CHANGELOG.md** — If user-visible changes were made, add entries under current version.
6. **docs/** — If features, APIs, setup, or architecture changed, update the affected docs.

Skip files that genuinely don't need updates. But memory/MEMORY.md and the Daily Log MUST always be updated.

Daily Log format:
## HH:MM — Topic
- What: [1 sentence]
- Decision: [if applicable]
- Files: [key files changed]

After updating, commit and push all documentation changes with: git commit -m 'docs: update memory and project documentation'
```

**Step 2: Commit**

```bash
git add hooks/hooks.json
git commit -m "feat(memory): update Stop hook prompt for daily logs"
git push
```

---

### Task 4: Update PreCompact-Hook Prompt for Daily Logs

**Files:**
- Modify: `hooks/hooks.json:61` (PreCompact hook prompt)

**Step 1: Replace the PreCompact hook prompt**

Change references from `sessions.md` to daily log:

```
Context is about to be compacted. BEFORE compaction, you MUST save critical state:

1. **memory/MEMORY.md** — Write current project state, what you were working on, pending tasks, key decisions made this session.
2. **Today's Daily Log (memory/YYYY-MM-DD.md)** — Add session progress so far: goal, what's done, what's unfinished. Use ## HH:MM — Topic format.
3. **memory/decisions.md** — Log any undocumented decisions.

This information will be LOST after compaction if not saved now. Be thorough — future you depends on this.

Commit and push after saving: git commit -m 'docs: pre-compact memory save'
```

**Step 2: Commit**

```bash
git add hooks/hooks.json
git commit -m "feat(memory): update PreCompact hook prompt for daily logs"
git push
```

Note: Tasks 3 and 4 both modify hooks.json. If implementing sequentially, combine into one commit.

---

### Task 5: Update documentation-standards.md Rule

**Files:**
- Modify: `.claude/rules/documentation-standards.md:13-16`

**Step 1: Replace sessions.md reference with daily log**

In the "Memory Updates (REQUIRED)" section, change:

Old line (around line 13):
```
- **memory/MEMORY.md** — Keep the index current (max 200 lines). Update: what changed, current state, key decisions.
```

Add after MEMORY.md line:
```
- **Today's Daily Log (memory/YYYY-MM-DD.md)** — Append entries for this session. Use `## HH:MM — Topic` format. Include: what was done, decisions, files changed.
```

**Step 2: Commit**

```bash
git add .claude/rules/documentation-standards.md
git commit -m "feat(memory): add daily log to documentation standards rule"
git push
```

---

### Task 6: Create Daily Log Template

**Files:**
- Create: `templates/memory/daily-log.md`

**Step 1: Create the template file**

```markdown
# {{DATE}}

<!-- Daily log for this project. Append-only, newest entry last. -->
<!-- Format: ## HH:MM — Topic -->
<!-- This file is auto-created by session-stop.sh -->
<!-- Content is filled by Claude via Stop hook + documentation standards -->
```

This template is documentation-only. The actual daily log files are created by `session-stop.sh` with just a `# YYYY-MM-DD` header. The template serves as reference for the format.

**Step 2: Commit**

```bash
git add templates/memory/daily-log.md
git commit -m "feat(memory): add daily log template"
git push
```

---

### Task 7: Deprecate sessions.md Template

**Files:**
- Modify: `templates/memory/sessions.md`

**Step 1: Mark sessions.md as deprecated**

```markdown
# Session Log (DEPRECATED)

> **Note:** This file is deprecated since CWE v0.4.2. Session logs now use Daily Logs (`memory/YYYY-MM-DD.md`).
> This file is kept for backward compatibility with existing projects.
> New projects should use Daily Logs exclusively.

Recent sessions for this project. Newest first. Max 50 entries.

---

<!-- Sessions will be prepended here by session-stop.sh -->
```

**Step 2: Commit**

```bash
git add templates/memory/sessions.md
git commit -m "docs(memory): deprecate sessions.md in favor of daily logs"
git push
```

---

### Task 8: Add Auto-Seeding to /cwe:init

**Files:**
- Modify: `commands/init.md` (add Step 2b after Step 2)

**Step 1: Add tech-stack detection step to init.md**

Insert a new step between the existing Step 2 (check existing workflow setup) and Step 3 (create structure). This step detects the tech stack and pre-populates memory files.

Add after the `## Step 3: Create structure` section (after copying templates, before "## File contents"):

```markdown
## Step 3b: Auto-Seed Project Memory

After creating the memory structure, detect the project's tech stack and populate memory files.

### Tech-Stack Detection

Check for these files in the project root:

| File | Stack | Language |
|------|-------|----------|
| `package.json` | Node.js | Read `dependencies`/`devDependencies` for framework (React, Vue, Express, etc.) |
| `tsconfig.json` | TypeScript | (additional to package.json) |
| `Cargo.toml` | Rust | Read `[dependencies]` for crates |
| `go.mod` | Go | Read module name |
| `pyproject.toml` | Python | Read `[project.dependencies]` or `[tool.poetry.dependencies]` |
| `requirements.txt` | Python | List major packages |
| `composer.json` | PHP | Read `require` for framework (Laravel, Symfony, etc.) |
| `Gemfile` | Ruby | Read gems for framework (Rails, Sinatra, etc.) |
| `pom.xml` | Java | Read dependencies |
| `build.gradle` / `build.gradle.kts` | Java/Kotlin | Read dependencies |
| `Dockerfile` | Docker | Note presence |
| `.github/workflows/` | GitHub Actions CI | Note presence |

### Populate memory/project-context.md

Replace the `(not configured)` placeholders with detected values:

```markdown
# Project Context

## Tech Stack
- Language: [detected]
- Framework: [detected]
- Build: [detected]
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

Create `memory/YYYY-MM-DD.md` with:

```markdown
# YYYY-MM-DD

## HH:MM — Project Initialized
- CWE initialized with /cwe:init
- Stack: [detected tech stack]
- Phase: init
```
```

**Step 2: Commit**

```bash
git add commands/init.md
git commit -m "feat(memory): add auto-seeding tech-stack detection to /cwe:init"
git push
```

---

### Task 9: Update MEMORY.md Template with Daily Log Reference

**Files:**
- Modify: `templates/memory/MEMORY.md`

**Step 1: Update template to reference daily logs instead of sessions**

```markdown
# CWE Memory: {{project-name}}

## Current Focus
(not yet set)

## Ideas: 0 captured, 0 exploring, 0 planned
Details: → memory/ideas.md | Raw: → ~/.claude/cwe/ideas/{{project-slug}}.jsonl

## Last Session
(see today's daily log: memory/YYYY-MM-DD.md)

## Key Decisions
(no decisions recorded yet — details → memory/decisions.md)

## Patterns
(no patterns recognized yet — details → memory/patterns.md)

## Project Context
Stack: (not configured) | Phase: init
Details: → memory/project-context.md

## Daily Logs
Session context is stored in daily logs: memory/YYYY-MM-DD.md (append-only, auto-loaded at session start)
```

**Step 2: Commit**

```bash
git add templates/memory/MEMORY.md
git commit -m "feat(memory): update MEMORY.md template with daily log references"
git push
```

---

### Task 10: Version Bump + CHANGELOG + Documentation

**Files:**
- Modify: `CHANGELOG.md` (add v0.4.2 section)
- Modify: `.claude-plugin/plugin.json:3` (version bump)
- Modify: `README.md` (version + memory system description)
- Modify: `hooks/scripts/session-start.sh:8` (version string)
- Modify: `ROADMAP.md` (add v0.4.2 entry)

**Step 1: Add v0.4.2 section to CHANGELOG.md**

Insert after the `---` on line 8, before the `## [0.4.1]` section:

```markdown
## [0.4.2] — 2026-02-13 (Memory System v2 — Phase 1)

### Added — Daily Logs
- Daily log files (`memory/YYYY-MM-DD.md`): append-only session context per day
- `session-start.sh`: injects MEMORY.md + today + yesterday daily logs as systemMessage
- Auto-seeding: `/cwe:init` detects tech stack and populates memory/project-context.md
- Daily log template: `templates/memory/daily-log.md`
- Old daily logs auto-cleaned after 30 days

### Changed — Memory System
- `session-stop.sh`: writes to daily logs instead of sessions.md
- Stop hook: references daily logs instead of sessions.md
- PreCompact hook: references daily logs instead of sessions.md
- `documentation-standards.md`: daily log in required updates checklist
- `MEMORY.md` template: references daily logs

### Deprecated
- `sessions.md`: replaced by daily logs (kept for backward compatibility)

---
```

**Step 2: Bump plugin.json version**

Change `"version": "0.4.1"` to `"version": "0.4.2"` in `.claude-plugin/plugin.json`.

**Step 3: Update README.md version references**

- Title: `v0.4.1` → `v0.4.2`
- Version History section: add v0.4.2 entry
- Memory System description: mention daily logs

**Step 4: Update session-start.sh version string**

Change `VERSION="Claude Workflow Engine v0.4.1"` to `VERSION="Claude Workflow Engine v0.4.2"`.

**Step 5: Commit**

```bash
git add CHANGELOG.md .claude-plugin/plugin.json README.md hooks/scripts/session-start.sh
git commit -m "chore: bump version to v0.4.2 + update changelog and docs"
git push
```

---

## Execution Order

Tasks 1-9 can be grouped logically:

1. **Task 1** — session-start.sh (core: context injection)
2. **Task 2** — session-stop.sh (core: daily log writing)
3. **Tasks 3+4** — hooks.json (both prompts, one file, one commit)
4. **Task 5** — documentation-standards.md
5. **Task 6** — daily log template
6. **Task 7** — deprecate sessions.md
7. **Task 8** — /cwe:init auto-seeding
8. **Task 9** — MEMORY.md template update
9. **Task 10** — version bump + changelog + docs

Tasks 1-2 are independent and can run in parallel.
Tasks 3-4 modify the same file and should be one commit.
Task 10 must be last.

## Testing

After implementation, verify by running CWE in a test project:

1. `cwe` → check systemMessage contains "PROJECT MEMORY" section
2. `/cwe:init` → check memory/project-context.md has detected stack
3. Session end → check memory/YYYY-MM-DD.md was created with entries
4. New session → check yesterday's daily log is injected
