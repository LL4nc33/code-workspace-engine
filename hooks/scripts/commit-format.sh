#!/usr/bin/env bash
# Validate commit message follows Conventional Commits format
# Triggered by PreToolUse on Bash(git commit*)
# Exit 0 = valid, Exit 2 = blocked with guidance

set -euo pipefail

TOOL_INPUT=$(cat)

# Use python3 for robust JSON parsing (handles escaped quotes, newlines, heredocs)
COMMAND=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('command', ''))
except:
    pass
" 2>/dev/null || true)

# If we couldn't extract the command, let it through
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only check git commit (not amend without message, merge commits, etc.)
case "$COMMAND" in
  git\ commit\ -m*|git\ commit\ --message*)
    ;;
  git\ commit*--no-verify*|git\ commit*--amend*)
    # Allow --no-verify and --amend to pass through
    exit 0
    ;;
  git\ commit*)
    # Other commit forms (interactive editor) — can't validate pre-emptively
    exit 0
    ;;
  *)
    exit 0
    ;;
esac

# Extract commit message — handles:
#   git commit -m "message"
#   git commit -m 'message'
#   git commit -m "$(cat <<'EOF'\nmessage\nEOF\n)"
MSG=$(echo "$COMMAND" | python3 -c "
import sys, re
cmd = sys.stdin.read()

# Try heredoc: -m \"\$(cat <<'EOF'\n..first line..\n...\nEOF\n)\"
m = re.search(r'-m\s+.*?<<.*?EOF.*?\n(.*?)\n.*?EOF', cmd, re.DOTALL)
if m:
    print(m.group(1).split('\n')[0].strip())
    sys.exit(0)

# Try quoted: -m \"message\" or -m 'message'
m = re.search(r'-m\s+[\"'\''](.*?)[\"\\'']', cmd)
if m:
    print(m.group(1).split('\n')[0].strip())
    sys.exit(0)

# Try unquoted: -m message
m = re.search(r'-m\s+(\S+)', cmd)
if m:
    print(m.group(1))
" 2>/dev/null || true)

# If we can't extract the message, let it through
if [ -z "$MSG" ]; then
  exit 0
fi

# Get first line of commit message
FIRST_LINE=$(echo "$MSG" | head -1)

# Conventional Commits regex
# type(scope)!: subject
# type!: subject
# type(scope): subject
# type: subject
PATTERN='^(feat|fix|chore|docs|style|refactor|test|perf|ci|build|revert)(\([a-z0-9_,/-]+\))?!?:\s.+'

if ! echo "$FIRST_LINE" | grep -qE "$PATTERN"; then
  echo ""
  echo "=== CWE Git Standards: Invalid Commit Message ==="
  echo ""
  echo "  Your message: \"$FIRST_LINE\""
  echo ""
  echo "  Expected format: <type>(<scope>): <subject>"
  echo ""
  echo "  Valid types: feat, fix, chore, docs, style, refactor, test, perf, ci, build, revert"
  echo ""
  echo "  Examples:"
  echo "    feat(auth): add JWT token refresh"
  echo "    fix: prevent crash on empty input"
  echo "    docs: update API documentation"
  echo "    chore: update dependencies"
  echo ""
  echo "  Use --no-verify to bypass (for emergencies)."
  echo ""
  exit 2
fi

exit 0
