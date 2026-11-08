#!/usr/bin/env bash
# Validate branch names on branch-CREATING git commands.
# PreToolUse(Bash). Exit 0 = ok / not applicable, Exit 2 = blocked (reason on stderr).
#
# Covers: git checkout -b, git switch -c, git branch <new>, git worktree add -b.
# Command + branch name are parsed in Python (tool_input.command) so quoting is
# handled portably — the old sed used GNU-only \s and tripped over quotes.

set -euo pipefail

PY=$(command -v python3 || command -v python || command -v py || true)
[ -z "$PY" ] && exit 0

TOOL_INPUT=$(cat)

BRANCH=$(printf '%s' "$TOOL_INPUT" | "$PY" -c '
import sys, json, shlex

try:
    cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "")
except Exception:
    print(""); sys.exit(0)

try:
    toks = shlex.split(cmd)          # also strips surrounding quotes
except ValueError:
    toks = cmd.split()

name = ""
if len(toks) >= 2 and toks[0] == "git":
    sub, args = toks[1], toks[2:]
    if sub in ("checkout", "switch"):
        flag = "-b" if sub == "checkout" else "-c"
        if flag in args and args.index(flag) + 1 < len(args):
            name = args[args.index(flag) + 1]
    elif sub == "branch":
        # Creation only: skip delete/move/rename/list forms.
        if not any(a in ("-d","-D","-m","-M","--delete","--move","-r","-a","--list","--edit-description") for a in args):
            pos = [a for a in args if not a.startswith("-")]
            if pos:
                name = pos[0]
    elif sub == "worktree" and args[:1] == ["add"] and "-b" in args:
        if args.index("-b") + 1 < len(args):
            name = args[args.index("-b") + 1]

print(name)
' 2>/dev/null || true)

# Nothing to validate (not a branch-creating command, or no name)
[ -z "$BRANCH" ] && exit 0

# Allowed: the project conventions PLUS multi-terminal worktree branches (tN-role).
PATTERN='^(main|develop|feature/[a-z0-9]+-[a-z0-9._-]+|fix/[a-z0-9]+-[a-z0-9._-]+|hotfix/[a-z0-9._-]+|chore/[a-z0-9._-]+|release/[0-9]+\.[0-9]+\.[0-9]+|t[0-9]+-[a-z0-9-]+)$'

if ! printf '%s' "$BRANCH" | grep -qE "$PATTERN"; then
  # exit 2 reports its reason via stderr; stdout is not shown to Claude on a block.
  {
    echo ""
    echo "=== CWE Git Standards: Invalid Branch Name ==="
    echo ""
    echo "  Your branch: \"$BRANCH\""
    echo ""
    echo "  Allowed patterns:"
    echo "    main, develop"
    echo "    feature/<ticket>-<description>"
    echo "    fix/<ticket>-<description>"
    echo "    hotfix/<description>"
    echo "    chore/<description>"
    echo "    release/<version>"
    echo "    t<N>-<role>            (multi-terminal worktrees)"
    echo ""
    echo "  Examples:"
    echo "    feature/123-user-auth   fix/456-login-crash"
    echo "    chore/update-deps       release/0.4.2       t2-qa"
    echo ""
    echo "  Rules: lowercase, hyphens, prefix required."
    echo ""
  } >&2
  exit 2
fi

exit 0
