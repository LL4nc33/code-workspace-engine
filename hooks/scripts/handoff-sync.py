#!/usr/bin/env python3
"""Handoff Sync Hook (UserPromptSubmit): Sync handoff entries from other terminal branches.

Silently exits if not in a multi-terminal worktree (no tN- branch prefix).
Merges new entries from other branches into local handoff files using entry-count strategy.
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
if not re.match(r"t\d+-", branch):
    sys.exit(0)

# Find project root
try:
    root = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True, timeout=5
    ).stdout.strip()
except Exception:
    sys.exit(0)

handoff_dir = os.path.join(root, "shared", "handoff")
if not os.path.isdir(handoff_dir):
    sys.exit(0)

# Fetch latest from all remotes (quiet, best effort) — throttled to 60s
import tempfile
import time
fetch_marker = os.path.join(tempfile.gettempdir(), f"cwe-handoff-fetch-{branch.replace('/', '-')}.ts")
now = time.time()
try:
    last_fetch = os.path.getmtime(fetch_marker)
except OSError:
    last_fetch = 0

if now - last_fetch > 60:
    subprocess.run(
        ["git", "fetch", "--all", "--quiet"],
        capture_output=True, timeout=15
    )
    try:
        with open(fetch_marker, "w") as f:
            f.write(str(now))
    except OSError:
        pass

# Get list of other terminal branches
try:
    result = subprocess.run(
        ["git", "branch", "-r"],
        capture_output=True, text=True, timeout=5
    )
    remote_branches = []
    for raw in result.stdout.strip().split("\n"):
        b = raw.strip()
        if "->" in b or "/" not in b:
            continue  # skip symbolic refs like "origin/HEAD -> origin/main"
        short = b.split("/", 1)[1]  # branch name without the remote prefix
        # Exact match so t1-dev does not accidentally exclude t1-dev2.
        if re.match(r"t\d+-", short) and short != branch:
            remote_branches.append(b)
except Exception:
    remote_branches = []

if not remote_branches:
    sys.exit(0)

# Parse entries from a handoff file content
ENTRY_PATTERN = re.compile(
    r"^## \[\d{4}-\d{2}-\d{2} \d{2}:\d{2}\] T\d+ → T\d+: .+",
    re.MULTILINE
)

def parse_entries(content):
    """Extract entry headers as unique identifiers."""
    return set(ENTRY_PATTERN.findall(content))

# For each handoff file, check if other branches have more entries
synced = 0
for handoff_file in os.listdir(handoff_dir):
    if not handoff_file.endswith(".md") or handoff_file == "README.md":
        continue

    local_path = os.path.join(handoff_dir, handoff_file)
    relative_path = os.path.join("shared", "handoff", handoff_file)

    with open(local_path, "r") as f:
        local_content = f.read()

    local_entries = parse_entries(local_content)

    for remote_branch in remote_branches:
        try:
            result = subprocess.run(
                ["git", "show", f"{remote_branch}:{relative_path}"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode != 0:
                continue

            remote_content = result.stdout
            remote_entries = parse_entries(remote_content)

            # Find entries in remote but not in local
            new_entries = remote_entries - local_entries

            if new_entries:
                # Extract full entry blocks for new entries
                for entry_header in new_entries:
                    # Find the full entry block in remote content
                    idx = remote_content.find(entry_header)
                    if idx == -1:
                        continue

                    # Extract until next entry or end of file
                    rest = remote_content[idx:]
                    next_entry = ENTRY_PATTERN.search(rest[len(entry_header):])
                    if next_entry:
                        entry_block = rest[:len(entry_header) + next_entry.start()]
                    else:
                        entry_block = rest

                    # Append to local file
                    with open(local_path, "a") as f:
                        f.write("\n" + entry_block.strip() + "\n")

                    local_entries.add(entry_header)
                    synced += 1

        except Exception:
            continue

# Output result (use systemMessage for consistency with other hooks)
if synced > 0:
    # NOTE: do NOT auto-stage. Staging/committing is the user's decision
    # (via /cwe:handoff or manual git). We only write the local file.
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": f"[handoff-sync] Synced {synced} new handoff entries from other terminals.",
        }
    }))
else:
    # Silent exit — no message when nothing to sync
    sys.exit(0)
