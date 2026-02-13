#!/usr/bin/env bash
# On session stop: Notify if new idea observations exist for CURRENT project

# Consume stdin to prevent hook errors
cat > /dev/null 2>&1

# Determine project slug from $CLAUDE_PROJECT_DIR or PWD
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  PROJECT_SLUG=$(basename "$CLAUDE_PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
else
  PROJECT_SLUG="_global"
fi

IDEAS_FILE="$HOME/.claude/cwe/ideas/${PROJECT_SLUG}.jsonl"

# Skip if no observations for this project
[ ! -f "$IDEAS_FILE" ] && exit 0
[ ! -s "$IDEAS_FILE" ] && exit 0

# Count ideas for this project only
COUNT=$(wc -l < "$IDEAS_FILE" | tr -d ' ')

# Count by status
RAW=$(grep -c '"status":"raw"' "$IDEAS_FILE" 2>/dev/null || echo 0)

echo "{\"systemMessage\":\"${COUNT} idea(s) captured for ${PROJECT_SLUG} (${RAW} unreviewed). Review with /cwe:innovator.\"}"

exit 0
