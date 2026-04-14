# XPM Copilot Studio skills catalogue

Live index of every agent and skill in the XPM Copilot Studio library. Edit this file alongside the underlying YAML/JSON — `copilot-skill-builder` maintains it.

## Agents

| Agent | Kind | Role | Tools | Sample utterances |
|-------|------|------|-------|-------------------|
| `<prefix>_xpm_orchestrator` | orchestrator | Routes to connected agents | *(none)* | "What's the status of Atlas?", "Log a risk on Downtown Rollout", "Summarise Project Beta" |
| `<prefix>_xpm_risk_analyst` | connected | Risk domain | searchQuery on `pum_risk`, List rows on `pum_risk`, flow `<prefix>_skill_create_risk` | "Show me high-probability risks on Atlas", "Log a new risk about vendor delays, probability 4 impact 5" |
| `<prefix>_xpm_status_reporting` | connected | RAG status snapshots | searchQuery across `pum_project`/`pum_milestone`/`pum_task`, List rows, flow `<prefix>_skill_generate_status_report` | "Status report for Atlas", "Which projects are red?" |
| `<prefix>_xpm_project_summarization` | connected | Narrative summaries | searchQuery on `pum_project`, List rows on related tables, agent-native generation | "Summarise Atlas for the steering committee", "Give me a stakeholder brief on Downtown Rollout" |

## Flows

| Flow | Agent | Trigger | Inputs | Outputs | Solution |
|------|-------|---------|--------|---------|----------|
| `<prefix>_skill_create_risk` | Risk Analyst | When Copilot Studio calls a flow | `projectId`, `description`, `probability`, `impact`, `mitigation` (optional) | `riskId`, `riskScore`, `riskUrl` | XPMCopilotSkills |
| `<prefix>_skill_generate_status_report` | Status Reporting | When Copilot Studio calls a flow | `projectId`, `asOfDate` (optional) | `rag`, `narrative`, `milestoneSummary[]` | XPMCopilotSkills |

## Environment variables

| Name | Type | Used by | Purpose |
|------|------|---------|---------|
| _(none yet)_ | | | Add rows as env variables are introduced |

## Columns

- **Kind**: `orchestrator` or `connected`
- **Tools**: short list of the data-access mechanisms the agent owns (searchQuery / List rows / flow)
- **Sample utterances**: happy-path plus one negative or edge case per agent
- **Solution**: defaults to `XPMCopilotSkills` for flows; connection references and env variables also go there
