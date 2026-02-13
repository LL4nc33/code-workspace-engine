# CWE User Guide

> Vollständige Dokumentation für das Code Workspace Engine Plugin v0.4.3

---

## Inhalt

1. [Was ist CWE?](#1-was-ist-cwe)
2. [Installation & Setup](#2-installation--setup)
3. [Die 6 Core Principles](#3-die-6-core-principles)
4. [Auto-Delegation verstehen](#4-auto-delegation-verstehen)
5. [Die 10 Agents im Detail](#5-die-10-agents-im-detail)
6. [Der Workflow: Von der Idee zum Feature](#6-der-workflow-von-der-idee-zum-feature)
7. [Das Memory System](#7-das-memory-system)
8. [Das Standards System](#8-das-standards-system)
9. [Hooks — Automatisierung im Hintergrund](#9-hooks--automatisierung-im-hintergrund)
10. [Das Idea System](#10-das-idea-system)
11. [Skills — Progressive Disclosure](#11-skills--progressive-disclosure)
12. [Quality Gates](#12-quality-gates)
13. [Projekt-Struktur Reference](#13-projekt-struktur-reference)
14. [FAQ / Troubleshooting](#14-faq--troubleshooting)
15. [Kreislauf-Diagramm: Wie alles zusammenhängt](#15-kreislauf-diagramm-wie-alles-zusammenhängt)

---

## 1. Was ist CWE?

### Vision und Zweck

CWE (Code Workspace Engine) ist ein **Claude Code Plugin**, das eine einzelne KI-Assistenz in ein Team von 10 spezialisierten Agents verwandelt. Statt einem generischen Prompt, der alles erledigt, routet CWE deine Anfragen automatisch zum richtigen Experten mit dem passenden Kontext.

### Warum Spec-Driven Development?

Software-Projekte scheitern selten an der Implementierung — sie scheitern an unklaren Anforderungen. CWE erzwingt einen strukturierten Workflow:

```
Idee → Plan → Spec → Tasks → Build → Review
```

Jede Phase hat klare Inputs und Outputs. Ein Feature wird nicht "einfach gebaut", sondern durchläuft eine Shape-Spec Interview, bekommt einen Task-Breakdown, wird in parallelen Waves implementiert und durch Quality Gates validiert.

### Warum 10 spezialisierte Agents statt eines generischen?

| Problem mit einem Agent | Lösung durch Spezialisierung |
|------------------------|------------------------------|
| Riesiger System-Prompt mit allem | Jeder Agent hat nur sein Fachgebiet |
| Kontextfenster wird schnell voll | Context Isolation: Agents liefern Summaries |
| Keine Zugriffskontrolle | Builder kann schreiben, Explainer nur lesen |
| Kein einheitlicher Output | Standardisierte Report-Formate pro Agent |
| Keine Qualitätssicherung | Quality Agent blockt Releases unter Schwellwerten |

### CWE vs. "einfach Claude Code nutzen"

| Feature | Claude Code (vanilla) | Claude Code + CWE |
|---------|----------------------|-------------------|
| Agent-Routing | Manuell (du musst Kontext setzen) | Automatisch (sage was du brauchst) |
| Standards | Keine | 8 Domains, auto-loaded per Dateipfad |
| Memory | MEMORY.md (200 Zeilen) | Daily Logs + Semantic Search + Hub-Spoke |
| Workflow | Ad-hoc | Plan → Spec → Tasks → Build → Review |
| Quality | Du entscheidest | Quality Gates mit Metriken |
| Sicherheit | Keine Prüfung | Safety Gate scannt jeden Commit |
| Ideen | Gehen verloren | Automatisch per Keyword erfasst |
| Git | Freier Stil | Conventional Commits + Branch Naming |

---

## 2. Installation & Setup

### Voraussetzungen

- **Claude Code** (CLI) installiert und konfiguriert
- **Git** für Versionskontrolle
- **Node.js** (optional, für MCP Server)

### Installation

```bash
# 1. Plugin klonen
git clone https://github.com/LL4nc33/claude-workflow-engine.git

# 2. Alias einrichten (in ~/.bashrc oder ~/.zshrc)
alias cwe='claude --plugin-dir /path/to/claude-workflow-engine --dangerously-skip-permissions'

# 3. Terminal neu starten oder source ausführen
source ~/.bashrc
```

### Plugin-Dependencies

CWE arbeitet mit anderen Claude Code Plugins zusammen. `/cwe:init` prüft und bietet Installation an:

| Plugin | Level | Warum? |
|--------|-------|--------|
| **superpowers** | Required | TDD, Debugging, Planning, Code Review — die Kern-Skills für jeden Agent |
| **serena** | Recommended | Semantische Code-Analyse via Language Server Protocol (LSP) — versteht Symbole, Referenzen, Typen |
| **feature-dev** | Recommended | 7-Phasen Feature-Workflow mit Code-Architektur, Code-Explorer und Code-Reviewer |

### MCP Server Dependencies

| Server | Warum? |
|--------|--------|
| **playwright** | Browser-Testing, Screenshot-Verifikation für Frontend-Arbeit |
| **context7** | Library-Dokumentation nachschlagen (React, Vue, etc.) |
| **github** | GitHub API Integration (Issues, PRs, Actions) |
| **cwe-memory** | Semantische Suche über alle Memory-Dateien (v0.4.3) |

### /cwe:init Walkthrough

Beim ersten Start in einem Projekt führt `/cwe:init` folgende Schritte aus:

**Step 1: Plugin-Check**
- Prüft ob superpowers, serena, feature-dev installiert sind
- Bietet Installation per `claude plugin add` an
- Optionale Plugins (frontend-design, plugin-dev) werden angeboten

**Step 2: MCP Server-Check**
- Prüft ob playwright, context7, github MCP Server konfiguriert sind
- Bietet `claude mcp add` an für fehlende Server

**Step 3: Projekt-Struktur erstellen**
```
workflow/
├── config.yml           # CWE Konfiguration
├── ideas.md             # Kuratierter Ideen-Backlog
├── product/
│   └── mission.md       # Produkt-Vision (hier startest du!)
├── specs/               # Feature-Spezifikationen (je Ordner)
└── standards/           # Projekt-spezifische Standards

memory/
├── MEMORY.md            # Index (max 200 Zeilen)
├── ideas.md             # Ideen-Übersicht
├── decisions.md         # Architecture Decision Records
├── patterns.md          # Erkannte Muster
└── project-context.md   # Tech-Stack (auto-seeded!)

docs/
├── README.md            # Projekt-README
├── ARCHITECTURE.md      # Systemarchitektur
├── API.md               # API-Dokumentation
├── SETUP.md             # Setup-Anleitung
└── decisions/           # ADR-Ordner
    └── _template.md     # ADR-Vorlage

VERSION                  # Single Source of Truth (z.B. "0.1.0")
CHANGELOG.md             # Keep-a-Changelog Format
```

**Step 4: Auto-Seeding**
- Erkennt Tech-Stack aus package.json, Cargo.toml, go.mod, etc.
- Schreibt Ergebnis in `memory/project-context.md`
- Initialisiert `memory/MEMORY.md` mit Projekt-Metadaten

---

## 3. Die 6 Core Principles

### Prinzip 1: Agent-First

**Was:** Jede Aufgabe wird an einen spezialisierten Agent delegiert. Der Haupt-Kontext bleibt schlank.

**Warum:** Claude Code hat ein begrenztes Kontextfenster. Wenn ein Agent 5000 Zeilen Code liest, füllt das den Hauptkontext. Mit Delegation liest der Agent den Code, liefert eine 20-Zeilen-Summary, und der Hauptkontext bleibt frei.

**Beispiel:**
```
Du: "Fix the login bug"
CWE: Delegiert an builder-Agent
Builder: Liest Code, debuggt, fixt, testet
Builder → CWE: "Fixed: NullPointerException in AuthService.login() (line 47). Root cause: missing null check on session token."
```

### Prinzip 2: Auto-Delegation

**Was:** CWE analysiert deine natürliche Sprache und routet automatisch zum passenden Agent.

**Warum:** Du musst nicht wissen, welcher Agent was kann. Sage einfach was du brauchst.

**Beispiel:**
```
"Fix the login bug"        → builder (Keywords: fix, bug)
"Explain how auth works"   → explainer (Keywords: explain, how)
"What if we used GraphQL?" → innovator (Keywords: what if)
"Run the test suite"       → quality (Keywords: test)
```

### Prinzip 3: Spec-Driven

**Was:** Features durchlaufen immer den Zyklus: Plan → Spec → Tasks → Build → Review.

**Warum:** Ein Feature ohne Spec ist wie ein Gebäude ohne Bauplan. Die Shape-Spec Interview zwingt dich, Scope zu definieren, bevor Code geschrieben wird. Das verhindert Scope Creep und macht Features nachvollziehbar.

**Beispiel:**
```
/cwe:architect shape
→ Interview: "Was ist IN Scope? Was ist OUT of Scope?"
→ Interview: "Welche Komponenten sind betroffen?"
→ Interview: "Was ist die Definition of Done?"
→ Generiert: workflow/specs/2026-02-13-1430-user-auth/
   ├── plan.md, shape.md, references.md, standards.md
```

### Prinzip 4: Context Isolation

**Was:** Agents arbeiten in isolierten Kontexten. Nur das Ergebnis (Summary) kommt zurück.

**Warum:** Ein Security-Audit liest 50 Dateien und produziert 2000 Zeilen Analyse. Davon brauchst du nur die 30 Zeilen Summary. Context Isolation hält das Kontextfenster effizient.

### Prinzip 5: Plugin Integration

**Was:** Agents nutzen Skills aus installierten Plugins (superpowers, serena, feature-dev).

**Warum:** CWE erfand das Rad nicht neu. superpowers hat exzellentes TDD und Debugging. serena hat semantische Code-Analyse. feature-dev hat einen 7-Phasen Feature-Workflow. CWE orchestriert diese Skills.

### Prinzip 6: Always Document

**Was:** Jede nicht-triviale Änderung aktualisiert: MEMORY.md, Daily Log, CHANGELOG, betroffene Docs.

**Warum:** CWE hat kein Langzeitgedächtnis ohne explizite Dokumentation. Wenn die Memory-Dateien nicht aktuell sind, startet die nächste Session ohne Kontext. Documentation ist kein Nice-to-have — es ist die Persistenzschicht.

---

## 4. Auto-Delegation verstehen

### Wie CWE Requests routet

```
User request
    ↓
Explicit /command? ─────────→ Execute command directly
    ↓ no
Plugin skill matches? ──────→ Invoke skill (PRIORITY)
    ↓ no
CWE agent matches? ────────→ Delegate to agent
    ↓ no
Multi-step task? ──────────→ Orchestrate with subagents
    ↓ no
Unclear? ──────────────────→ Ask (max 2 questions)
```

**Wichtig:** Plugin-Skills haben Vorrang vor Agent-Routing. Wenn du "debug this" sagst, matcht `superpowers:systematic-debugging` bevor der builder-Agent aktiviert wird.

### Intent → Agent Keyword-Tabelle

| Intent | Agent | Keywords |
|--------|-------|----------|
| Code schreiben/fixen | **builder** | implement, fix, build, create, code, feature, bug, refactor |
| Fragen/Diskussion | **ask** | question, discuss, think about |
| Code erklären | **explainer** | explain, how, what, why, understand |
| Testen/Qualität | **quality** | test, write tests, coverage, quality, validate, metrics, gate |
| Sicherheit | **security** | security, audit, vulnerability, scan, gdpr, owasp, cve |
| Infrastruktur | **devops** | deploy, docker, ci, cd, release, kubernetes, terraform |
| Architektur | **architect** | design, architecture, adr, api, schema |
| Recherche/Docs | **researcher** | analyze, document, research, compare |
| Brainstorming | **innovator** | brainstorm, idea, ideas, what if, alternative, explore |
| Prozess-Verbesserung | **guide** | workflow, process, pattern, improve, optimize |

### Intent → Plugin Skill

| Keywords | Skill | Plugin |
|----------|-------|--------|
| UI, frontend, component | `frontend-design` | frontend-design |
| simplify, cleanup | `code-simplifier` | code-simplifier |
| debug, investigate bug | `systematic-debugging` | superpowers |
| write plan, planning | `writing-plans` | superpowers |
| review code | `requesting-code-review` | superpowers |
| TDD, test first | `test-driven-development` | superpowers |
| create plugin, hook | plugin-dev skills | plugin-dev |
| develop feature | `/feature-dev` | feature-dev |

### "manual" Override

Sage **"manual"** oder **"no delegation"** um Auto-Delegation zu deaktivieren. Dann verarbeitet CWE deinen Request direkt, ohne an einen Agent zu delegieren.

### Beispiele aus der Praxis

```
"Fix the login bug"
  → Keywords: fix, bug → builder
  → Builder nutzt: systematic-debugging + serena

"How does the auth middleware work?"
  → Keywords: how → explainer
  → Explainer nutzt: serena (find_symbol, get_symbols_overview)

"What if we replaced REST with GraphQL?"
  → Keywords: what if → innovator
  → Innovator nutzt: SCAMPER-Methodik, WebSearch

"Run all tests and check coverage"
  → Keywords: test, coverage → quality
  → Quality nutzt: Bash(npm test), quality-gates skill

"Create a Docker setup"
  → Keywords: docker → devops
  → DevOps nutzt: Bash(docker), Dockerfile-Erstellung

"Look at this code"
  → Keine eindeutigen Keywords → ASK: "Möchtest du den Code fixen, erklären oder analysieren?"
```

---

## 5. Die 10 Agents im Detail

### 5.1 builder — Der "Code Coroner"

**Identity:** Systematic, thorough, never guesses — always investigates the evidence first.

**Wann:** Code schreiben, Bugs fixen, Features implementieren, Refactoring.

**Tools:** Read, Write, Edit, Bash, Grep, Glob, alle serena-Tools, Task (für Subagents)

**Skills:** Nutzt superpowers (TDD, debugging), serena (symbol navigation), feature-dev (code-architect)

**Access:** Voller Lese-/Schreibzugriff auf Code

**Typische Befehle:**
```
"Fix the login bug"
"Implement user authentication"
"Refactor the API layer"
/cwe:builder "add input validation to the signup form"
```

**Besonderheit:** Der Builder folgt dem TDD-Cycle (Red → Green → Refactor) wenn superpowers:test-driven-development verfügbar ist. Er implementiert nie ohne Tests.

---

### 5.2 architect — Der System-Denker

**Identity:** Thinks in systems, not files. Sees the forest, not just the trees.

**Wann:** Systemdesign, ADRs schreiben, Feature-Specs formen (Shape-Spec Interview).

**Tools:** Read, Grep, Glob, Task, AskUserQuestion, serena (Symbole + Muster)

**Access:** READ-ONLY für Code, Schreibzugriff auf workflow/specs/ und docs/

**Typische Befehle:**
```
"Design the authentication system"
/cwe:architect shape    → Shape-Spec Interview
/cwe:architect "write an ADR for the database choice"
```

**Besonderheit:** Die Shape-Spec Interview ist das Herzstück. Der Architect fragt:
1. Was ist IN Scope? Was ist OUT of Scope?
2. Welche Komponenten sind betroffen?
3. Welche Standards gelten?
4. Was ist die Definition of Done?

Das Ergebnis ist ein Spec-Ordner mit plan.md, shape.md, references.md und standards.md.

---

### 5.3 ask — Der Diskussions-Partner

**Identity:** Thoughtful, analytical, explores all angles without jumping to conclusions.

**Wann:** Offene Fragen, Diskussionen, "Lass uns mal darüber nachdenken".

**Tools:** Read, Grep, Glob, WebSearch, WebFetch, serena (Symbole)

**Access:** STRIKT READ-ONLY — macht keine Änderungen

**Typische Befehle:**
```
"Discuss: Should we use microservices or monolith?"
"Think about the trade-offs of caching here"
/cwe:ask "what are the implications of upgrading to Node 22?"
```

**Besonderheit:** Der Ask-Agent ist der einzige, der explizit keine Aktion ausführt. Er denkt, analysiert und präsentiert Optionen — die Entscheidung liegt bei dir.

---

### 5.4 explainer — Der Erklärer

**Identity:** Patient, clear technical educator. Explains complex things simply without being condescending.

**Wann:** Code verstehen, Konzepte erklärt bekommen, Architektur-Entscheidungen nachvollziehen.

**Tools:** Read, Grep, Glob, serena (get_symbols_overview, find_symbol)

**Access:** READ-ONLY

**Output-Formate:**
- **Code Explanations:** TL;DR → Step-by-step → Design Rationale
- **Concept Explanations:** Simple Terms → In This Project → Example
- **How-To:** Quick Answer → Step by Step → Watch Out For

**Typische Befehle:**
```
"Explain how the auth middleware works"
"What does this function do?"
/cwe:explainer "walk me through the payment flow"
```

---

### 5.5 quality — Der Quality Guardian

**Identity:** Nothing ships without your approval. Thorough. Data-driven. Uncompromising on standards.

**Wann:** Tests laufen lassen, Coverage prüfen, Code Reviews, Health Dashboard.

**Tools:** Read, Grep, Glob, Bash (jest, npm test, nyc, eslint), serena

**Skills:** quality-gates, health-dashboard

**Access:** READ-ONLY + Test-Commands

**Quality Gates:**

| Metric | Minimum | Target | Blocks Release |
|--------|---------|--------|----------------|
| Line Coverage | 70% | 80% | <60% |
| Branch Coverage | 65% | 75% | <55% |
| Cyclomatic Complexity | <15 | <10 | >20 |
| Test Duration | <5min | <2min | >10min warns |
| Flaky Tests | 0 | 0 | >0 |

**Typische Befehle:**
```
"Run tests and check coverage"
/cwe:quality health        → Full Health Dashboard
/cwe:quality "review the last commit"
```

---

### 5.6 security — Der Security-Prüfer

**Identity:** Cautious, thorough, assumes breach. "Trust nothing, verify everything."

**Wann:** Security Audits, Vulnerability Scans, OWASP-Checks, GDPR-Compliance.

**Tools:** Read, Grep, Glob, Bash (trivy, grype, semgrep, nmap, curl), serena

**Skills:** quality-gates

**Access:** RESTRICTED — Read + spezifische Audit-Commands

**Prüf-Framework:** OWASP Top 10 (2021)
- Severity Levels: Critical, High, Medium, Low, Informational
- Immer mit Remediation-Empfehlung
- GDPR-Compliance-Check inklusive

**Typische Befehle:**
```
"Audit the API for security issues"
/cwe:security "scan dependencies for CVEs"
/cwe:security "GDPR compliance check"
```

**Besonderheit:** Reports enthalten nie den Wert eines Secrets — nur die Location. Der Security Agent reportet `LOCATION: config.js:42`, niemals den tatsächlichen Key.

---

### 5.7 devops — Der Infrastruktur-Experte

**Identity:** Automates everything. If you do it twice, script it.

**Wann:** Docker, CI/CD, Releases, Deployments, Terraform.

**Tools:** Read, Write, Edit, Bash, Grep, Glob, serena

**Access:** Voller Zugriff (braucht Schreibrechte für Dockerfiles, CI configs, etc.)

**Typische Befehle:**
```
"Set up Docker for this project"
"Create a GitHub Actions CI pipeline"
/cwe:devops release        → VERSION bump + CHANGELOG + git tag
/cwe:devops "add staging environment"
```

**Besonderheit:** Bei `release` liest der DevOps-Agent die VERSION-Datei, bumpt sie, generiert Release Notes aus Conventional Commits, aktualisiert CHANGELOG.md und erstellt einen git tag.

---

### 5.8 researcher — Der Analyst

**Identity:** Thorough, structured, citation-oriented. Every claim has evidence.

**Wann:** Codebase-Analyse, Dokumentation generieren, Technologie-Vergleiche, Reports.

**Tools:** Read, Grep, Glob, WebSearch, WebFetch, serena

**Skills:** project-docs

**Access:** READ-ONLY (Ausnahme: docs/ Dateien)

**Dokumentations-Modi:**
- `docs update` → Scannt Codebase, aktualisiert alle Docs
- `docs check` → Validiert Docs-Freshness vs. Code
- `docs adr` → Erstellt neues ADR in docs/decisions/

**Typische Befehle:**
```
"Analyze the codebase architecture"
"Compare React vs Vue for our use case"
/cwe:researcher docs update
/cwe:researcher "generate a dependency report"
```

---

### 5.9 innovator — Die Idea Forge

**Identity:** Creative, curious, unbound by "how it's always been done."

**Wann:** Brainstorming, Ideen entwickeln, "Was wäre wenn?", Idea Backlog verwalten.

**Tools:** Read, Write, Grep, Glob, WebSearch, WebFetch, serena

**Access:** READ-ONLY für Code, WRITE für workflow/ideas.md

**4 Modi:**

| Modus | Command | Was passiert |
|-------|---------|-------------|
| Default | `/cwe:innovator` | Zeigt aktuelle Projekt-Ideen |
| All | `/cwe:innovator all` | Cross-Project Ideen-Übersicht |
| Review | `/cwe:innovator review` | Interaktiver Triage: Keep/Develop/Reject |
| Develop | `/cwe:innovator develop <idea>` | Deep-Dive auf eine Idee (SCAMPER) |

**Ideation Methodology:** UNDERSTAND → DIVERGE (SCAMPER) → EXPLORE → CONVERGE → PRESENT

---

### 5.10 guide — Der Process Whisperer

**Identity:** Sees patterns others miss. Reflective. Data-informed. Evolution-focused.

**Wann:** Muster analysieren, Standards aus Code extrahieren, Workflow verbessern.

**Tools:** Read, Grep, Glob, serena (search_for_pattern, get_symbols_overview)

**Access:** READ-ONLY + Schreibzugriff auf .claude/rules/

**2 Haupt-Modi:**
- `discover` → Scannt Codebase für Muster, interviewt User, generiert `.claude/rules/`
- `index` → Regeneriert `.claude/rules/_index.yml` mit Keyword-Detection

**Evolution Methodology:** OBSERVE → ANALYZE → HYPOTHESIZE → PROPOSE → VALIDATE

**Typische Befehle:**
```
/cwe:guide discover          → Auto-Discovery aller Patterns
/cwe:guide discover api      → Nur API-Patterns
/cwe:guide index             → Standards-Index regenerieren
/cwe:guide "analyze our workflow efficiency"
```

---

## 6. Der Workflow: Von der Idee zum Feature

### Die 5 Phasen

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   Plan ──→ Spec ──→ Tasks ──→ Build ──→ Review         │
│    │         │                   │         │            │
│    │    Shape-Spec          Wave Exec   Quality         │
│    │    Interview           (parallel)   Gates          │
│    │                                      │             │
│    └──────────────────────────────────────┘             │
│                  next feature                           │
└─────────────────────────────────────────────────────────┘
```

### Phase 1: Plan

**Ziel:** Produktvision definieren.

**Datei:** `workflow/product/mission.md`

Beantworte diese Fragen:
- Was löst dieses Produkt? Für wen?
- Was sind die Ziele?
- Was sind die Non-Goals (was wir bewusst NICHT machen)?
- Wie messen wir Erfolg?

### Phase 2: Spec (Shape-Spec Interview)

**Ziel:** Feature-Scope präzise definieren, bevor Code geschrieben wird.

**Trigger:** `/cwe:architect shape` oder `/cwe:start` in der Spec-Phase.

Der Architect führt ein strukturiertes Interview:
1. **Scope:** Was ist IN Scope? Was ist OUT of Scope?
2. **Komponenten:** Welche Dateien/Module sind betroffen?
3. **Constraints:** Technische/Business Einschränkungen?
4. **Standards:** Welche bestehenden Standards gelten?
5. **Definition of Done:** Wann ist das Feature fertig?

**Output:** Spec-Ordner `workflow/specs/YYYY-MM-DD-HHMM-<slug>/`
```
├── plan.md          # Implementierungsplan + Task-Breakdown
├── shape.md         # Scope, Entscheidungen, Constraints
├── references.md    # Ähnlicher Code, Patterns, Prior Art
├── standards.md     # Standards-Snapshot zum Zeitpunkt der Spec
└── visuals/         # Mockups, Diagramme, Screenshots
```

### Phase 3: Tasks

**Ziel:** Spec in implementierbare Aufgaben aufbrechen.

Organisation-Modi:
- **By Component** — Gruppiert nach Datei/Modul
- **By Priority** — Kritische zuerst, Nice-to-have zuletzt
- **By Dependency** — Build-Reihenfolge (A vor B)

### Phase 4: Build (Wave Execution)

**Ziel:** Tasks parallel mit mehreren Agents implementieren.

**Wave Execution Algorithmus:**
1. Alle pending Tasks laden
2. Unblockierte Tasks filtern (keine offenen Dependencies)
3. Wave bilden: bis zu 3 parallele Tasks
4. Für jeden Task: Agent bestimmen, parallel ausführen
5. Warten bis alle in der Wave fertig sind
6. Nächste Wave starten bis keine Tasks mehr offen

**Beispiel:**
```
Wave 1 (3 Tasks parallel):
  [builder] Task 1: Implement API endpoints ✓
  [devops]  Task 2: Setup Docker ✓
  [builder] Task 3: Add input validation ✓

Wave 2 (1 Task, war blockiert durch Task 1):
  [quality] Task 4: Write integration tests ✓

Alle Tasks abgeschlossen.
```

### Phase 5: Review

**Ziel:** Qualität sicherstellen, bevor das Feature shipped wird.

Optionen nach Abschluss:
- **Code Review** → Quality Agent
- **Tests laufen lassen** → Quality Agent
- **PR erstellen** → DevOps Agent
- **Weitere Tasks hinzufügen** → Zurück zu Phase 4

---

## 7. Das Memory System

### Warum Memory?

**Problem:** Claude Code hat kein Langzeitgedächtnis zwischen Sessions. Jede neue Session startet bei Null — vergangene Entscheidungen, Patterns und Kontext sind verloren.

**Lösung:** CWE's Memory System persistiert Wissen in strukturierten Dateien, die bei jedem Session-Start automatisch injiziert werden.

### Die Memory-Architektur (Hub-and-Spoke)

```
                    ┌──────────────┐
                    │  MEMORY.md   │  ← Hub (max 200 Zeilen, immer geladen)
                    │   (Index)    │
                    └──────┬───────┘
                           │
           ┌───────┬───────┼───────┬──────────┐
           │       │       │       │          │
     ┌─────┴─┐ ┌──┴──┐ ┌──┴──┐ ┌──┴──┐ ┌────┴────┐
     │Daily  │ │deci-│ │pat- │ │ideas│ │project- │
     │Logs   │ │sions│ │terns│ │ .md │ │context  │
     │YYYY-  │ │ .md │ │ .md │ │     │ │  .md    │
     │MM-DD  │ │     │ │     │ │     │ │         │
     └───────┘ └─────┘ └─────┘ └─────┘ └─────────┘
```

### MEMORY.md — Der Hub

- **Max 200 Zeilen** (wird bei Session-Start komplett injiziert)
- Enthält: Projekt-Name, Version, aktuelle Prioritäten, Key Decisions
- Wird bei jeder Session aktualisiert
- Fungiert als Index: "Für Details siehe decisions.md"

### Daily Logs — Tägliche Protokolle

**Datei:** `memory/YYYY-MM-DD.md`

```markdown
# 2026-02-13

## 14:30 — Session Start
- Goal: Memory System Upgrade planen
- Context: CWE v0.4.1, alle Phasen abgeschlossen

## 14:45 — Design Decision
- Decision: Daily Logs statt sessions.md
- Rationale: Natürliche Zeitstruktur, keine Datei wächst unbegrenzt

## 16:00 — Session End
- Done: Design complete, Plan geschrieben
- Next: Phase 1 implementieren
- Files changed: hooks/hooks.json, hooks/scripts/session-start.sh
```

- **Append-only** — nur neue Einträge, nie existierende editieren
- **Today + Yesterday** werden bei Session-Start injiziert
- **Automatisch aufgeräumt** — Logs älter als 30 Tage werden gelöscht

### project-context.md — Tech-Stack und Prioritäten

- Beim `/cwe:init` automatisch geseedet (Tech-Stack-Erkennung)
- Enthält: Sprache, Framework, Database, CI/CD, aktuelle Prioritäten
- Wird on-demand gelesen, nicht bei jeder Session

### decisions.md — Architecture Decision Records

Format pro Eintrag:
```markdown
## ADR-001: JWT statt Session Cookies
- **Date:** 2026-02-13
- **Status:** Accepted
- **Context:** SPA braucht stateless auth
- **Decision:** JWT mit Refresh Token Rotation
- **Alternatives:** Session Cookies, OAuth2 PKCE
- **Consequences:** Kein Server-Side Session Store nötig
```

### patterns.md — Erkannte Muster

Vom Guide-Agent entdeckte und dokumentierte Code-Patterns.

### Memory MCP Server (v0.4.3)

**Semantische Suche** über alle Memory-Dateien mit Hybrid Search:

| Tool | Beschreibung |
|------|-------------|
| `memory_search` | Semantische Suche: Query → relevante Snippets aus allen Memory-Dateien |
| `memory_get` | Datei/Section lesen: Pfad → Content |
| `memory_write` | Eintrag anhängen: Entry → Today's Daily Log |
| `memory_status` | Index-Status: Dateien, Chunks, Freshness |

**Wie die Hybrid Search funktioniert:**
- **Vector Similarity** (70%): Semantische Ähnlichkeit via Embeddings
- **BM25** (30%): Keyword-basierte Suche via SQLite FTS5
- **Chunking:** ~400 Tokens pro Chunk, 80 Token Overlap
- **Storage:** SQLite mit `sqlite-vec` Extension, lokal pro Projekt

### Context Injection bei Session Start

Bei jedem Session-Start (via `session-start.sh`):
1. `memory/MEMORY.md` komplett lesen (max 200 Zeilen)
2. `memory/YYYY-MM-DD.md` (heute) lesen
3. `memory/YYYY-MM-DD.md` (gestern) lesen
4. Alles zusammen auf max 8000 Zeichen begrenzen
5. Als `systemMessage` injizieren

### Pre-Compact Memory Save

Wenn das Kontextfenster voll wird und Claude Code komprimiert, speichert der PreCompact-Hook vorher:
- Aktuelle Arbeit in den Daily Log
- MEMORY.md-Aktualisierung

---

## 8. Das Standards System

### Wie Standards funktionieren

CWE nutzt Claude Code's native `.claude/rules/` mit `paths`-Frontmatter für auto-loaded Standards:

```markdown
---
paths:
  - "src/api/**"
  - "routes/**"
---

# API Standards

## REST Endpoints
- Use plural nouns: /users, /posts
- Use kebab-case: /user-profiles
...
```

Wenn du an einer Datei in `src/api/` arbeitest, werden die API-Standards automatisch geladen.

### 8 eingebaute Standards

| Standard | Paths | Domain |
|----------|-------|--------|
| `global-standards.md` | `**/*` (immer) | Naming, Tech-Stack |
| `api-standards.md` | `src/api/**`, `routes/**` | REST, Validation |
| `frontend-standards.md` | `src/components/**`, `pages/**` | Components, State |
| `database-standards.md` | `migrations/**`, `models/**` | Queries, Schema |
| `devops-standards.md` | `Dockerfile`, `.github/**`, `terraform/**` | CI/CD, Docker |
| `testing-standards.md` | `**/*.test.*`, `**/*.spec.*` | Coverage, Mocking |
| `agent-standards.md` | `agents/**`, `skills/**`, `hooks/**` | Agent Authoring |
| `documentation-standards.md` | `docs/**`, `memory/**` | Memory Updates |

### Standards Discovery

```
/cwe:guide discover
```

Der Guide-Agent:
1. Scannt die Codebase nach wiederkehrenden Patterns (>3x = Kandidat)
2. Interviewt dich: "Ich habe bemerkt, du nutzt immer Pattern X. Warum? Soll das ein Standard werden?"
3. Generiert `.claude/rules/<domain>-<pattern>.md` mit korrektem `paths` Frontmatter
4. Aktualisiert `.claude/rules/_index.yml`

### Standards Indexing

```
/cwe:guide index
```

Regeneriert den `_index.yml` aus allen vorhandenen `.claude/rules/*.md` Dateien:
- Extrahiert `paths` Frontmatter
- Identifiziert Keywords aus dem Content
- Validiert dass keine Konflikte zwischen Rules bestehen

### _index.yml Struktur

```yaml
- file: global-standards.md
  paths: ["**/*"]
  keywords: ["naming", "convention", "tech stack"]
  auto_inject: true
  priority: 100
- file: api-standards.md
  paths: ["src/api/**", "routes/**"]
  keywords: ["api", "endpoint", "REST", "validation"]
  auto_inject: true
  priority: 80
```

**Wichtig:** Paths müssen als YAML-Liste formatiert sein, NICHT als Comma-Separated String.

### Eigene Standards erstellen

1. Erstelle `.claude/rules/your-standard.md` mit `paths:` Frontmatter
2. Laufe `/cwe:guide index` um den Index zu aktualisieren
3. Oder nutze `/cwe:guide discover` für automatische Erkennung

---

## 9. Hooks — Automatisierung im Hintergrund

### Was sind Hooks?

Hooks sind Shell-Scripts und Prompts die automatisch auf Events reagieren. Sie laufen im Hintergrund — du merkst sie meist nicht, aber sie halten alles zusammen.

**Hook-Events in CWE:**

| Event | Wann | Hooks |
|-------|------|-------|
| `SessionStart` | Session beginnt | Context Injection |
| `Stop` | Session endet | Daily Log schreiben |
| `PreCompact` | Kontext wird komprimiert | Memory sichern |
| `UserPromptSubmit` | User schreibt etwas | Idea Observer |
| `SubagentStop` | Agent fertig | Agent Logging |
| `PreToolUse (Bash)` | Vor Bash-Kommando | Safety Gate, Commit Format, Branch Naming |

### SessionStart: Context Injection

**Script:** `hooks/scripts/session-start.sh`

Bei jedem Session-Start:
1. Liest MEMORY.md (max 200 Zeilen)
2. Liest heute's Daily Log
3. Liest gestrige's Daily Log
4. Begrenzt auf 8000 Zeichen
5. Injiziert als `systemMessage`

Du bekommst dadurch immer den aktuellen Projekt-Kontext, ohne manuell Dateien öffnen zu müssen.

### Stop: Memory Flush + Daily Log

Drei Hooks laufen sequentiell beim Session-Ende:

**1. Prompt-Hook:** Fordert Claude auf, MEMORY.md und den Daily Log zu aktualisieren (Dokumentations-Checkliste).

**2. Script:** `hooks/scripts/session-stop.sh`
- Erstellt `memory/YYYY-MM-DD.md` falls nicht vorhanden
- Hängt Session-End Timestamp an
- Räumt Daily Logs älter als 30 Tage auf

**3. Script:** `hooks/scripts/idea-flush.sh`
- Zählt erfasste Ideen des aktuellen Projekts
- Zeigt Anzahl unreviewed Ideas als systemMessage
- Erinnert an `/cwe:innovator` für Review

### PreCompact: Memory Save

**Prompt-Hook:** Wenn Claude's Kontextfenster voll wird, werden ältere Nachrichten komprimiert. Vorher sichert dieser Hook den aktuellen Stand in den Daily Log.

### UserPromptSubmit: Idea Observer

**Script:** `hooks/scripts/idea-observer.sh`

Scannt jede User-Nachricht auf Idea-Keywords:
- Deutsch: idee, was wäre wenn, könnte man, vielleicht, alternativ, verbesserung
- English: idea, what if, could we, maybe, alternative, improvement

Match → JSONL-Entry in `~/.claude/cwe/ideas/<project-slug>.jsonl`

### SubagentStop: Agent Logging

**Script:** `hooks/scripts/subagent-stop.sh`

Loggt Agent-Ausführungen für Observability:
- Welcher Agent lief?
- Wann?
- Ergebnis-Status

### PreToolUse: Safety Gate

**Script:** `hooks/scripts/safety-gate.sh`

Triggert auf: `git commit`, `git push`, `git add -A`

**Scannt für:**
- API Keys (sk-*, AKIA*, ghp_*, xoxb-*)
- Private Keys (-----BEGIN.*PRIVATE KEY-----)
- Hardcoded Passwords (password=, secret=)
- Database URLs mit Credentials
- .env Dateien
- Zertifikate (.pem, .key, .pfx)

**Exit Codes:** 0 = safe, 2 = BLOCKED (mit Report)

### PreToolUse: Commit Format

**Script:** `hooks/scripts/commit-format.sh`

Validiert Conventional Commit Format:
```
<type>(<scope>): <subject>
```

Types: feat, fix, chore, docs, style, refactor, test, perf, ci, build, revert

### PreToolUse: Branch Naming

**Script:** `hooks/scripts/branch-naming.sh`

Validiert Branch-Namensformat:
- `feature/<description>`, `fix/<description>`, `hotfix/<description>`
- `chore/<description>`, `release/<version>`
- `main`, `develop` (erlaubt)

### Wie der Kreis sich schließt

```
Session Start
    │
    ├── session-start.sh → MEMORY.md + Daily Logs injiziert
    │
    ▼
User arbeitet
    │
    ├── idea-observer.sh → Ideen erfasst
    ├── safety-gate.sh → Commits geprüft
    ├── commit-format.sh → Format validiert
    ├── branch-naming.sh → Branch validiert
    ├── subagent-stop.sh → Agents geloggt
    │
    ▼
Context wird voll
    │
    ├── PreCompact Hook → Memory gesichert
    │
    ▼
Session endet
    │
    ├── Stop Prompt → MEMORY.md + Daily Log aktualisiert
    ├── session-stop.sh → Timestamp + Cleanup
    │
    ▼
Nächste Session
    │
    └── session-start.sh → Alles wieder injiziert ← ─ ─ Kreislauf
```

---

## 10. Das Idea System

### Automatische Capture

Jede User-Nachricht wird durch den `idea-observer.sh` Hook gescannt. Enthält sie bestimmte Keywords, wird automatisch ein Eintrag erstellt:

**Keywords (DE):** idee, was wäre wenn, könnte man, vielleicht, alternativ, verbesserung
**Keywords (EN):** idea, what if, could we, maybe, alternative, improvement

### JSONL Format

Ideen werden per Projekt gespeichert: `~/.claude/cwe/ideas/<project-slug>.jsonl`

```json
{"ts":"2026-02-13T14:30:00Z","prompt":"was wäre wenn wir GraphQL statt REST nutzen?","project":"my-app","keywords":["was wäre wenn"],"status":"raw"}
```

### 4 Modi des Innovator-Agents

| Modus | Command | Beschreibung |
|-------|---------|-------------|
| **Default** | `/cwe:innovator` | Zeigt neue Observations + Backlog-Status für aktuelles Projekt |
| **All** | `/cwe:innovator all` | Cross-Project Übersicht, zeigt transferierbare Ideen |
| **Review** | `/cwe:innovator review` | Interaktiver Triage: Keep / Develop / Reject pro Observation |
| **Develop** | `/cwe:innovator develop <idea>` | Deep-Dive mit SCAMPER-Methodik |

### Von der Idee zum Feature

```
Casual remark → Idea Observer erfasst
    ↓
/cwe:innovator review → Triage: Keep/Develop/Reject
    ↓
/cwe:innovator develop <idea> → SCAMPER Deep-Dive
    ↓
User entscheidet → Status: "planned"
    ↓
/cwe:architect shape → Spec erstellen
    ↓
/cwe:start → Build Phase
```

---

## 11. Skills — Progressive Disclosure

Skills sind spezialisierte Anleitungen, die Agents bei bestimmten Aufgaben unterstützen. Sie werden im Agent-Frontmatter referenziert.

### auto-delegation

**Datei:** `skills/auto-delegation/SKILL.md`

Das Herzstück von CWE. Enthält den kompletten Decision Flow, Keyword-Tabellen und Context-Injection-Regeln für Auto-Delegation von User-Requests zu Agents und Plugin-Skills.

### agent-detection

**Datei:** `skills/agent-detection/SKILL.md`

Wie auto-delegation, aber für die Build-Phase: Erkennt welcher Agent für einen strukturierten Task zuständig ist (nicht für freie User-Requests).

### quality-gates

**Datei:** `skills/quality-gates/SKILL.md`

Definiert die 3 Quality Gates:
1. **Pre-Implementation:** Architect prüft Spec
2. **Post-Implementation:** Quality prüft Code, Tests, Coverage
3. **Pre-Release:** Security prüft auf Vulnerabilities

### safety-gate

**Datei:** `skills/safety-gate/SKILL.md`

Pre-Commit Scanning für Secrets, Credentials, PII. Beschreibt welche Patterns gescannt werden und wie Remediation funktioniert.

### git-standards

**Datei:** `skills/git-standards/SKILL.md`

Conventional Commits Format, Branch Naming Patterns, Auto-Generated Release Notes. Referenziert von den PreToolUse Hooks.

### health-dashboard

**Datei:** `skills/health-dashboard/SKILL.md`

Definiert den Project Health Score (0-100) aus 5 Kategorien: Code Quality (25%), Dependencies (20%), Documentation (20%), Git Health (20%), Security (15%).

### project-docs

**Datei:** `skills/project-docs/SKILL.md`

Generierung und Pflege von Projekt-Dokumentation: README, ARCHITECTURE, API, SETUP. Inklusive Tech-Stack Auto-Detection und Docs Freshness Check.

---

## 12. Quality Gates

### Pre-Implementation Gate

**Trigger:** Bevor Code geschrieben wird.
**Agent:** Architect
**Prüft:**
- Ist der Spec vollständig? (plan.md + shape.md)
- Sind betroffene Komponenten identifiziert?
- Gibt es eine Definition of Done?
- Sind Standards referenziert?

### Post-Implementation Gate

**Trigger:** Nach Code-Completion.
**Agent:** Quality
**Prüft:**

| Metric | Minimum | Blocks |
|--------|---------|--------|
| Line Coverage | 70% | <60% |
| Branch Coverage | 65% | <55% |
| Cyclomatic Complexity | <15 | >20 |
| Test Duration | <5min | >10min |
| Flaky Tests | 0 | >0 |

### Pre-Release Gate

**Trigger:** Vor `git push` oder Release.
**Agent:** Security + Safety Gate Hook
**Prüft:**
- Keine Secrets im Code
- Keine bekannten CVEs in Dependencies
- .gitignore vollständig
- OWASP Top 10 Compliance

### Health Score

Der `/cwe:quality health` Command berechnet einen Gesamt-Score:

| Kategorie | Gewichtung | Scoring |
|-----------|-----------|---------|
| Code Quality | 25% | Coverage >80% = voll, -2 pro % darunter |
| Dependencies | 20% | 0 vulnerable = voll, -10 pro Vulnerability |
| Documentation | 20% | Alle aktuell = voll, -5 pro stale Doc |
| Git Health | 20% | CC >95% + clean tree = voll |
| Security | 15% | Clean Scan + complete .gitignore = voll |

| Score | Rating |
|-------|--------|
| 90-100 | Excellent |
| 75-89 | Good |
| 60-74 | Needs Attention |
| <60 | Critical |

---

## 13. Projekt-Struktur Reference

### CWE Plugin-Struktur

```
claude-workflow-engine/
├── agents/                     # 10 spezialisierte Agents
│   ├── ask.md                  # Diskussions-Partner (READ-ONLY)
│   ├── architect.md            # System-Denker (READ-ONLY + specs/)
│   ├── builder.md              # Code Coroner (voller Zugriff)
│   ├── devops.md               # Infrastruktur-Experte (voller Zugriff)
│   ├── explainer.md            # Erklärer (READ-ONLY)
│   ├── guide.md                # Process Whisperer (READ-ONLY + rules/)
│   ├── innovator.md            # Idea Forge (READ-ONLY + ideas.md)
│   ├── quality.md              # Quality Guardian (READ-ONLY + tests)
│   ├── researcher.md           # Analyst (READ-ONLY + docs/)
│   └── security.md             # Security-Prüfer (RESTRICTED)
│
├── commands/                   # 13 Slash Commands
│   ├── help.md                 # /cwe:help
│   ├── init.md                 # /cwe:init (Project Setup)
│   ├── start.md                # /cwe:start (Guided Workflow)
│   ├── ask.md                  # /cwe:ask
│   ├── builder.md              # /cwe:builder
│   ├── architect.md            # /cwe:architect
│   ├── devops.md               # /cwe:devops
│   ├── security.md             # /cwe:security
│   ├── researcher.md           # /cwe:researcher
│   ├── explainer.md            # /cwe:explainer
│   ├── quality.md              # /cwe:quality
│   ├── innovator.md            # /cwe:innovator
│   └── guide.md                # /cwe:guide
│
├── skills/                     # 7 Skills
│   ├── auto-delegation/SKILL.md
│   ├── agent-detection/SKILL.md
│   ├── quality-gates/SKILL.md
│   ├── safety-gate/SKILL.md
│   ├── git-standards/SKILL.md
│   ├── health-dashboard/SKILL.md
│   └── project-docs/SKILL.md
│
├── hooks/                      # Automatisierung
│   ├── hooks.json              # Hook-Konfiguration
│   └── scripts/
│       ├── session-start.sh    # Context Injection
│       ├── session-stop.sh     # Daily Log + Cleanup
│       ├── idea-observer.sh    # Idea Capture
│       ├── idea-flush.sh       # Idea Export
│       ├── subagent-stop.sh    # Agent Logging
│       ├── safety-gate.sh      # Pre-Commit Scanning
│       ├── commit-format.sh    # Conventional Commits
│       └── branch-naming.sh    # Branch Validation
│
├── .claude/rules/              # 8 Standards + Index
│   ├── _index.yml              # Standard-Index
│   ├── global-standards.md
│   ├── api-standards.md
│   ├── frontend-standards.md
│   ├── database-standards.md
│   ├── devops-standards.md
│   ├── testing-standards.md
│   ├── agent-standards.md
│   └── documentation-standards.md
│
├── templates/                  # Vorlagen
│   ├── memory/                 # 6 Memory-Templates
│   ├── specs/                  # 4 Spec-Templates (plan, shape, references, standards)
│   └── docs/                   # 7 Doc-Templates (README, ARCHITECTURE, API, etc.)
│
├── docs/                       # Plugin-Dokumentation
│   ├── USER-GUIDE.md           # Diese Datei
│   ├── assets/
│   │   ├── cwe-logo.svg
│   │   └── cwe-header.svg
│   └── plans/                  # Design-Dokumente
│
├── CLAUDE.md                   # Plugin-Konfiguration
├── README.md                   # GitHub README
├── CHANGELOG.md                # Version History
└── ROADMAP.md                  # Geplante Features
```

### Was CWE bei /cwe:init erstellt

Im Ziel-Projekt:

```
your-project/
├── workflow/
│   ├── config.yml              # CWE Konfiguration
│   ├── ideas.md                # Kuratierter Ideen-Backlog
│   ├── product/
│   │   ├── README.md           # Erklärung
│   │   └── mission.md          # Produktvision (DU schreibst das!)
│   ├── specs/
│   │   ├── README.md           # Erklärung Spec-Struktur
│   │   └── YYYY-MM-DD-HHMM-<slug>/  # Pro Feature
│   └── standards/
│       └── README.md           # Erklärung
├── memory/
│   ├── MEMORY.md               # Index (auto-seeded)
│   ├── YYYY-MM-DD.md           # Daily Logs (auto-created)
│   ├── ideas.md                # Ideen-Übersicht
│   ├── decisions.md            # ADRs
│   ├── patterns.md             # Erkannte Muster
│   └── project-context.md      # Tech-Stack (auto-seeded!)
├── docs/
│   ├── README.md               # Projekt-README (aus Template)
│   ├── ARCHITECTURE.md         # Architektur
│   ├── API.md                  # API-Docs
│   ├── SETUP.md                # Setup-Anleitung
│   ├── DEVLOG.md               # Developer Journal
│   └── decisions/
│       └── _template.md        # ADR-Vorlage
└── VERSION                     # z.B. "0.1.0"
```

---

## 14. FAQ / Troubleshooting

### "CWE routet zum falschen Agent"

**Ursache:** Die Keywords in deiner Nachricht matchen einen anderen Agent als erwartet.

**Fix:**
1. Nutze den expliziten Command: `/cwe:builder "deine Aufgabe"` statt Auto-Delegation
2. Sage "manual" um Auto-Delegation zu deaktivieren
3. Prüfe die Keyword-Tabelle in [Section 4](#4-auto-delegation-verstehen)

### "Memory wird nicht injiziert"

**Ursache:** Mögliche Gründe:
- `memory/` Verzeichnis existiert nicht → `/cwe:init` ausführen
- `MEMORY.md` ist leer → Inhalt hinzufügen
- Session-Start Hook fehlgeschlagen → `hooks.json` prüfen

**Fix:**
1. Prüfe ob `memory/MEMORY.md` existiert und Inhalt hat
2. Prüfe ob `hooks/hooks.json` korrekt konfiguriert ist
3. Manueller Test: `bash hooks/scripts/session-start.sh < /dev/null`

### "MCP Server startet nicht"

**Ursache:** Konfigurationsproblem in `.mcp.json`.

**Fix:**
1. Prüfe `.mcp.json` Syntax (valides JSON?)
2. Prüfe ob der Server-Befehl existiert: `which npx`
3. Für cwe-memory: Stelle sicher dass `memory/` Verzeichnis existiert
4. Starte Claude Code neu

### "Wie setze ich alles zurück?"

**Achtung:** Dies löscht CWE-Konfiguration im Projekt.

```bash
# Nur CWE-Struktur entfernen (behält deinen Code):
rm -rf workflow/ memory/ docs/
rm -f VERSION CHANGELOG.md

# Dann neu initialisieren:
/cwe:init
```

### "Safety Gate blockt meinen Commit"

**Ursache:** Der Pre-Commit Scanner hat ein potentielles Secret gefunden.

**Fix:**
1. Prüfe den Report — welche Datei, welche Zeile?
2. Entferne das Secret und nutze Environment Variables statt dessen
3. Falls False Positive: `git commit --no-verify` (wird geloggt!)
4. Rotiere das Secret falls es bereits committed war

### "Conventional Commit wird abgelehnt"

**Format:** `type(scope): subject`

**Erlaubte Types:** feat, fix, chore, docs, style, refactor, test, perf, ci, build, revert

**Häufige Fehler:**
- Großbuchstabe am Anfang: ~~`Fix: bug`~~ → `fix: bug`
- Punkt am Ende: ~~`feat: add login.`~~ → `feat: add login`
- Fehlender Type: ~~`fixed the bug`~~ → `fix: resolve login crash`

---

## 15. Kreislauf-Diagramm: Wie alles zusammenhängt

```
┌───────────────────────────────────────────────────────────────────┐
│                        CWE LIFECYCLE                              │
│                                                                   │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────────┐        │
│  │  SESSION  │    │    WORK      │    │    PERSIST       │        │
│  │  START    │    │              │    │                  │        │
│  │          │    │              │    │                  │        │
│  │ Memory   │───→│ User Request │───→│ Daily Log        │        │
│  │ Injection│    │      │       │    │ MEMORY.md        │        │
│  │          │    │      ▼       │    │ CHANGELOG        │        │
│  │ MEMORY.md│    │ Auto-Dele-   │    │                  │        │
│  │ + Daily  │    │ gation       │    └────────┬─────────┘        │
│  │ Logs     │    │      │       │             │                  │
│  └──────────┘    │      ▼       │             │                  │
│       ▲          │ Agent mit    │             │                  │
│       │          │ Standards    │             │                  │
│       │          │      │       │             │                  │
│       │          │      ▼       │             │                  │
│       │          │ Build +      │             │                  │
│       │          │ Quality Gate │             │                  │
│       │          │      │       │             │                  │
│       │          │      ▼       │             │                  │
│       │          │ Safety Gate  │             │                  │
│       │          │ (pre-commit) │             │                  │
│       │          └──────────────┘             │                  │
│       │                                       │                  │
│       │          ┌──────────────┐             │                  │
│       │          │  SESSION     │             │                  │
│       │          │  STOP        │◄────────────┘                  │
│       │          │              │                                │
│       │          │ Daily Log    │                                │
│       │          │ Cleanup      │                                │
│       │          └──────┬───────┘                                │
│       │                 │                                        │
│       └─────────────────┘                                        │
│              Next Session                                        │
│                                                                   │
│  ┌───────────────────────────────────────────────────────┐       │
│  │  BACKGROUND (always running)                          │       │
│  │                                                       │       │
│  │  Idea Observer ──→ JSONL ──→ /cwe:innovator          │       │
│  │  Safety Gate ──→ Blocks dangerous commits             │       │
│  │  Commit Format ──→ Validates Conventional Commits     │       │
│  │  Branch Naming ──→ Validates branch patterns          │       │
│  │  Agent Logger ──→ Tracks which agents ran             │       │
│  └───────────────────────────────────────────────────────┘       │
└───────────────────────────────────────────────────────────────────┘
```

**Der Kreislauf:**

1. **Session Start** → Memory injiziert (MEMORY.md + Daily Logs)
2. **User Request** → Auto-Delegation routet zum passenden Agent
3. **Agent arbeitet** → Standards auto-loaded, Skills verfügbar
4. **Code geschrieben** → Safety Gate scannt, Commit Format validiert
5. **Memory aktualisiert** → Daily Log, MEMORY.md, CHANGELOG
6. **Session Stop** → Alles persistiert
7. **Nächste Session** → Alles wieder da (→ Schritt 1)

Im Hintergrund laufen permanent:
- **Idea Observer** erfasst jede Idee automatisch
- **Safety Gate** prüft jeden Commit
- **Agent Logger** trackt welche Agents liefen

Das ist CWE: Ein sich selbst dokumentierendes, sicherheitsbewusstes, spec-getriebenes Workflow-System, das mit jeder Session klüger wird.
