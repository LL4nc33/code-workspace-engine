---
description: Delegate to architect agent - system design, ADRs, API design
allowed-tools: ["Task", "AskUserQuestion"]
---

# Architect

Delegate to the **architect** agent for design and architecture work.

**Usage:** `/cwe:architect [topic]`

## Interactive Mode (no topic provided)

If user runs `/cwe:architect` without a topic, use AskUserQuestion:

```
Question: "What type of architecture work?"
Header: "Design Type"
Options:
  1. "System design" - High-level architecture
  2. "API design" - Endpoints, contracts, schemas
  3. "Data model" - Database schema, relationships
  4. "ADR" - Architecture Decision Record
```

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
