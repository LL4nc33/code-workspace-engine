# Hybrid Delegation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix CWE agent delegation so all 10 agents get used, not just builder.

**Architecture:** Intent router hook (Python) detects keywords in user prompts and returns systemMessage with explicit agent routing. CLAUDE.md radically reduced. Command descriptions sharpened with "MUST use when" pattern.

**Tech Stack:** Python 3 (hook), Bash (registration), Markdown (CLAUDE.md, commands)

**Design Doc:** `docs/plans/2026-02-23-hybrid-delegation-design.md`

---

### Task 1: Intent Router Hook

Create the Python hook that routes user prompts to agents.

**Files:**
- Create: `hooks/scripts/intent-router.py`

**Step 1: Create intent-router.py**

```python
#!/usr/bin/env python3
"""CWE Intent Router — UserPromptSubmit hook.

Reads user prompt, matches keywords to CWE agents,
returns systemMessage with routing instruction.
"""

import json
import re
import sys

# Agent keyword patterns — order matters (first match wins within priority)
# Higher priority patterns are checked first
AGENTS = [
    # Priority 0: Explicit multi-agent signals
    {
        "agent": "delegator",
        "skill": True,
        "patterns": [
            r"\b(and|und)\b.*\b(and|und)\b",  # 2+ conjunctions
            r"\b(komplett|complete|full|end.to.end|mit allem)\b",
        ],
        "multi_check": True,  # only triggers if 2+ other agents match
    },
    # Priority 1: Domain-specific agents (narrow scope)
    {
        "agent": "security",
        "patterns": [r"\b(security|audit|vulnerabilit|owasp|gdpr|cve|penetration|pentest)\b"],
    },
    {
        "agent": "devops",
        "patterns": [r"\b(deploy|docker|ci/?cd|pipeline|kubernetes|k8s|terraform|release|infrastructure)\b"],
    },
    {
        "agent": "quality",
        "patterns": [r"\b(test|coverage|tdd|quality.gate|flaky|assert|metric|bench)\b"],
    },
    {
        "agent": "architect",
        "patterns": [r"\b(architect|adr|system.design|api.design|schema.design|trade.?off)\b"],
    },
    {
        "agent": "innovator",
        "patterns": [r"\b(brainstorm|idea|what.if|was.w[äa]re|alternativ|kreativ)\b"],
    },
    {
        "agent": "guide",
        "patterns": [r"\b(workflow|process|optimize|improve.*(process|workflow)|pattern.*(extract|discover))\b"],
    },
    {
        "agent": "researcher",
        "patterns": [r"\b(analyz|document|research|compare|report)\b"],
    },
    {
        "agent": "explainer",
        "patterns": [r"\b(explain|walk.?through|how.does|was.ist|wie.funktioniert)\b"],
    },
    {
        "agent": "ask",
        "patterns": [r"\b(discuss|think.about|diskutier|besprechen)\b"],
    },
    # Priority 2: Builder (broadest scope — last to avoid false positives)
    {
        "agent": "builder",
        "patterns": [r"\b(implement|fix|build|create|code|feature|bug|refactor|erstell|baue|reparier)\b"],
    },
]


def extract_prompt(stdin_data):
    """Extract user prompt from hook stdin JSON."""
    try:
        data = json.loads(stdin_data)
        return data.get("message", data.get("prompt", ""))
    except (json.JSONDecodeError, AttributeError):
        return stdin_data.strip()


def should_skip(prompt):
    """Check if routing should be skipped."""
    # Explicit commands
    if prompt.strip().startswith("/"):
        return True
    # Manual override
    if re.search(r"\b(manual|no.delegation|kein.delegation)\b", prompt, re.IGNORECASE):
        return True
    # Very short questions (likely conversational)
    if len(prompt.split()) < 5 and prompt.strip().endswith("?"):
        return True
    return False


def match_agents(prompt):
    """Return list of matched agent names."""
    prompt_lower = prompt.lower()
    matched = []
    for entry in AGENTS:
        if entry.get("multi_check"):
            continue  # handled separately
        for pattern in entry["patterns"]:
            if re.search(pattern, prompt_lower):
                matched.append(entry["agent"])
                break
    return matched


def route(prompt):
    """Determine the best agent for this prompt."""
    if should_skip(prompt):
        return None

    matched = match_agents(prompt)

    if not matched:
        return None

    # Multi-agent detection
    if len(matched) >= 2:
        return {
            "agent": "delegator",
            "skill": True,
            "matched": matched,
            "reason": f"Multi-agent request: {', '.join(matched)}",
        }

    return {
        "agent": matched[0],
        "skill": False,
        "matched": matched,
        "reason": f"Keywords matched agent '{matched[0]}'",
    }


def main():
    stdin_data = sys.stdin.read()
    prompt = extract_prompt(stdin_data)

    if not prompt:
        print(json.dumps({}))
        return

    result = route(prompt)

    if result is None:
        print(json.dumps({}))
        return

    if result["skill"]:
        msg = (
            f"CWE routing: Multi-agent request detected ({result['reason']}). "
            f"Use the delegator skill (Skill tool: cwe:delegator) to decompose and dispatch."
        )
    else:
        agent = result["agent"]
        msg = (
            f"CWE routing: This request matches agent '{agent}' ({result['reason']}). "
            f"Use Task tool with subagent_type='cwe:{agent}' to delegate this work. "
            f"Do not handle it in the main conversation."
        )

    print(json.dumps({"systemMessage": msg}))


if __name__ == "__main__":
    main()
```

**Step 2: Test the router manually**

```bash
echo '{"message":"fix the login bug"}' | python3 hooks/scripts/intent-router.py
# Expected: {"systemMessage": "CWE routing: This request matches agent 'builder'..."}

echo '{"message":"explain how the auth system works"}' | python3 hooks/scripts/intent-router.py
# Expected: {"systemMessage": "CWE routing: This request matches agent 'explainer'..."}

echo '{"message":"design the API and implement it with tests"}' | python3 hooks/scripts/intent-router.py
# Expected: {"systemMessage": "CWE routing: Multi-agent request detected..."}

echo '{"message":"/cwe:help"}' | python3 hooks/scripts/intent-router.py
# Expected: {} (skipped — explicit command)

echo '{"message":"ok danke"}' | python3 hooks/scripts/intent-router.py
# Expected: {} (no match)
```

**Step 3: Commit**

```bash
git add hooks/scripts/intent-router.py
git commit -m "feat: add intent-router hook for agent delegation"
```

---

### Task 2: Register Hook in hooks.json

Add the intent router to the UserPromptSubmit hook chain.

**Files:**
- Modify: `hooks/hooks.json`

**Step 1: Add intent-router to UserPromptSubmit hooks**

In the `UserPromptSubmit` hooks array, add the intent-router BEFORE idea-observer (routing should happen first):

```json
{
    "type": "command",
    "command": "python3 ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/intent-router.py",
    "timeout": 3
}
```

The full UserPromptSubmit section should be:
```json
"UserPromptSubmit": [
    {
        "hooks": [
            {
                "type": "command",
                "command": "python3 ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/intent-router.py",
                "timeout": 3
            },
            {
                "type": "command",
                "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/idea-observer.sh",
                "timeout": 3
            },
            {
                "type": "command",
                "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/yt-transcript.sh",
                "timeout": 45
            }
        ]
    }
]
```

**Step 2: Commit**

```bash
git add hooks/hooks.json
git commit -m "feat: register intent-router in UserPromptSubmit hooks"
```

---

### Task 3: Minimize CLAUDE.md

Radically reduce CLAUDE.md from 98 lines to ~10 lines.

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Replace CLAUDE.md content**

```markdown
# CWE v0.5.1

Orchestration plugin. Delegation via hooks — follow systemMessage routing hints.

## Mistakes to avoid
- Don't handle tasks yourself when a CWE agent exists for it
- Don't skip memory updates after changes (memory/MEMORY.md, CHANGELOG.md)
- Run /cwe:help if unsure about available commands
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "refactor: radically reduce CLAUDE.md to behavioral corrections only

Inspired by research showing context files degrade AI performance.
Routing now handled by intent-router hook instead of prose tables."
```

---

### Task 4: Sharpen Command Descriptions

Update all 10 command frontmatter descriptions to "MUST use when..." pattern.
These are what appear in Claude Code's system reminder as skill descriptions.

**Files:**
- Modify: `commands/builder.md` (line 2)
- Modify: `commands/architect.md` (line 2)
- Modify: `commands/quality.md` (line 2)
- Modify: `commands/security.md` (line 2)
- Modify: `commands/devops.md` (line 2)
- Modify: `commands/researcher.md` (line 2)
- Modify: `commands/explainer.md` (line 2)
- Modify: `commands/ask.md` (line 2)
- Modify: `commands/innovator.md` (line 2)
- Modify: `commands/guide.md` (line 2)

**Step 1: Update each command's description field**

| Command | Old description | New description |
|---------|----------------|-----------------|
| builder | Delegate to builder agent - implementation, bug fixes, code changes | MUSS verwendet werden für Code-Implementierung, Bug-Fixes, Refactoring. Experte für Code-Änderungen mit vollem Dateisystem-Zugriff. |
| architect | Delegate to architect agent - system design, ADRs, API design, spec shaping | MUSS verwendet werden für Systemdesign, Architekturentscheidungen, ADRs, API-Design und Spec-Shaping. READ-ONLY Analyse-Agent. |
| quality | Delegate to quality agent - testing, coverage, quality metrics | MUSS verwendet werden für Testing, Coverage-Analyse, Quality Gates und Code-Metriken. Test-Experte. |
| security | Delegate to security agent - audits, vulnerability assessment, OWASP | MUSS verwendet werden für Security-Audits, Vulnerability-Assessments, OWASP-Checks und GDPR-Compliance. |
| devops | Delegate to devops agent - CI/CD, Docker, infrastructure, releases | MUSS verwendet werden für CI/CD Pipelines, Docker, Kubernetes, Terraform und Deployment-Automatisierung. |
| researcher | Delegate to researcher agent - analysis, documentation, reports | MUSS verwendet werden für Codebase-Analyse, Dokumentationserstellung, Research-Reports und Dependency-Mapping. |
| explainer | Delegate to explainer agent - explanations, code walkthroughs, learning | MUSS verwendet werden für Code-Erklärungen, Architektur-Walkthroughs und Konzept-Vermittlung. READ-ONLY. |
| ask | Ask questions about the project, discuss ideas (READ-ONLY) | MUSS verwendet werden für Fragen, Diskussionen und Ideen-Austausch OHNE Code-Änderungen. STRIKT READ-ONLY. |
| innovator | Develop ideas from the collected backlog, brainstorming, creative solutions | MUSS verwendet werden für Brainstorming, Ideen-Entwicklung und kreative Lösungsansätze. |
| guide | Delegate to guide agent - process improvement, workflow optimization | MUSS verwendet werden für Workflow-Optimierung, Process-Improvement und Pattern-Erkennung. |

**Step 2: Commit**

```bash
git add commands/*.md
git commit -m "refactor: sharpen command descriptions with MUSS verwendet werden pattern"
```

---

### Task 5: Update Documentation

Update docs to reflect the new delegation architecture.

**Files:**
- Modify: `docs/ARCHITECTURE.md` — add Intent Router section
- Modify: `CHANGELOG.md` — add entry

**Step 1: Add Intent Router to ARCHITECTURE.md**

Find the Hook System section and add an entry for the intent router hook explaining:
- It runs on every UserPromptSubmit
- It does keyword matching, not LLM inference
- It returns systemMessage with routing instruction
- Fallback chain: hook → agent descriptions → auto-delegation skill

**Step 2: Add CHANGELOG entry**

Under a new `## [0.5.2]` section:

```markdown
### Changed
- CLAUDE.md radically reduced from 98 to ~10 lines (behavioral corrections only)
- All 10 command descriptions sharpened with "MUSS verwendet werden" pattern

### Added
- `hooks/scripts/intent-router.py`: UserPromptSubmit hook for automatic agent routing
- Keyword-based intent detection routes prompts to correct CWE agent via systemMessage
- Multi-agent detection triggers delegator skill for compound requests

### Removed
- Routing tables, Decision Flow, Quick Reference from CLAUDE.md (moved to hook)
```

**Step 3: Commit**

```bash
git add docs/ARCHITECTURE.md CHANGELOG.md
git commit -m "docs: update architecture and changelog for hybrid delegation"
```

---

### Task 6: Verification

Test the complete delegation chain.

**Step 1: Test intent-router with all agent types**

```bash
for msg in \
  "fix the login bug" \
  "explain how auth works" \
  "design the API schema" \
  "write tests for the auth module" \
  "audit the security of our API" \
  "set up the Docker deployment" \
  "document the API endpoints" \
  "what if we used GraphQL instead" \
  "improve our development workflow" \
  "discuss the architecture approach" \
  "build auth and write tests and document it"; do
  echo -n "$msg → "
  echo "{\"message\":\"$msg\"}" | python3 hooks/scripts/intent-router.py | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('systemMessage','(no routing)')[:80])"
done
```

Expected: Each prompt routes to a different agent. The last one triggers delegator.

**Step 2: Verify CLAUDE.md is minimal**

```bash
wc -l CLAUDE.md
# Expected: ~10 lines
```

**Step 3: Verify command descriptions updated**

```bash
grep "description:" commands/builder.md commands/architect.md commands/quality.md
# Expected: All contain "MUSS verwendet werden"
```

**Step 4: Commit any fixes**

```bash
git add -A && git commit -m "fix: resolve verification findings"
```
