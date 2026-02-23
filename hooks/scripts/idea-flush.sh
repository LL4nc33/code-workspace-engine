#!/usr/bin/env bash
# On session stop: Notify if new idea observations exist for CURRENT project

source "$(dirname "$0")/_lib.sh"

# Consume stdin to prevent hook errors
cat > /dev/null 2>&1

resolve_slug

IDEAS_FILE="$HOME/.claude/cwe/ideas/${PROJECT_SLUG}.jsonl"

# Skip if no observations for this project
[ ! -f "$IDEAS_FILE" ] && exit 0
[ ! -s "$IDEAS_FILE" ] && exit 0

# Track last reported count to avoid repeating the same message
FLUSH_STATE="$HOME/.claude/cwe/ideas/.flush-${PROJECT_SLUG}"
RAW=$(grep_count '"status":"raw"' "$IDEAS_FILE")

# Skip if no unreviewed ideas
[ "$RAW" -eq 0 ] 2>/dev/null && exit 0

# Skip if count unchanged since last flush (avoid repeating same message every turn)
LAST_RAW=$(cat "$FLUSH_STATE" 2>/dev/null || echo "0")
[ "$RAW" = "$LAST_RAW" ] && exit 0

# New ideas since last flush — notify and update state
echo "$RAW" > "$FLUSH_STATE"
json_msg "${RAW} new unreviewed idea(s) for ${PROJECT_SLUG}. Review with /cwe:innovator."

exit 0
