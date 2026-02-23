---
description: MUSS VERWENDET WERDEN für Brainstorming, Ideen-Entwicklung, kreative Lösungsansätze und Idea-Backlog-Review. Experte für kreative Ideation.
allowed-tools: ["Task", "AskUserQuestion", "Read", "Write", "Bash"]
---

# Innovator

Delegate to the **innovator** agent for creative work and idea development.

**Usage:** `/cwe:innovator [mode]`

## Modes (via $ARGUMENTS)

### Default (no args) — Current project ideas

1. Determine project slug from `$CLAUDE_PROJECT_DIR`
2. Read raw observations from `~/.claude/cwe/ideas/<project-slug>.jsonl`
3. Read curated backlog from `workflow/ideas.md`
4. Present: new observations count, backlog status
5. Ask which to explore

### `all` — Cross-project overview

Read ALL `.jsonl` files from `~/.claude/cwe/ideas/`, group by project.
Show transferable ideas between projects.

### `review` — Interactive triage

Walk through each raw observation (status: "raw"), ask: Keep / Develop / Reject?
Update `workflow/ideas.md` with decisions.
Update JSONL status from "raw" to "reviewed".

### `develop <idea>` — Deep-dive on specific idea

Use ideation methodology on a specific idea from the backlog.

## Interactive Mode (default, no args)

First, check for captured ideas:
```bash
PROJECT_SLUG=$(basename "$CLAUDE_PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
wc -l < ~/.claude/cwe/ideas/${PROJECT_SLUG}.jsonl 2>/dev/null || echo 0
```

### If ideas were captured:

Show count and use AskUserQuestion:
```
Question: "I found X captured idea(s) for this project. What would you like to do?"
Header: "Ideas"
Options:
  1. "Review new ideas" - Triage unreviewed observations
  2. "Brainstorm new ideas" - Start fresh
  3. "Check idea backlog" - Review workflow/ideas.md
  4. "Cross-project view" - Ideas from all projects
```

### If "Review new ideas":

Read the JSONL file, filter for `"status":"raw"`, display each:
```
Question: "Idea from <date>: '<prompt excerpt>' — What do you think?"
Header: "Triage"
Options:
  1. "Keep & develop" - Add to backlog as 'exploring'
  2. "Keep for later" - Add to backlog as 'new'
  3. "Reject" - Mark as rejected
  4. "Skip" - Review later
```

### If no ideas captured or "Brainstorm new ideas":

```
Question: "What kind of brainstorming?"
Header: "Brainstorm"
Options:
  1. "Feature ideas" - New functionality
  2. "Improvements" - Enhance existing features
  3. "Alternatives" - Different approaches
  4. "What-if exploration" - Hypothetical scenarios
```

### If "Check idea backlog":

Read `workflow/ideas.md` and show ideas by status.

## Ideas Format (workflow/ideas.md)

```markdown
### [Idea Title]
- **Status:** new | exploring | planned | rejected
- **Source:** auto-captured | user
- **Date:** YYYY-MM-DD
- **Context:** Relevant files, current state
- **Notes:** Discussion, pros/cons
```

## JSONL Format (~/.claude/cwe/ideas/<project>.jsonl)

```json
{"ts":"2025-02-13T14:30:00Z","prompt":"was wäre wenn...","project":"my-project","keywords":["was wäre wenn"],"status":"raw"}
```

## Process

Delegate using the Task tool:

```
subagent_type: innovator
prompt: [constructed from mode + context]
```
