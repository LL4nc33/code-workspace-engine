---
name: api-standards
description: API design standards including response formats, error handling, and endpoint conventions. Use PROACTIVELY when designing APIs, implementing endpoints, handling errors, or reviewing API contracts.
allowed-tools: Read, Grep, Glob, Bash
context: fork
agent: Explore
---

# API Standards

## Instructions

Apply API standards from workflow/standards/api/ when:
- Designing new API endpoints
- Implementing request/response handling
- Creating error handling logic
- Reviewing API contracts or OpenAPI specs
- Setting up API middleware (auth, validation, rate limiting)

## Key Standards

### Response Format
- Consistent envelope: `{ success, data, meta }`
- Error envelope: `{ success: false, error: { code, message, details } }`
- Always include requestId for tracing
- Pagination: `{ page, pageSize, totalItems, totalPages }`

### Error Handling
- Error hierarchy with typed exceptions
- Never expose internal details in responses
- Machine-readable codes + human-readable messages
- GDPR: no PII in error messages or logs
- Log levels: ERROR (5xx), WARN (handled), INFO (lifecycle)

### Endpoint Naming
- Pattern: `/api/v{n}/{resource}` (plural nouns)
- HTTP verbs for actions (GET=read, POST=create, PUT=replace, PATCH=update, DELETE=remove)
- Query params: camelCase
- Response fields: camelCase

## Application Triggers

This skill automatically applies when:
- Files matching `**/api/**`, `**/routes/**`, `**/controllers/**` are modified
- Error handling patterns are implemented
- HTTP status codes are being chosen
- API documentation is written

## Usage Examples

```typescript
// Standard success response
return { success: true, data: user, meta: { timestamp, requestId } };

// Standard error response
throw new ValidationError('USER_EMAIL_INVALID', 'Email format is not valid', [
  { field: 'email', issue: 'Must be a valid email address' }
]);
```

## Reference Files
- @workflow/standards/api/response-format.md
- @workflow/standards/api/error-handling.md
