---
description: Delegate to architect agent - system design, ADRs, API design, spec shaping
allowed-tools: ["Task", "AskUserQuestion", "Write", "Read", "Glob"]
---

# Architect

Delegate to the **architect** agent for design and architecture work.

**Usage:** `/cwe:architect [topic]`

## Shape Mode ($ARGUMENTS contains "shape")

If user runs `/cwe:architect shape [feature-name]`, conduct a Shape-Spec Interview:

### Step 1: Read Context

Read these files if they exist:
- `workflow/product/mission.md` — Product vision
- `.claude/rules/_index.yml` — Standards index
- `workflow/config.yml` — Project configuration

### Step 2: Feature Name

If no feature name provided after "shape", use AskUserQuestion:
```
Question: "What feature should we shape?"
Header: "Feature"
Options:
  1. "New feature" - Build something new
  2. "Bug fix" - Fix an existing issue
  3. "Refactoring" - Improve existing code
  4. "Integration" - Connect to external service
```
Then ask for a short description via "Other".

### Step 3: Structured Interview

Ask these questions sequentially via AskUserQuestion:

```
Question: "What's the scope? What should this feature do?"
Header: "Scope"
Options:
  1. "Small — single component/file"
  2. "Medium — multiple files, one module"
  3. "Large — multiple modules, cross-cutting"
```

```
Question: "What's explicitly OUT of scope?"
Header: "Boundaries"
Options:
  1. "Just this feature, nothing else"
  2. "No breaking changes"
  3. "No new dependencies"
```
(User can type specifics via "Other")

```
Question: "Are there security or performance concerns?"
Header: "Concerns"
Options:
  1. "None expected"
  2. "Security-sensitive (auth, PII, encryption)"
  3. "Performance-critical (latency, throughput)"
  4. "Both security and performance"
```

```
Question: "What does 'done' look like?"
Header: "Done Criteria"
Options:
  1. "Working code + tests"
  2. "Working code + tests + docs"
  3. "Working code + tests + docs + review"
```

### Step 4: Generate Spec Folder

Create the spec folder using timestamp + slug:
```
workflow/specs/YYYY-MM-DD-HHMM-<feature-slug>/
```

Copy templates from `${CLAUDE_PLUGIN_ROOT}/templates/specs/` and fill in:
- `shape.md` — Populated from interview answers
- `plan.md` — Initial task breakdown (can be refined later)
- `references.md` — Auto-detect similar code with Glob/Read
- `standards.md` — Snapshot relevant standards from `.claude/rules/`

### Step 5: Handoff

Show summary of created spec folder, then suggest:
- "Run `/cwe:start` to continue with task breakdown"
- "Or edit the spec files directly"

---

## Interactive Mode (no topic, not "shape")

If user runs `/cwe:architect` without a topic, use AskUserQuestion:

```
Question: "What type of architecture work?"
Header: "Design Type"
Options:
  1. "Shape-Spec Interview" - Structured feature shaping (Recommended)
  2. "System design" - High-level architecture
  3. "API design" - Endpoints, contracts, schemas
  4. "Data model" - Database schema, relationships
```

If "Shape-Spec Interview" selected, follow the Shape Mode flow above.

If "System design", "API design", or "Data model" selected, also offer "ADR" as follow-up:

### If "System design":
```
Question: "What aspect?"
Header: "System"
Options:
  1. "New system" - Design from scratch
  2. "Extend existing" - Add to current architecture
  3. "Review current" - Analyze and document
  4. "Migration plan" - Move to new architecture
```

### If "API design":
```
Question: "API style?"
Header: "API Type"
Options:
  1. "REST" - Resource-based endpoints
  2. "GraphQL" - Query language
  3. "gRPC" - Protocol buffers
  4. "WebSocket" - Real-time communication
```

Then:
```
Question: "What should the API do?"
Header: "Purpose"
Options:
  1. "CRUD operations" - Create, read, update, delete
  2. "Authentication" - Login, tokens, sessions
  3. "Data retrieval" - Query, filter, paginate
  4. "Actions/Commands" - Trigger operations
```

### If "Data model":
```
Question: "Database type?"
Header: "Database"
Options:
  1. "SQL" - PostgreSQL, MySQL, SQLite
  2. "NoSQL Document" - MongoDB, Firestore
  3. "NoSQL Key-Value" - Redis, DynamoDB
  4. "Graph" - Neo4j, Neptune
```

### If "ADR":
```
Question: "What decision needs to be documented?"
Header: "ADR Topic"
Options:
  1. "Technology choice" - Framework, library, service
  2. "Pattern adoption" - Architecture pattern
  3. "Trade-off decision" - Pros/cons analysis
  4. "Policy change" - Process or convention
```

After selections, ask for context:
```
Question: "Any specific requirements or constraints?"
Header: "Context"
Options:
  1. "Show current architecture" - Analyze first
  2. "I have requirements" - (User types via Other)
  3. "No constraints" - Open design
```

## Direct Mode (topic provided)

If user provides a topic like `/cwe:architect design the payment system`, skip the menus and delegate directly.

## Process

Delegate using the Task tool:

```
subagent_type: architect
prompt: [constructed or provided topic]
```

## Plugin Integration

The architect agent automatically uses:
- **superpowers:writing-plans** - For detailed design plans
- **superpowers:brainstorming** - For exploring alternatives
- **feature-dev:code-architect** - For implementation blueprints
- **serena** - For codebase analysis

## Output

The architect agent produces:
- Architecture diagrams (Mermaid)
- ADR documents (when applicable)
- API specifications
- Data models
- Trade-off analysis
