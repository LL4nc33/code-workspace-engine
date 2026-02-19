#!/usr/bin/env bash
# Session Stop Hook: Write session end to daily log
# Creates memory/YYYY-MM-DD.md if needed, appends session-end entry
# Cleans up daily logs older than 30 days

# Consume stdin to prevent hook errors (must be synchronous, no &)
cat > /dev/null 2>&1

# Determine project root
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  ROOT="$CLAUDE_PROJECT_DIR"
else
  ROOT="$PWD"
fi

# Only log if memory directory already exists (project is initialized with CWE memory)
# Do NOT create memory/ if it doesn't exist — user may be using Serena memory instead
if [ -d "${ROOT}/memory" ]; then
  DATE=$(date +%Y-%m-%d)
  TIME=$(date +%H:%M)
  DAILY_LOG="${ROOT}/memory/${DATE}.md"

  # Create daily log with header if it doesn't exist
  if [ ! -f "$DAILY_LOG" ]; then
    printf "# %s\n" "$DATE" > "$DAILY_LOG"
  fi

  # Append session-end entry
  printf "\n## %s — Session End\n- (summary pending — will be filled by Stop hook prompt)\n" "$TIME" >> "$DAILY_LOG"

  # Clean up old daily logs (keep last 30 days)
  find "${ROOT}/memory" -maxdepth 1 -name "????-??-??.md" -type f -mtime +30 -delete 2>/dev/null
fi

echo '{"systemMessage": "Session complete. Daily log updated. Run /cwe:start next time to continue."}'
