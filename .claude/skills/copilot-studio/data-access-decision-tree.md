# Data access decision tree

For every agent capability, pick the **first** option that satisfies the requirement. Climb down only when a constraint forces it.

## 1. Dataverse `searchQuery` unbound action

Use when: the user's utterance is keyword-led ("show me risks about vendor delays on Atlas"), fuzzy matching helps, and the columns returned can be a fixed shortlist.

**Setup:**
1. In Copilot Studio: Tools → Add a tool → Dataverse connector → Perform an unbound action.
2. Authentication: **Maker-provided credentials** (service principal, zero end-user auth).
3. Inputs:
   - **Environment**: your Dataverse URL (custom value).
   - **Action Name**: literal string `searchquery`.
   - **entities**: JSON array of `{Name, SearchColumns, SelectColumns}` — one object per table.
   - **search**: leave dynamic; Copilot fills it from user keywords.
4. Tables must be enabled in Dataverse Search and the Quick Find view (see `register-dataverse-tools.ps1`).

**Example `entities` payload** (after schema-dump confirms field names):
```json
[
  {
    "Name": "pum_risk",
    "SearchColumns": ["pum_name", "pum_description"],
    "SelectColumns": ["pum_name", "pum_probability", "pum_impact", "_pum_project_value"]
  }
]
```

**Limits:** `filter` is a post-filter on ranked results, not a pre-filter across the whole table. Columns outside `SelectColumns` / `SearchColumns` require a follow-up `List rows` call.

## 2. Dataverse connector built-ins

Use when: you need a specific column set, a precise OData filter, paging, or a single-record fetch by id.

**Common operations:**
- `List rows` — structured query with `$filter`, `$select`, `$top`, `$orderby`.
- `Get row` — single record by primary id.
- `Create row` — when the create is simple (no validation, no computed columns, no side effects).
- `Update row` — simple field updates.

**When to prefer over searchQuery:** when the AI should reason over specific rows by filter criteria ("open risks with probability ≥ 4 on project X"), not by keyword relevance.

**Example instruction for List rows tool:** "Returns open risks for a project. Filter: `statecode eq 0 and _pum_project_value eq @{project_id} and pum_probability ge @{min_probability}`. Select: `pum_name, pum_probability, pum_impact, pum_mitigation`."

## 3. Power Automate cloud flow with Copilot Studio trigger

Use when: the action writes data **and** requires one of:
- Multi-step logic (find-then-update, create-then-notify)
- Validation the agent cannot reliably do itself
- Computed fields (risk score, RAG colour, rollup calcs)
- Side effects (Teams post, email, external API call)

**Template:** `flow-copilot-trigger.json` in this skill folder.

**Shape:**
- Trigger: "When Copilot Studio calls a flow" with typed inputs + descriptions.
- Try scope: schema-aware Dataverse actions.
- `Respond to Copilot` with a typed output schema (Copilot reads schema to render the response).
- Catch scope: log to `pum_activitylog`, respond with a structured error.

**Worked example — `<prefix>_skill_create_risk`:**
- Inputs: `projectId` (string, required), `description` (string, required), `probability` (int 1-5, required), `impact` (int 1-5, required), `mitigation` (string, optional).
- Actions: Create `pum_risk` with bound lookup to project, computed `pum_score = probability × impact`, linked `pum_owner` resolved dynamically from the triggering user.
- Outputs: `riskId`, `riskScore`, `riskUrl` (deep-link to the record).

## 4. MCP server via custom connector (advanced)

Use when: the action targets a **non-Dataverse** API or a catalogued registry of MCP endpoints that should be selectable at runtime. Example: an internal PPM-reporting service that already exposes an MCP interface.

**Setup sketch** (not shipped by default):
- Author a Swagger 2.0 definition for the connector.
- Declare the protocol: `"x-ms-agentic-protocol": "mcp-streamable-1.0"`.
- For dynamic instance selection, add `x-ms-dynamic-values` to the endpoint parameter and back it with a catalog service.

**Caveats:**
- DLP policies may block C# in custom connectors (required for URL rewriting patterns).
- Authentication for cross-environment MCP needs an OBO flow; keep it out of scope unless you have that plumbing.
- Monitoring and observability are thinner than with flows or built-in actions.

## Quick reference — which tool for which verb

| User verb | First choice |
|-----------|--------------|
| find, show, list by keyword | `searchQuery` |
| list by precise filter / date range | `List rows` |
| get this one | `Get row` |
| create simple record | `Create row` |
| create with validation / computed fields | Power Automate flow |
| update simple field | `Update row` |
| multi-step workflow | Power Automate flow |
| call external system | Custom connector (or flow via prebuilt connector) |
| runtime-selected endpoint | MCP custom connector (advanced) |
