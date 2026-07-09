# Agent guidance

Default rules every contributor — human or AI — follows in this repo. These are guardrails, not handcuffs: if the user explicitly asks for something different, follow their lead.

This is a multi-customer Power Platform / Dataverse consulting repo (Context& / Projectum). Work here spans a dev environment plus several customer engagements under `customers/` — always know which environment you're in before writing anything.

## Startup

Run `/connect` at the start of every session before doing any Dataverse work.

`/connect` handles environment selection, authentication, solution context, and publisher prefix discovery automatically. Do not ask the user for the publisher prefix — it is derived from the solution's publisher record in Dataverse.

## Dataverse access

- Use the Dataverse Web API (REST/OData) for **all** data, metadata, solution, and security operations. This is mandatory — it's cross-platform, scriptable, and auditable without installing extra tooling.
- Use `pwsh` (PowerShell Core) for all scripts — never `powershell.exe`. All scripts must be cross-platform (Windows and macOS).
- Authenticate via OAuth2 (MSAL) or client credentials. Target API endpoint: `https://<org>.api.crm.dynamics.com/api/data/v9.2/`.
- Never use the default `new_` publisher prefix — always use the prefix derived from the active solution via `/connect`.
- **`pac` CLI exception**: the Web API has no equivalent for PCF project scaffolding or local test harness workflows. `pac` is allowed *only* for `pac pcf init`, the local PCF test harness, and `pac pcf push` during dev iteration. Every other operation (data, metadata, solution import/export, security roles) stays on the Web API — never `pac` for those.
- **Schema-first for `pum_*` tables**: read `docs/schema/<table>.md` before writing any `pum_` column name — don't guess. The committed schema was generated from the Projectum dev environment (`esben`) — it is orientation, not ground truth for customers. Before any write against a `/connect`'d customer environment, verify the fields you're using against live metadata (`.claude/skills/dataverse-api/get-entity-metadata.ps1`). On any conflict between the committed reference and live metadata, **live metadata wins**.

## Skills

Domain knowledge lives in `.claude/skills/`. Each skill is a folder containing `SKILL.md`. Load the relevant skill before starting work in that area.

| Skill | When to load |
|-------|-------------|
| `dataverse-api` | Making any Dataverse Web API call |
| `data-model` | Creating or modifying tables, columns, lookups, relationships |
| `security-roles` | Creating a new custom security role, or granting/revoking table privileges on an existing role |
| `xpm` | Working with Projectum xPM Essentials entities, picklists, or financial data |
| `xpm-processes` | Executing xPM processes via Dataverse MCP (create initiatives, status reports, resource allocations) or configuring the Power Heatmap PCF component |
| `resource-management` | RM concepts, terminology, stakeholder needs, failure modes, and consulting-grade responses — load as background when advising on any resource management topic |
| `model-router` | Spawning sub-agents via the Agent tool |
| `power-automate` | Building or modifying cloud flows |
| `copilot-studio` | Building or modifying Copilot Studio agents, connected agents, or agent tools (Dataverse searchQuery, List rows, Power Automate flows) |
| `copilot-skill-authoring` | Creating skill files for the Copilot Studio agent skill uploader |
| `business-skills` | Creating/updating Dataverse Business Skill records or their reference-file resources, or adding skills to a solution programmatically |
| `xrm-copilot` | Calling the Xrm.Copilot Client API (M365 Copilot + Copilot Studio) from model-driven app code, forms, web resources, or PCF |
| `microsoft-learn` | Deciding which Microsoft Learn MCP tool to use |
| `browser-testing` | Verifying records or UI state using the Chrome MCP |
| `model-driven-app` | Creating model-driven apps, updating forms (FormXml), updating views (FetchXml/LayoutXml) |
| `deploy` | Full ship flow — deploying changes to GitHub (build/package + push) |
| `git-push` | Git only — staging, committing, and pushing to remote, without a deploy step |
| `vibe-projects` | Spawning a new web resource / frontend project from the `context-and/vibe-template` GitHub template |

## Installed (plugin) skills & precedence

Beyond `.claude/skills/`, this environment has plugin-provided skills that overlap some of the above by topic: the `dataverse` plugin ships `dv-connect` / `dv-data` / `dv-metadata` / `dv-query` / `dv-security` / `dv-solution` / `dv-admin` / `dv-overview`; the `copilot-studio` plugin ships a generic Copilot Studio skill; `microsoft-docs` ships doc-lookup skills overlapping `microsoft-learn`.

**Local `.claude/skills/` always wins on overlap.** They encode this repo's actual constraints — Web API only, `/connect`-derived prefix, no `pac` outside PCF — that the generic plugin skills don't know about. Treat plugin skills as fallback/supplementary only, e.g. `microsoft-docs` for general doc lookups where no local skill exists.

For browser verification specifically: **`playwright-cli`** (installed plugin skill) is the primary tool for scripted, repeatable browser checks and Playwright test authoring. `browser-testing` (local, via `claude-in-chrome`) is for interactive/visual verification and Chrome-session-specific checks — live record state, PCF rendering in an existing browser session. Load `browser-testing` first; it points to `playwright-cli` for scripted scenarios.

## Sub-agents & MCPs

Custom sub-agents live in `.claude/agents/`. Load `model-router` before spawning any sub-agent via the Agent tool.

| MCP | When to use |
|-----|-------------|
| `microsoft-learn` | API docs, Dataverse schema questions, Power Platform reference |
| `claude-in-chrome` | Verifying record state in the UI, checking PCF rendering — load `browser-testing` skill first |
| `Gmail` | Sending status updates or reports on behalf of the user |
| `Google Calendar` | Scheduling project milestones or meetings |
| `Google Drive` | Reading shared specification documents |

## Customer environments

Customer connection configurations live in `customers/`. Each sub-folder represents one customer engagement.

- `customers/_template/` — copy this to create a new customer folder
- `customers/<name>/.env` — gitignored; written by `/connect` from credentials you provide at session start
- `customers/<name>/notes.md` — committed; reference notes for this customer (entities, solutions, known issues)

For customer sessions: run `/connect <name>` — you will be prompted for credentials and solution. Publisher prefix is auto-derived from the solution.

For the dev environment: run `/connect` (or `/connect dev`) — uses root `.env`, prefix auto-derived from solution.

## Spawning new projects

New web resource / frontend projects are spawned from the `context-and/vibe-template` GitHub template — never hand-rolled. Load `vibe-projects` for the exact command and post-clone checklist.

PCF (PowerApps Component Framework) projects are a different shape — scaffolded via `pac pcf init` (see the `pac` exception above), not this template.

## Compliance

- Never paste client data into AI prompts.
- `.env` files hold scoped credentials — secret, never commit, never paste into chat.
- Customer-tenant access is only via that customer's own credentials in `customers/<name>/.env`. Never bridge between clients.

## Never

- Use `DefaultAzureCredential` or `az` CLI auth.
- Use the default `new_` publisher prefix.
- Use `pac` for anything other than PCF scaffolding/dev-loop workflows (see the exception above) — Web API only for data, metadata, solutions, security.
- Use `powershell.exe` — always `pwsh`.
- Invent environment values — if `/connect` hasn't been run or credentials are missing, ask or run it.
- Guess `pum_*` (or any customer prefix) field names — read the schema reference or live metadata first.
- Hand-roll a new web resource project instead of spawning it from `vibe-template`.

## Context& / Projectum overlay

These naming and reference rules apply to Projectum-owned dev work (the xPM Essentials product itself). **For customer engagements, the `/connect`-derived publisher prefix always wins** — do not apply `pum` naming to a customer's solution.

### Naming (Projectum dev work only)

- Publisher unique + display name: `Projectum`. Prefix: `pum`.
- Solution unique name: `Pum{ProjectName}Solution` (e.g. `PumPowerGanttSolution`).
- Web resource name: `{prefix}_{snake_case_feature}` (e.g. `pum_power_gantt`).

### Schema reference

The committed schema at [`docs/schema/`](./docs/schema/index.md) covers 90+ xPM tables — logical names, types, required flags, lookup `@odata.bind` syntax, picklist option values. When a consultant names an entity ("initiatives", "risks", "the gantt tasks"), map it to the logical name from the index (`pum_initiative`, `pum_risk`, `pum_gantttask`, …) and open that table's `.md` for the fields.

The reference was generated from the Projectum dev environment (`esben`) via the internal `xpm-admin` toolkit's `gen-schema` command (see `vibe-template/README.md` / `npm run schema:refresh` for the regeneration flow). Regenerate and re-copy into `docs/schema/` when the dev schema changes; it is not auto-synced.
