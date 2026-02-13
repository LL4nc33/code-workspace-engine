---
name: database-standards
description: Database migration and schema standards. Use PROACTIVELY when creating migrations, modifying database schemas, writing SQL, or managing data lifecycle.
allowed-tools: Read, Grep, Glob, Bash
context: fork
agent: Explore
---

# Database Standards

## Instructions

Apply database standards from workflow/standards/database/ when:
- Creating new database migrations
- Modifying table schemas
- Writing raw SQL or ORM queries
- Setting up database infrastructure
- Planning data migration strategies

## Key Standards

### Migration Rules
- File naming: `{YYYYMMDD_HHMMSS}_{description}.{up|down}.sql`
- Every UP needs a DOWN (reversible migrations)
- One concern per migration file
- Use `IF NOT EXISTS` / `IF EXISTS` for idempotency
- No destructive changes in production without deprecation cycle

### Safe Schema Changes
- Adding columns: always with DEFAULT NULL initially
- Renaming: 4-step process (add new, copy, dual-read, drop old)
- Indexes: use CONCURRENTLY for zero-downtime
- Large tables (>100k rows): batch operations

### Environment Rules
- Development: auto-migrate, seed data OK
- Staging: auto-migrate, subset seed, destructive with approval
- Production: manual trigger, no seed, never destructive directly

### GDPR Compliance
- PII columns require review
- Data deletion needs audit trail
- Encryption-at-rest for sensitive columns
- EU-only data residency for new tables

## Application Triggers

This skill automatically applies when:
- Files matching `**/migrations/**`, `**/db/**`, `**/*.sql` are modified
- Database schema discussions occur
- ORM model definitions are created/modified
- Data lifecycle or retention is discussed

## Reference Files
- @workflow/standards/database/migrations.md
