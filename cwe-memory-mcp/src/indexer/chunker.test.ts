import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { chunkMarkdown } from "./chunker.js";

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

  it("should return empty array for empty content", () => {
    const chunks = chunkMarkdown("", "memory/test.md");
    assert.equal(chunks.length, 0);
  });
});
