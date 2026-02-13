---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/test_*"
  - "**/*_test.*"
  - "**/__tests__/**"
  - "**/tests/**"
---

# Testing Standards

## Coverage Targets
- Unit tests: 70% minimum, 85% target, 95% critical paths
- Integration: 50% minimum, 70% target
- E2E: Key flows covered (happy path + primary error paths)

## Test Structure (AAA)
- Arrange: Set up test data and preconditions
- Act: Execute the function/action under test
- Assert: Verify expected outcomes

## File Naming
- Jest/Vitest: `{module}.test.ts`
- Pytest: `test_{module}.py`
- Go: `{module}_test.go`

## What to Test
- Always: business logic, error paths, edge cases, security boundaries
- Consider: integrations, data transforms, state machines
- Skip: framework internals, trivial accessors, generated code

## CI Rules
- Tests block merge (required check)
- Coverage decrease > 2% blocks merge
- Flaky test = broken test (fix immediately)
- No real PII in test data

## Reference
- @workflow/standards/testing/coverage.md
