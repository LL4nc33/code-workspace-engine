#!/usr/bin/env bash
# On session stop: Notify if new idea observations exist

OBS_FILE="$HOME/.claude/cwe/idea-observations.toon"

# Skip if no observations
[ ! -f "$OBS_FILE" ] && exit 0
[ ! -s "$OBS_FILE" ] && exit 0

# Count ideas
COUNT=$(wc -l < "$OBS_FILE")

# Output message for Claude
echo "{\"systemMessage\":\"$COUNT idea(s) captured. Review with /cwe:innovator.\"}"

exit 0
