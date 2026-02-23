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
        "agent": "debug",
        "patterns": [
            r"\bdebug",
            r"\bfehlersuche\b",
            r"\btroubleshoot",
            r"\broot.?cause\b",
            r"\bstacktrace\b",
            r"\bcrash",
            r"\bwarum.*(fehlt|geht.nicht|crasht|bricht|funktioniert.nicht|fehlschl(ä|ae|a)|failed|fails)",
            r"\b(finde|find).*(fehler|error|bug)",
            r"\buntersuch",
        ],
    },
    {
        "agent": "security",
        "patterns": [
            r"\bsecurity\b",
            r"\bsicherheit",
            r"\baudit\b",
            r"\bvulnerabilit",
            r"\bschwachstell",
            r"\bowasp\b",
            r"\bgdpr\b",
            r"\bcve\b",
            r"\bpentest|penetration",
            r"\bpr[uü]f.*(auf|sicherheit|schwach)",
        ],
    },
    {
        "agent": "devops",
        "patterns": [
            r"\bdeploy",
            r"\bdocker\b",
            r"\bci/?cd\b",
            r"\bpipeline\b",
            r"\bkubernetes|k8s\b",
            r"\bterraform\b",
            r"\brelease\b",
            r"\binfrastruktur|infrastructure\b",
        ],
    },
    {
        "agent": "quality",
        "patterns": [
            r"\btests?\b",
            r"\btesting\b",
            r"\bcoverage\b",
            r"\btdd\b",
            r"\bquality.gate",
            r"\bflaky\b",
            r"\bmetric|bench",
        ],
    },
    {
        "agent": "architect",
        "patterns": [
            r"\barchitect",
            r"\barchitektur",
            r"\badr\b",
            r"\bsystemdesign",
            r"\bdesign\b",
            r"\bschema\b",
            r"\btrade.?off",
            r"\bmigrat",
            r"\bplan(e|ung)?\b",
        ],
    },
    {
        "agent": "innovator",
        "patterns": [
            r"\bbrainstorm",
            r"\bidea\b",
            r"\bidee\b",
            r"\bwhat.if\b",
            r"\bwas.w(ä|ae|a)re",
            r"\balternativ",
            r"\bkreativ",
            r"\binnovation",
            r"\bvision\b",
        ],
    },
    {
        "agent": "guide",
        "patterns": [
            r"\bworkflow\b",
            r"\bprocess\b",
            r"\bprozess",
            r"\boptimiz|optimier",
            r"\bimprove|verbesser",
            r"\bpattern.*(extract|discover)",
            r"\bstandard",
        ],
    },
    {
        "agent": "researcher",
        "patterns": [
            r"\banalys",
            r"\bdokument",
            r"\bresearch|recherch",
            r"\bcompar|vergleich",
            r"\breport\b",
            r"\bbericht",
            r"\bzusammenfass",
        ],
    },
    {
        "agent": "explainer",
        "patterns": [
            r"\bexplain",
            r"\berkl(ä|ae|a)r",
            r"\bwalk.?through",
            r"\bhow.does",
            r"\bwas.ist\b",
            r"\bwie.funktioniert",
            r"\bwas.bedeutet",
            r"\bwas.macht",
        ],
    },
    {
        "agent": "ask",
        "patterns": [
            r"\bdiscuss",
            r"\bdiskutier",
            r"\bthink.about",
            r"\bbesprechen|besprich",
            r"\blass.uns\b",
            r"\bmeinung|opinion",
        ],
    },
    # Priority 2: Builder (broadest scope — last to avoid false positives)
    {
        "agent": "builder",
        "patterns": [
            r"\bimplement",
            r"\bfix\b",
            r"\bbuild\b",
            r"\bcreate\b",
            r"\b(schreib|write).*(code|funktion|klasse)",
            r"\bfeature\b",
            r"\bbug\b",
            r"\brefactor",
            r"\berstell",
            r"\bbaue?\b",
            r"\breparier",
            r"\bprogrammier",
        ],
    },
]

# Utility command patterns — checked BEFORE agents (higher priority)
# These route to /cwe: commands via Skill tool, not Task subagents
UTILITIES = [
    {
        "command": "yt-transcript",
        "patterns": [
            r"https?://(www\.)?(youtube\.com|youtu\.be)/",
            r"\b(youtube|video.?transcript|transkript)\b",
        ],
    },
    {
        "command": "url-scraper",
        "patterns": [
            r"https?://(?!.*(youtube\.com|youtu\.be)/)\S+",  # any non-YouTube URL
        ],
        "hook_handled": True,  # url-scraper hook already scrapes this
    },
    {
        "command": "screenshot",
        "patterns": [r"\b(screenshot|clipboard|zwischenablage|bildschirmfoto)\b"],
    },
    {
        "command": "web-research",
        "patterns": [
            r"\b(web.?search|web.?research|google|suche?.im.?(web|internet|netz))\b",
            r"\b(scrape|crawl|webseite.?lesen)\b",
        ],
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


def match_utility(prompt):
    """Check if prompt matches a utility command. Returns entry dict or None."""
    prompt_lower = prompt.lower()
    for entry in UTILITIES:
        for pattern in entry["patterns"]:
            if re.search(pattern, prompt_lower):
                return entry
    return None


def route(prompt):
    """Determine the best agent or utility for this prompt."""
    if should_skip(prompt):
        return None

    # Utility commands take priority (youtube URLs, screenshot, web search)
    utility = match_utility(prompt)
    if utility:
        if utility.get("hook_handled"):
            return None  # Another hook handles this, don't route
        return {
            "agent": utility["command"],
            "utility": True,
            "matched": [utility["command"]],
            "reason": f"Utility command matched: {utility['command']}",
        }

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

    if result.get("utility"):
        cmd = result["agent"]
        msg = (
            f"CWE routing: This request matches utility command '{cmd}' ({result['reason']}). "
            f"Use the Skill tool with skill='cwe:{cmd}' to handle this. "
            f"Do not handle it manually."
        )
    elif result.get("skill"):
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
