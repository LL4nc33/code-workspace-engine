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
    const vectorScores = new Map<string, number>();
    if (this.embeddings.isReady() && this.store.isVectorEnabled()) {
      const queryVec = await this.embeddings.embed(query);
      const vectorResults = this.store.searchVector(queryVec, overFetch);
      for (const r of vectorResults) {
        vectorScores.set(r.id, 1 - r.distance);
      }
    }

    // BM25 search
    const bm25Scores = new Map<string, number>();
    try {
      const ftsQuery = this.buildFtsQuery(query);
      const bm25Results = this.store.searchBM25(ftsQuery, overFetch);
      for (const r of bm25Results) {
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
        : bs;
      scored.push({ id, score });
    }

    scored.sort((a, b) => b.score - a.score);
    const topIds = scored.slice(0, limit);

    const results: SearchResult[] = [];
    for (const { id, score } of topIds) {
      const chunk = this.store.getChunkById(id);
      if (!chunk) continue;

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
    const words = query.trim().split(/\s+/).filter(Boolean);
    if (words.length === 0) return '""';
    return words.map((w) => `"${w.replace(/"/g, "")}"`).join(" OR ");
  }
}
