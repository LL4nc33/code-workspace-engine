# Architecture: {{PROJECT_NAME}}

## Overview

[High-level system description]

## Component Diagram

```mermaid
graph TB
    A[Component A] --> B[Component B]
    B --> C[Component C]
```

## Components

### Component A

- **Purpose:** [what it does]
- **Location:** `src/component-a/`
- **Dependencies:** [what it depends on]

### Component B

- **Purpose:** [what it does]
- **Location:** `src/component-b/`
- **Dependencies:** [what it depends on]

## Data Flow

```mermaid
sequenceDiagram
    participant User
    participant API
    participant DB
    User->>API: Request
    API->>DB: Query
    DB-->>API: Result
    API-->>User: Response
```

## Key Decisions

See [decisions/](decisions/) for Architecture Decision Records.

## Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| [Layer] | [Tech] | [Why] |
