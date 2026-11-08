#!/usr/bin/env bash
# SessionEnd / PreCompact Hook: append an entry to today's daily log.
# Creates memory/YYYY-MM-DD.md if needed, cleans up logs older than 30 days.
#
# The SAME script is wired to SessionEnd and PreCompact, so it labels the entry
# by hook_event_name — a compaction is NOT a session end.

source "$(dirname "$0")/_lib.sh"

# Capture stdin (must be synchronous, no &) to learn which event fired.
STDIN_DATA=$(cat 2>/dev/null || true)
PY=$(_cwe_py)
EVENT=""
if [ -n "$PY" ]; then
  EVENT=$(printf '%s' "$STDIN_DATA" | "$PY" -c 'import sys, json
try:
    print(json.load(sys.stdin).get("hook_event_name", ""))
except Exception:
    pass' 2>/dev/null || true)
fi

case "$EVENT" in
  PreCompact) LABEL="Context Compacted"; NOTE="Pre-compact snapshot — session still active" ;;
  *)          LABEL="Session End";       NOTE="Session ended, daily log entry written" ;;
esac

resolve_root

# Only log if memory/ already exists (project initialized with CWE memory).
# Do NOT create memory/ — the user may be using Serena memory instead.
if [ -d "${ROOT}/memory" ]; then
  DATE=$(date +%Y-%m-%d)
  TIME=$(date +%H:%M)
  DAILY_LOG="${ROOT}/memory/${DATE}.md"

  if [ ! -f "$DAILY_LOG" ]; then
    printf "# %s\n" "$DATE" > "$DAILY_LOG"
  fi

  printf "\n## %s — %s\n- %s\n" "$TIME" "$LABEL" "$NOTE" >> "$DAILY_LOG"

  # Clean up old daily logs (keep last 30 days)
  find "${ROOT}/memory" -maxdepth 1 -name "????-??-??.md" -type f -mtime +30 -delete 2>/dev/null
fi

json_msg "Daily log updated (${LABEL})."
