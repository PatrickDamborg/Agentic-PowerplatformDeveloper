---
name: model-router
description: Route sub-agents to the cheapest model that can reliably complete the task. Governs the `model` parameter on Agent tool calls.
---

# Model Router

Route sub-agents to the cheapest model that can reliably complete the task. The main conversation stays on the user's chosen model; this skill governs the `model` parameter on Agent tool calls.

## Haiku — lightweight, fast, lowest cost
Use for tasks that are **retrieval, verification, or simple transformation** with no design decisions:
- Querying EntityDefinitions to verify logical names, schema, or metadata
- Running existing scripts and reporting output
- Fetching docs via Microsoft Learn MCP tools
- Reading error messages and extracting the relevant info
- Simple file reads, glob/grep searches
- Listing solutions, tables, columns, or relationships

## Sonnet — balanced, good for structured execution
Use for tasks that require **writing or modifying code from a known pattern** with no architectural decisions:
- Writing PowerShell scripts for CRUD, schema changes, or API calls (when the docs/format are already known)
- Adding columns, lookups, relationships using documented API patterns
- Modifying existing scripts (changing prefixes, table names, parameters)
- Debugging script errors that require code changes
- Creating/updating .env, .gitignore, config files
- Standard git operations (commit, branch, PR creation)

## Opus — full reasoning, highest cost
Use only for tasks that require **planning, design, or judgment**:
- Designing table schemas, relationships, and solution architecture
- Multi-step feature planning across multiple tables/components
- Evaluating trade-offs (e.g., N:N vs junction table, ownership model)
- Creating or refining skills, instructions, and CLAUDE.md content
- Cross-solution impact analysis
- Reflecting on process, distilling learnings, writing project documentation
- Any task where the user explicitly asks for a plan or review

## Routing rules
1. **Default to the lowest viable model** — when in doubt between two tiers, pick the cheaper one
2. **Escalate on failure** — if a Haiku/Sonnet agent fails or produces incorrect output, retry with the next tier up
3. **Never downgrade the main conversation** — the router only applies to sub-agents spawned via the Agent tool
4. **Log routing decisions** — when spawning a sub-agent, briefly note which model was chosen and why, so we can review and tune the router over time

## Version
v1.0 — 2026-03-22 — Initial routing based on first working session. To be refined as we encounter more task types.
