#!/usr/bin/env bash
# SubagentStop Hook: Log agent execution for observability
# Receives agent metadata via stdin JSON

# Read stdin (agent result metadata)
INPUT=$(cat)

# Determine project root
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  ROOT="$CLAUDE_PROJECT_DIR"
else
  ROOT="$PWD"
fi

# Only log if memory directory exists (project is initialized)
# Only log if either memory or workflow directory exists (project is initialized)
[ ! -d "${ROOT}/memory" ] && [ ! -d "${ROOT}/workflow" ] && exit 0
# If only workflow exists but no memory, skip logging (no daily log target)
[ ! -d "${ROOT}/memory" ] && exit 0

mkdir -p "${ROOT}/memory"

# Extract agent name from input if available (best effort)
AGENT_NAME=$(echo "$INPUT" | grep -oP '"agent_type"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"agent_type"\s*:\s*"\([^"]*\)".*/\1/' 2>/dev/null)

if [ -n "$AGENT_NAME" ]; then
  DATE=$(date +%Y-%m-%d)
  TIME=$(date +%H:%M)
  DAILY_LOG="${ROOT}/memory/${DATE}.md"

  # Create daily log with header if it doesn't exist
  if [ ! -f "$DAILY_LOG" ]; then
    printf "# %s\n" "$DATE" > "$DAILY_LOG"
  fi

  # Append agent completion as lightweight entry
  printf "\n- %s agent=%s completed\n" "$TIME" "$AGENT_NAME" >> "$DAILY_LOG"
fi

exit 0
