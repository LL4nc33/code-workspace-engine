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
