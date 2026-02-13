#!/usr/bin/env bash
# Scan user prompts for idea keywords
# Append to ~/.claude/cwe/idea-observations.toon (TOON format)

IDEA_PATTERNS="idee|was wäre wenn|könnte man|vielleicht|alternativ|feature|verbesserung|idea|what if|could we|maybe|alternative|improvement"

# Read stdin (user prompt)
PROMPT=$(cat)

# Check for idea patterns (case insensitive)
if echo "$PROMPT" | grep -iE "$IDEA_PATTERNS" > /dev/null; then
  DIR="$HOME/.claude/cwe"
  mkdir -p "$DIR"
  # TOON format: i{d:MM-DD p:prompt}
  DATE=$(date +%m-%d)
  # Escape special chars and truncate
  CLEAN_PROMPT=$(echo "${PROMPT:0:200}" | tr '\n' ' ' | sed 's/[{}]//g')
  echo "i{d:$DATE p:$CLEAN_PROMPT}" >> "$DIR/idea-observations.toon"
fi

exit 0
