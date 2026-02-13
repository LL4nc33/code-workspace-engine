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
