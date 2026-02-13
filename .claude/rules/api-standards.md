---
paths:
  - "**/api/**"
  - "**/routes/**"
  - "**/controllers/**"
---

# API Standards

## Response Format
- Consistent envelope: `{ success, data, meta }`
- Error envelope: `{ success: false, error: { code, message, details } }`
- Always include requestId for tracing
- Pagination: `{ page, pageSize, totalItems, totalPages }`

## Error Handling
- Error hierarchy with typed exceptions
- Never expose internal details in responses
- Machine-readable codes + human-readable messages
- GDPR: no PII in error messages or logs
- Log levels: ERROR (5xx), WARN (handled), INFO (lifecycle)

## Endpoint Naming
- Pattern: `/api/v{n}/{resource}` (plural nouns)
- HTTP verbs for actions (GET=read, POST=create, PUT=replace, PATCH=update, DELETE=remove)
- Query params: camelCase
- Response fields: camelCase

## Example
```typescript
// Success
return { success: true, data: user, meta: { timestamp, requestId } };

// Error
throw new ValidationError('USER_EMAIL_INVALID', 'Email format is not valid', [
  { field: 'email', issue: 'Must be a valid email address' }
]);
```

## Reference
- @workflow/standards/api/response-format.md
- @workflow/standards/api/error-handling.md
