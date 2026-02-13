---
name: mcp-usage
description: MCP Tool catalog and usage guide. Use when doing semantic code analysis, symbol navigation, MCP, Serena.
---

# MCP Tools - Usage Guide

## Available MCP Servers

### Serena (Semantic Code Analysis)

Serena provides semantic code navigation and manipulation via Language Server.

| Tool | Function | Typical Use |
|------|----------|-------------|
| `get_symbols_overview` | List symbols in a file | Understand file structure |
| `find_symbol` | Find symbol by name path | Locate class/method |
| `find_referencing_symbols` | Find references to a symbol | Track dependencies |
| `replace_symbol_body` | Replace symbol body | Precise code changes |
| `search_for_pattern` | Regex search in codebase | Pattern recognition |
| `insert_after_symbol` | Insert code after a symbol | Add new methods |
| `insert_before_symbol` | Insert code before a symbol | Add imports |
| `rename_symbol` | Rename symbol codebase-wide | Refactoring |
| `read_file` | Read file (with line range) | Get context |

#### Examples

```
# Find all methods of a class
find_symbol(name_path_pattern="MyClass", depth=1, include_body=False)

# Who calls this method?
find_referencing_symbols(name_path="MyClass/myMethod", relative_path="src/service.ts")

# Overview of file structure
get_symbols_overview(relative_path="src/controllers/auth.ts", depth=1)

# Replace method
replace_symbol_body(name_path="MyClass/myMethod", relative_path="src/service.ts", body="...")
```

## Agent-Tool Matrix

| Agent | Serena Tools |
|-------|-------------|
| **architect** | find_symbol, get_symbols_overview, find_referencing_symbols |
| **builder** | find_referencing_symbols, replace_symbol_body, find_symbol, get_symbols_overview |
| **devops** | - |
| **explainer** | get_symbols_overview, find_symbol |
| **guide** | search_for_pattern, get_symbols_overview |
| **innovator** | - |
| **quality** | find_symbol, get_symbols_overview |
| **researcher** | search_for_pattern, find_symbol, get_symbols_overview |
| **security** | search_for_pattern, find_symbol |
| **ask** | get_symbols_overview, find_symbol, find_referencing_symbols |

## When MCP Tools vs Standard Tools?

| Situation | Standard Tool | MCP Tool (better) |
|-----------|---------------|-------------------|
| "Where is X called?" | Grep | find_referencing_symbols |
| "What methods does class Y have?" | Read (whole file) | find_symbol + depth=1 |
| "Replace method Z" | Edit (string match) | replace_symbol_body |
| "Rename variable" | Grep + Edit | rename_symbol |
| "Understand file structure" | Read (whole file) | get_symbols_overview |

## Prerequisites

MCP tools are only available when the Serena server is configured:
- **Serena:** Requires `.serena/` configuration in project

If the MCP server is unavailable, agents automatically fall back to standard tools.
