---
name: testing-standards
description: Testing and code coverage standards. Use PROACTIVELY when writing tests, configuring test frameworks, reviewing test coverage, or setting up CI test pipelines.
allowed-tools: Read, Grep, Glob, Bash
context: fork
agent: Explore
---

# Testing Standards

## Instructions

Apply testing standards from workflow/standards/testing/ when:
- Writing new test files
- Reviewing test coverage reports
- Configuring test frameworks (Jest, Vitest, Pytest)
- Setting up test pipelines in CI
- Deciding what to test vs. skip

## Key Standards

### Coverage Targets
- Unit tests: 70% minimum, 85% target, 95% critical paths
- Integration: 50% minimum, 70% target
- E2E: Key flows covered (happy path + primary error paths)

### Test Structure (AAA)
- Arrange: Set up test data and preconditions
- Act: Execute the function/action under test
- Assert: Verify expected outcomes

### File Naming
- Jest/Vitest: `{module}.test.ts`
- Pytest: `test_{module}.py`
- Go: `{module}_test.go`

### What to Test
- Always: business logic, error paths, edge cases, security boundaries
- Consider: integrations, data transforms, state machines
- Skip: framework internals, trivial accessors, generated code

### CI Rules
- Tests block merge (required check)
- Coverage decrease > 2% blocks merge
- Flaky test = broken test (fix immediately)
- No real PII in test data

## Application Triggers

This skill automatically applies when:
- Files matching `**/*.test.*`, `**/test_*`, `**/*_test.*` are created/modified
- Test configuration files are modified
- Coverage reports are discussed
- CI pipeline test stages are configured

## Reference Files
- @workflow/standards/testing/coverage.md
