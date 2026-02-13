#!/usr/bin/env bash
# SessionStart Hook: Status check + Auto-Delegation hint for CWE
# Provides workflow context at session start

# Consume stdin to prevent hook errors
cat > /dev/null 2>&1 &

# Find project root (where .git or workflow/ exists)
find_root() {
  local dir="${PWD}"
  while [ "${dir}" != "/" ]; do
    if [ -d "${dir}/.git" ] || [ -d "${dir}/workflow" ]; then
      echo "${dir}"
      return
    fi
    dir="$(dirname "${dir}")"
  done
  echo "${PWD}"
}

ROOT="$(find_root)"

# Build status message
VERSION="Claude Workflow Engine v0.4.0a"

if [ -d "${ROOT}/workflow" ]; then
  STATUS="Ready"
  HINT="Run /cwe:start to continue or just describe what you need."
else
  STATUS="No project initialized"
  HINT="Run /cwe:init to start."
fi

# Auto-delegation reminder (compact)
DELEGATION="Auto-delegation: fix/build->builder | explain->explainer | audit->security | deploy->devops | design->architect | brainstorm->innovator"

# Output combined message
echo "{\"systemMessage\": \"${VERSION} | ${STATUS}. ${HINT} | ${DELEGATION}\"}"
