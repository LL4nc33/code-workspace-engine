import { pipeline, type FeatureExtractionPipeline } from "@huggingface/transformers";

const MODEL_NAME = "Xenova/all-MiniLM-L6-v2";
const DIMENSIONS = 384;

export class EmbeddingService {
  private extractor: FeatureExtractionPipeline | null = null;
  private ready = false;

  async init(): Promise<void> {
    if (this.ready) return;
    console.error(`[cwe-memory] Loading embedding model: ${MODEL_NAME}`);
    this.extractor = await (pipeline as any)("feature-extraction", MODEL_NAME, {
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
