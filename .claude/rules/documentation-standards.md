---
paths:
  - "**/*"
---

# Documentation Standards (Always Active)

## After Every Non-Trivial Change

Update documentation so the project remembers across sessions (when applicable and memory/ directory exists):

### Memory Updates (REQUIRED)
- **memory/MEMORY.md** — Keep the index current (max 200 lines). Update: what changed, current state, key decisions.
- **Today's Daily Log (memory/YYYY-MM-DD.md)** — Append entries for this session. Use `## HH:MM — Topic` format. Include: what was done, decisions, files changed.
- **memory/decisions.md** — Log any design decisions with context, alternatives considered, and rationale.
- **memory/patterns.md** — Record new patterns or conventions established.
- **memory/project-context.md** — Update if tech stack, priorities, or team structure changed.

### Project Docs (WHEN AFFECTED)
- **CHANGELOG.md** — Add entry under current version section for any user-visible change.
- **docs/README.md** — Update if features, installation, or usage changed.
- **docs/ARCHITECTURE.md** — Update if components, data flow, or structure changed.
- **docs/API.md** — Update if endpoints changed.
- **docs/SETUP.md** — Update if dependencies or setup steps changed.
- **VERSION** — Only via `/cwe:devops release`, never manually.

### What Counts as "Non-Trivial"
- New feature or component
- Architecture or design decision
- Dependency added or removed
- API endpoint added or changed
- Bug fix with root cause worth remembering
- Configuration or infrastructure change

### What Does NOT Need Documentation
- Typo fixes, formatting, whitespace
- Internal refactoring with no behavior change
- Work-in-progress that will change again soon

## Memory Format

Keep memory entries concise and scannable:

```markdown
## [Date] — [Summary]
- What: [1 sentence]
- Why: [1 sentence]
- Files: [list of key files changed]
- Decision: [if applicable]
```
