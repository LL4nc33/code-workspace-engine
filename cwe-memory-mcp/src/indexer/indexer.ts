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
