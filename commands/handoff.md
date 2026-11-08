---
description: Write a structured handoff entry to another terminal, commit and push
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "AskUserQuestion"]
---

# Handoff — Write Entry

Write a structured handoff entry for another terminal and commit + push it.

## Step 1: Detect Context

```bash
BRANCH=$(git branch --show-current 2>/dev/null)
echo "$BRANCH"
```

Extract this terminal's number (e.g., `t1-frontend` → `1`).

If not in a multi-terminal branch:
> "Not in a multi-terminal worktree. Use `/cwe:init` to set up Multi-Terminal."

## Step 2: Gather Info

If `$ARGUMENTS` is provided, parse it for target and title. Otherwise, use AskUserQuestion:

**Question:** "Handoff an welches Terminal?"

List available terminals (from branch names or handoff files).

Then ask:
- **Title:** Short description of the handoff
- **Context:** What was done / current state
- **Action Required:** What the target terminal should do

## Step 3: Write Entry

Determine the correct handoff file. Files are named by the role pair (e.g., `frontend-backend.md`, `backend-qa.md`).

If no matching file exists, create one from the template.

Append the entry at the end of the file (before the last `---` if present, or at EOF):

```markdown
## [YYYY-MM-DD HH:MM] T{source} → T{target}: {title}

**Status:** 📋 TODO

**Kontext:** {context}

**Action Required:** {action}

---
```

Use the current date/time for the timestamp.

## Step 4: Commit + Push

```bash
git add shared/handoff/
git commit -m "chore(handoff): t{source}→t{target} {title}"
git push
```

## Step 5: Confirm

Show: "Handoff written and pushed. T{target} will pick it up on next sync."
