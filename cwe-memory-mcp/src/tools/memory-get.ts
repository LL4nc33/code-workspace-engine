import { z } from "zod";
import fs from "node:fs";
import nodePath from "node:path";
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
      const fullPath = nodePath.join(memoryDir, relPath);

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
