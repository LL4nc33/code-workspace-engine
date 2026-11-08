#!/usr/bin/env bash
# Shared helpers for CWE hook scripts
# Source this at the top of any hook that outputs JSON:
#   source "$(dirname "$0")/_lib.sh"

# --- Resolve a Python interpreter once ---
_cwe_py() { command -v python3 || command -v python || command -v py || true; }

# --- Legacy JSON string escape (fallback only) ---
# json_dumps below is preferred. This hand-escape misses control chars other
# than TAB/CR/LF and is kept only for the no-Python fallback path.
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\t'/\\t}"
  s="${s//$'\r'/}";  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

# --- Emit JSON {"systemMessage": "<text>"} — shown to the USER only ---
# Built with python json.dumps so any control character stays valid JSON.
# Usage: json_msg "message with $variables"
json_msg() {
  local py; py="$(_cwe_py)"
  if [ -n "$py" ]; then
    printf '%s' "$1" | "$py" -c 'import sys,json; print(json.dumps({"systemMessage": sys.stdin.read()}))'
  else
    printf '{"systemMessage": "%s"}\n' "$(json_escape "$1")"
  fi
}

# --- Emit JSON additionalContext — injected into CLAUDE's context window ---
# Use this (not json_msg) whenever Claude needs the information, since
# systemMessage is only displayed to the user. Delivered via hookSpecificOutput
# for the given hook event (e.g. SessionStart, UserPromptSubmit).
# Usage: json_ctx <HookEventName> "text"
json_ctx() {
  local event="$1" py; py="$(_cwe_py)"
  if [ -n "$py" ]; then
    printf '%s' "$2" | "$py" -c 'import sys,json; print(json.dumps({"hookSpecificOutput":{"hookEventName":sys.argv[1],"additionalContext":sys.stdin.read()}}))' "$event"
  else
    printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$event" "$(json_escape "$2")"
  fi
}

# --- Safe grep -c wrapper ---
# grep -c returns exit code 1 on zero matches, which breaks || chains.
# Usage: COUNT=$(grep_count "pattern" "file")
grep_count() {
  local pattern="$1"
  local file="$2"
  local n
  n=$(grep -c "$pattern" "$file" 2>/dev/null) || true
  printf '%s' "${n:-0}"
}

# --- Determine project root ---
# Sets ROOT variable from CLAUDE_PROJECT_DIR or PWD.
# Usage: resolve_root
resolve_root() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    ROOT="$CLAUDE_PROJECT_DIR"
  else
    ROOT="$PWD"
  fi
}

# --- Determine project slug ---
# Sanitized, lowercase, hyphenated basename of project dir.
# Usage: resolve_slug  (sets PROJECT_SLUG)
resolve_slug() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    PROJECT_SLUG=$(basename "$CLAUDE_PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9_-]//g')
  else
    PROJECT_SLUG="_global"
  fi
}

# --- Safe wc -l wrapper ---
# wc -l can have leading spaces on some platforms.
# Usage: COUNT=$(line_count "file")
line_count() {
  local file="$1"
  local n
  n=$(wc -l < "$file" 2>/dev/null) || true
  # Strip whitespace (macOS wc pads with spaces)
  printf '%s' "${n// /}"
}
