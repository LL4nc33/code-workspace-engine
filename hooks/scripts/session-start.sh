#!/usr/bin/env bash
# SessionStart Hook: Status check + Memory injection for CWE
# Reads project memory (MEMORY.md + daily logs) for session continuity
# Outputs JSON: {"systemMessage": "..."}

# Consume stdin to prevent hook errors (must be synchronous, no &)
cat > /dev/null 2>&1

VERSION="Claude Workflow Engine v0.4.3"
MAX_MEMORY_CHARS=8000
MAX_MEMORY_LINES=200

# --- Determine project root ---
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
  ROOT="$CLAUDE_PROJECT_DIR"
else
  ROOT="$PWD"
fi

# --- Build status message ---
if [ -d "${ROOT}/workflow" ]; then
  STATUS="Ready"
  HINT="Run /cwe:start to continue or just describe what you need."
else
  STATUS="No project initialized"
  HINT="Run /cwe:init to start."
fi

# --- Check for idea count ---
PROJECT_SLUG=$(basename "$ROOT" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
IDEAS_FILE="$HOME/.claude/cwe/ideas/${PROJECT_SLUG}.jsonl"
IDEA_COUNT=0
if [ -f "$IDEAS_FILE" ]; then
  IDEA_COUNT=$(wc -l < "$IDEAS_FILE" | tr -d ' ')
fi

# --- JSON-escape a string ---
# Uses bash parameter expansion for backslash/quote/tab/CR (reliable),
# and sed only for newline joining (single pass, no multi-line escaping issues).
# Input: stdin. Output: stdout. Pure bash + minimal sed.
json_escape_stdin() {
  local content
  content=$(cat)
  if [ -z "$content" ]; then
    return
  fi
  # Order matters: backslashes first, then the rest
  content="${content//\\/\\\\}"
  content="${content//\"/\\\"}"
  content="${content//$'\t'/\\t}"
  content="${content//$'\r'/}"
  # Replace real newlines with literal \n using sed slurp
  printf '%s' "$content" | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'
}

# --- Read a file safely (up to N lines) ---
read_file_limited() {
  local filepath="$1"
  local maxlines="$2"
  if [ -f "$filepath" ]; then
    head -n "$maxlines" "$filepath" 2>/dev/null
  fi
}

# --- Determine yesterday's date (cross-platform) ---
get_yesterday() {
  local yesterday
  # Try GNU date first (Linux)
  yesterday=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$yesterday" ]; then
    # Try BSD date (macOS)
    yesterday=$(date -v-1d +%Y-%m-%d 2>/dev/null)
  fi
  printf '%s' "$yesterday"
}

# --- Build project memory block as real multi-line text ---
MEMORY_BLOCK=""

# 1. Read MEMORY.md (main project memory, up to 200 lines)
MEMORY_FILE="${ROOT}/memory/MEMORY.md"
MEMORY_CONTENT=$(read_file_limited "$MEMORY_FILE" "$MAX_MEMORY_LINES")
if [ -n "$MEMORY_CONTENT" ]; then
  MEMORY_BLOCK="=== PROJECT MEMORY (MEMORY.md) ===
${MEMORY_CONTENT}"
fi

# 2. Read today's daily log
TODAY=$(date +%Y-%m-%d)
TODAY_FILE="${ROOT}/memory/${TODAY}.md"
TODAY_CONTENT=$(read_file_limited "$TODAY_FILE" 100)
if [ -n "$TODAY_CONTENT" ]; then
  if [ -n "$MEMORY_BLOCK" ]; then
    MEMORY_BLOCK="${MEMORY_BLOCK}

"
  fi
  MEMORY_BLOCK="${MEMORY_BLOCK}=== TODAY (${TODAY}) ===
${TODAY_CONTENT}"
fi

# 3. Read yesterday's daily log
YESTERDAY=$(get_yesterday)
if [ -n "$YESTERDAY" ]; then
  YESTERDAY_FILE="${ROOT}/memory/${YESTERDAY}.md"
  YESTERDAY_CONTENT=$(read_file_limited "$YESTERDAY_FILE" 100)
  if [ -n "$YESTERDAY_CONTENT" ]; then
    if [ -n "$MEMORY_BLOCK" ]; then
      MEMORY_BLOCK="${MEMORY_BLOCK}

"
    fi
    MEMORY_BLOCK="${MEMORY_BLOCK}=== YESTERDAY (${YESTERDAY}) ===
${YESTERDAY_CONTENT}"
  fi
fi

# 4. Cap total memory at MAX_MEMORY_CHARS
if [ -n "$MEMORY_BLOCK" ]; then
  CHAR_COUNT=${#MEMORY_BLOCK}
  if [ "$CHAR_COUNT" -gt "$MAX_MEMORY_CHARS" ]; then
    MEMORY_BLOCK="${MEMORY_BLOCK:0:$MAX_MEMORY_CHARS}...[TRUNCATED]"
  fi
fi

# --- Idea info ---
IDEA_INFO=""
if [ "$IDEA_COUNT" -gt 0 ]; then
  IDEA_INFO=" | ${IDEA_COUNT} idea(s) captured"
fi

# --- Auto-delegation reminder (compact) ---
DELEGATION="Auto-delegation: fix/build->builder | explain->explainer | audit->security | deploy->devops | design->architect | brainstorm->innovator"

# --- Compose the full system message as real multi-line text ---
HEADER="${VERSION} | ${STATUS}. ${HINT}${IDEA_INFO} | ${DELEGATION}"

if [ -n "$MEMORY_BLOCK" ]; then
  FULL_MESSAGE="${HEADER}

PROJECT MEMORY:
${MEMORY_BLOCK}"
else
  FULL_MESSAGE="${HEADER}"
fi

# --- JSON-escape and output ---
ESCAPED=$(printf '%s' "$FULL_MESSAGE" | json_escape_stdin)

echo "{\"systemMessage\": \"${ESCAPED}\"}"
