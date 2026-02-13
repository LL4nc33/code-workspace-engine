---
description: Develop ideas from the collected backlog, brainstorming, creative solutions
allowed-tools: ["Task", "AskUserQuestion", "Read", "Bash"]
---

# Innovator

Delegate to the **innovator** agent for creative work and idea development.

**Usage:** `/cwe:innovator [topic]`

## Interactive Mode (no topic provided)

First, check for captured ideas:
```bash
cat ~/.claude/cwe/idea-observations.toon 2>/dev/null | wc -l
```

### If ideas were captured:

Show count and use AskUserQuestion:
```
Question: "I found X captured idea(s). What would you like to do?"
Header: "Ideas"
Options:
  1. "Review captured ideas" - See what was collected
  2. "Brainstorm new ideas" - Start fresh
  3. "Check idea backlog" - Review workflow/ideas.md
  4. "Clear captured ideas" - Start over
```

### If "Review captured ideas":

Read and display the ideas, then:
```
Question: "Which idea interests you?"
Header: "Select Idea"
Options:
  [Dynamically list captured ideas]
```

Then:
```
Question: "What would you like to do with this idea?"
Header: "Action"
Options:
  1. "Explore further" - Generate alternatives
  2. "Add to backlog" - Save to ideas.md as 'new'
  3. "Plan implementation" - Mark as 'planned'
  4. "Discard" - Remove from observations
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

Then:
```
Question: "What area or topic?"
Header: "Topic"
Options:
  1. "Current project" - Based on codebase
  2. "Specific feature" - (User types via Other)
  3. "Technical approach" - Architecture/patterns
  4. "User experience" - UX improvements
```

### If "Check idea backlog":

Read `workflow/ideas.md` and show ideas by status:
```
Question: "Filter by status?"
Header: "Status"
Options:
  1. "All ideas" - Show everything
  2. "New" - Unreviewed ideas
  3. "Exploring" - In discussion
  4. "Planned" - Ready for implementation
```

Then for selected idea:
```
Question: "Update status?"
Header: "New Status"
Options:
  1. "Keep current" - No change
  2. "Mark as exploring" - Needs more thought
  3. "Mark as planned" - Ready to implement
  4. "Mark as rejected" - Won't do
```

## Direct Mode (topic provided)

If user provides a topic like `/cwe:innovator alternatives for state management`, skip the menus and delegate directly.

## Ideas Format (workflow/ideas.md)

```markdown
### [Idea Title]
- **Status:** new | exploring | planned | rejected
- **Source:** auto-captured | user
- **Date:** YYYY-MM-DD
- **Context:** Relevant files, current state
- **Notes:** Discussion, pros/cons
```

## Process

Delegate using the Task tool:

```
subagent_type: innovator
prompt: [constructed or provided topic]
```

## Plugin Integration

The innovator agent has:
- READ-ONLY access for code
- WRITE access for workflow/ideas.md only
- Web access for inspiration and research
- **superpowers:brainstorming** - Creative ideation
- Divergent thinking methodology
- "What if" exploration

## Output

The innovator produces:
- 3-5 alternative approaches
- Pros/cons for each
- Feasibility assessment
- Suggested next steps
