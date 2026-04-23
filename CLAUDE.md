# Project Instructions

## Startup

Run `/connect` at the start of every session before doing any Dataverse work.

`/connect` handles environment selection, authentication, solution context, and publisher prefix discovery automatically. Do not ask the user for the publisher prefix — it is derived from the solution's publisher record in Dataverse.

## Dataverse Development

- Never use the default `new_` publisher prefix — always use the prefix derived from the active solution
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
| `xpm` | Working with Projectum xPM Essentials entities, picklists, or financial data |
| `model-router` | Spawning sub-agents via the Agent tool |
| `power-automate` | Building or modifying cloud flows |
| `copilot-studio` | Building or modifying Copilot Studio agents, connected agents, or agent tools (Dataverse searchQuery, List rows, Power Automate flows) |
| `microsoft-learn` | Deciding which Microsoft Learn MCP tool to use |
| `browser-testing` | Verifying records or UI state using the Chrome MCP |
| `deploy` | Deploying changes to GitHub |
| `git-push` | Staging, committing, and pushing to remote |

## MCPs

| MCP | When to use |
|-----|-------------|
| `microsoft-learn` | API docs, Dataverse schema questions, Power Platform reference |
| `claude-in-chrome` | Verifying record state in the UI, checking PCF rendering — load `browser-testing` skill first |
| `Gmail` | Sending status updates or reports on behalf of the user |
| `Google Calendar` | Scheduling project milestones or meetings |
| `Google Drive` | Reading shared specification documents |

## Customer Environments

Customer connection configurations live in `customers/`. Each sub-folder represents one customer engagement.

- `customers/_template/` — copy this to create a new customer folder
- `customers/<name>/.env` — gitignored; written by `/connect` from credentials you provide at session start
- `customers/<name>/notes.md` — committed; reference notes for this customer (entities, solutions, known issues)

For customer sessions: run `/connect <name>` — you will be prompted for credentials and solution. Publisher prefix is auto-derived from the solution.

For the dev environment: run `/connect` (or `/connect dev`) — uses root `.env`, prefix auto-derived from solution.
