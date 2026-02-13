---
paths:
  - "**/migrations/**"
  - "**/db/**"
  - "**/*.sql"
  - "**/models/**"
  - "**/schema/**"
---

# Database Standards

## Migration Rules
- File naming: `{YYYYMMDD_HHMMSS}_{description}.{up|down}.sql`
- Every UP needs a DOWN (reversible migrations)
- One concern per migration file
- Use `IF NOT EXISTS` / `IF EXISTS` for idempotency
- No destructive changes in production without deprecation cycle

## Safe Schema Changes
- Adding columns: always with DEFAULT NULL initially
- Renaming: 4-step process (add new, copy, dual-read, drop old)
- Indexes: use CONCURRENTLY for zero-downtime
- Large tables (>100k rows): batch operations

## Environment Rules
- Development: auto-migrate, seed data OK
- Staging: auto-migrate, subset seed, destructive with approval
- Production: manual trigger, no seed, never destructive directly

## GDPR Compliance
- PII columns require review
- Data deletion needs audit trail
- Encryption-at-rest for sensitive columns
- EU-only data residency for new tables

## Reference
- @workflow/standards/database/migrations.md
