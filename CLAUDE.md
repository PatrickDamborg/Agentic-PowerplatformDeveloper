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

## Skills

Domain knowledge lives in `.claude/skills/`. Load the relevant skill before starting work in that area.

| Skill | When to load |
|-------|-------------|
| `dataverse-api` | Making any Dataverse Web API call |
| `data-model` | Creating or modifying tables, columns, lookups, relationships |
| `model-router` | Spawning sub-agents via the Agent tool |
| `power-automate` | Building or modifying cloud flows |
| `microsoft-learn` | Deciding which Microsoft Learn MCP tool to use |
| `deploy` | Deploying changes to GitHub |
| `git-push` | Staging, committing, and pushing to remote |
