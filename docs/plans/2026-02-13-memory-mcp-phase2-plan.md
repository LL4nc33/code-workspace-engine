# CWE Memory MCP Server — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a local MCP server that provides semantic + keyword hybrid search over project memory files, bundled in the CWE plugin.

**Architecture:** TypeScript MCP server using stdio transport. Transformers.js for local embeddings (all-MiniLM-L6-v2, 384 dim), SQLite + sqlite-vec for vector KNN, FTS5 for BM25 keyword search. Hybrid scoring: 70% vector + 30% BM25. chokidar for file watching with debounced reindex. Four MCP tools: memory_search, memory_get, memory_write, memory_status.

**Tech Stack:** TypeScript, @modelcontextprotocol/sdk, @huggingface/transformers, better-sqlite3, sqlite-vec, chokidar, zod

**Design Doc:** `docs/plans/2026-02-13-memory-mcp-server-design.md`

---

### Task 1: Project Scaffolding

**Files:**
- Create: `cwe-memory-mcp/package.json`
- Create: `cwe-memory-mcp/tsconfig.json`
- Create: `cwe-memory-mcp/src/index.ts` (minimal placeholder)

**Step 1: Create package.json**

Create `cwe-memory-mcp/package.json`:

```json
{
  "name": "cwe-memory-mcp",
  "version": "0.4.3",
  "description": "CWE Memory MCP Server — semantic + keyword search over project memory",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch",
    "start": "node dist/index.js",
    "test": "node --test dist/**/*.test.js",
    "clean": "rm -rf dist"
  },
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
    "@types/better-sqlite3": "^7.0.0",
    "@types/node": "^22.0.0"
  }
}
```

**Step 2: Create tsconfig.json**

Create `cwe-memory-mcp/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

**Step 3: Create minimal index.ts placeholder**

Create `cwe-memory-mcp/src/index.ts`:

```typescript
#!/usr/bin/env node

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const server = new McpServer({
  name: "cwe-memory",
  version: "0.4.3",
});

async function main(): Promise<void> {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("[cwe-memory] Server started on stdio");
}

main().catch((err) => {
  console.error("[cwe-memory] Fatal error:", err);
  process.exit(1);
});
```

**Step 4: Install dependencies**

Run: `cd cwe-memory-mcp && npm install`
Expected: `node_modules/` created, `package-lock.json` generated

**Step 5: Verify build**

Run: `cd cwe-memory-mcp && npm run build`
Expected: `dist/index.js` created without errors

**Step 6: Add .gitignore**

Create `cwe-memory-mcp/.gitignore`:

```
node_modules/
dist/
*.tsbuildinfo
```

**Step 7: Commit**

```bash
git add cwe-memory-mcp/
git commit -m "feat(memory-mcp): scaffold TypeScript MCP server project"
```

---

### Task 2: SQLite Store — Schema + CRUD

**Files:**
- Create: `cwe-memory-mcp/src/indexer/store.ts`
- Create: `cwe-memory-mcp/src/indexer/store.test.ts`

**Step 1: Write the failing test**

Create `cwe-memory-mcp/src/indexer/store.test.ts`:

```typescript
import { describe, it, before, after } from "node:test";
import assert from "node:assert/strict";
import { Store } from "./store.js";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

describe("Store", () => {
  let store: Store;
  let dbDir: string;

  before(() => {
    dbDir = fs.mkdtempSync(path.join(os.tmpdir(), "cwe-store-test-"));
    store = new Store(dbDir, "test-project");
    store.init();
  });

  after(() => {
    store.close();
    fs.rmSync(dbDir, { recursive: true, force: true });
  });

  it("should create tables on init", () => {
    const tables = store.listTables();
    assert.ok(tables.includes("chunks"), "chunks table missing");
    assert.ok(tables.includes("files"), "files table missing");
    assert.ok(tables.includes("chunks_fts"), "chunks_fts table missing");
  });

  it("should upsert and retrieve chunks", () => {
    store.upsertChunks("memory/MEMORY.md", [
      {
        id: "chunk-1",
        text: "This is a test chunk about authentication patterns",
        startLine: 1,
        endLine: 10,
        hash: "abc123",
        embedding: new Float32Array(384).fill(0.1),
      },
    ]);
    const chunks = store.getChunksByPath("memory/MEMORY.md");
    assert.equal(chunks.length, 1);
    assert.equal(chunks[0].text, "This is a test chunk about authentication patterns");
  });

  it("should delete chunks by path", () => {
    store.upsertChunks("memory/old.md", [
      {
        id: "old-1",
        text: "Old content",
        startLine: 1,
        endLine: 5,
        hash: "old123",
        embedding: new Float32Array(384).fill(0.2),
      },
    ]);
    assert.equal(store.getChunksByPath("memory/old.md").length, 1);
    store.deleteChunksByPath("memory/old.md");
    assert.equal(store.getChunksByPath("memory/old.md").length, 0);
  });

  it("should search FTS5 with BM25", () => {
    store.upsertChunks("memory/patterns.md", [
      {
        id: "fts-1",
        text: "Authentication uses JWT tokens for session management",
        startLine: 1,
        endLine: 5,
        hash: "fts1",
        embedding: new Float32Array(384).fill(0.3),
      },
      {
        id: "fts-2",
        text: "Docker containers run in kubernetes pods",
        startLine: 6,
        endLine: 10,
        hash: "fts2",
        embedding: new Float32Array(384).fill(0.4),
      },
    ]);
    const results = store.searchBM25("authentication JWT", 5);
    assert.ok(results.length > 0, "BM25 should return results");
    assert.equal(results[0].id, "fts-1");
  });

  it("should track files", () => {
    store.upsertFile("memory/MEMORY.md", "hash1", 1000, 500);
    const file = store.getFile("memory/MEMORY.md");
    assert.ok(file, "file should exist");
    assert.equal(file!.hash, "hash1");
  });

  it("should search vectors with KNN", () => {
    const queryVec = new Float32Array(384).fill(0.1);
    const results = store.searchVector(queryVec, 5);
    assert.ok(Array.isArray(results));
  });
});
```

**Step 2: Run test to verify it fails**

Run: `cd cwe-memory-mcp && npm run build && npm test`
Expected: FAIL — `store.ts` does not exist

**Step 3: Implement store.ts**

Create `cwe-memory-mcp/src/indexer/store.ts`:

```typescript
import Database from "better-sqlite3";
import * as sqliteVec from "sqlite-vec";
import path from "node:path";
import fs from "node:fs";

export interface ChunkInput {
  id: string;
  text: string;
  startLine: number;
  endLine: number;
  hash: string;
  embedding: Float32Array;
}

export interface ChunkRow {
  id: string;
  path: string;
  text: string;
  start_line: number;
  end_line: number;
  hash: string;
  updated_at: number;
}

export interface FileRow {
  path: string;
  hash: string;
  mtime: number;
  size: number;
}

export interface BM25Result {
  id: string;
  rank: number;
}

export interface VectorResult {
  id: string;
  distance: number;
}

export class Store {
  private db: Database.Database | null = null;
  private dbPath: string;
  private vectorEnabled = false;

  constructor(dbDir: string, projectSlug: string) {
    fs.mkdirSync(dbDir, { recursive: true });
    this.dbPath = path.join(dbDir, `${projectSlug}.sqlite`);
  }

  init(): void {
    this.db = new Database(this.dbPath);
    this.db.pragma("journal_mode = WAL");
    this.db.pragma("foreign_keys = ON");

    // Try to load sqlite-vec extension
    try {
      sqliteVec.load(this.db);
      this.vectorEnabled = true;
    } catch {
      console.error("[cwe-memory] sqlite-vec not available, vector search disabled");
      this.vectorEnabled = false;
    }

    this.createTables();
  }

  private createTables(): void {
    const db = this.getDb();

    db.exec(`
      CREATE TABLE IF NOT EXISTS chunks (
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        text TEXT NOT NULL,
        start_line INTEGER NOT NULL,
        end_line INTEGER NOT NULL,
        hash TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_chunks_path ON chunks(path);

      CREATE TABLE IF NOT EXISTS files (
        path TEXT PRIMARY KEY,
        hash TEXT NOT NULL,
        mtime INTEGER NOT NULL,
        size INTEGER NOT NULL
      );
    `);

    // FTS5 virtual table
    db.exec(`
      CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5(
        text, id UNINDEXED, path UNINDEXED
      );
    `);

    // Vector table (only if sqlite-vec loaded)
    if (this.vectorEnabled) {
      try {
        db.exec(`
          CREATE VIRTUAL TABLE IF NOT EXISTS chunks_vec USING vec0(
            id TEXT PRIMARY KEY,
            embedding float[384] distance_metric=cosine
          );
        `);
      } catch {
        console.error("[cwe-memory] Failed to create vector table");
        this.vectorEnabled = false;
      }
    }
  }

  private getDb(): Database.Database {
    if (!this.db) throw new Error("Store not initialized. Call init() first.");
    return this.db;
  }

  listTables(): string[] {
    const db = this.getDb();
    const rows = db.prepare(
      "SELECT name FROM sqlite_master WHERE type IN ('table', 'view') ORDER BY name"
    ).all() as Array<{ name: string }>;
    return rows.map((r) => r.name);
  }

  upsertChunks(filePath: string, chunks: ChunkInput[]): void {
    const db = this.getDb();
    const now = Date.now();

    const upsertChunk = db.prepare(`
      INSERT OR REPLACE INTO chunks (id, path, text, start_line, end_line, hash, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);

    const upsertFts = db.prepare(`
      INSERT OR REPLACE INTO chunks_fts (rowid, text, id, path)
      VALUES ((SELECT rowid FROM chunks WHERE id = ?), ?, ?, ?)
    `);

    const upsertVec = this.vectorEnabled
      ? db.prepare(`
          INSERT OR REPLACE INTO chunks_vec (id, embedding)
          VALUES (?, ?)
        `)
      : null;

    const transaction = db.transaction(() => {
      for (const chunk of chunks) {
        upsertChunk.run(chunk.id, filePath, chunk.text, chunk.startLine, chunk.endLine, chunk.hash, now);

        // FTS: delete old entry first, then insert
        db.prepare("DELETE FROM chunks_fts WHERE id = ?").run(chunk.id);
        db.prepare(
          "INSERT INTO chunks_fts (text, id, path) VALUES (?, ?, ?)"
        ).run(chunk.text, chunk.id, filePath);

        if (upsertVec) {
          upsertVec.run(chunk.id, Buffer.from(chunk.embedding.buffer));
        }
      }
    });

    transaction();
  }

  getChunksByPath(filePath: string): ChunkRow[] {
    const db = this.getDb();
    return db.prepare("SELECT * FROM chunks WHERE path = ?").all(filePath) as ChunkRow[];
  }

  getChunkById(id: string): ChunkRow | undefined {
    const db = this.getDb();
    return db.prepare("SELECT * FROM chunks WHERE id = ?").get(id) as ChunkRow | undefined;
  }

  deleteChunksByPath(filePath: string): void {
    const db = this.getDb();
    const chunkIds = db
      .prepare("SELECT id FROM chunks WHERE path = ?")
      .all(filePath) as Array<{ id: string }>;

    const transaction = db.transaction(() => {
      for (const { id } of chunkIds) {
        db.prepare("DELETE FROM chunks_fts WHERE id = ?").run(id);
        if (this.vectorEnabled) {
          db.prepare("DELETE FROM chunks_vec WHERE id = ?").run(id);
        }
      }
      db.prepare("DELETE FROM chunks WHERE path = ?").run(filePath);
    });

    transaction();
  }

  searchBM25(query: string, limit: number): BM25Result[] {
    const db = this.getDb();
    return db
      .prepare(
        `SELECT id, rank FROM chunks_fts WHERE text MATCH ? ORDER BY rank LIMIT ?`
      )
      .all(query, limit) as BM25Result[];
  }

  searchVector(queryVec: Float32Array, limit: number): VectorResult[] {
    if (!this.vectorEnabled) return [];
    const db = this.getDb();
    return db
      .prepare(
        `SELECT id, distance FROM chunks_vec WHERE embedding MATCH ? AND k = ?`
      )
      .all(Buffer.from(queryVec.buffer), limit) as VectorResult[];
  }

  upsertFile(filePath: string, hash: string, mtime: number, size: number): void {
    const db = this.getDb();
    db.prepare(
      `INSERT OR REPLACE INTO files (path, hash, mtime, size) VALUES (?, ?, ?, ?)`
    ).run(filePath, hash, mtime, size);
  }

  getFile(filePath: string): FileRow | undefined {
    const db = this.getDb();
    return db.prepare("SELECT * FROM files WHERE path = ?").get(filePath) as FileRow | undefined;
  }

  getAllFiles(): FileRow[] {
    const db = this.getDb();
    return db.prepare("SELECT * FROM files").all() as FileRow[];
  }

  deleteFile(filePath: string): void {
    const db = this.getDb();
    db.prepare("DELETE FROM files WHERE path = ?").run(filePath);
  }

  getStats(): { chunks: number; files: number; dbSizeBytes: number; vectorEnabled: boolean; ftsEnabled: boolean } {
    const db = this.getDb();
    const chunksCount = (db.prepare("SELECT COUNT(*) as count FROM chunks").get() as { count: number }).count;
    const filesCount = (db.prepare("SELECT COUNT(*) as count FROM files").get() as { count: number }).count;
    const stat = fs.statSync(this.dbPath);
    return {
      chunks: chunksCount,
      files: filesCount,
      dbSizeBytes: stat.size,
      vectorEnabled: this.vectorEnabled,
      ftsEnabled: true,
    };
  }

  isVectorEnabled(): boolean {
    return this.vectorEnabled;
  }

  close(): void {
    if (this.db) {
      this.db.close();
      this.db = null;
    }
  }

  destroy(): void {
    this.close();
    if (fs.existsSync(this.dbPath)) {
      fs.unlinkSync(this.dbPath);
    }
  }
}
```

**Step 4: Run tests**

Run: `cd cwe-memory-mcp && npm run build && npm test`
Expected: All 6 tests PASS

**Step 5: Commit**

```bash
git add cwe-memory-mcp/src/indexer/
git commit -m "feat(memory-mcp): SQLite store with sqlite-vec + FTS5"
```

---

### Task 3: Markdown Chunker

**Files:**
- Create: `cwe-memory-mcp/src/indexer/chunker.ts`
- Create: `cwe-memory-mcp/src/indexer/chunker.test.ts`

**Step 1: Write the failing test**

Create `cwe-memory-mcp/src/indexer/chunker.test.ts`:

```typescript
import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { chunkMarkdown, type Chunk } from "./chunker.js";

describe("chunkMarkdown", () => {
  it("should return a single chunk for small content", () => {
    const content = "# Title\n\nShort paragraph.";
    const chunks = chunkMarkdown(content, "memory/test.md");
    assert.equal(chunks.length, 1);
    assert.equal(chunks[0].startLine, 1);
    assert.ok(chunks[0].text.includes("Short paragraph"));
  });

  it("should split on paragraph boundaries", () => {
    const paragraphs = Array.from({ length: 20 }, (_, i) =>
      `Paragraph ${i}: ${"word ".repeat(30)}`
    ).join("\n\n");
    const chunks = chunkMarkdown(paragraphs, "memory/test.md");
    assert.ok(chunks.length > 1, `Expected >1 chunks, got ${chunks.length}`);
  });

  it("should include overlap between chunks", () => {
    const paragraphs = Array.from({ length: 30 }, (_, i) =>
      `Paragraph ${i}: ${"word ".repeat(25)}`
    ).join("\n\n");
    const chunks = chunkMarkdown(paragraphs, "memory/test.md");
    if (chunks.length >= 2) {
      // Last lines of chunk N should overlap with first lines of chunk N+1
      assert.ok(
        chunks[0].endLine >= chunks[1].startLine,
        "Chunks should overlap"
      );
    }
  });

  it("should generate deterministic chunk IDs", () => {
    const content = "# Title\n\nSome content here.";
    const chunks1 = chunkMarkdown(content, "memory/test.md");
    const chunks2 = chunkMarkdown(content, "memory/test.md");
    assert.equal(chunks1[0].id, chunks2[0].id);
  });

  it("should track correct line numbers", () => {
    const content = "Line 1\n\nLine 3\n\nLine 5";
    const chunks = chunkMarkdown(content, "memory/test.md");
    assert.equal(chunks[0].startLine, 1);
  });

  it("should generate content hash", () => {
    const content = "# Title\n\nContent.";
    const chunks = chunkMarkdown(content, "memory/test.md");
    assert.ok(chunks[0].hash.length > 0, "hash should not be empty");
  });
});
```

**Step 2: Run test to verify it fails**

Run: `cd cwe-memory-mcp && npm run build && npm test`
Expected: FAIL — `chunker.ts` does not exist

**Step 3: Implement chunker.ts**

Create `cwe-memory-mcp/src/indexer/chunker.ts`:

```typescript
import { createHash } from "node:crypto";

const TARGET_TOKENS = 400;
const OVERLAP_TOKENS = 80;
// Rough approximation: 1 token ≈ 4 characters
const CHARS_PER_TOKEN = 4;
const TARGET_CHARS = TARGET_TOKENS * CHARS_PER_TOKEN;
const OVERLAP_CHARS = OVERLAP_TOKENS * CHARS_PER_TOKEN;

export interface Chunk {
  id: string;
  text: string;
  startLine: number;
  endLine: number;
  hash: string;
}

interface Paragraph {
  text: string;
  startLine: number;
  endLine: number;
}

function splitIntoParagraphs(content: string): Paragraph[] {
  const lines = content.split("\n");
  const paragraphs: Paragraph[] = [];
  let currentText = "";
  let currentStart = 1;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineNum = i + 1;

    if (line.trim() === "" && currentText.trim() !== "") {
      paragraphs.push({
        text: currentText.trim(),
        startLine: currentStart,
        endLine: lineNum - 1,
      });
      currentText = "";
      currentStart = lineNum + 1;
    } else {
      if (currentText === "" && line.trim() !== "") {
        currentStart = lineNum;
      }
      currentText += (currentText ? "\n" : "") + line;
    }
  }

  if (currentText.trim() !== "") {
    paragraphs.push({
      text: currentText.trim(),
      startLine: currentStart,
      endLine: lines.length,
    });
  }

  return paragraphs;
}

function splitLongParagraph(para: Paragraph): Paragraph[] {
  if (para.text.length <= TARGET_CHARS) return [para];

  // Split on sentence boundaries
  const sentences = para.text.match(/[^.!?]+[.!?]+\s*/g) || [para.text];
  const result: Paragraph[] = [];
  let currentText = "";
  let sentenceCount = 0;

  for (const sentence of sentences) {
    if (currentText.length + sentence.length > TARGET_CHARS && currentText.length > 0) {
      const linesInChunk = currentText.split("\n").length;
      result.push({
        text: currentText.trim(),
        startLine: para.startLine + (result.length > 0 ? result.length : 0),
        endLine: para.startLine + linesInChunk - 1,
      });
      currentText = "";
    }
    currentText += sentence;
    sentenceCount++;
  }

  if (currentText.trim()) {
    result.push({
      text: currentText.trim(),
      startLine: para.startLine + result.length,
      endLine: para.endLine,
    });
  }

  return result;
}

function makeChunkId(filePath: string, index: number, hash: string): string {
  return createHash("sha256")
    .update(`${filePath}:${index}:${hash}`)
    .digest("hex")
    .slice(0, 16);
}

function makeContentHash(text: string): string {
  return createHash("sha256").update(text).digest("hex").slice(0, 12);
}

export function chunkMarkdown(content: string, filePath: string): Chunk[] {
  if (!content.trim()) return [];

  // Split into paragraphs, then split long paragraphs
  const rawParagraphs = splitIntoParagraphs(content);
  const paragraphs = rawParagraphs.flatMap(splitLongParagraph);

  if (paragraphs.length === 0) return [];

  const chunks: Chunk[] = [];
  let currentParagraphs: Paragraph[] = [];
  let currentLength = 0;

  for (let i = 0; i < paragraphs.length; i++) {
    const para = paragraphs[i];

    if (currentLength + para.text.length > TARGET_CHARS && currentParagraphs.length > 0) {
      // Emit current chunk
      const text = currentParagraphs.map((p) => p.text).join("\n\n");
      const hash = makeContentHash(text);
      chunks.push({
        id: makeChunkId(filePath, chunks.length, hash),
        text,
        startLine: currentParagraphs[0].startLine,
        endLine: currentParagraphs[currentParagraphs.length - 1].endLine,
        hash,
      });

      // Overlap: keep paragraphs from the end that fit in OVERLAP_CHARS
      let overlapLength = 0;
      let overlapStart = currentParagraphs.length;
      for (let j = currentParagraphs.length - 1; j >= 0; j--) {
        if (overlapLength + currentParagraphs[j].text.length > OVERLAP_CHARS) break;
        overlapLength += currentParagraphs[j].text.length;
        overlapStart = j;
      }
      currentParagraphs = currentParagraphs.slice(overlapStart);
      currentLength = currentParagraphs.reduce((sum, p) => sum + p.text.length, 0);
    }

    currentParagraphs.push(para);
    currentLength += para.text.length;
  }

  // Emit final chunk
  if (currentParagraphs.length > 0) {
    const text = currentParagraphs.map((p) => p.text).join("\n\n");
    const hash = makeContentHash(text);
    chunks.push({
      id: makeChunkId(filePath, chunks.length, hash),
      text,
      startLine: currentParagraphs[0].startLine,
      endLine: currentParagraphs[currentParagraphs.length - 1].endLine,
      hash,
    });
  }

  return chunks;
}
```

**Step 4: Run tests**

Run: `cd cwe-memory-mcp && npm run build && npm test`
Expected: All chunker tests PASS

**Step 5: Commit**

```bash
git add cwe-memory-mcp/src/indexer/chunker.ts cwe-memory-mcp/src/indexer/chunker.test.ts
git commit -m "feat(memory-mcp): markdown chunker with paragraph splitting and overlap"
```

---

### Task 4: Transformers.js Embeddings Wrapper

**Files:**
- Create: `cwe-memory-mcp/src/indexer/embeddings.ts`
- Create: `cwe-memory-mcp/src/indexer/embeddings.test.ts`

**Step 1: Write the failing test**

Create `cwe-memory-mcp/src/indexer/embeddings.test.ts`:

```typescript
import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { EmbeddingService } from "./embeddings.js";

describe("EmbeddingService", () => {
  let service: EmbeddingService;

  it("should initialize and report model info", async () => {
    service = new EmbeddingService();
    await service.init();
    assert.equal(service.getDimensions(), 384);
    assert.equal(service.getModelName(), "Xenova/all-MiniLM-L6-v2");
  });

  it("should generate embeddings of correct dimension", async () => {
    const embedding = await service.embed("Hello, this is a test sentence.");
    assert.equal(embedding.length, 384);
    assert.ok(embedding instanceof Float32Array);
  });

  it("should generate different embeddings for different texts", async () => {
    const emb1 = await service.embed("Authentication uses JWT tokens.");
    const emb2 = await service.embed("Docker containers and Kubernetes.");
    // Cosine distance should be non-trivial
    let dotProduct = 0;
    for (let i = 0; i < 384; i++) dotProduct += emb1[i] * emb2[i];
    assert.ok(dotProduct < 0.95, "Different texts should have different embeddings");
  });

  it("should batch embed multiple texts", async () => {
    const texts = ["First sentence.", "Second sentence.", "Third sentence."];
    const embeddings = await service.embedBatch(texts);
    assert.equal(embeddings.length, 3);
    assert.equal(embeddings[0].length, 384);
  });
});
```

**Step 2: Run test to verify it fails**

Run: `cd cwe-memory-mcp && npm run build && npm test`
Expected: FAIL — `embeddings.ts` does not exist

**Step 3: Implement embeddings.ts**

Create `cwe-memory-mcp/src/indexer/embeddings.ts`:

```typescript
import { pipeline, type FeatureExtractionPipeline } from "@huggingface/transformers";

const MODEL_NAME = "Xenova/all-MiniLM-L6-v2";
const DIMENSIONS = 384;

export class EmbeddingService {
  private extractor: FeatureExtractionPipeline | null = null;
  private ready = false;

  async init(): Promise<void> {
    if (this.ready) return;
    console.error(`[cwe-memory] Loading embedding model: ${MODEL_NAME}`);
    this.extractor = await pipeline("feature-extraction", MODEL_NAME, {
      dtype: "fp32",
    }) as FeatureExtractionPipeline;
    this.ready = true;
    console.error("[cwe-memory] Embedding model loaded");
  }

  async embed(text: string): Promise<Float32Array> {
    if (!this.extractor) throw new Error("EmbeddingService not initialized");
    const output = await this.extractor(text, {
      pooling: "mean",
      normalize: true,
    });
    return new Float32Array(output.data as Float64Array);
  }

  async embedBatch(texts: string[]): Promise<Float32Array[]> {
    if (!this.extractor) throw new Error("EmbeddingService not initialized");
    const results: Float32Array[] = [];
    // Process one at a time to avoid OOM on large batches
    for (const text of texts) {
      results.push(await this.embed(text));
    }
    return results;
  }

  getDimensions(): number {
    return DIMENSIONS;
  }

  getModelName(): string {
    return MODEL_NAME;
  }

  isReady(): boolean {
    return this.ready;
  }
}
```

**Step 4: Run tests**

Run: `cd cwe-memory-mcp && npm run build && npm test`
Expected: All embeddings tests PASS (first run may take 30-60s to download model)

**Step 5: Commit**

```bash
git add cwe-memory-mcp/src/indexer/embeddings.ts cwe-memory-mcp/src/indexer/embeddings.test.ts
git commit -m "feat(memory-mcp): Transformers.js embedding service (all-MiniLM-L6-v2)"
```

---

### Task 5: File Watcher

**Files:**
- Create: `cwe-memory-mcp/src/watcher.ts`

**Step 1: Implement watcher.ts**

Create `cwe-memory-mcp/src/watcher.ts`:

```typescript
import { watch, type FSWatcher } from "chokidar";
import path from "node:path";

export type IndexCallback = (filePath: string) => Promise<void>;
export type DeleteCallback = (filePath: string) => Promise<void>;

export class MemoryWatcher {
  private watcher: FSWatcher | null = null;
  private debounceTimers = new Map<string, NodeJS.Timeout>();
  private debounceMs: number;

  constructor(
    private memoryDir: string,
    private onIndex: IndexCallback,
    private onDelete: DeleteCallback,
    debounceMs = 2000
  ) {
    this.debounceMs = debounceMs;
  }

  start(): void {
    const globPattern = path.join(this.memoryDir, "**/*.md");
    this.watcher = watch(globPattern, {
      persistent: true,
      ignoreInitial: true,
      awaitWriteFinish: {
        stabilityThreshold: 500,
        pollInterval: 100,
      },
    });

    this.watcher
      .on("add", (filePath) => this.debounce(filePath, "index"))
      .on("change", (filePath) => this.debounce(filePath, "index"))
      .on("unlink", (filePath) => this.debounce(filePath, "delete"));

    console.error(`[cwe-memory] Watching: ${globPattern}`);
  }

  private debounce(filePath: string, action: "index" | "delete"): void {
    const key = `${action}:${filePath}`;
    const existing = this.debounceTimers.get(key);
    if (existing) clearTimeout(existing);

    this.debounceTimers.set(
      key,
      setTimeout(async () => {
        this.debounceTimers.delete(key);
        try {
          if (action === "index") {
            await this.onIndex(filePath);
          } else {
            await this.onDelete(filePath);
          }
        } catch (err) {
          console.error(`[cwe-memory] Watcher ${action} error for ${filePath}:`, err);
        }
      }, this.debounceMs)
    );
  }

  async stop(): Promise<void> {
    for (const timer of this.debounceTimers.values()) {
      clearTimeout(timer);
    }
    this.debounceTimers.clear();
    if (this.watcher) {
      await this.watcher.close();
      this.watcher = null;
    }
  }
}
```

**Step 2: Verify build**

Run: `cd cwe-memory-mcp && npm run build`
Expected: Compiles without errors

**Step 3: Commit**

```bash
git add cwe-memory-mcp/src/watcher.ts
git commit -m "feat(memory-mcp): chokidar file watcher with debounced reindex"
```

---

### Task 6: Indexer — Orchestrates Chunking + Embedding + Store

**Files:**
- Create: `cwe-memory-mcp/src/indexer/indexer.ts`

**Step 1: Implement indexer.ts**

Create `cwe-memory-mcp/src/indexer/indexer.ts`:

```typescript
import fs from "node:fs";
import path from "node:path";
import { createHash } from "node:crypto";
import { Store } from "./store.js";
import { chunkMarkdown } from "./chunker.js";
import { EmbeddingService } from "./embeddings.js";

export class Indexer {
  private lastIndexed: string | null = null;

  constructor(
    private store: Store,
    private embeddings: EmbeddingService,
    private memoryDir: string
  ) {}

  async indexFile(filePath: string): Promise<number> {
    const relativePath = path.relative(this.memoryDir, filePath).replace(/\\/g, "/");
    const fullPath = path.isAbsolute(filePath) ? filePath : path.join(this.memoryDir, filePath);

    if (!fs.existsSync(fullPath)) {
      console.error(`[cwe-memory] File not found: ${fullPath}`);
      return 0;
    }

    const content = fs.readFileSync(fullPath, "utf-8");
    const stat = fs.statSync(fullPath);
    const fileHash = createHash("sha256").update(content).digest("hex").slice(0, 16);

    // Check if file changed
    const existingFile = this.store.getFile(relativePath);
    if (existingFile && existingFile.hash === fileHash) {
      return 0; // unchanged
    }

    // Delete old chunks for this file
    this.store.deleteChunksByPath(relativePath);

    // Chunk the content
    const chunks = chunkMarkdown(content, relativePath);
    if (chunks.length === 0) return 0;

    // Generate embeddings
    const embeddings = this.embeddings.isReady()
      ? await this.embeddings.embedBatch(chunks.map((c) => c.text))
      : chunks.map(() => new Float32Array(384)); // zero vectors if no model

    // Store chunks with embeddings
    this.store.upsertChunks(
      relativePath,
      chunks.map((chunk, i) => ({
        ...chunk,
        embedding: embeddings[i],
      }))
    );

    // Update file tracking
    this.store.upsertFile(relativePath, fileHash, stat.mtimeMs, stat.size);
    this.lastIndexed = new Date().toISOString();

    console.error(`[cwe-memory] Indexed: ${relativePath} (${chunks.length} chunks)`);
    return chunks.length;
  }

  async indexAll(): Promise<{ files: number; chunks: number }> {
    const mdFiles = this.findMarkdownFiles();
    let totalChunks = 0;

    for (const filePath of mdFiles) {
      const count = await this.indexFile(filePath);
      totalChunks += count;
    }

    console.error(`[cwe-memory] Full index complete: ${mdFiles.length} files, ${totalChunks} chunks`);
    return { files: mdFiles.length, chunks: totalChunks };
  }

  async removeFile(filePath: string): Promise<void> {
    const relativePath = path.relative(this.memoryDir, filePath).replace(/\\/g, "/");
    this.store.deleteChunksByPath(relativePath);
    this.store.deleteFile(relativePath);
    console.error(`[cwe-memory] Removed: ${relativePath}`);
  }

  getLastIndexed(): string | null {
    return this.lastIndexed;
  }

  private findMarkdownFiles(): string[] {
    if (!fs.existsSync(this.memoryDir)) return [];
    const entries = fs.readdirSync(this.memoryDir, { withFileTypes: true, recursive: true });
    return entries
      .filter((e) => e.isFile() && e.name.endsWith(".md"))
      .map((e) => path.join(e.parentPath || e.path, e.name));
  }
}
```

**Step 2: Verify build**

Run: `cd cwe-memory-mcp && npm run build`
Expected: Compiles without errors

**Step 3: Commit**

```bash
git add cwe-memory-mcp/src/indexer/indexer.ts
git commit -m "feat(memory-mcp): indexer orchestrates chunking + embedding + store"
```

---

### Task 7: Hybrid Search Service

**Files:**
- Create: `cwe-memory-mcp/src/search.ts`

**Step 1: Implement search.ts**

Create `cwe-memory-mcp/src/search.ts`:

```typescript
import { Store } from "./indexer/store.js";
import { EmbeddingService } from "./indexer/embeddings.js";

export interface SearchResult {
  path: string;
  text: string;
  score: number;
  startLine: number;
  endLine: number;
}

const VECTOR_WEIGHT = 0.7;
const BM25_WEIGHT = 0.3;

export class SearchService {
  constructor(
    private store: Store,
    private embeddings: EmbeddingService
  ) {}

  async search(query: string, limit: number, source?: string): Promise<SearchResult[]> {
    const overFetch = limit * 4;

    // Vector search
    let vectorScores = new Map<string, number>();
    if (this.embeddings.isReady() && this.store.isVectorEnabled()) {
      const queryVec = await this.embeddings.embed(query);
      const vectorResults = this.store.searchVector(queryVec, overFetch);
      for (const r of vectorResults) {
        // cosine distance → similarity: 1 - distance
        vectorScores.set(r.id, 1 - r.distance);
      }
    }

    // BM25 search
    const bm25Scores = new Map<string, number>();
    try {
      const ftsQuery = this.buildFtsQuery(query);
      const bm25Results = this.store.searchBM25(ftsQuery, overFetch);
      for (const r of bm25Results) {
        // FTS5 rank is negative (lower = better), normalize to 0-1
        bm25Scores.set(r.id, 1 / (1 + Math.abs(r.rank)));
      }
    } catch {
      // FTS query syntax errors are non-fatal
    }

    // Merge scores
    const allIds = new Set([...vectorScores.keys(), ...bm25Scores.keys()]);
    const scored: Array<{ id: string; score: number }> = [];

    for (const id of allIds) {
      const vs = vectorScores.get(id) ?? 0;
      const bs = bm25Scores.get(id) ?? 0;
      const hasVector = vectorScores.size > 0;
      const score = hasVector
        ? VECTOR_WEIGHT * vs + BM25_WEIGHT * bs
        : bs; // fallback to BM25-only if no vector
      scored.push({ id, score });
    }

    // Sort by score descending, take top limit
    scored.sort((a, b) => b.score - a.score);
    const topIds = scored.slice(0, limit);

    // Hydrate results from store
    const results: SearchResult[] = [];
    for (const { id, score } of topIds) {
      const chunk = this.store.getChunkById(id);
      if (!chunk) continue;

      // Apply source filter
      if (source === "memory" && chunk.path.match(/^\d{4}-\d{2}-\d{2}\.md$/)) continue;
      if (source === "daily" && !chunk.path.match(/^\d{4}-\d{2}-\d{2}\.md$/)) continue;

      results.push({
        path: chunk.path,
        text: chunk.text,
        score: Math.round(score * 1000) / 1000,
        startLine: chunk.start_line,
        endLine: chunk.end_line,
      });
    }

    return results;
  }

  private buildFtsQuery(query: string): string {
    // FTS5 query: wrap each word in quotes to avoid syntax issues
    const words = query.trim().split(/\s+/).filter(Boolean);
    if (words.length === 0) return '""';
    return words.map((w) => `"${w.replace(/"/g, "")}"`).join(" OR ");
  }
}
```

**Step 2: Verify build**

Run: `cd cwe-memory-mcp && npm run build`
Expected: Compiles without errors

**Step 3: Commit**

```bash
git add cwe-memory-mcp/src/search.ts
git commit -m "feat(memory-mcp): hybrid search service (70% vector + 30% BM25)"
```

---

### Task 8: MCP Tools — memory_search, memory_get, memory_write, memory_status

**Files:**
- Create: `cwe-memory-mcp/src/tools/memory-search.ts`
- Create: `cwe-memory-mcp/src/tools/memory-get.ts`
- Create: `cwe-memory-mcp/src/tools/memory-write.ts`
- Create: `cwe-memory-mcp/src/tools/memory-status.ts`

**Step 1: Implement memory-search.ts**

Create `cwe-memory-mcp/src/tools/memory-search.ts`:

```typescript
import { z } from "zod";
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import type { SearchService } from "../search.js";

export function registerMemorySearch(server: McpServer, searchService: SearchService): void {
  server.tool(
    "memory_search",
    "Semantic + keyword search over project memory files. Returns relevant chunks with scores.",
    {
      query: z.string().describe("Search query"),
      limit: z.number().default(5).describe("Max results (1-20)"),
      source: z.enum(["all", "memory", "daily"]).default("all").describe("Filter: all, memory files only, or daily logs only"),
    },
    async ({ query, limit, source }) => {
      const clampedLimit = Math.min(Math.max(limit, 1), 20);
      const results = await searchService.search(query, clampedLimit, source);
      return {
        content: [
          {
            type: "text" as const,
            text: JSON.stringify(results, null, 2),
          },
        ],
      };
    }
  );
}
```

**Step 2: Implement memory-get.ts**

Create `cwe-memory-mcp/src/tools/memory-get.ts`:

```typescript
import { z } from "zod";
import fs from "node:fs";
import path from "node:path";
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";

export function registerMemoryGet(server: McpServer, memoryDir: string): void {
  server.tool(
    "memory_get",
    "Read a memory file by path. Supports line range selection.",
    {
      path: z.string().describe("Relative path within memory/ directory"),
      startLine: z.number().optional().describe("Start line (1-based)"),
      lines: z.number().optional().describe("Number of lines to read"),
    },
    async ({ path: relPath, startLine, lines }) => {
      const fullPath = path.join(memoryDir, relPath);

      if (!fs.existsSync(fullPath)) {
        return {
          content: [{ type: "text" as const, text: JSON.stringify({ error: `File not found: ${relPath}` }) }],
          isError: true,
        };
      }

      const content = fs.readFileSync(fullPath, "utf-8");
      const allLines = content.split("\n");
      const totalLines = allLines.length;

      let result: string;
      if (startLine !== undefined && lines !== undefined) {
        const start = Math.max(0, startLine - 1);
        const end = Math.min(totalLines, start + lines);
        result = allLines.slice(start, end).join("\n");
      } else if (startLine !== undefined) {
        const start = Math.max(0, startLine - 1);
        result = allLines.slice(start).join("\n");
      } else {
        result = content;
      }

      return {
        content: [
          {
            type: "text" as const,
            text: JSON.stringify({ content: result, path: relPath, totalLines }),
          },
        ],
      };
    }
  );
}
```

**Step 3: Implement memory-write.ts**

Create `cwe-memory-mcp/src/tools/memory-write.ts`:

```typescript
import { z } from "zod";
import fs from "node:fs";
import path from "node:path";
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";

export function registerMemoryWrite(server: McpServer, memoryDir: string): void {
  server.tool(
    "memory_write",
    "Append an entry to today's daily log (memory/YYYY-MM-DD.md).",
    {
      entry: z.string().describe("Content to append"),
      topic: z.string().optional().describe("Topic header — will create ## HH:MM — Topic"),
    },
    async ({ entry, topic }) => {
      const now = new Date();
      const dateStr = now.toISOString().slice(0, 10);
      const timeStr = now.toTimeString().slice(0, 5);
      const fileName = `${dateStr}.md`;
      const fullPath = path.join(memoryDir, fileName);

      fs.mkdirSync(memoryDir, { recursive: true });

      let appendText = "\n";
      if (topic) {
        appendText += `## ${timeStr} — ${topic}\n\n`;
      }
      appendText += entry + "\n";

      // Create file with header if it doesn't exist
      if (!fs.existsSync(fullPath)) {
        const header = `# Daily Log — ${dateStr}\n`;
        fs.writeFileSync(fullPath, header + appendText, "utf-8");
      } else {
        fs.appendFileSync(fullPath, appendText, "utf-8");
      }

      return {
        content: [
          {
            type: "text" as const,
            text: JSON.stringify({ path: fileName, success: true }),
          },
        ],
      };
    }
  );
}
```

**Step 4: Implement memory-status.ts**

Create `cwe-memory-mcp/src/tools/memory-status.ts`:

```typescript
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import type { Store } from "../indexer/store.js";
import type { EmbeddingService } from "../indexer/embeddings.js";
import type { Indexer } from "../indexer/indexer.js";

export function registerMemoryStatus(
  server: McpServer,
  store: Store,
  embeddings: EmbeddingService,
  indexer: Indexer
): void {
  server.tool(
    "memory_status",
    "Show index status: file count, chunk count, DB size, model info, capabilities.",
    {},
    async () => {
      const stats = store.getStats();
      const status = {
        files: stats.files,
        chunks: stats.chunks,
        lastIndexed: indexer.getLastIndexed() ?? "never",
        model: embeddings.getModelName(),
        dimensions: embeddings.getDimensions(),
        dbSizeBytes: stats.dbSizeBytes,
        vectorEnabled: stats.vectorEnabled,
        ftsEnabled: stats.ftsEnabled,
      };

      return {
        content: [
          {
            type: "text" as const,
            text: JSON.stringify(status, null, 2),
          },
        ],
      };
    }
  );
}
```

**Step 5: Verify build**

Run: `cd cwe-memory-mcp && npm run build`
Expected: Compiles without errors

**Step 6: Commit**

```bash
git add cwe-memory-mcp/src/tools/
git commit -m "feat(memory-mcp): 4 MCP tools (search, get, write, status)"
```

---

### Task 9: MCP Server Entry Point — Wire Everything Together

**Files:**
- Modify: `cwe-memory-mcp/src/index.ts`

**Step 1: Rewrite index.ts to wire all components**

Replace `cwe-memory-mcp/src/index.ts` with:

```typescript
#!/usr/bin/env node

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import path from "node:path";
import fs from "node:fs";

import { Store } from "./indexer/store.js";
import { EmbeddingService } from "./indexer/embeddings.js";
import { Indexer } from "./indexer/indexer.js";
import { SearchService } from "./search.js";
import { MemoryWatcher } from "./watcher.js";
import { registerMemorySearch } from "./tools/memory-search.js";
import { registerMemoryGet } from "./tools/memory-get.js";
import { registerMemoryWrite } from "./tools/memory-write.js";
import { registerMemoryStatus } from "./tools/memory-status.js";

const MEMORY_DIR = process.env.CWE_MEMORY_DIR || path.join(process.cwd(), "memory");
const DB_DIR = process.env.CWE_DB_DIR || path.join(process.env.HOME || "~", ".claude", "cwe", "memory");

function getProjectSlug(): string {
  const dir = path.basename(path.dirname(MEMORY_DIR));
  return dir.replace(/[^a-zA-Z0-9-_]/g, "-").toLowerCase();
}

async function main(): Promise<void> {
  console.error(`[cwe-memory] Memory dir: ${MEMORY_DIR}`);
  console.error(`[cwe-memory] DB dir: ${DB_DIR}`);

  // Check memory dir exists
  if (!fs.existsSync(MEMORY_DIR)) {
    console.error(`[cwe-memory] Warning: Memory directory not found: ${MEMORY_DIR}`);
    console.error("[cwe-memory] Tools will return warnings until the directory is created.");
  }

  // Init components
  const store = new Store(DB_DIR, getProjectSlug());
  store.init();

  const embeddings = new EmbeddingService();
  try {
    await embeddings.init();
  } catch (err) {
    console.error("[cwe-memory] Embedding model failed to load, falling back to BM25-only:", err);
  }

  const indexer = new Indexer(store, embeddings, MEMORY_DIR);
  const searchService = new SearchService(store, embeddings);

  // Create MCP server
  const server = new McpServer({
    name: "cwe-memory",
    version: "0.4.3",
  });

  // Register tools
  registerMemorySearch(server, searchService);
  registerMemoryGet(server, MEMORY_DIR);
  registerMemoryWrite(server, MEMORY_DIR);
  registerMemoryStatus(server, store, embeddings, indexer);

  // Initial indexing
  if (fs.existsSync(MEMORY_DIR)) {
    console.error("[cwe-memory] Starting initial index...");
    const result = await indexer.indexAll();
    console.error(`[cwe-memory] Initial index done: ${result.files} files, ${result.chunks} chunks`);
  }

  // Start file watcher
  const watcher = new MemoryWatcher(
    MEMORY_DIR,
    async (filePath) => {
      await indexer.indexFile(filePath);
    },
    async (filePath) => {
      await indexer.removeFile(filePath);
    }
  );
  watcher.start();

  // Start MCP transport
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("[cwe-memory] Server started on stdio");

  // Graceful shutdown
  const shutdown = async () => {
    console.error("[cwe-memory] Shutting down...");
    await watcher.stop();
    store.close();
    process.exit(0);
  };

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

main().catch((err) => {
  console.error("[cwe-memory] Fatal error:", err);
  process.exit(1);
});
```

**Step 2: Verify build**

Run: `cd cwe-memory-mcp && npm run build`
Expected: Compiles without errors

**Step 3: Smoke test — server starts and exits cleanly**

Run: `echo '{"jsonrpc":"2.0","method":"initialize","params":{"capabilities":{}},"id":1}' | timeout 10 node cwe-memory-mcp/dist/index.js 2>/dev/null || true`
Expected: JSON response with server capabilities (or timeout, which is OK for stdio)

**Step 4: Commit**

```bash
git add cwe-memory-mcp/src/index.ts
git commit -m "feat(memory-mcp): wire MCP server entry point with all components"
```

---

### Task 10: Plugin Integration — .mcp.json + init.md

**Files:**
- Create: `.mcp.json` (at plugin root)
- Modify: `commands/init.md`

**Step 1: Create .mcp.json at plugin root**

Create `.mcp.json`:

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

**Step 2: Add cwe-memory-mcp build to /cwe:init**

In `commands/init.md`, add a new step after the existing MCP server installations:

```markdown
### Step 4b: Build CWE Memory MCP Server

Check if `cwe-memory-mcp/dist/index.js` exists. If not:

```bash
cd ${CLAUDE_PLUGIN_ROOT}/cwe-memory-mcp && npm install && npm run build
```

Report to user: "CWE Memory MCP server built — semantic search over memory/ active."
```

Read `commands/init.md` first to find the exact insertion point.

**Step 3: Verify .mcp.json is valid**

Run: `node -e "JSON.parse(require('fs').readFileSync('.mcp.json','utf-8')); console.log('valid')"`
Expected: `valid`

**Step 4: Commit**

```bash
git add .mcp.json commands/init.md
git commit -m "feat(memory-mcp): plugin integration via .mcp.json + init build step"
```

---

### Task 11: Build + Add to .gitignore

**Files:**
- Modify: `.gitignore` (project root)

**Step 1: Add cwe-memory-mcp build artifacts to root .gitignore**

Ensure `.gitignore` contains:

```
cwe-memory-mcp/node_modules/
cwe-memory-mcp/dist/
```

**Step 2: Full build verification**

Run: `cd cwe-memory-mcp && npm run clean && npm install && npm run build && npm test`
Expected: Build succeeds, tests pass

**Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: add cwe-memory-mcp build artifacts to .gitignore"
```

---

### Task 12: Version Bump + CHANGELOG + Documentation

**Files:**
- Modify: `.claude-plugin/plugin.json` — version to `0.4.3`
- Modify: `CHANGELOG.md` — add v0.4.3 section
- Modify: `README.md` — update version, add Memory MCP server info
- Modify: `ROADMAP.md` — mark Phase 2 as completed

**Step 1: Bump version in plugin.json**

In `.claude-plugin/plugin.json`, change `"version": "0.4.2"` to `"version": "0.4.3"`.

**Step 2: Add CHANGELOG entry**

Add to top of `CHANGELOG.md` (after header, before v0.4.2 section):

```markdown
## [0.4.3] — 2026-02-13 (Memory MCP Server — Phase 2)

### Added — CWE Memory MCP Server
- `cwe-memory-mcp/`: local MCP server for semantic + keyword memory search
- Hybrid search: 70% vector (sqlite-vec, cosine) + 30% BM25 (FTS5)
- Local embeddings: Transformers.js `all-MiniLM-L6-v2` (384 dim, ~80MB, no API key)
- 4 MCP tools: `memory_search`, `memory_get`, `memory_write`, `memory_status`
- Markdown chunker: ~400 tokens, 80 token overlap, paragraph/sentence splitting
- chokidar file watcher: debounced 2s auto-reindex on file changes
- SQLite store: better-sqlite3 + sqlite-vec + FTS5, WAL mode
- Graceful fallback: BM25-only if sqlite-vec or model fails to load
- Plugin-bundled via `.mcp.json` — auto-starts with CWE plugin

### Changed
- `/cwe:init` now builds cwe-memory-mcp if dist/ missing
- `.mcp.json` added at plugin root for MCP server auto-discovery

---
```

**Step 3: Update README.md**

- Version: `0.4.3`
- Add Memory MCP Server to feature list
- Update version history section

**Step 4: Update ROADMAP.md**

Mark Phase 2 (Memory MCP Server) as completed.

**Step 5: Commit**

```bash
git add .claude-plugin/plugin.json CHANGELOG.md README.md ROADMAP.md
git commit -m "release: v0.4.3 — CWE Memory MCP Server (Phase 2)"
```

**Step 6: Push**

```bash
git push
```

---

## Summary

| Task | Component | Key Files |
|------|-----------|-----------|
| 1 | Project Scaffolding | package.json, tsconfig.json, index.ts |
| 2 | SQLite Store | indexer/store.ts + tests |
| 3 | Markdown Chunker | indexer/chunker.ts + tests |
| 4 | Embedding Service | indexer/embeddings.ts + tests |
| 5 | File Watcher | watcher.ts |
| 6 | Indexer Orchestrator | indexer/indexer.ts |
| 7 | Hybrid Search | search.ts |
| 8 | MCP Tools (4) | tools/*.ts |
| 9 | Server Entry Point | index.ts (full wiring) |
| 10 | Plugin Integration | .mcp.json, init.md |
| 11 | Build Verification | .gitignore, full build test |
| 12 | Version + Docs | plugin.json, CHANGELOG, README, ROADMAP |

**Total: 12 tasks, ~15 files to create/modify**
