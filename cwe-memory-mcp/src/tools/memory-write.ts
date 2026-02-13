import { z } from "zod";
import fs from "node:fs";
import nodePath from "node:path";
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
      const fullPath = nodePath.join(memoryDir, fileName);

      fs.mkdirSync(memoryDir, { recursive: true });

      let appendText = "\n";
      if (topic) {
        appendText += `## ${timeStr} — ${topic}\n\n`;
      }
      appendText += entry + "\n";

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
