#!/usr/bin/env bash
# CWE Python launcher — resolves a Python 3 interpreter across platforms.
#
# Why this exists:
#   hooks.json invokes the .py hooks. Linux/WSL has `python3`, but native
#   Windows (Git Bash) only has `python` / the `py` launcher. Hardcoding
#   `python3` broke every Python hook on Windows ("python3: command not found").
#
# Behaviour:
#   - Linux/WSL: picks `python3` first  -> behaviour unchanged.
#   - Windows:   falls back to `python`, then the `py` launcher.
#   - Resolves the target script relative to THIS file, then converts it to a
#     native Windows path via `cygpath` when present, so the Windows Python exe
#     can open it regardless of how CLAUDE_PLUGIN_ROOT is formatted (/d/.., D:/..).
#
# Usage (from hooks.json):
#   ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/_py.sh <script-name.py> [args...]
# stdin (the hook JSON payload) is forwarded untouched via exec.

set -euo pipefail

PY="$(command -v python3 || command -v python || command -v py || true)"
if [ -z "$PY" ]; then
  echo "[cwe] no python interpreter found (tried python3, python, py)" >&2
  exit 0  # non-blocking: never block the prompt just because Python is missing
fi

here="$(cd "$(dirname "$0")" 2>/dev/null && pwd)" || here="$(dirname "$0")"
script="$here/${1:?_py.sh: missing target script}"
shift

# Native Windows Python cannot open MSYS paths like /d/...; normalise on Windows.
if command -v cygpath >/dev/null 2>&1; then
  script="$(cygpath -w "$script")"
fi

exec "$PY" "$script" "$@"
