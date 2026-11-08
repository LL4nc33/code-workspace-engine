#!/usr/bin/env bash
# Pre-commit safety gate: scan for secrets, PII, credentials
# Validates .gitignore completeness
# Exit 0 = safe, Exit 2 = blocked with report
#
# Triggered by PreToolUse on: git commit, git push, git add -A

set -euo pipefail

# Fail CLOSED: an unexpected scanner error exits 1, not 0. Paired with
# onFailure:"block" in hooks.json, a crash/timeout blocks the commit instead of
# silently letting it through. A clean scan exits 0; a real secret match exits 2.
trap 'exit 1' ERR

# Read tool input from stdin
TOOL_INPUT=$(cat)

# Robust JSON parsing (handles escaped quotes, heredocs, newlines)
PY=$(command -v python3 || command -v python || true)
if [ -z "$PY" ]; then
  # No python available — can't safely parse, let through
  exit 0
fi

COMMAND=$(printf '%s' "$TOOL_INPUT" | "$PY" -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except Exception:
    pass
" 2>/dev/null || true)

# Only check git commit, git push, git add -A/--all.
# Known limitation: variants like `git -c k=v commit`, `git -C <path> push`, or a
# quoted subcommand (`git 'push'`) are not recognized here — nor by the hooks.json
# `if` rules — and are therefore not scanned.
case "$COMMAND" in
  git\ commit*|git\ push*|git\ add\ -A*|git\ add\ --all*)
    ;;
  *)
    exit 0
    ;;
esac

run_scan() {
ISSUES=()
WARNINGS=()

# --- Secret Patterns ---
SECRET_PATTERNS=(
  'sk-[A-Za-z0-9_-]{20,}'                        # OpenAI / Anthropic keys (incl. sk-ant-...)
  'pk-[a-zA-Z0-9]{20,}'                          # Public keys
  'ANTHROPIC_API_KEY\s*=\s*["'\'']?[A-Za-z0-9]'  # Anthropic API key assignment
  'OPENAI_API_KEY\s*=\s*["'\'']?[A-Za-z0-9]'     # OpenAI API key assignment
  'AKIA[0-9A-Z]{16}'                              # AWS access key
  'ghp_[a-zA-Z0-9]{36}'                           # GitHub PAT
  'gho_[a-zA-Z0-9]{36}'                           # GitHub OAuth
  'github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}'   # GitHub fine-grained PAT
  'xoxb-[0-9]{10,}-[a-zA-Z0-9]+'                  # Slack bot token
  'xoxp-[0-9]{10,}-[a-zA-Z0-9]+'                  # Slack user token
  '-----BEGIN[A-Z0-9 ]*PRIVATE KEY-----'          # Private keys (bounded: matches real PEM headers, not this line)
)

PASSWORD_PATTERNS=(
  'password\s*=\s*["'\''][^$\{]'                  # password= with literal value (not variable)
  'passwd\s*=\s*["'\''][^$\{]'                    # passwd= with literal value
  'secret\s*=\s*["'\''][^$\{]'                    # secret= with literal value
)

DB_URL_PATTERNS=(
  'postgres://[^@]+:[^@]+@'                        # PostgreSQL with credentials
  'mongodb://[^@]+:[^@]+@'                         # MongoDB with credentials
  'mysql://[^@]+:[^@]+@'                           # MySQL with credentials
)

# --- Get the files to scan + where to read their content from (MODE) ---
if [[ "$COMMAND" == git\ commit* ]]; then
  MODE=commit
  FILES=$(git diff --cached --name-only 2>/dev/null || true)
  # `git commit -a/-am/--all` stages modified tracked files AS PART OF the commit,
  # i.e. AFTER this hook runs, so they are not in the index yet. Detect that and
  # also scan their working-tree content — otherwise a secret slips through `-am`.
  # Detect -a/-am/--all by parsing argv (NOT a substring match — the commit message
  # may legitimately contain "-a", which must not trigger the working-tree scan).
  COMMIT_ALL=$(printf '%s' "$COMMAND" | "$PY" -c '
import sys, shlex
try:
    toks = shlex.split(sys.stdin.read())
except ValueError:
    toks = sys.stdin.read().split()
args = toks[toks.index("commit") + 1:] if "commit" in toks else []
takes_value = {"-m","--message","-F","--file","-C","--reuse-message",
               "-c","--reedit-message","--author","--date","--template","-S","--gpg-sign"}
skip = False
allflag = 0
for a in args:
    if skip:
        skip = False; continue
    if a in takes_value:
        skip = True; continue
    if a == "--all" or (a.startswith("-") and not a.startswith("--") and "a" in a):
        allflag = 1
print(allflag)
' 2>/dev/null || echo 0)
  if [ "$COMMIT_ALL" = 1 ]; then
    EXTRA=$(git diff --name-only 2>/dev/null || true)   # modified tracked, not yet staged
  fi
elif [[ "$COMMAND" == git\ push* ]]; then
  MODE=push
  # All not-yet-pushed commits (@{u}..HEAD); fall back if no upstream is set.
  FILES=$(git diff --name-only @{u}..HEAD 2>/dev/null \
            || git diff --name-only HEAD~1 2>/dev/null || true)
else
  MODE=add
  # git add -A: every untracked + modified path. NUL-delimited, rename-safe.
  FILES=$(git status --porcelain -z -uall 2>/dev/null | "$PY" -c "
import sys
for rec in sys.stdin.buffer.read().split(b'\0'):
    if not rec:
        continue
    s = rec.decode('utf-8', 'replace')
    print(s[3:] if len(s) > 3 and s[2] == ' ' else s)
" 2>/dev/null || true)
fi

if [ -z "$FILES" ] && [ -z "${EXTRA:-}" ]; then
  exit 0
fi

# --- Scan files for secrets ---
# Read the content that is actually about to be shared, not the working tree:
#   commit → staged blob, push → committed blob at HEAD, add → working tree.
file_content() {
  local file="$1"
  case "${SCAN_SRC:-$MODE}" in
    commit) git show ":$file" 2>/dev/null || true ;;
    push)   git show "HEAD:$file" 2>/dev/null || true ;;
    *)      [ -f "$file" ] && cat "$file" 2>/dev/null || true ;;   # add / worktree
  esac
}

scan_file() {
  local file="$1"
  local pattern="$2"
  local category="$3"

  local matches
  # -e so a pattern beginning with '-' isn't treated as an option; -I skips binary.
  matches=$(file_content "$file" | grep -nEI -e "$pattern" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    while IFS= read -r match; do
      ISSUES+=("BLOCKED [$category] $file:$match")
    done <<< "$matches"
  fi
}

# Scan a newline-delimited file list, reading content per the current SCAN_SRC.
scan_list() {
  while IFS= read -r file; do
    [ -z "$file" ] && continue

    # Check for dangerous file types being committed
    case "$file" in
      *.pem|*.key|*.pfx|*.p12|*.crt)
        ISSUES+=("BLOCKED [certificate/key file] $file — should not be committed")
        continue
        ;;
      .env.example|.env.example.*)
        # Template-Dateien: absichtlich committed, kein Block
        ;;
      .env|.env.*|*.env)
        ISSUES+=("BLOCKED [env file] $file — should be in .gitignore")
        continue
        ;;
      id_rsa*|id_ed25519*|id_ecdsa*)
        ISSUES+=("BLOCKED [SSH key] $file — should never be committed")
        continue
        ;;
    esac

    # Skip node_modules, vendor, etc.
    case "$file" in
      node_modules/*|.venv/*|__pycache__/*|vendor/*|.git/*)
        continue
        ;;
    esac

    for pattern in "${SECRET_PATTERNS[@]}"; do
      scan_file "$file" "$pattern" "secret/API key"
    done
    for pattern in "${PASSWORD_PATTERNS[@]}"; do
      scan_file "$file" "$pattern" "hardcoded password"
    done
    for pattern in "${DB_URL_PATTERNS[@]}"; do
      scan_file "$file" "$pattern" "database credentials"
    done
  done <<< "$1"
}

SCAN_SRC="$MODE"
scan_list "$FILES"

# git commit -a/-am: also scan the working-tree content of modified tracked files
# (they get staged by the commit itself, after this hook, so --cached misses them).
if [ "${COMMIT_ALL:-0}" = 1 ] && [ -n "${EXTRA:-}" ]; then
  SCAN_SRC=worktree
  scan_list "$EXTRA"
fi

# --- Validate .gitignore ---
if [ -f ".gitignore" ]; then
  GITIGNORE_REQUIRED=(".env" "*.pem" "*.key" "node_modules/" ".DS_Store")
  for entry in "${GITIGNORE_REQUIRED[@]}"; do
    if ! grep -qF "$entry" .gitignore 2>/dev/null; then
      WARNINGS+=("WARNING [.gitignore] Missing entry: $entry")
    fi
  done
else
  WARNINGS+=("WARNING [.gitignore] No .gitignore file found!")
fi

# --- Report ---
if [ ${#ISSUES[@]} -gt 0 ]; then
  # exit 2 reports its reason via stderr; stdout is not shown to Claude on a block.
  {
    echo ""
    echo "=== CWE Safety Gate: BLOCKED ==="
    echo ""
    for issue in "${ISSUES[@]}"; do
      echo "  $issue"
    done
    echo ""
    if [ ${#WARNINGS[@]} -gt 0 ]; then
      for warning in "${WARNINGS[@]}"; do
        echo "  $warning"
      done
      echo ""
    fi
    echo "Fix these issues before committing."
    echo "(Claude Code PreToolUse hook — 'git --no-verify' does NOT bypass it.)"
    echo ""
  } >&2
  exit 2
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo ""
  echo "=== CWE Safety Gate: WARNINGS ==="
  echo ""
  for warning in "${WARNINGS[@]}"; do
    echo "  $warning"
  done
  echo ""
fi

return 0
}

# Run scan; any unexpected error trips the ERR trap → exit 1 (fail-closed, blocks)
run_scan
exit 0
