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
