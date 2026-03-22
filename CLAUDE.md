# Project Instructions

## Startup

On the first message of every session, before doing any Dataverse work, ask the user:
1. Which **publisher prefix** to use for this session (e.g., `pda`, `contoso`, etc.)
2. Do NOT default to `new_` — always ask first

Store the chosen prefix and use it for all SchemaName values (tables, columns, etc.) throughout the session.

## Dataverse Development

- Never use the default `new_` publisher prefix — always use the prefix confirmed by the user at session start
- Use `pwsh` (PowerShell Core) for all scripts — never use `powershell.exe`
- All scripts must be cross-platform (Windows and macOS)
- Use the Dataverse Web API (REST/OData) for all operations
- Do not use the `pac` CLI
- Authenticate via OAuth2 (MSAL) or client credentials
- Target API endpoint: `https://<org>.api.crm.dynamics.com/api/data/v9.2/`

## Skill: Dataverse API Usage

Before making ANY Dataverse Web API call:

1. **Reference the official docs first** — Use the Microsoft Learn MCP tools (`microsoft-code-reference` or `microsoft-docs`) to look up the exact API format for the operation. Never guess JSON payloads or endpoint patterns. The docs contain the correct headers, body structure, and odata types.

2. **Verify entity logical names** — Before referencing any table in a relationship, lookup, or query, confirm the exact logical name by querying `EntityDefinitions` (e.g., filter by `LogicalName` containing the expected prefix). Do not assume spelling — names may differ from what the user says (e.g., `pum_resource` not `pum_ressource`).

3. **Publisher prefix is immutable** — The publisher prefix is baked into SchemaName at creation time and cannot be changed afterward. If the wrong prefix is used, the only fix is to delete and recreate. Always confirm the prefix before creating any component.

## Skill: Data Model Management

When creating or modifying Dataverse schema (tables, columns, lookups, relationships):

1. **Use `MSCRM.SolutionUniqueName` header** — Always include this header on POST requests to `EntityDefinitions`, `RelationshipDefinitions`, and `Attributes` endpoints. This associates the component with the solution at creation time. Do NOT create components first and add them to a solution separately via `AddSolutionComponent`.

2. **Publish after schema changes** — After creating or modifying tables, columns, or relationships, call `PublishXml` to make changes visible in the application:
   ```
   POST {url}/PublishXml
   {"ParameterXml": "<importexportxml><entities><entity>{logicalname}</entity></entities></importexportxml>"}
   ```

3. **Form changes via maker portal** — Do not manipulate form XML programmatically via the API. Adding subgrids, sections, or controls to forms is fragile via API and risks corrupting form XML. Always recommend the user do form layout changes in the Power Apps maker portal.

## Skill: Model Router

Route sub-agents to the cheapest model that can reliably complete the task. The main conversation stays on the user's chosen model; this skill governs the `model` parameter on Agent tool calls.

### Haiku — lightweight, fast, lowest cost
Use for tasks that are **retrieval, verification, or simple transformation** with no design decisions:
- Querying EntityDefinitions to verify logical names, schema, or metadata
- Running existing scripts and reporting output
- Fetching docs via Microsoft Learn MCP tools
- Reading error messages and extracting the relevant info
- Simple file reads, glob/grep searches
- Listing solutions, tables, columns, or relationships

### Sonnet — balanced, good for structured execution
Use for tasks that require **writing or modifying code from a known pattern** with no architectural decisions:
- Writing PowerShell scripts for CRUD, schema changes, or API calls (when the docs/format are already known)
- Adding columns, lookups, relationships using documented API patterns
- Modifying existing scripts (changing prefixes, table names, parameters)
- Debugging script errors that require code changes
- Creating/updating .env, .gitignore, config files
- Standard git operations (commit, branch, PR creation)

### Opus — full reasoning, highest cost
Use only for tasks that require **planning, design, or judgment**:
- Designing table schemas, relationships, and solution architecture
- Multi-step feature planning across multiple tables/components
- Evaluating trade-offs (e.g., N:N vs junction table, ownership model)
- Creating or refining skills, instructions, and CLAUDE.md content
- Cross-solution impact analysis
- Reflecting on process, distilling learnings, writing project documentation
- Any task where the user explicitly asks for a plan or review

### Routing rules
1. **Default to the lowest viable model** — when in doubt between two tiers, pick the cheaper one
2. **Escalate on failure** — if a Haiku/Sonnet agent fails or produces incorrect output, retry with the next tier up
3. **Never downgrade the main conversation** — the router only applies to sub-agents spawned via the Agent tool
4. **Log routing decisions** — when spawning a sub-agent, briefly note which model was chosen and why, so we can review and tune the router over time

### Version
v1.0 — 2026-03-22 — Initial routing based on first working session. To be refined as we encounter more task types.

## Microsoft Learn MCP Skills

Use the Microsoft Learn MCP server skills based on the task at hand:

- **`microsoft-code-reference`** — Use when writing, debugging, or reviewing code that touches any Microsoft SDK, .NET library, Azure client library, or Microsoft API. Catches hallucinated methods, wrong signatures, and deprecated patterns. If the task involves producing or fixing Microsoft-related code, use this skill.
- **`microsoft-docs`** — Use when the question is about understanding concepts, configuration, limits, quotas, best practices, or tutorials for any Microsoft technology (Azure, .NET, M365, Power Platform, Dataverse, etc.). Facts and concepts, not code.
- **`microsoft-skill-creator`** — Use when generating or scaffolding a custom agent skill for a specific Microsoft technology. Investigates the topic via official docs, then produces a hybrid skill with local knowledge and dynamic lookups.
