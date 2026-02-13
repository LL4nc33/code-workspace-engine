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
