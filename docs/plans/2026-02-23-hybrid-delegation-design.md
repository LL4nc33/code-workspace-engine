# Hybrid Delegation Design

**Date:** 2026-02-23
**Status:** Approved
**Problem:** CWE's agent delegation doesn't work — Claude defaults to builder or handles tasks itself instead of routing to specialized agents.

## Root Cause Analysis

CWE's delegation relies entirely on prose instructions (CLAUDE.md routing table + auto-delegation skill). The model rationalizes skipping delegation: "I can handle this myself." Key issues:

1. **CLAUDE.md routing table is noise** — duplicates what auto-delegation skill already has, adds ~3KB of context that distracts rather than steers
2. **auto-delegation skill is never proactively invoked** — despite "Use PROACTIVELY" in description, the model doesn't call it
3. **Agent descriptions are too generic** — "Delegate to builder agent" doesn't create urgency to actually delegate
4. **Builder bias** — most requests contain "build/fix/implement" keywords, and the model defaults to doing the work itself

## Inspiration

Theo's video "Delete your CLAUDE.md" (2026-02-23) presents research showing:
- Developer-written context files: only +4% improvement
- LLM-generated context files: -3% degradation
- Cost increase: 20%+ from unnecessary exploration
- Core insight: **if the model can find info in the codebase, don't put it in context files**

## Solution: 3-Pillar Hybrid Delegation

### Pillar 1: Intent Router Hook (NEW)

A Python script (`hooks/scripts/intent-router.py`) registered as UserPromptSubmit hook.

**How it works:**
1. Reads user prompt from stdin JSON
2. Keyword-matches against agent patterns (regex, not LLM)
3. Returns a `systemMessage` with explicit routing instruction

**Example output:**
```json
{"systemMessage": "CWE routing: This request matches agent 'architect' (keywords: design, architecture). Use Task tool with subagent_type='cwe:architect' to delegate this work."}
```

**Why this works:** systemMessage from hooks has higher priority than prose in CLAUDE.md. It's a concrete, actionable instruction — not a suggestion.

**Multi-agent detection:** When keywords match 2+ agents, the hook suggests the delegator skill instead.

**Exclusions:** The hook does NOT route when:
- User typed a /command (explicit intent)
- Prompt is a simple question (< 10 words, ends with ?)
- Prompt contains "manual" or "no delegation"

### Pillar 2: Minimal CLAUDE.md

Reduce from 98 lines (~3.5KB) to ~5 lines (~200 bytes):

```markdown
# CWE v0.5.1

Orchestration plugin. Delegation via hooks — follow systemMessage routing hints.

## Mistakes to avoid
- Don't handle tasks yourself when a CWE agent exists for it
- Don't skip memory updates after changes (memory/MEMORY.md, CHANGELOG.md)
- Run /cwe:help if unsure about available commands
```

**What's removed and why:**
- 6 Principles table → philosophy, not behavior correction
- Intent→Agent table → hook handles routing now
- Decision Flow → hook + auto-delegation skill have this
- Idea Capture → hook does this automatically
- Quick Reference → "pink elephants" effect (mentioning all agents biases toward them)

### Pillar 3: Sharp Agent Descriptions

Update all 10 agent frontmatter `description` fields to use "MUST use when..." pattern:

| Agent | Current | New |
|-------|---------|-----|
| builder | Delegate to builder agent - implementation, bug fixes, code changes | MUST use when user asks to implement, fix, build, create, or refactor code. Never handle code changes in main chat. |
| architect | Delegate to architect agent - system design, ADRs, API design, spec shaping | MUST use when user asks about system design, architecture, ADRs, API design, or spec shaping. Read-only analysis agent. |
| quality | Delegate to quality agent - testing, coverage, quality metrics | MUST use when user asks about testing, coverage, quality metrics, or code review. |
| security | Delegate to security agent - audits, vulnerability assessment, OWASP | MUST use when user asks about security audits, vulnerabilities, OWASP, GDPR, or CVEs. |
| devops | Delegate to devops agent - CI/CD, Docker, infrastructure, releases | MUST use when user asks about deployment, Docker, CI/CD, Kubernetes, Terraform, or releases. |
| researcher | Delegate to researcher agent - analysis, documentation, reports | MUST use when user asks to analyze, document, research, or compare code/architecture. |
| explainer | Delegate to explainer agent - explanations, code walkthroughs, learning | MUST use when user asks to explain code, concepts, or wants a walkthrough. |
| ask | Ask questions about the project, discuss ideas (READ-ONLY) | MUST use when user wants to discuss, ask questions, or think about approaches without making changes. |
| innovator | Develop ideas from the collected backlog, brainstorming, creative solutions | MUST use when user wants to brainstorm, explore ideas, or review the idea backlog. |
| guide | Delegate to guide agent - process improvement, workflow optimization | MUST use when user asks about workflow, process improvement, or pattern optimization. |

### Fallback Chain

```
User prompt arrives
    ↓
Intent Router Hook → systemMessage with routing hint
    ↓
Claude reads systemMessage → delegates via Task tool
    ↓ (if hook didn't match)
Agent descriptions → Claude matches from system reminder
    ↓ (if still unclear)
auto-delegation skill → loaded on demand as fallback
    ↓ (if multi-agent)
delegator skill → wave-based parallel dispatch
```

## What Stays Unchanged

- auto-delegation skill (SKILL.md) — fallback, no changes needed
- delegator skill — wave-based dispatch, no changes
- Agent files content (rules, context, tools) — only frontmatter description changes
- Hook scripts (session-start, session-stop, etc.)
- Commands (/cwe:builder, /cwe:architect etc.)
- Memory system, rules, standards

## Expected Outcomes

- Agents other than builder actually get used
- 20%+ context reduction (CLAUDE.md: 3.5KB → 200 bytes)
- Faster response times (less context to process)
- Hook provides consistent routing regardless of model version

## Risks

- Hook keyword matching is simplistic — may misroute ambiguous requests
  - Mitigation: fallback chain, user can say "manual"
- Radical CLAUDE.md cut may lose useful steering
  - Mitigation: iterative — we can add back specific lines if needed
- "MUST use" in descriptions may be too aggressive
  - Mitigation: test and adjust wording
