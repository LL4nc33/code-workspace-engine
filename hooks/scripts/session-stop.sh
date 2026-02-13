#!/usr/bin/env bash
# Session Stop Hook: Simple end message
# Runs at session end

# Consume stdin to prevent hook errors
cat > /dev/null 2>&1 &

echo '{"systemMessage": "Session complete. Run /cwe:start next time to continue where you left off."}'
