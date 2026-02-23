#!/usr/bin/env bash
# Session Stop Hook: Write session end to daily log
# Creates memory/YYYY-MM-DD.md if needed, appends session-end entry
# Cleans up daily logs older than 30 days

source "$(dirname "$0")/_lib.sh"

# Consume stdin to prevent hook errors (must be synchronous, no &)
cat > /dev/null 2>&1

resolve_root

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
  printf "\n## %s — Session End\n- Session ended, daily log entry written\n" "$TIME" >> "$DAILY_LOG"

  # Clean up old daily logs (keep last 30 days)
  find "${ROOT}/memory" -maxdepth 1 -name "????-??-??.md" -type f -mtime +30 -delete 2>/dev/null
fi

# Silent — no systemMessage to avoid confusing "Session complete" after every turn
exit 0
