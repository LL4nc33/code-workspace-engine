#!/usr/bin/env bash
# Scan user prompts for idea keywords
# Write JSONL to ~/.claude/cwe/ideas/<project-slug>.jsonl (project-scoped)
# Migrates old .toon file on first run

IDEA_PATTERNS="idee|was wäre wenn|könnte man|vielleicht|alternativ|verbesserung|idea|what if|could we|maybe|alternative|improvement"

# Read stdin (user prompt)
PROMPT=$(cat)

# Check for idea patterns (case insensitive)
if ! echo "$PROMPT" | grep -iqE "$IDEA_PATTERNS"; then
  exit 0
fi

IDEAS_DIR="$HOME/.claude/cwe/ideas"
mkdir -p "$IDEAS_DIR"

# Determine project slug from $CLAUDE_PROJECT_DIR or PWD
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  PROJECT_SLUG=$(basename "$CLAUDE_PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
else
  PROJECT_SLUG="_global"
fi

# Migration: convert old .toon to JSONL on first run
OLD_TOON="$HOME/.claude/cwe/idea-observations.toon"
if [ -f "$OLD_TOON" ] && [ ! -f "$OLD_TOON.bak" ]; then
  while IFS= read -r line; do
    # Parse TOON format: i{d:MM-DD p:prompt text}
    if [[ "$line" =~ ^i\{d:([0-9-]+)\ p:(.*)\}$ ]]; then
      OLD_DATE="${BASH_REMATCH[1]}"
      OLD_PROMPT="${BASH_REMATCH[2]}"
      # Write to _global.jsonl (can't determine project from old format)
      printf '{"ts":"2025-%s","prompt":"%s","project":"_global","keywords":[],"status":"raw"}\n' \
        "$OLD_DATE" "$(echo "$OLD_PROMPT" | sed 's/"/\\"/g')" >> "$IDEAS_DIR/_global.jsonl"
    fi
  done < "$OLD_TOON"
  mv "$OLD_TOON" "$OLD_TOON.bak"
fi

# Extract matched keywords
MATCHED_KEYWORDS=$(echo "$PROMPT" | grep -ioE "$IDEA_PATTERNS" | tr '[:upper:]' '[:lower:]' | sort -u | paste -sd',' -)

# Truncate and escape prompt for JSON
CLEAN_PROMPT=$(echo "${PROMPT:0:300}" | tr '\n' ' ' | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')

# Write JSONL entry
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
printf '{"ts":"%s","prompt":"%s","project":"%s","keywords":[%s],"status":"raw"}\n' \
  "$TIMESTAMP" "$CLEAN_PROMPT" "$PROJECT_SLUG" \
  "$(echo "$MATCHED_KEYWORDS" | sed 's/,/","/g' | sed 's/^/"/;s/$/"/')" \
  >> "$IDEAS_DIR/${PROJECT_SLUG}.jsonl"

exit 0
