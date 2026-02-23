#!/usr/bin/env bash
# SessionStart Hook: Status check + Memory injection for CWE
# Reads project memory (MEMORY.md + daily logs) for session continuity
# Outputs JSON: {"systemMessage": "..."}

source "$(dirname "$0")/_lib.sh"

# Consume stdin to prevent hook errors (must be synchronous, no &)
cat > /dev/null 2>&1

VERSION="Code Workspace Engine v0.6.2"
MAX_MEMORY_CHARS=8000
MAX_MEMORY_LINES=200

resolve_root

# --- Build status message ---
if [ -d "${ROOT}/workflow" ]; then
  STATUS="Ready"
  HINT="Run /cwe:start to continue or just describe what you need."
else
  STATUS="No project initialized"
  HINT="Run /cwe:init to start."
fi

# --- Check for idea count ---
resolve_slug
IDEAS_FILE="$HOME/.claude/cwe/ideas/${PROJECT_SLUG}.jsonl"
IDEA_COUNT=0
if [ -f "$IDEAS_FILE" ]; then
  IDEA_COUNT=$(line_count "$IDEAS_FILE")
fi

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
  yesterday=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null) || true
  if [ -z "$yesterday" ]; then
    # Try BSD date (macOS)
    yesterday=$(date -v-1d +%Y-%m-%d 2>/dev/null) || true
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
DELEGATION="Auto-delegation: fix/build->builder | explain->explainer | ask/discuss->ask | audit->security | deploy->devops | design->architect | brainstorm->innovator | workflow/process->guide"

# --- Compose the full system message ---
HEADER="${VERSION} | ${STATUS}. ${HINT}${IDEA_INFO} | ${DELEGATION}"

if [ -n "$MEMORY_BLOCK" ]; then
  FULL_MESSAGE="${HEADER}

PROJECT MEMORY:
${MEMORY_BLOCK}"
else
  FULL_MESSAGE="${HEADER}"
fi

# --- Output via safe JSON helper ---
json_msg "$FULL_MESSAGE"
