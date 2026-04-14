---
name: copilot-studio
description: Rules for building and maintaining Copilot Studio agents, connected agents, and agent tools for the XPM skill library. Load whenever authoring Copilot Studio YAML, wiring Dataverse tools, or integrating Power Automate flows as agent actions.
---

# Copilot Studio Agent Skills (XPM)

Authoritative guidance for building the **XPM orchestrator agent and its three connected agents** (Risk Analyst, Status Reporting, Project Summarization). Every artefact must remain editable by clients in the Power Platform maker portal.

## When to load this skill

- Building or modifying any Copilot Studio agent in this repo
- Adding / removing tools on an existing agent
- Registering a Dataverse table as a searchQuery or List rows tool
- Creating a Power Automate flow that will be surfaced as an agent action
- Wiring connected (child) agents under an orchestrator

## Mandatory pre-creation steps

Before creating **any** new Dataverse SchemaName (solution, flow, env variable, etc.):

1. **Ask the user for the publisher prefix.** Do not assume. Do not default to `new_` or any previously-used value. Prompt every time.
2. **Run schema discovery** if the artefact references Dataverse fields:
   `pwsh .claude/skills/power-automate/schema-dump.ps1` → read `schema_dump.json`.
3. **Confirm the target solution exists.** Default is `XPMCopilotSkills` (unmanaged). Create via `pwsh .claude/skills/data-model/add-to-solution.ps1` if absent.

## Runtime topology

```
<prefix>_xpm_orchestrator              (parent — routing only)
├── <prefix>_xpm_risk_analyst          (connected — risk domain)
├── <prefix>_xpm_status_reporting      (connected — RAG reports)
└── <prefix>_xpm_project_summarization (connected — narrative summaries)
```

The orchestrator owns no domain tools. Each connected agent owns a focused tool set from the data-access decision tree below. See `orchestrator-pattern.md` for rationale and maintenance guidance.

## Data access decision tree

For every new skill the agent needs, pick the **first** option that satisfies the requirement:

1. **Dataverse `searchQuery` unbound action** — fuzzy keyword relevance ranking across indexed tables. Zero user auth (maker-provided credentials). First choice for any "find me…" or "show me X about Y" utterance.
2. **Dataverse connector built-ins** (`List rows`, `Get row`, `Create row`, `Update row`) — structured filter / paging / specific columns. Use when `searchQuery` cannot return the required column set or precise filter.
3. **Power Automate cloud flow with Copilot Studio trigger** — use for mutations that require multi-step logic, validation, downstream side effects, or computed fields (e.g. risk score = probability × impact).
4. **MCP server via custom connector** (`x-ms-agentic-protocol: mcp-streamable-1.0`) — advanced. Only when the action targets a non-Dataverse API or a curated tool registry with runtime discovery. Subject to DLP restrictions; documented but not shipped by default.

Worked examples live in `data-access-decision-tree.md`.

## The seven maintainability rules

Every artefact this skill produces must satisfy all seven. `validate-yaml.ps1` enforces them.

1. **One verb per skill.** A flow does `create_risk`, not "manage risks". Splitting keeps the maker's mental model small.
2. **Naming convention.** Flows: `<prefix>_skill_<verb>_<noun>`. Agents: `<prefix>_xpm_<role>`. Solution: `XPMCopilotSkills`.
3. **Descriptions are mandatory.** Every agent, connected-agent reference, tool, input parameter, and output property carries a natural-language `description`. Copilot's orchestrator routes on descriptions — missing descriptions silently degrade routing quality.
4. **Connection references for every connector.** Never embed connection IDs inline. Clients rebind connections per tenant.
5. **Environment variables for tunables.** Thresholds, default views, escalation emails — all environment variables created via `pwsh .claude/skills/power-automate/create-env-variable.ps1` and referenced as `@parameters('schemaname (schemaname)')`.
6. **Try/Catch shape for every flow.** Extend `flow-copilot-trigger.json` — never roll your own. Errors log to the `pum_activitylog` table (see `dashboard/log-activity.ps1`).
7. **Solution membership.** Every flow, env variable, and connection reference is added to `XPMCopilotSkills` via `add-to-solution.ps1`. Agents themselves live in Copilot Studio and are cloned locally via the VS Code extension.

## Plugin integration — `microsoft/skills-for-copilot-studio`

This repo extends Microsoft's experimental plugin rather than replacing it. The plugin is the authoritative YAML author for Copilot Studio agents; our skill adds XPM-specific scaffolding, schema-discovery, flow wiring, and Dataverse tool registration around it.

**Install (inside Claude Code or GitHub Copilot CLI):**

```
/plugin marketplace add microsoft/skills-for-copilot-studio
/plugin install copilot-studio@skills-for-copilot-studio
```

**Plugin commands** (invoke with `/copilot-studio:<command>` after install):

| Command | Role in our workflow |
|---------|----------------------|
| `copilot-studio-manage` | Clone the empty agent from Copilot Studio, pull updates, push local edits back to the cloud |
| `copilot-studio-author` | Generate / edit YAML for topics, actions, knowledge, triggers, variables |
| `copilot-studio-test` | Point-tests, batch suites, evaluation analysis against a published agent |
| `copilot-studio-troubleshoot` | Debug routing errors, validation errors, unexpected orchestration |

**Prerequisites for push/pull:**
- VS Code with the Copilot Studio Extension installed (handles browser sign-in and cloud sync)
- Node.js 18+
- Claude Code or GH Copilot CLI (depending on where the plugin runs)

`install-plugin.ps1` checks prerequisites and prints the exact install commands for your environment.

## Templates in this skill

| File | Purpose |
|------|---------|
| `orchestrator-agent.yaml` | Parent-agent skeleton with `connectedAgents:` list and routing instruction |
| `connected-agent.yaml` | Reusable child-agent skeleton (name, description, instructions, tools, knowledge) |
| `tool-dataverse-searchquery.yaml` | YAML fragment for a Dataverse `searchQuery` tool |
| `tool-dataverse-listrows.yaml` | YAML fragment for a Dataverse `List rows` tool |
| `tool-flow-agent-action.yaml` | YAML fragment for a Power Automate flow tool |
| `flow-copilot-trigger.json` | Logic Apps definition: Copilot Studio trigger + try/catch + Respond to Copilot |

> **Schema caveat**: the Copilot Studio YAML schema is not publicly documented and may change. Our templates are illustrative scaffolds. For authoritative structure always run `/copilot-studio:copilot-studio-author` (from the Microsoft plugin) and let it regenerate the YAML — then diff against our templates to propagate XPM patterns.

## Scripts in this skill

| Script | Purpose |
|--------|---------|
| `install-plugin.ps1` | Verify prerequisites and print the plugin install commands for the detected host |
| `scaffold-xpm-agents.ps1` | Create the four XPM agent folders + YAMLs from templates, substituting a user-confirmed prefix |
| `validate-yaml.ps1` | Lint YAML and flow JSON for required descriptions, naming convention, and solution membership |
| `register-dataverse-tools.ps1` | Ensure the Dataverse tables used by `searchQuery` are in the search index; publishes customisations |

## Supporting docs

- `orchestrator-pattern.md` — runtime topology, rationale, and a maintenance story
- `data-access-decision-tree.md` — the four-tier tree with worked examples
- `maintainability-checklist.md` — the seven rules as a maker checklist

## Reuse — do not re-implement

- OAuth / headers: `helpers.psm1` (`Initialize-DataverseConnection`, `Get-DataverseHeaders`, `Invoke-DataverseRequest`)
- Schema dump: `.claude/skills/power-automate/schema-dump.ps1`
- Flow create/update: `.claude/skills/power-automate/create-flow.ps1`, `update-flow.ps1`, `toggle-flow.ps1`
- Env variables: `.claude/skills/power-automate/create-env-variable.ps1`
- Solution membership: `.claude/skills/data-model/add-to-solution.ps1`, `publish-customizations.ps1`
- Try/catch base: `flows/templates/try-catch-scope.json`
- Error logging: `dashboard/log-activity.ps1`
