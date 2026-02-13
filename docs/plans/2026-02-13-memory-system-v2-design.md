# CWE Memory System v2 — Design

**Date:** 2026-02-13
**Status:** Approved
**Scope:** Phase 1 (v0.4.2) + Phase 2 (v0.4.3)

## Problem

CWE's current memory system is structurally present but functionally blind:
- `session-start.sh` reads only 1 line from `sessions.md` — no real context at session start
- `session-stop.sh` writes only a timestamp placeholder — no content
- Stop-Hook forces memory updates but Claude doesn't see current MEMORY.md state
- `memory: project` in agent frontmatter is declarative only — no loading mechanism
- All memory templates are empty after `/cwe:init` — no auto-seeding

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Memory location | Project-local (`memory/`) | Versionable, project-specific |
| Log format | Daily Logs (`memory/YYYY-MM-DD.md`) | Natural time structure, no single file grows too large |
| Vector Search | Own CWE Memory MCP Server | Full control, deep integration |
| Context injection | MEMORY.md + Daily (today+yesterday) | Compact but sufficient (~500-2000 tokens) |
| Phasing | Phase 1 first, MCP in Phase 2 | Immediate value, risk distributed |

## Phase 1: Daily Logs + Context Injection (v0.4.2)

### New File Structure

```
memory/
├── MEMORY.md              # Curated index (max 200 lines) — STAYS
├── YYYY-MM-DD.md          # Daily log (append-only) — NEW
├── decisions.md           # ADRs — STAYS
├── patterns.md            # Work patterns — STAYS
├── project-context.md     # Tech stack — STAYS
├── ideas.md               # Idea backlog — STAYS
└── sessions.md            # → DEPRECATED (migrated to Daily Logs)
```

### Daily Log Format

```markdown
# 2026-02-13

## 14:30 — Session Start
- Goal: Memory System Upgrade planen
- Context: CWE v0.4.1, alle 10 Phasen abgeschlossen

## 14:45 — Design Decision
- Decision: Daily Logs statt sessions.md
- Rationale: Natural time structure, no file grows too large

## 16:00 — Session End
- Done: Design complete, plan written
- Next: Implement Phase 1
- Files changed: hooks/hooks.json, hooks/scripts/session-start.sh
```

### session-start.sh Upgrade

Reads and injects as `systemMessage`:
1. `memory/MEMORY.md` (full, max 200 lines)
2. `memory/YYYY-MM-DD.md` (today)
3. `memory/YYYY-MM-DD.md` (yesterday, if exists)

### session-stop.sh Changes

- Creates `memory/YYYY-MM-DD.md` if not exists
- Appends session-end timestamp to today's daily log

### Stop-Hook Changes

Updated prompt: "Update MEMORY.md + today's Daily Log" instead of sessions.md.

### PreCompact-Hook Changes

Updated prompt: references Daily Log instead of sessions.md.

### Auto-Seeding at `/cwe:init`

Tech-stack detection from:
- `package.json` → Node/TS/JS
- `Cargo.toml` → Rust
- `go.mod` → Go
- `pyproject.toml` / `requirements.txt` → Python
- `composer.json` → PHP
- `Gemfile` → Ruby
- `pom.xml` / `build.gradle` → Java/Kotlin

Results written to `memory/project-context.md` + initial `memory/MEMORY.md`.

### sessions.md Migration

- Keep `sessions.md` template but mark as deprecated
- New projects get Daily Logs only
- Existing projects: sessions.md content is still readable

## Phase 2: CWE Memory MCP Server (v0.4.3)

### Architecture

```
cwe-memory-mcp/
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts               # MCP Server entry point (stdio)
│   ├── tools/
│   │   ├── memory-search.ts   # Semantic search over memory/*.md
│   │   ├── memory-get.ts      # Read file/section
│   │   └── memory-write.ts    # Append to daily log
│   ├── indexer/
│   │   ├── chunker.ts         # Markdown → chunks (~400 tokens, 80 overlap)
│   │   ├── embeddings.ts      # Embedding provider (OpenAI/local)
│   │   └── sqlite-store.ts    # SQLite + vector storage
│   └── watcher.ts             # File watcher for auto-reindex
```

### MCP Tools

| Tool | Description |
|------|-------------|
| `memory_search` | Semantic search: query → relevant snippets from all memory files |
| `memory_get` | Read file/section: path → content |
| `memory_write` | Append to daily log: entry → today's log |
| `memory_status` | Index status: files, chunks, freshness |

### Embedding Strategy

- **Default:** OpenAI `text-embedding-3-small`
- **Fallback:** Local model via `node-llama-cpp`
- **Storage:** SQLite with `sqlite-vec` extension
- **Chunking:** ~400 tokens per chunk, 80 token overlap

### Hybrid Search

- Vector similarity (semantic) + BM25 (keywords)
- Weighted score: 70% vector + 30% BM25
- FTS5 for full-text search in SQLite

### Integration

- Installation via `/cwe:init` (Step 1b: MCP Servers)
- Config in `.mcp.json`: `cwe-memory` server
- State: `~/.claude/cwe/memory/<project-slug>.sqlite`
- Watcher: debounced reindex on file changes

### Installation Command

```bash
claude mcp add cwe-memory -- npx @cwe/memory-mcp --workspace ./memory
```

## What Changes (Summary)

| Component | Before | After |
|-----------|--------|-------|
| Session start | 1 line from sessions.md | MEMORY.md + 2 daily logs |
| Session end | Timestamp in sessions.md | Content summary in daily log |
| Stop-Hook | "Update MEMORY.md + sessions.md" | "Update MEMORY.md + daily log" |
| `/cwe:init` | Empty templates | Auto-seeding of tech stack |
| Memory search | — | MCP server with vector + BM25 |
| sessions.md | Active | Deprecated → daily logs |

## Versioning

- Phase 1 = v0.4.2
- Phase 2 = v0.4.3
