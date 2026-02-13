---
description: Delegate to researcher agent - analysis, documentation, reports
allowed-tools: ["Task", "AskUserQuestion"]
---

# Researcher

Delegate to the **researcher** agent for analysis and documentation work.

**Usage:** `/cwe:researcher [task]`

## Docs Mode ($ARGUMENTS starts with "docs")

If user runs `/cwe:researcher docs [subcommand]`:

- `docs update` → Delegate to researcher agent with project-docs skill: scan codebase, update all docs
- `docs check` → Delegate to researcher agent: validate docs freshness, output report
- `docs adr [topic]` → Delegate to researcher agent: create new ADR in docs/decisions/

If no subcommand after "docs", use AskUserQuestion:
```
Question: "What docs task?"
Header: "Docs"
Options:
  1. "Update all docs" - Scan codebase, refresh docs (Recommended)
  2. "Check freshness" - Validate docs are current
  3. "Create ADR" - New Architecture Decision Record
```

---

## Interactive Mode (no task provided)

If user runs `/cwe:researcher` without a task, use AskUserQuestion:

```
Question: "What type of research?"
Header: "Research"
Options:
  1. "Documentation" - Update, check, or create docs (Recommended)
  2. "Analyze codebase" - Understand patterns and structure
  3. "Compare options" - Evaluate alternatives
  4. "Generate report" - Create formal report
```

If "Documentation" selected, follow the Docs Mode flow above.

### If "Analyze codebase":
```
Question: "What to analyze?"
Header: "Analysis"
Options:
  1. "Architecture" - System structure
  2. "Patterns" - Design patterns used
  3. "Dependencies" - External dependencies
  4. "Code quality" - Health metrics
```

Then:
```
Question: "Analysis depth?"
Header: "Depth"
Options:
  1. "Quick overview" - Summary only
  2. "Detailed analysis" - Full breakdown
  3. "Specific area" - (User types via Other)
```

### If "Document":
```
Question: "Document what?"
Header: "Document"
Options:
  1. "API" - Endpoints, contracts
  2. "Architecture" - System design
  3. "Getting started" - Onboarding guide
  4. "Specific feature" - (User types via Other)
```

Then:
```
Question: "Output format?"
Header: "Format"
Options:
  1. "Markdown" - Standard docs
  2. "README section" - For README.md
  3. "ADR" - Architecture Decision Record
  4. "Wiki page" - Formatted for wiki
```

### If "Compare options":
```
Question: "Compare what?"
Header: "Comparison"
Options:
  1. "Frameworks/libraries" - Technology options
  2. "Approaches" - Implementation strategies
  3. "Tools" - Development tools
  4. "Something specific" - (User types via Other)
```

Then:
```
Question: "Comparison criteria?"
Header: "Criteria"
Options:
  1. "Performance" - Speed, efficiency
  2. "Developer experience" - Ease of use
  3. "Ecosystem" - Community, support
  4. "All factors" - Comprehensive
```

### If "Generate report":
```
Question: "Report type?"
Header: "Report"
Options:
  1. "Technical assessment" - Code/architecture review
  2. "Dependency audit" - Package analysis
  3. "Progress report" - Project status
  4. "Custom report" - (User types via Other)
```

## Direct Mode (task provided)

If user provides a task like `/cwe:researcher document the API`, skip the menus and delegate directly.

## Process

Delegate using the Task tool:

```
subagent_type: researcher
prompt: [constructed or provided task]
```

## Plugin Integration

The researcher agent has:
- READ-ONLY access
- **serena** MCP tools for pattern discovery
- **superpowers:brainstorming** for exploring options
- **feature-dev:code-explorer** for deep analysis
- Web access for external research

## Output

Research produces:
- Structured reports
- Comparison tables
- Recommendations with rationale
- Action items when applicable
