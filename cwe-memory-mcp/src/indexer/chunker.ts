import { createHash } from "node:crypto";

const TARGET_TOKENS = 400;
const OVERLAP_TOKENS = 80;
// Rough approximation: 1 token ≈ 4 characters
const CHARS_PER_TOKEN = 4;
const TARGET_CHARS = TARGET_TOKENS * CHARS_PER_TOKEN;
const OVERLAP_CHARS = OVERLAP_TOKENS * CHARS_PER_TOKEN;

export interface Chunk {
  id: string;
  text: string;
  startLine: number;
  endLine: number;
  hash: string;
}

interface Paragraph {
  text: string;
  startLine: number;
  endLine: number;
}

function splitIntoParagraphs(content: string): Paragraph[] {
  const lines = content.split("\n");
  const paragraphs: Paragraph[] = [];
  let currentText = "";
  let currentStart = 1;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineNum = i + 1;

    if (line.trim() === "" && currentText.trim() !== "") {
      paragraphs.push({
        text: currentText.trim(),
        startLine: currentStart,
        endLine: lineNum - 1,
      });
      currentText = "";
      currentStart = lineNum + 1;
    } else {
      if (currentText === "" && line.trim() !== "") {
        currentStart = lineNum;
      }
      currentText += (currentText ? "\n" : "") + line;
    }
  }

  if (currentText.trim() !== "") {
    paragraphs.push({
      text: currentText.trim(),
      startLine: currentStart,
      endLine: lines.length,
    });
  }

  return paragraphs;
}

function splitLongParagraph(para: Paragraph): Paragraph[] {
  if (para.text.length <= TARGET_CHARS) return [para];

  const sentences = para.text.match(/[^.!?]+[.!?]+\s*/g) || [para.text];
  const result: Paragraph[] = [];
  let currentText = "";

  for (const sentence of sentences) {
    if (currentText.length + sentence.length > TARGET_CHARS && currentText.length > 0) {
      const linesInChunk = currentText.split("\n").length;
      result.push({
        text: currentText.trim(),
        startLine: para.startLine + (result.length > 0 ? result.length : 0),
        endLine: para.startLine + linesInChunk - 1,
      });
      currentText = "";
    }
    currentText += sentence;
  }

  if (currentText.trim()) {
    result.push({
      text: currentText.trim(),
      startLine: para.startLine + result.length,
      endLine: para.endLine,
    });
  }

  return result;
}

function makeChunkId(filePath: string, index: number, hash: string): string {
  return createHash("sha256")
    .update(`${filePath}:${index}:${hash}`)
    .digest("hex")
    .slice(0, 16);
}

function makeContentHash(text: string): string {
  return createHash("sha256").update(text).digest("hex").slice(0, 12);
}

export function chunkMarkdown(content: string, filePath: string): Chunk[] {
  if (!content.trim()) return [];

  const rawParagraphs = splitIntoParagraphs(content);
  const paragraphs = rawParagraphs.flatMap(splitLongParagraph);

  if (paragraphs.length === 0) return [];

  const chunks: Chunk[] = [];
  let currentParagraphs: Paragraph[] = [];
  let currentLength = 0;

  for (let i = 0; i < paragraphs.length; i++) {
    const para = paragraphs[i];

    if (currentLength + para.text.length > TARGET_CHARS && currentParagraphs.length > 0) {
      const text = currentParagraphs.map((p) => p.text).join("\n\n");
      const hash = makeContentHash(text);
      chunks.push({
        id: makeChunkId(filePath, chunks.length, hash),
        text,
        startLine: currentParagraphs[0].startLine,
        endLine: currentParagraphs[currentParagraphs.length - 1].endLine,
        hash,
      });

      let overlapLength = 0;
      let overlapStart = currentParagraphs.length;
      for (let j = currentParagraphs.length - 1; j >= 0; j--) {
        if (overlapLength + currentParagraphs[j].text.length > OVERLAP_CHARS) break;
        overlapLength += currentParagraphs[j].text.length;
        overlapStart = j;
      }
      currentParagraphs = currentParagraphs.slice(overlapStart);
      currentLength = currentParagraphs.reduce((sum, p) => sum + p.text.length, 0);
    }

    currentParagraphs.push(para);
    currentLength += para.text.length;
  }

  if (currentParagraphs.length > 0) {
    const text = currentParagraphs.map((p) => p.text).join("\n\n");
    const hash = makeContentHash(text);
    chunks.push({
      id: makeChunkId(filePath, chunks.length, hash),
      text,
      startLine: currentParagraphs[0].startLine,
      endLine: currentParagraphs[currentParagraphs.length - 1].endLine,
      hash,
    });
  }

  return chunks;
}
