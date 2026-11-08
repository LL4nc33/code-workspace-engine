#!/usr/bin/env bash
# Tests for the PreToolUse git hooks (safety-gate.sh, commit-format.sh).
#
# Each test builds a real PreToolUse payload (as Claude Code delivers it:
# {"tool_name":"Bash","tool_input":{"command":"..."}}), feeds it to the hook
# on stdin inside a throwaway git repo, and asserts the exit code.
#
# Exit 2 = hook blocked the action. Exit 0 = hook let it through.
#
# Run:  bash tests/hooks/test_git_hooks.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$(cd "$HERE/../../hooks/scripts" && pwd)"
PY="$(command -v python3 || command -v python || command -v py || true)"
[ -z "$PY" ] && { echo "FATAL: no python interpreter found"; exit 1; }

PASS=0
FAIL=0

# Build a PreToolUse JSON payload for a given Bash command (quoting-safe).
payload() {
  "$PY" -c 'import json,sys; print(json.dumps({"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$1"
}

# run_case <name> <hook-script> <command> <expected-exit> [setup-fn]
# setup-fn runs inside the temp repo before the hook, to stage files etc.
run_case() {
  local name="$1" hook="$2" cmd="$3" want="$4" setup="${5:-}"
  local repo; repo="$(mktemp -d)"
  (
    cd "$repo"
    git init -q
    git config user.email t@t.t
    git config user.name t
    printf '.env\n*.pem\n*.key\nnode_modules/\n.DS_Store\n' > .gitignore
    git add .gitignore >/dev/null 2>&1
    [ -n "$setup" ] && "$setup"
    payload "$cmd" | bash "$SCRIPTS/$hook" >/dev/null 2>&1
    echo $? > "$repo/.exit"
  )
  local got; got="$(cat "$repo/.exit" 2>/dev/null || echo 99)"
  rm -rf "$repo"
  if [ "$got" = "$want" ]; then
    echo "  PASS: $name (exit $got)"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $name — expected exit $want, got $got"
    FAIL=$((FAIL+1))
  fi
}

# --- setup helpers (run with CWD inside the temp repo) ---
# Secret fixtures are assembled at RUNTIME so this test file holds no contiguous
# secret literal — otherwise the (now working) safety gate would flag its own test.
SK="sk-"
GH="ghp_"
stage_anthropic_key() { printf '%sant-api03-abcDEF123456789_ghijKLMno-pqrstuvwx\n' "$SK" > conf.py; git add conf.py >/dev/null 2>&1; }
stage_private_key()  { printf -- '-----BEGIN RSA PRIVATE %s-----\nMIIabc123\n-----END RSA PRIVATE %s-----\n' KEY KEY > id.pem.txt; git add id.pem.txt >/dev/null 2>&1; }
stage_password()     { printf 'password = %s\n' "'hunter2'" > settings.py; git add settings.py >/dev/null 2>&1; }
stage_clean()        { printf 'def add(a, b):\n    return a + b\n' > app.py; git add app.py >/dev/null 2>&1; }

# add-mode: secret sits UNSTAGED in the working tree; `git add -A` must catch it.
untracked_secret()   { printf '%sant-api03-ABCdef123456789_ZZZ-qqqqqqqqqqqq\n' "$SK" > leak.py; }
# push-mode: HEAD carries a secret commit. No upstream → exercises the HEAD~1 fallback.
history_with_secret() {
  printf 'print("ok")\n' > base.py; git add base.py >/dev/null 2>&1; git commit -qm "feat: base"
  printf '%sant-api03-ABCdef123456789_ZZZ-qqqqqqqqqqqq\n' "$SK" > secret.py
  git add secret.py >/dev/null 2>&1; git commit -qm "feat: more"
}
# commit -am: a tracked file committed clean, then MODIFIED (unstaged) to hold a secret.
tracked_then_dirty_secret() {
  printf 'x = 1\n' > svc.py; git add svc.py >/dev/null 2>&1; git commit -qm "feat: svc"
  printf 'token = %s\n' "'${GH}abcdefghijklmnopqrstuvwxyz0123456789'" >> svc.py   # modify, do NOT stage
}
# commit -am: tracked file modified cleanly — must NOT block.
tracked_then_dirty_clean() {
  printf 'x = 1\n' > svc.py; git add svc.py >/dev/null 2>&1; git commit -qm "feat: svc"
  printf 'y = 2\n' >> svc.py
}
# "-a" appears only in the MESSAGE (not as a flag): the unstaged secret in b.py must
# NOT be scanned, so the clean staged change commits fine. Guards the argv parser.
dash_a_in_message_only() {
  printf 'ok\n' > b.py; git add b.py >/dev/null 2>&1; git commit -qm "feat: b"
  printf 'token = %s\n' "'${GH}abcdefghijklmnopqrstuvwxyz0123456789'" >> b.py   # unstaged secret
  printf 'x = 1\n' > a.py; git add a.py >/dev/null 2>&1                        # staged, clean
}

echo "== safety-gate.sh =="
run_case "blocks staged Anthropic key"  safety-gate.sh  'git commit -m "feat: add config"'  2  stage_anthropic_key
run_case "blocks staged private key"    safety-gate.sh  'git commit -m "feat: add key"'      2  stage_private_key
run_case "blocks hardcoded password"    safety-gate.sh  'git commit -m "feat: settings"'     2  stage_password
run_case "allows a clean commit"        safety-gate.sh  'git commit -m "feat: add adder"'     0  stage_clean
run_case "add -A catches unstaged secret" safety-gate.sh 'git add -A'                          2  untracked_secret
run_case "push catches secret in HEAD"   safety-gate.sh  'git push'                            2  history_with_secret
run_case "commit -am catches dirty secret" safety-gate.sh 'git commit -am "feat: svc"'         2  tracked_then_dirty_secret
run_case "commit -am allows clean change" safety-gate.sh 'git commit -am "feat: svc"'          0  tracked_then_dirty_clean
run_case "-a only in message, no false block" safety-gate.sh 'git commit -m "handle -a flag"'  0  dash_a_in_message_only

echo "== commit-format.sh =="
run_case "allows conventional commit"   commit-format.sh  'git commit -m "feat: add adder"'   0  stage_clean
run_case "blocks non-conventional msg"  commit-format.sh  'git commit -m "added a thing"'      2  stage_clean

echo "== branch-naming.sh =="
run_case "allows multi-terminal branch"   branch-naming.sh  'git checkout -b t2-qa'                     0
run_case "allows quoted valid branch"      branch-naming.sh  'git switch -c "fix/99-login"'              0
run_case "blocks invalid git branch name"  branch-naming.sh  'git branch BadBranchName'                  2
run_case "allows dotted chore branch"      branch-naming.sh  'git checkout -b chore/cc-2.1.3xx-update'   0
run_case "ignores non-creation checkout"   branch-naming.sh  'git checkout main'                         0
run_case "blocks worktree bad branch"      branch-naming.sh  'git worktree add ../wt -b BadName'         2

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
