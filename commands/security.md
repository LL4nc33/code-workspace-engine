---
description: Delegate to security agent - audits, vulnerability assessment, OWASP
allowed-tools: ["Task", "AskUserQuestion"]
---

# Security

Delegate to the **security** agent for security work.

**Usage:** `/cwe:security [task]`

## Interactive Mode (no task provided)

If user runs `/cwe:security` without a task, use AskUserQuestion:

```
Question: "What type of security work?"
Header: "Security Task"
Options:
  1. "Security audit" - Full codebase review
  2. "Vulnerability scan" - Check for known issues
  3. "Specific review" - Focus on one area
  4. "Compliance check" - GDPR, OWASP, etc.
```

### If "Security audit":
```
Question: "Audit scope?"
Header: "Scope"
Options:
  1. "Full codebase" - Everything
  2. "Authentication" - Login, sessions, tokens
  3. "API endpoints" - Input validation, auth
  4. "Data handling" - Storage, encryption
```

### If "Vulnerability scan":
```
Question: "What to scan?"
Header: "Scan Type"
Options:
  1. "Dependencies" - Check packages for CVEs
  2. "Code" - Static analysis (SAST)
  3. "Secrets" - Hardcoded credentials
  4. "All of the above" - Comprehensive scan
```

### If "Specific review":
```
Question: "Which area?"
Header: "Focus Area"
Options:
  1. "SQL Injection" - Database queries
  2. "XSS" - Cross-site scripting
  3. "CSRF" - Cross-site request forgery
  4. "Authentication" - Auth flow security
```

### If "Compliance check":
```
Question: "Which standard?"
Header: "Standard"
Options:
  1. "OWASP Top 10" - Web security risks
  2. "GDPR" - Data privacy (EU)
  3. "SOC 2" - Security controls
  4. "Custom checklist" - (User types via Other)
```

After selections:
```
Question: "Report format?"
Header: "Output"
Options:
  1. "Summary" - High-level findings
  2. "Detailed" - Full report with fixes
  3. "Actionable only" - Just the issues to fix
```

## Direct Mode (task provided)

If user provides a task like `/cwe:security audit the API`, skip the menus and delegate directly.

## Process

Delegate using the Task tool:

```
subagent_type: security
prompt: [constructed or provided task]
```

## Plugin Integration

The security agent has:
- Restricted access (read + specific audit commands)
- OWASP Top 10 expertise
- Dependency scanning (trivy, grype, semgrep)
- GDPR compliance checking
- **superpowers:verification-before-completion** - Verify fixes
- **serena** - Pattern-based code search

## Output

Security reports include:
- Severity levels (Critical, High, Medium, Low)
- OWASP/CWE references
- Affected code locations
- Recommended fixes
