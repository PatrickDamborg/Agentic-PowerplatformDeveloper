# XPM orchestrator + connected-agent pattern

## Why this topology

One agent cannot cover every PPM concern without instruction bloat and routing collisions. A parent orchestrator that delegates to **small, focused connected agents** produces better results for three reasons:

1. **Smaller prompts route better.** Each connected agent carries only the instructions for its domain, so Copilot's tool-selection prompt stays short and unambiguous.
2. **Isolated tool sets.** The Risk Analyst never sees status-report tools, so it cannot misfire. Changes to one domain do not regress others.
3. **Clearer maintenance surface.** A maker opens "Risk Analyst" to change risk behaviour. They do not need to read the orchestrator or the other agents.

```
<prefix>_xpm_orchestrator              (greeting, clarification, hand-off)
├── <prefix>_xpm_risk_analyst          (risk taxonomy, probability × impact)
├── <prefix>_xpm_status_reporting      (RAG snapshots, exec-tone summaries)
└── <prefix>_xpm_project_summarization (narrative summaries across project artefacts)
```

## Responsibilities

### Orchestrator
- Single-line greeting topic.
- One clarification topic that asks "which aspect — risks, status, or a summary?" when the user's intent spans multiple domains.
- Connected-agent references for the three children. No domain tools of its own.
- Instruction: "You are a project and portfolio management assistant. Route the user to the best connected agent based on the description of each."

### Risk Analyst
- Owns `pum_risk` read + write.
- `searchQuery` for discovery, `List rows` for structured pulls, flow `<prefix>_skill_create_risk` for mutation.
- Instruction emphasises probability × impact scoring, escalation thresholds (via env variable), and taxonomy.

### Status Reporting
- Owns multi-table reads across `pum_project`, `pum_milestone`, `pum_task`.
- `searchQuery` + `List rows` for data, flow `<prefix>_skill_generate_status_report` to assemble a RAG-colored narrative.
- Instruction enforces RAG convention and exec-tone output.

### Project Summarization
- Owns reads across `pum_project` and related tables — no flow initially.
- Produces narrative summaries by combining `searchQuery` (fuzzy project name resolution) + `List rows` (related artefacts) + the agent's own generative answer.
- Add an AI Builder prompt tool only if the agent's native generation is not specific enough.

## Maintenance story — adding a fourth connected agent

A client wants a Resource Allocation agent. Steps for a maker:

1. In Copilot Studio, create a new agent named `<prefix>_xpm_resource_allocation`.
2. Clone it locally via the VS Code Copilot Studio Extension.
3. Copy `connected-agent.yaml` from this skill into the new agent folder as a starting point; fill in instructions, tools, and description.
4. Run `pwsh .claude/skills/power-automate/schema-dump.ps1` to confirm `pum_resource` / `pum_assignment` logical names.
5. Add tools per the data access decision tree (searchQuery on `pum_resource`, List rows with date-range filter, optional flow for booking mutations).
6. Run `pwsh .claude/skills/copilot-studio/validate-yaml.ps1` against the new folder.
7. Push back to Copilot Studio via the VS Code extension.
8. In the **orchestrator agent**, open `orchestrator-agent.yaml`, add a new entry to `connectedAgents:` pointing at the new agent; keep the description concrete ("Handles questions about resource availability, allocation, and booking").
9. Push the orchestrator update.
10. Append a row to `skills-catalogue.md` documenting the new agent and its tools.

No code changes are required in this repo for the client to add the fourth agent — only YAML and Dataverse configuration.

## Anti-patterns to avoid

- **Orchestrator owning domain tools.** Concentrates routing load on one prompt; degrades as the tool list grows.
- **Connected agents calling each other directly.** Always route through the orchestrator to keep the dependency graph a tree.
- **Generic "PPM assistant" connected agents.** Splits must be by domain verb cluster (risks / reports / summaries), not by table.
- **Sharing a flow between connected agents.** Fork the flow or push the shared logic into a library flow that both call. Shared flows with multi-purpose parameters are hard to reason about.
