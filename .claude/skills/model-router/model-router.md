---
name: model-router
description: Route sub-agents to the cheapest model that can reliably complete the task. Governs the `model` parameter on Agent tool calls.
---

# Model Router

Route sub-agents to the cheapest model that can reliably complete the task. The main conversation stays on the user's chosen model; this skill governs the `model` parameter on Agent tool calls.

> **Ceiling: `claude-sonnet-4-6`** — Opus 4.7 is not used in the router. If the user needs Opus-level reasoning they will request it explicitly.

## Haiku (`claude-haiku-4-5-20251001`) — lightweight, fast, lowest cost
Use for tasks that are **retrieval, verification, or simple transformation** with no design decisions:
- Querying EntityDefinitions to verify logical names, schema, or metadata
- Running existing scripts and reporting output
- Fetching docs via Microsoft Learn MCP tools
- Reading error messages and extracting the relevant info
- Simple file reads, glob/grep searches
- Listing solutions, tables, columns, relationships, or xPM entities

## Sonnet (`claude-sonnet-4-6`) — balanced, good for structured execution
Use for tasks that require **writing or modifying code from a known pattern** with no architectural decisions:
- Writing PowerShell scripts for CRUD, schema changes, or API calls (when the docs/format are already known)
- Adding columns, lookups, relationships using documented API patterns
- Modifying existing scripts (changing prefixes, table names, parameters)
- Debugging script errors that require code changes
- Creating/updating .env, .gitignore, config files
- Standard git operations (commit, branch, PR creation)
- Creating or updating skill files and CLAUDE.md content
- Cross-solution impact analysis

## Routing Rules
1. **Default to the lowest viable model** — when in doubt between two tiers, pick Haiku
2. **Escalate on failure** — if a Haiku agent fails or produces incorrect output, retry with Sonnet
3. **Never downgrade the main conversation** — the router only applies to sub-agents spawned via the Agent tool
4. **Log routing decisions** — when spawning a sub-agent, briefly note which model was chosen and why

## Version
v2.0 — 2026-04-23 — Removed Opus from router (on-demand only). Updated to Claude 4.x model IDs.
