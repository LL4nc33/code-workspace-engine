#!/usr/bin/env python3
"""Multi-Terminal Session Init Hook (SessionStart): Detect worktree context and load handoff summary.

Silently exits if not in a multi-terminal worktree (no tN- branch prefix).
When in a worktree, provides context about the terminal role and pending handoffs.
"""

import json
import os
import re
import subprocess
import sys

# Consume stdin
stdin_data = sys.stdin.read()

# Detect branch
try:
    branch = subprocess.run(
        ["git", "branch", "--show-current"],
        capture_output=True, text=True, timeout=5
    ).stdout.strip()
except Exception:
    sys.exit(0)

# Silent exit if not in a multi-terminal worktree
match = re.match(r"t(\d+)-(.+)", branch)
if not match:
    sys.exit(0)

terminal_num = match.group(1)
role = match.group(2)

# Find project root
try:
    root = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True, timeout=5
    ).stdout.strip()
except Exception:
    sys.exit(0)

# Check for handoff directory
handoff_dir = os.path.join(root, "shared", "handoff")
pending_todos = 0
in_progress = 0
blocked = 0

if os.path.isdir(handoff_dir):
    target_pattern = re.compile(rf"→ T{terminal_num}:")

    for handoff_file in os.listdir(handoff_dir):
        if not handoff_file.endswith(".md") or handoff_file == "README.md":
            continue

        filepath = os.path.join(handoff_dir, handoff_file)
        try:
            with open(filepath, "r") as f:
                content = f.read()

            # Only count entries targeting this terminal
            lines = content.split("\n")
            current_target = False
            for line in lines:
                if line.startswith("## [") and target_pattern.search(line):
                    current_target = True
                elif line.startswith("## ["):
                    current_target = False

                if current_target:
                    if "📋 TODO" in line:
                        pending_todos += 1
                    elif "🔄 IN PROGRESS" in line:
                        in_progress += 1
                    elif "❌ BLOCKED" in line:
                        blocked += 1
        except Exception:
            continue

# Build context message
parts = [f"Multi-Terminal T{terminal_num} ({role})"]

if pending_todos > 0 or in_progress > 0 or blocked > 0:
    status_parts = []
    if pending_todos > 0:
        status_parts.append(f"{pending_todos} TODO")
    if in_progress > 0:
        status_parts.append(f"{in_progress} in progress")
    if blocked > 0:
        status_parts.append(f"{blocked} BLOCKED")
    parts.append(f"Handoffs: {', '.join(status_parts)}")
    parts.append("Run /cwe:check-handoff for details.")
else:
    parts.append("No pending handoffs.")

# Check for terminal prompt file
prompt_dir = os.path.join(root, "terminal-prompts")
prompt_file = None
if os.path.isdir(prompt_dir):
    for f in os.listdir(prompt_dir):
        if f.startswith(f"T{terminal_num}-"):
            prompt_file = os.path.join(prompt_dir, f)
            break

if prompt_file:
    parts.append(f"Terminal prompt: {prompt_file}")

context_msg = " | ".join(parts)

# SessionStart context must reach Claude via additionalContext; there is no
# "result" output field (the old key was silently ignored).
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": context_msg,
    }
}))
