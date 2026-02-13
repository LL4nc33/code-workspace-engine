---
description: Delegate to quality agent - testing, coverage, quality metrics
allowed-tools: ["Task", "AskUserQuestion"]
---

# Quality

Delegate to the **quality** agent for QA work.

**Usage:** `/cwe:quality [task]`

## Health Mode ($ARGUMENTS contains "health")

If user runs `/cwe:quality health`:

Delegate to quality agent with health-dashboard skill:
- Full project health report (code quality, deps, docs, git, security)
- Health score (0-100) with rating
- CODEOWNERS generation (optional)

---

## Interactive Mode (no task provided)

If user runs `/cwe:quality` without a task, use AskUserQuestion:

```
Question: "What type of quality check?"
Header: "QA Task"
Options:
  1. "Project health" - Full health dashboard (Recommended)
  2. "Run tests" - Execute test suite
  3. "Coverage analysis" - Check test coverage
  4. "Code review" - Review recent changes
```

If "Project health" selected, follow the Health Mode flow above.

### If "Run tests":
```
Question: "Which tests?"
Header: "Test Scope"
Options:
  1. "All tests" - Full test suite
  2. "Unit tests only" - Fast, isolated tests
  3. "Integration tests" - Component interaction
  4. "Failed tests" - Re-run failures only
```

### If "Coverage analysis":
```
Question: "Coverage focus?"
Header: "Coverage"
Options:
  1. "Overall report" - Full coverage summary
  2. "Uncovered code" - Show gaps
  3. "Recent changes" - Coverage of new code
  4. "Specific file/folder" - (User types via Other)
```

### If "Code review":
```
Question: "What to review?"
Header: "Review Scope"
Options:
  1. "Uncommitted changes" - Current work
  2. "Last commit" - Most recent commit
  3. "Branch diff" - Compare to main
  4. "Specific files" - (User types via Other)
```

Then:
```
Question: "Review focus?"
Header: "Focus"
Options:
  1. "Bugs & logic errors" - Correctness
  2. "Code style" - Conventions, readability
  3. "Performance" - Efficiency issues
  4. "All aspects" - Comprehensive review
```

### If "Quality metrics":
```
Question: "Which metrics?"
Header: "Metrics"
Options:
  1. "Complexity" - Cyclomatic complexity
  2. "Maintainability" - Code health score
  3. "Duplication" - Copy-paste detection
  4. "All metrics" - Full report
```

After selections, output preference:
```
Question: "How detailed?"
Header: "Detail"
Options:
  1. "Summary" - Quick overview
  2. "Detailed" - Full breakdown
  3. "Actionable" - Only issues to fix
```

## Direct Mode (task provided)

If user provides a task like `/cwe:quality check coverage`, skip the menus and delegate directly.

## Process

Delegate using the Task tool:

```
subagent_type: quality
prompt: [constructed or provided task]
```

## Plugin Integration

The quality agent has:
- READ-ONLY + test commands
- Coverage analysis tools (nyc, coverage)
- Complexity metrics (eslint, pylint)
- **superpowers:requesting-code-review** - Structured reviews
- **superpowers:verification-before-completion** - Verify quality
- **feature-dev:code-reviewer** - Deep code analysis
