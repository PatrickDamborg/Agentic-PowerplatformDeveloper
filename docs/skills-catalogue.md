# XPM Copilot Studio skills catalogue

Live index of every agent and skill in the XPM Copilot Studio library. Edit this file alongside the underlying YAML/JSON — `copilot-skill-builder` maintains it.

## Agents

| Agent | Kind | Role | Tools | Sample utterances |
|-------|------|------|-------|-------------------|
| `<prefix>_xpm_orchestrator` | orchestrator | Routes to connected agents | *(none)* | "What's the status of Atlas?", "Log a risk on Downtown Rollout", "Summarise Project Beta" |
| `<prefix>_xpm_risk_analyst` | connected | Risk domain | searchQuery on `pum_risk`, List rows on `pum_risk`, flow `<prefix>_skill_create_risk` | "Show me high-probability risks on Atlas", "Log a new risk about vendor delays, probability 4 impact 5" |
| `<prefix>_xpm_status_reporting` | connected | 5-dimension status snapshots | flow `<prefix>_skill_fetch_status_data` (single call, all dimensions); Dataverse MCP `read_query` for ad-hoc questions only | "Status report for Atlas", "Which projects are red?" |
| `<prefix>_xpm_project_summarization` | connected | Narrative summaries | searchQuery on `pum_project`, List rows on related tables, agent-native generation | "Summarise Atlas for the steering committee", "Give me a stakeholder brief on Downtown Rollout" |

## Flows

| Flow | Agent | Trigger | Inputs | Outputs | Solution |
|------|-------|---------|--------|---------|----------|
| `<prefix>_skill_create_risk` | Risk Analyst | When Copilot Studio calls a flow | `projectId`, `description`, `probability`, `impact`, `mitigation` (optional) | `riskId`, `riskScore`, `riskUrl` | XPMCopilotSkills |
| `<prefix>_skill_fetch_status_data` | Status Reporting | When Copilot Studio calls a flow | `initiativeId`, `mode` (optional, reserved for cache) | Full 5-dimension payload: `timeline`, `financials`, `scope`, `quality`, `resources`, `overall`, `trend`, `dataGaps[]` (see `flows/skills/pum_skill_fetch_status_data.json` schema) | XPMCopilotSkills |
| `<prefix>_skill_precompute_status_drafts` | Status Reporting (background) | Recurrence (Phase 2 — not yet deployed) | *(none — iterates all active initiatives)* | Writes/refreshes `pum_statusdraftcache` rows | XPMCopilotSkills |
| ~~`<prefix>_skill_generate_status_report`~~ | ~~Status Reporting~~ | *(deprecated, never deployed)* | — | — | — |

## Environment variables

| Name | Type | Used by | Purpose |
|------|------|---------|---------|
| `pum_HighRiskProbabilityThreshold` | Integer | `pum_skill_fetch_status_data` | Risk probability picklist value (default 976880003 = 60%) at/above which a risk counts toward "high probability" for the Scope rating |
| `pum_HighRiskImpactThreshold` | Integer | `pum_skill_fetch_status_data` | Risk impact picklist value (default 976880003 = 4-High) at/above which a risk counts toward "high impact" for the Scope rating |
| `pum_QualityLessonsLookbackDays` | Integer | `pum_skill_fetch_status_data` | Days to look back (default 30) for negative-impact Lessons Learned used as the Quality proxy signal |
| `pum_StatusCacheTTLHours` | Integer | `pum_skill_precompute_status_drafts` (Phase 2) | Hours a cached status draft is considered fresh before the fetch flow recomputes live |

## Columns

- **Kind**: `orchestrator` or `connected`
- **Tools**: short list of the data-access mechanisms the agent owns (searchQuery / List rows / flow)
- **Sample utterances**: happy-path plus one negative or edge case per agent
- **Solution**: defaults to `XPMCopilotSkills` for flows; connection references and env variables also go there
