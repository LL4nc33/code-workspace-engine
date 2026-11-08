#!/usr/bin/env bash
# Scan user prompts for idea keywords
# Write JSONL to ~/.claude/cwe/ideas/<project-slug>.jsonl (project-scoped)
# Migrates old .toon file on first run

source "$(dirname "$0")/_lib.sh"

IDEA_PATTERNS="idee|was wäre wenn|könnte man|vielleicht|alternativ|verbesserung|idea|what if|could we|maybe|alternative|improvement"

PY=$(_cwe_py)

# Read the hook payload and extract the ACTUAL prompt text (not the raw JSON).
STDIN_DATA=$(cat)
if [ -n "$PY" ]; then
  PROMPT=$(printf '%s' "$STDIN_DATA" | "$PY" -c 'import sys, json
try:
    d = json.load(sys.stdin); print(d.get("prompt", d.get("message", "")))
except Exception:
    pass' 2>/dev/null || true)
else
  PROMPT="$STDIN_DATA"
fi

[ -z "$PROMPT" ] && exit 0

# Check for idea patterns (case insensitive) in the prompt itself.
if ! printf '%s' "$PROMPT" | grep -iqE "$IDEA_PATTERNS"; then
  exit 0
fi

IDEAS_DIR="$HOME/.claude/cwe/ideas"
mkdir -p "$IDEAS_DIR"

resolve_slug

# Migration: convert old .toon to JSONL on first run
OLD_TOON="$HOME/.claude/cwe/idea-observations.toon"
if [ -f "$OLD_TOON" ] && [ ! -f "$OLD_TOON.bak" ]; then
  while IFS= read -r line; do
    # Parse TOON format: i{d:MM-DD p:prompt text}
    if [[ "$line" =~ ^i\{d:([0-9-]+)\ p:(.*)\}$ ]]; then
      OLD_DATE="${BASH_REMATCH[1]}"
      OLD_PROMPT=$(json_escape "${BASH_REMATCH[2]}")
      printf '{"ts":"2025-%s","prompt":"%s","project":"_global","keywords":[],"status":"raw"}\n' \
        "$OLD_DATE" "$OLD_PROMPT" >> "$IDEAS_DIR/_global.jsonl"
    fi
  done < "$OLD_TOON"
  mv "$OLD_TOON" "$OLD_TOON.bak"
fi

# Extract matched keywords (comma-joined)
MATCHED_KEYWORDS=$(printf '%s' "$PROMPT" | grep -ioE "$IDEA_PATTERNS" | tr '[:upper:]' '[:lower:]' | sort -u | paste -sd',' -) || true

# Build + append the JSONL record via python json.dumps (robust escaping).
OUT="$IDEAS_DIR/${PROJECT_SLUG}.jsonl"
if [ -n "$PY" ]; then
  printf '%s' "$PROMPT" | "$PY" -c 'import sys, json, datetime
prompt = sys.stdin.read()[:300]
kw = [k for k in sys.argv[2].split(",") if k]
rec = {"ts": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
       "prompt": prompt, "project": sys.argv[1], "keywords": kw, "status": "raw"}
print(json.dumps(rec, ensure_ascii=False))' "$PROJECT_SLUG" "$MATCHED_KEYWORDS" >> "$OUT"
else
  CLEAN_PROMPT=$(json_escape "${PROMPT:0:300}")
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  printf '{"ts":"%s","prompt":"%s","project":"%s","keywords":[],"status":"raw"}\n' \
    "$TIMESTAMP" "$CLEAN_PROMPT" "$PROJECT_SLUG" >> "$OUT"
fi

exit 0
