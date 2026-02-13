# CWE Memory MCP Server — Detailed Design

**Date:** 2026-02-13
**Status:** Approved
**Version:** v0.4.3
**Parent:** docs/plans/2026-02-13-memory-system-v2-design.md (Phase 2)

## Overview

Local MCP server bundled in the CWE plugin that provides semantic + keyword search over project memory files. No API keys required — uses local Transformers.js embeddings.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Embedding | Transformers.js `all-MiniLM-L6-v2` (384 dim) | Local, no API key, ~80MB, ONNX Runtime |
| Vector Store | SQLite + sqlite-vec (`vec0` virtual table) | Single file DB, KNN via MATCH, zero infra |
| Full-Text | SQLite FTS5 | BM25 keyword search, built into SQLite |
| Search | Hybrid: 70% vector + 30% BM25 | Best of both — semantic + exact match |
| MCP Transport | stdio (plugin-bundled) | Auto-starts with plugin, no manual config |
| File Watcher | chokidar | Debounced reindex on file changes |
| Chunking | ~400 tokens, 80 token overlap | Balance between context and granularity |

## Architecture

```
cwe-memory-mcp/
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts               # MCP Server entry + stdio transport
│   ├── tools/
│   │   ├── memory-search.ts   # Hybrid search: vector + BM25
│   │   ├── memory-get.ts      # Read memory file
│   │   ├── memory-write.ts    # Append to daily log
│   │   └── memory-status.ts   # Index status
│   ├── indexer/
│   │   ├── chunker.ts         # Markdown → chunks (~400 tokens, 80 overlap)
│   │   ├── embeddings.ts      # Transformers.js all-MiniLM-L6-v2
│   │   └── store.ts           # SQLite + sqlite-vec + FTS5
│   └── watcher.ts             # chokidar file watcher → debounced reindex
```

## Dependencies

```json
{
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.12.0",
    "@huggingface/transformers": "^3.0.0",
    "better-sqlite3": "^11.0.0",
    "sqlite-vec": "^0.1.0",
    "chokidar": "^4.0.0",
    "zod": "^3.0.0"
  },
  "devDependencies": {
    "typescript": "^5.7.0",
    "@types/better-sqlite3": "^7.0.0"
  }
}
```

## MCP Tool Schemas

### memory_search — Semantic + keyword search

```typescript
input: {
  query: z.string().describe("Search query"),
  limit: z.number().default(5).describe("Max results"),
  source: z.enum(["all", "memory", "daily"]).default("all")
}
output: Array<{
  path: string,     // e.g. "memory/MEMORY.md"
  text: string,     // chunk text (~400 tokens)
  score: number,    // 0-1, hybrid score
  startLine: number,
  endLine: number
}>
```

### memory_get — Read memory file

```typescript
input: {
  path: z.string().describe("Relative path in memory/ dir"),
  startLine: z.number().optional(),
  lines: z.number().optional()
}
output: {
  content: string,
  path: string,
  totalLines: number
}
```

### memory_write — Append to daily log

```typescript
input: {
  entry: z.string().describe("Content to append"),
  topic: z.string().optional().describe("Topic header (## HH:MM — Topic)")
}
output: {
  path: string,     // e.g. "memory/2026-02-13.md"
  success: boolean
}
```

### memory_status — Index status

```typescript
input: {}
output: {
  files: number,
  chunks: number,
  lastIndexed: string,   // ISO timestamp
  model: string,         // "all-MiniLM-L6-v2"
  dimensions: number,    // 384
  dbSizeBytes: number,
  vectorEnabled: boolean,
  ftsEnabled: boolean
}
```

## Hybrid Search Algorithm

1. **Chunking**: Split markdown files into chunks of ~400 tokens with 80-token overlap
   - Split on paragraph boundaries (double newline)
   - If paragraph > 400 tokens, split on sentence boundaries
   - Each chunk stores: text, source path, start/end line numbers, content hash

2. **Embedding**: Each chunk → 384-dim Float32 vector via Transformers.js
   - Model: `Xenova/all-MiniLM-L6-v2`
   - Auto-downloads on first use (~80MB, cached in `~/.cache/huggingface/`)
   - Mean pooling + L2 normalization

3. **Storage**: SQLite with three structures:
   ```sql
   -- Metadata
   CREATE TABLE chunks (
     id TEXT PRIMARY KEY,
     path TEXT NOT NULL,
     text TEXT NOT NULL,
     start_line INTEGER NOT NULL,
     end_line INTEGER NOT NULL,
     hash TEXT NOT NULL,
     updated_at INTEGER NOT NULL
   );

   -- Vector index (sqlite-vec)
   CREATE VIRTUAL TABLE chunks_vec USING vec0(
     id TEXT PRIMARY KEY,
     embedding float[384] distance_metric=cosine
   );

   -- Full-text index (FTS5)
   CREATE VIRTUAL TABLE chunks_fts USING fts5(
     text, id UNINDEXED, path UNINDEXED
   );

   -- File tracking
   CREATE TABLE files (
     path TEXT PRIMARY KEY,
     hash TEXT NOT NULL,
     mtime INTEGER NOT NULL,
     size INTEGER NOT NULL
   );
   ```

4. **Search**:
   - Embed query → 384-dim vector
   - Vector: `SELECT id, distance FROM chunks_vec WHERE embedding MATCH :queryVec AND k = :limit * 4`
   - BM25: `SELECT id, rank FROM chunks_fts WHERE text MATCH :queryText ORDER BY rank LIMIT :limit * 4`
   - Normalize scores: vectorScore = 1 - distance (cosine), bm25Score = 1 / (1 + abs(rank))
   - Merge by chunk id: `finalScore = 0.7 * vectorScore + 0.3 * bm25Score`
   - Return top `limit` results sorted by finalScore

## Plugin Integration

### .mcp.json at plugin root

```json
{
  "mcpServers": {
    "cwe-memory": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/cwe-memory-mcp/dist/index.js"],
      "env": {
        "CWE_MEMORY_DIR": "${CLAUDE_PROJECT_DIR}/memory",
        "CWE_DB_DIR": "${HOME}/.claude/cwe/memory"
      }
    }
  }
}
```

- Auto-starts when CWE plugin is active
- `CWE_MEMORY_DIR` → project memory directory
- `CWE_DB_DIR` → SQLite DB storage (not in project to avoid git conflicts)
- DB file: `<project-slug>.sqlite`

### Build

```bash
cd cwe-memory-mcp && npm install && npm run build
# Output: dist/index.js (bundled)
```

## Lifecycle

1. **Server Start**: Check memory dir exists, init SQLite + extensions, start watcher
2. **First Index**: All `memory/*.md` → chunks → embeddings → SQLite (10-30s)
3. **Watcher**: chokidar watches `memory/*.md`, debounced 2s → re-index changed files only
4. **Search**: Tool call → hybrid search → results
5. **Write**: `memory_write` → append to daily log → watcher triggers re-index

## Error Handling

| Scenario | Behavior |
|----------|----------|
| No memory dir | Tools return warning, no crash |
| Model download fails | Fallback to BM25-only search |
| sqlite-vec fails to load | Fallback to BM25-only search |
| DB corrupt | Delete and re-index from scratch |
| File watcher error | Log warning, manual reindex via memory_status |
| Embedding timeout | Skip chunk, log warning |

## Performance Targets

| Metric | Target |
|--------|--------|
| First index (20 files) | < 30 seconds |
| Incremental reindex (1 file) | < 3 seconds |
| Search latency | < 500ms |
| DB size (20 files) | < 5MB |
| Memory usage | < 200MB (during embedding) |
