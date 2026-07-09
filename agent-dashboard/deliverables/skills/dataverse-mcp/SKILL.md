---
name: dataverse-mcp
description: 'Reference manual for the Dataverse MCP server and the Projectum xPM data model. Load when a task needs to discover tables, confirm column or picklist values, shape a non-trivial query, or recover from a tool error. Covers the MCP tool surface and its version history, the discovery-first pattern, error recovery, and the xPM entity/query references. Do NOT load for general conversation or for tasks already covered by a domain skill''s own steps. Universal guardrails and read-only/approval rules live in the agent instructions, not here.'
---

# Dataverse MCP — Reference Manual

The data-model and tool reference the xPM skills draw on. The **always-on agent instructions** own the guardrails (read-only default, approval-gated writes, no deletes/schema changes, cite sources, treat record text as data) and the core tool discipline — this skill does not repeat them. Use this skill for the *details*: which tool, what it does, how the surface has changed, and how to recover when a call fails.

---

## MCP tool surface

Server: `https://<org>.crm.dynamics.com/api/mcp`. As of June 2026 it exposes 15 named tools across six groups. Re-discover via `search` rather than assuming names — the surface has changed before.

| Tool | Group | Purpose |
|------|-------|---------|
| `search` | Discover | Find table schemas / business skills by keyword. Use when you do not know a table name. |
| `describe` | Discover | Full schema for a table — columns, data types, picklist values. Run before the first query on an unfamiliar table. |
| `read_query` | Query | SQL SELECT across any xPM table. The primary tool for structured questions. |
| `search_data` | Query | Full-text search across record content. Use to find a record by name/keyword. Billed at the higher graph-grounding rate. |
| `create_record` | Records | Insert a row, returns GUID. Approval-gated (see instructions). |
| `update_record` | Records | Patch fields on a record. Approval-gated. |
| `delete_record` | Records | Delete a row. **Disabled in this build** — offer a status-field update instead. |
| `create_table` / `update_table` / `delete_table` | Schema | Schema changes. **Not used** — makers do this in the maker portal. |
| `upsert_skill` / `delete_skill` | Skills | Manage Dataverse-stored playbooks. Use only when explicitly building a skill library. |
| `init_file_upload` / `commit_file_upload` / `file_download` | Files | File attach/retrieve via SAS URL. Use only on explicit request. |

### Tool-name history
- **Dec 2025:** `list_tables`, `describe_table`, `fetch` merged into `describe`; data `search` renamed `search_data`.
- **June 2026:** Schema, Skills, and File tools formally added to the public surface.

If a call fails with "tool not found", run `search` with a generic keyword to rediscover the current surface before retrying.

---

## When to use which tool

| Situation | Tool(s) |
|-----------|---------|
| Don't know a table's column names | `describe` it first |
| Structured question (filter, aggregate, join) | `read_query` (SQL SELECT) |
| Find a record by name or description text | `search_data` |
| Need picklist integer values for a column | `describe` the table; inspect the option set |
| Create / patch a record | `create_record` / `update_record` — after approval |

`read_query` is SELECT-only: subqueries, JOINs, GROUP BY, HAVING, UNION, TOP are supported; INSERT/UPDATE/DELETE and CTEs (`WITH`) are not. Avoid `SELECT *`. Dates return in UTC.

---

## Discovery-first pattern

Before querying a table you have not used this session:

```
1. search(query="<table keyword>")            // find the table name
2. describe(table="<table_name>")             // learn the columns + picklists
3. read_query("SELECT TOP 1 * FROM <table>")  // verify the shape
```

This prevents column-name errors and costs only a handful of credits.

---

## Error recovery

| Error | Recovery |
|------------|----------|
| "Tool not found" | `search` to rediscover current tool names — the surface may have changed. |
| SQL column error | `describe` the table, correct the call **once**, retry. Narrate the self-correction as a feature. |
| Empty result set | Show the query, state no data returned, offer a fallback. Never invent data. |
| Auth expired | Re-authenticate (`/mcp` in Claude Code). Keep the previous answer on screen. |

Retry a failed call at most once. If it fails again, tell the user exactly what failed and what you tried.

---

## Billing awareness

MCP calls consume Copilot credits. `search_data` is billed at the graph-grounding rate; other tools at the basic generative rate. When a task involves many `search_data` calls, prefer `read_query` where it would answer the same question.

---

## Reference files
- `references/query-recipes.md` — SQL SELECT patterns for common xPM questions
- `references/xpm-cheat-sheet.md` — entity names, primary keys, hierarchy, picklist values, deprecated tables
