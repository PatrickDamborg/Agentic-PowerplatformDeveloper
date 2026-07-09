# xPM AI Demo — Copilot Studio Build Package

**Author:** Patrick Damborg  
**Environment:** pdausa (xPM Essentials, solution snapshot 2026-04-21)  
**Target platform:** Microsoft Copilot Studio  
**Date:** June 2026

---

## 1. Objective and context

This build delivers a working demo of six AI use cases on top of Projectum xPM Essentials. The goal is to prove — with live data, in front of consultants and leadership — that an AI agent can answer portfolio questions, draft status reports, capture ideas, surface resource gaps, run a standing PMO scan, and autonomously route a business case to a human approver, all directly from xPM's Dataverse tables. Each use case corresponds to a PoC that Projectum can sell and deliver repeatably, with a fixed timebox.

The demo does not need to be production-hardened. It needs to be convincing, correct, and reproducible. Every answer must cite the source records. Every write must require explicit human approval. The agent must never invent data.

---

## 2. What you are building

A single Copilot Studio agent (no orchestrator, no connected-agents topology) with the following components:

| Component | Description |
|---|---|
| **Agent** | One agent in Copilot Studio; model set to Claude Sonnet 4.6 |
| **Agent instructions** | Role definition, scope, guardrails, and routing logic (which skill to invoke for which request). Paste-ready blocks in `deliverables/COPILOT-STUDIO-INSTRUCTIONS.md` |
| **Skills** | Six SKILL.md files in agentskills.io format — one per use case (see Section 3). Located in `deliverables/skills/` |
| **Agent flows** | Power Automate flows triggered with "When an agent calls the flow" + "Respond to the agent" action. One flow per use case that needs structured data retrieval or write operations |
| **Workflow** | One Copilot Studio **workflow** (the new public-preview experience, built on the Workflows page — not Power Automate, not a classic agent flow) for PoC 06: Dataverse event trigger → agent node → Microsoft 365 Copilot node → Teams approval → owner notification. Solution-aware; consumes Copilot Studio capacity per action |
| **Prompt node** | Native Copilot Studio AI step (GA, May 2026) inside the Status Report Drafter flow. Handles narrative generation after deterministic data assembly. Model is selectable in the node |
| **Dataverse MCP** | Connected to `https://pdausa.crm.dynamics.com/api/mcp` for ad-hoc reads. Used for discovery queries and free-form Q&A in PoC 01 and PoC 04 |
| **Knowledge** | xPM data model grounding — entity names, deprecated tables, picklist semantics — loaded from `deliverables/skills/dataverse-mcp/` content |
| **Channels** | Microsoft Teams; M365 Copilot (requires admin approval); xPM model-driven app (agent pane or custom page) |

### Guardrails baked into agent instructions

These must appear verbatim in the agent's system instructions, not just in skill files:

- Read-only by default; writes only after the human has explicitly approved the shown draft in chat.
- Never call delete operations (`delete_record`, `delete_table`).
- Never touch deprecated tables `pum_GanttTeam` or `pum_Ganttuser`.
- Every answer must cite the source tables and record names/IDs it drew from.
- Never state or invent data not returned by a tool call.
- Declare on every draft write: "This record will not be saved until you confirm."

---

## 3. The six deliverables

### 3.1 PoC 01 — Ask Your Portfolio (read-only)

**Timebox:** 1 week

**User story:**  
A portfolio manager opens the Teams agent, types "Which initiatives are in trouble, and why?" and receives a ranked list — initiative, which KPI dimension is red, the top open risk, and the most overdue task — with every row linked back to its source table and record. They then ask a free-form follow-up and get an equally grounded answer.

**What to build:**

- SKILL.md file at `deliverables/skills/ask-portfolio/SKILL.md` describing the procedure:
  1. Run `describe` on `pum_StatusReporting` to confirm KPI column names at runtime (never hardcode).
  2. `read_query` for the latest status report per initiative where any `KPICurrent*` picklist is at its worst value. Inspect picklist metadata first to determine which integer value equals "red".
  3. For each flagged initiative, pull open `pum_Risk` records and overdue `pum_GanttTask` rows (finish date past today, percent complete < 100).
  4. Respond with a ranked trouble list: initiative name, which KPI is red, top risk, most overdue task.
  5. End every response with a sources block: tables queried, record names or counts.
- Dataverse MCP connection is the only tool needed (no agent flow required for this PoC).
- Backup query patterns the skill should know: initiatives per portfolio; business drivers with most ideas; initiatives with no status report in 30 days.

**Acceptance criteria:**

1. Given at least two initiatives with a red/worst KPI rating in `pum_StatusReporting`, the agent returns a ranked list identifying them correctly without prompting for clarification.
2. The response cites specific record names and the tables queried (e.g., "`pum_StatusReporting`, `pum_Risk`, `pum_GanttTask`").
3. If no data matches the query, the agent says so and shows the query it ran — it does not fabricate records.
4. A free-form follow-up question (e.g., "How many initiatives are in the EMEA portfolio?") is answered in a second turn using live data.
5. The agent does not touch `pum_GanttTeam` or `pum_Ganttuser` at any point.

---

### 3.2 PoC 02 — Status Report Drafter (one approved write)

**Timebox:** 3 weeks

**User story:**  
A PM types "Draft a status report for initiative Horizon." The agent assembles schedule data, open risks, and the previous status report trend, then displays a full draft in chat — proposed KPI ratings for Cost, Schedule, Scope, Resources, Quality, and Summary, each with a one-line data-backed justification, plus a 4–6 sentence narrative. The PM reviews, types "yes", and the record is created in `pum_StatusReporting`. The agent returns the record GUID and tells the PM where to find it in the xPM app.

**What to build:**

- SKILL.md file at `deliverables/skills/status-report-drafter/SKILL.md` describing the procedure:
  1. Resolve the initiative name to a GUID via `searchQuery` / `search_data`.
  2. Gather: schedule health from `pum_GanttTask` (overdue count, upcoming milestones); open `pum_Risk` records; latest existing `pum_StatusReporting` row for prior-period trend.
  3. Hand off to the **Status Report Drafter agent flow** (see below).
  4. Display the draft returned by the flow in chat with a clear approval prompt: "This record will not be saved until you confirm."
  5. On explicit "yes", call the flow's write step (or a second flow) to `create_record` on `pum_StatusReporting` linked to the initiative.
  6. Return the created record GUID and the app navigation path.
- **Agent flow — Status Report Drafter:**
  - Trigger: "When an agent calls the flow"; inputs: initiative GUID, gathered data payload.
  - Steps: query `pum_GanttTask`, `pum_Risk`, `pum_StatusReporting` via Dataverse connector to assemble structured facts.
  - **Prompt node** (Claude Sonnet 4.6 selectable in the node): takes the structured facts as input, produces the KPI ratings with justifications and narrative prose.
  - Output: draft object returned to agent via "Respond to the agent" action.
  - Separate flow (or second path in the same flow) handles the `create_record` write after approval.
- KPI rating justifications must reference actual record data (e.g., "Schedule: Amber — 4 of 31 tasks overdue, worst by 18 days").

**Acceptance criteria:**

1. Given an initiative name, the agent returns a draft with all six KPI dimensions (Cost, Schedule, Scope, Resources, Quality, Summary), each with a rating and a justification that cites at least one specific number or record name from the live data.
2. The draft includes a 4–6 sentence narrative summarising the overall health of the initiative.
3. The agent displays "This record will not be saved until you confirm" before any write action.
4. The record is not created if the user says anything other than an explicit confirmation.
5. On confirmation, a `pum_StatusReporting` record is created linked to the correct initiative; the agent returns the GUID.
6. If the initiative name does not resolve, the agent asks for clarification — it does not guess or use a wrong GUID.

---

### 3.3 PoC 03 — Idea Intake and Qualification (one approved write)

**Timebox:** 3 weeks

**User story:**  
A business stakeholder opens the Teams agent and types "I have an idea: we should build a self-service analytics portal for project sponsors." The agent acts as an intake assistant, asks at most three clarifying questions (problem, expected value, urgency), checks for existing duplicates in `pum_Idea`, then proposes a record: title, description, best-fit Business Driver (`pum_InvestmentCategory`), and Strategic Objective (`pum_StrategicObjectives`), with reasoning shown for each link. The stakeholder confirms, and the idea record is created with the strategy links populated. The agent reports back with the GUID and the "wow" line: which objective and driver the idea now supports.

**What to build:**

- SKILL.md file at `deliverables/skills/idea-intake/SKILL.md` describing the procedure:
  1. Enter intake mode: ask at most three questions covering problem, expected value, urgency. Do not ask all three at once; adapt based on what the user already said.
  2. Duplicate check: `search_data` across `pum_Idea` for similar titles or descriptions. If candidates exist, list them and ask whether to proceed.
  3. Discover available `pum_InvestmentCategory` and `pum_StrategicObjectives` records at runtime — never hardcode GUIDs.
  4. Propose the record in chat: title, description, chosen Business Driver (with reasoning), chosen Strategic Objective (with reasoning). Include "This record will not be saved until you confirm."
  5. On explicit yes, call the Idea Intake agent flow to `create_record` on `pum_Idea` with the strategy link fields populated.
  6. Return the GUID and the strategy alignment statement.
- **Agent flow — Idea Intake:**
  - Trigger: "When an agent calls the flow"; inputs: title, description, `pum_InvestmentCategory` GUID, `pum_StrategicObjectives` GUID.
  - Action: `create_record` on `pum_Idea` with OData bind references for the lookup fields.
  - Output: new record GUID returned via "Respond to the agent" action.

**Acceptance criteria:**

1. The agent does not ask more than three clarifying questions before proposing the record.
2. The duplicate check runs before the proposal; if a likely duplicate exists, the agent surfaces it and asks whether to proceed rather than creating a second record silently.
3. The proposed record shows which Strategic Objective and Business Driver were selected, with one sentence of reasoning for each choice, drawn from what exists in the environment.
4. The record is not created until the user explicitly confirms.
5. On confirmation, the created `pum_Idea` record is linked to both the `pum_InvestmentCategory` and `pum_StrategicObjectives` records; the GUID is returned.
6. If there are no Strategic Objectives or Business Drivers in the environment, the agent says so rather than failing silently.

---

### 3.4 PoC 04 — Resource and Capacity Assistant (read-only)

**Timebox:** 3–6 weeks

**User story:**  
A PMO director types "Where will staffing hurt next quarter?" The agent aggregates proposed versus committed effort per resource plan and role for the next quarter, computes the gap, ranks initiatives by uncovered demand, and lists candidate resources who could fill the largest gap. The answer shows demand that was proposed but never committed — the gap that no standard report surfaces.

**What to build:**

- SKILL.md file at `deliverables/skills/resource-capacity/SKILL.md` describing the procedure:
  1. `describe` `pum_Propose` and `pum_Commit` to confirm period and effort column names at runtime.
  2. `read_query`: aggregate proposed effort vs committed effort per `pum_ResourcePlan` header and `pum_Role` for the next quarter date range.
  3. Compute the gap (proposed minus committed) per role per initiative. Rank by uncovered demand descending.
  4. For the top gap, query `pum_Resource` filtered by the needed `pum_Role` to list candidate people.
  5. Respond with: gap table (initiative, role, proposed hours, committed hours, gap hours) and the candidate list for the top gap.
  6. Cite source tables: `pum_ResourcePlan`, `pum_Propose`, `pum_Commit`, `pum_Resource`, `pum_Role`.
- Dataverse MCP connection is the only tool needed; no agent flow required.
- Resource plan creation order is `pum_ResourcePlan` header → `pum_Propose` / `pum_Commit` rows; queries must respect this hierarchy.

**Acceptance criteria:**

1. Given resource plan data for the next quarter, the agent returns a gap table with at least initiative name, role, proposed hours, committed hours, and the delta.
2. The table is ranked by gap size descending.
3. For the role with the largest uncovered demand, the agent lists at least one candidate resource from `pum_Resource` matching that role.
4. No write operations are triggered at any point during this flow.
5. The response cites `pum_Propose`, `pum_Commit`, and `pum_Resource` as sources.
6. If no resource plans exist for the next quarter, the agent says so and shows the date range it queried.

---

### 3.5 PoC 05 — Portfolio Watchdog (read-only digest)

**Timebox:** 6 weeks

**User story:**  
On Monday morning, the PMO channel in Teams receives a digest: overdue tasks grouped by initiative, initiatives with no status report in 30-plus days, and risks with no owner or past their review date. Each item is severity-ranked, capped at 10 items total, and includes the record name, what is wrong, and a suggested action. The digest looks exactly like something a PMO would want in their inbox.

**What to build:**

- SKILL.md file at `deliverables/skills/portfolio-watchdog/SKILL.md` describing the procedure:
  1. Run three `read_query` sweeps:
     - Overdue `pum_GanttTask`: finish date passed today, percent complete < 100, grouped by initiative. Return initiative name, count of overdue tasks, worst overdue date.
     - `pum_Initiative` with no linked `pum_StatusReporting` record in the last 30 days. Return initiative name and last report date (or "never").
     - `pum_Risk` with no owner assigned or with a past review date. Return risk name, initiative name, what is missing.
  2. Merge the three sweep results into a single severity-ranked list (max 10 items). Severity: missing owner on a risk > overdue tasks on critical initiative > stale status report.
  3. Format the digest with three columns per row: record name / what is wrong / suggested action.
  4. Do not write anything. Close with the statement: "In the 6-week PoC, this digest posts itself to the PMO channel every Monday at 07:00 — and drafts the follow-up change requests for approval."
- **Agent flow — Portfolio Watchdog (for the scheduled/autonomous variant):**
  - Trigger: scheduled (recurrence) or "When an agent calls the flow" for the manual demo path.
  - Steps: the three Dataverse queries above via Dataverse connector.
  - Output: formatted digest string returned to the agent or posted directly to a Teams channel via the Teams connector.
  - Note: the scheduled autonomous path is the 6-week deliverable; the on-demand manual path ("Run the Monday morning scan") is achievable in the 3-week window and is sufficient for the demo.

**Acceptance criteria:**

1. Typing "Run the Monday morning scan" triggers the full three-sweep sequence without further prompting.
2. The response lists overdue tasks (grouped by initiative), stale status reports, and ownerless/overdue risks as distinct sections.
3. The list is severity-ranked and capped at 10 items.
4. Each item contains: record name, description of the problem, suggested action.
5. No records are created, updated, or deleted during the scan.
6. The digest format is clean enough to be copied directly into a Teams message — no raw GUIDs, no JSON fragments visible to the user.

---

### 3.6 PoC 06 — Business Case Approval (autonomous, human-in-the-loop)

**Timebox:** 6 weeks (demoable subset in 3 — see note at the end of this section)

**User story:**
An initiative qualifies as a large project, so it follows the large-project business process flow in xPM. At the **Business Case** stage, the PM sets **Send Approval** to Yes and picks the **Approver** — two fields on the BPF stage itself, no chat involved. Saving the record wakes a Copilot Studio workflow autonomously: it calls the xPM agent to assemble a business case summary from live data (description, strategy links, cost plan, top risks, proposed resource demand), has Microsoft 365 Copilot turn that structured summary into a decision-ready message, and sends it to the approver as a Teams approval. The approver reads the summary in the Teams Approvals app and approves. The workflow advances the initiative to the next BPF stage and posts a Teams message to the project owner: "Your business case for Horizon was approved by Maria Olsen." On rejection, the owner gets the rejection and the approver's comments instead, and the stage does not move.

**What to build:**

- **Two new columns on `pum_Initiative`**, surfaced on the Business Case stage of the BPF:
  - **Send Approval** — Yes/No, default No.
  - **Approver** — lookup to User (`systemuser`).
  - Add them in the maker portal inside the build solution; logical names take your solution's publisher prefix (e.g. `pda_sendapproval`, `pda_approver`) — discover them at runtime, never assume. These columns are added by you, the maker — **never by the agent** (the no-schema-changes guardrail in Section 2 is about agent tool calls, not your build work).
- **BPF stage edit:** confirm the existing xPM initiative BPF used for large projects, and add both columns to its Business Case stage.
- **SKILL.md** at `deliverables/skills/business-case-approval/SKILL.md` — the summarization procedure the agent executes. The same skill is demoable conversationally ("Summarize the business case for Horizon") and is what the workflow's agent node invokes.
- **Workflow — Business Case Approval.** Build this as a **workflow** on the Copilot Studio **Workflows** page (New workflow — the redesigned public-preview canvas with native AI actions and node-level testing). It is not a Power Automate cloud flow and not a classic agent flow. Steps:
  1. **Trigger:** Dataverse "When a row is added, modified or deleted" — change type Modified, table Initiative, scope Organization. Configure the trigger so it fires **only** when Send Approval = Yes AND Approver is populated (select the two columns as the watched columns and filter rows on both values). This double condition is also the infinite-loop guard: the workflow's own write-back resets Send Approval to No, which can never satisfy the condition.
  2. **Get the initiative row** (Dataverse Get row by ID): name, owner, and the Approver lookup.
  3. **Agent node** (AI capabilities): call the published xPM demo agent with the message "Summarize the business case for initiative `<GUID>` following the business-case-approval skill." Configure **structured output** with the skill's contract fields: `summary`, `financialEnvelope`, `strategicAlignment`, `topRisks`, `resourceDemand`, `recommendation`, `sources`. The agent — with its Dataverse MCP tools and guardrails — does the data gathering and reasoning; the workflow stays deterministic.
  4. **Microsoft 365 Copilot node:** generate the approver-facing message from the agent node's structured output. Prompt constraints: executive tone, ≤200 words, lead with the ask ("Approve the business case for `<name>`"), then the financial envelope, strategy alignment, the top risk, and the agent's recommendation. The node must only restate the structured output — it must not add facts.
  5. **Approval (human in the loop):** start-and-wait approval assigned to the Approver from the trigger record. Title: "Business case approval — `<initiative name>`". Details: the generated message plus a link to the initiative record in the xPM app. The approver responds in the Teams Approvals app (or Outlook).
  6. **Condition on the approval outcome:**
     - **Approved:** advance the BPF — update the active stage on the initiative's BPF instance from Business Case to the next stage. (BPF instances live in their own Dataverse table created alongside the BPF; discover the table name and stage GUIDs at build time — do not hardcode either.) Then post a Teams message (Flow bot → chat with the project owner): approved, by whom, when, with the record link. Finally reset Send Approval to No.
     - **Rejected:** post the rejection and the approver's comments to the project owner; reset Send Approval to No; leave the stage unchanged.

**Acceptance criteria:**

1. Setting Send Approval = Yes with Approver populated on the Business Case stage starts the workflow without any chat interaction. Populating only one of the two fields starts nothing.
2. The approval arriving in the approver's Teams Approvals app contains a business case summary grounded in live data — financial envelope, strategy alignment, and at least one named risk — verifiable against the source records, with no invented facts.
3. The summary is produced by the agent node calling the published agent (visible in the workflow run history), not hardcoded in the workflow; the message text comes from the Microsoft 365 Copilot node.
4. On Approve: the initiative's BPF active stage advances to the stage after Business Case, and the project owner receives a Teams message naming the approver.
5. On Reject: the BPF stage does not move, and the owner receives the rejection with the approver's comments.
6. The workflow never retriggers itself: after a run completes, Send Approval is No and no second run has started.
7. The only Dataverse writes in the entire workflow are the BPF stage advance and the Send Approval reset. No deletes anywhere.

**Demo-vs-PoC note:** the 3-week demoable subset is trigger → agent summary → M365 Copilot message → Teams approval → owner notification (criteria 1–3, 5, 6). The BPF stage advance (criterion 4) is the fiddliest part — BPF instance tables and stage GUIDs are environment-specific — and is the 6-week deliverable, mirroring how PoC 05 treats its scheduled variant.

---

## 4. Build sequence and dependencies

Build in this order. Do not test a skill against a flow until the flow is active and returning responses; inactive flows will silently fail.

1. **Dataverse MCP connection** — verify the MCP server is enabled at `https://pdausa.crm.dynamics.com/api/mcp` in the Power Platform admin center for the pdausa environment. Confirm that `search`, `describe`, `read_query`, `search_data`, `create_record`, and `update_record` are all reachable. Do not proceed until this is confirmed.

2. **Agent scaffold** — create the Copilot Studio agent, set the model to Claude Sonnet 4.6, paste the agent instructions from `deliverables/COPILOT-STUDIO-INSTRUCTIONS.md` (base block + routing + task blocks), configure the Dataverse MCP tool toggles per that document's Section 2, and publish a minimal version. Verify the agent responds in Teams before adding any skills or flows.

3. **PoC 01 — Ask Your Portfolio** — no flow needed. Wire the Dataverse MCP as a tool, load the `ask-portfolio` SKILL.md as a skill. Test end-to-end with the acceptance criteria queries. This is the fastest confidence check on the MCP + skill loop.

4. **PoC 04 — Resource and Capacity Assistant** — no flow needed. Same pattern as PoC 01 but more complex queries. Load `resource-capacity` SKILL.md. Requires `pum_ResourcePlan`, `pum_Propose`, and `pum_Commit` data to be present and representative.

5. **Status Report Drafter flow** — build and activate the Power Automate flow (Trigger: "When an agent calls the flow"; Prompt node; "Respond to the agent"). Test the flow in isolation using its built-in test harness before wiring it to the agent. Only then load `status-report-drafter` SKILL.md and test PoC 02 end-to-end.

6. **PoC 02 — Status Report Drafter** — wire the flow from step 5 to the agent. Test the full draft-review-confirm-create sequence. Confirm the write creates a correctly linked `pum_StatusReporting` record.

7. **Idea Intake flow** — build and activate the Power Automate flow for record creation. Test in isolation. Load `idea-intake` SKILL.md.

8. **PoC 03 — Idea Intake and Qualification** — wire the flow. Test the interview → duplicate check → draft → confirm → create sequence. Confirm strategy links are populated on the created record.

9. **Portfolio Watchdog flow (manual trigger path)** — build the flow with "When an agent calls the flow" trigger and three Dataverse queries. Activate and test in isolation. Load `portfolio-watchdog` SKILL.md. Test PoC 05 on-demand digest.

10. **PoC 06 — Business Case Approval** — build this last: the workflow's agent node calls the *published* agent, so the agent and its skills (including `business-case-approval`) must already work conversationally. Sequence within the step: (a) add the two columns to `pum_Initiative` and surface them on the BPF Business Case stage; (b) verify "Summarize the business case for `<initiative>`" works in chat; (c) build the workflow on the Workflows page and use node-level testing to validate the agent node and M365 Copilot node outputs before wiring the approval; (d) test end-to-end from the xPM form with a real approver account.

11. **Channels** — once all six PoCs pass acceptance criteria, configure Teams channel and submit the M365 Copilot channel for admin approval. Test agent pane in the xPM model-driven app if the custom page is in scope.

---

## 5. Prerequisites

Before starting the build, confirm each of the following is in place.

| Prerequisite | Detail |
|---|---|
| **Copilot Studio access** | Maker access on the pdausa tenant. Confirm you can create agents and agent flows in the pdausa environment (not a personal environment). |
| **Copilot Studio capacity** | At minimum one Message Capacity pack, or a pay-as-you-go billing profile attached to the environment. Claude Sonnet 4.6 as the agent model requires Copilot Studio capacity — it does not run on the free tier. |
| **Dataverse MCP enabled** | MCP server must be enabled for the pdausa environment in the Power Platform admin center. URL: `https://pdausa.crm.dynamics.com/api/mcp`. Verify `search` returns xPM table metadata before anything else. |
| **Representative xPM data** | The pdausa environment must contain: at least 5 initiatives; status reports with mixed KPI ratings (green/amber/red); open risks (some with no owner); at least one initiative with overdue tasks; resource plans with both proposed and committed rows; at least two ideas; one or more Strategic Objectives and Business Drivers; and for PoC 06, at least one initiative on the large-project BPF sitting at the Business Case stage with a cost plan, strategy links, and open risks. Without this, acceptance criteria cannot be validated. |
| **Connection references** | Two standard connection references must be configured in the pdausa environment before flows can be activated: `shared_commondataserviceforapps` (Dataverse connector) and `shared_logicflows` (used by agent flow infrastructure). Both should already exist if xPM is installed; confirm they are not broken/orphaned. |
| **M365 Copilot admin approval** | Publishing to the M365 Copilot channel requires a tenant admin to approve the agent in the Microsoft 365 admin center. Raise this request early — it is a blocker for that channel only and does not block Teams. |
| **Workflows (public preview)** | PoC 06 is built as a Copilot Studio **workflow** (Workflows page → New workflow). Confirm the preview is available in the pdausa environment. Preview features are not for production and can change — acceptable for this demo, but flag it in the demo narrative. |
| **M365 Copilot license** | The Microsoft 365 Copilot node in the PoC 06 workflow calls M365 Copilot — the account the workflow runs as needs an M365 Copilot license. |
| **Teams Approvals app** | The PoC 06 approval lands in the approver's Teams Approvals app. Confirm the app is not blocked by Teams app policies for the approver account, and that the Approvals capability works in the tenant. |
| **Customization rights** | PoC 06 adds two columns to `pum_Initiative` and edits the Business Case stage of the initiative BPF. The build account needs system customizer rights in pdausa and an unmanaged build solution to hold the columns and the workflow. |
| **SKILL.md files** | The six skill files live under `deliverables/skills/` (one subfolder per skill: `ask-portfolio/`, `status-report-drafter/`, `idea-intake/`, `resource-capacity/`, `portfolio-watchdog/`, `business-case-approval/`). These are the SKILL.md files in agentskills.io format. They are either already provided or are the primary build output depending on what has been handed over. Check with Patrick before duplicating effort. |
| **Access account** | The account used to build and test must have the xPM security roles needed to read portfolios, initiatives, status reports, risks, resource plans, and ideas. Confirm the account is not scoped to a single business unit that would hide most records. |

---

## 6. Explicitly out of scope

Do not build, configure, or spend time on any of the following:

- Multi-agent / orchestrator topology. This is a single agent. No connected-agents wiring. (The PoC 06 workflow calling that same agent through an agent node is workflow orchestration, not a multi-agent topology — do not add a second agent for it.)
- `pac` CLI commands, solution packaging, or ALM pipeline setup.
- Deployment scripts or any form of environment-to-environment transport.
- Production rollout, security hardening, Entra agent identity, or DLP policy configuration.
- Governance objects beyond what the demo requires (no evaluation test sets, no agent inventory configuration).
- Autonomous scheduled runs of the Portfolio Watchdog — the demo path is on-demand ("Run the Monday morning scan"). The scheduled flow is the 6-week PoC deliverable, not the demo.
- Any interaction with deprecated tables `pum_GanttTeam` or `pum_Ganttuser`.
- Dataverse schema changes (`create_table`, `update_table`, `delete_table`). Never call these. (This guardrail is about agent tool calls at runtime — the two PoC 06 columns are added by you in the maker portal as part of the build solution, which is fine.)
- Bulk or batch writes. Every write is a single record created after explicit human approval.

---

## 7. Definition of done — hand-off criteria

The build is done when the following are true:

1. **All six acceptance criteria sets pass** (Sections 3.1–3.6) against live data in the pdausa environment. Each test must be run with real xPM data, not stub responses. (For PoC 06 in the 3-week window, the demoable subset defined in Section 3.6 is sufficient.)

2. **The agent is published and reachable in Teams** on the pdausa tenant. A reviewer can open Teams, find the agent, and run each of the five conversational demo prompts without accessing Copilot Studio. The PoC 06 scenario is triggered from the Business Case stage in the xPM app, not from chat — the reviewer flips Send Approval and picks an Approver on a test initiative.

3. **All flows and the PoC 06 workflow are active** in the pdausa environment. Nothing is draft or suspended. Connection references are resolved.

4. **The agent instructions document the guardrails** as listed in Section 2. The instructions are visible in the agent's configuration in Copilot Studio and have not been stripped out.

5. **A brief run-through document or screen recording** is provided showing each of the six demo scenarios executed end-to-end, with the agent's response visible — for PoC 06, the recording should show the form fields being set, the approval arriving in Teams, and the owner notification after approving. This does not need to be polished — a Loom or Teams recording is sufficient. The purpose is to confirm the build works before hand-off, not to produce a deliverable for the client.

6. **SKILL.md files are finalised** in `deliverables/skills/` (one per use case). If skills were modified during build to correct field names, query patterns, or flow input schemas, the committed version in `deliverables/skills/` must match what is loaded in the agent.

Hand-off is back to Patrick Damborg (pda@contextand.com). Raise blockers early — data gaps and connection reference issues are the most common delays on this kind of build.

---

## 8. Running cost and ROI summary

Full model with assumptions and sources: `CREDIT-COST-AND-VIABILITY.md` (rates verified against Microsoft Learn, June 2026). The build itself consumes ~nothing — test runs from the flow designer and the agent test chat are free of Copilot Credit charges.

**Per-use-case running cost** (mid-size PMO: 20 PMs, 30 reporting initiatives, 20 ideas + 3 business cases/month, weekly watchdog; pay-as-you-go $0.01/credit, unlicensed worst case; estimates ±50%):

| # | Use case | Credits/run | Credits/month | $/month (PAYG) | Value/month | Sell as |
|---|---|---|---|---|---|---|
| 01 | Ask Your Portfolio | ~20/question | ~6,000 | ~$60 | $1.1–6.7k time saved | Sell first |
| 02 | Status Report Drafter | ~25 | ~750 | ~$8 | $1.4–2.7k time saved | The anchor |
| 03 | Idea Intake | ~30 | ~600 | ~$6 | ~$0.5k + dedup | Bundle filler |
| 04 | Resource & Capacity | ~40 | ~320 | ~$3 | Episodic, large per event | Qualified fits |
| 05 | Portfolio Watchdog | ~27 | ~120 | ~$1 | $0.4–0.7k + earlier intervention | Retention hook |
| 06 | Business Case Approval | ~35 | ~105 | ~$1 | Gate cycle-time + audit trail | The vision closer |
| | **Total** | | **~7,900** | **~$79** | | |

**The three facts that frame every pricing conversation:**

1. All six use cases together consume less than a third of one $200/25,000-credit capacity pack per month.
2. Usage by Microsoft 365 Copilot-licensed users is zero-rated — a licensed pilot group runs the conversational use cases at $0.
3. Credit cost is therefore noise; the business case rests on time saved (PoC 01/02/05), decision quality (03/04), and governance cycle-time (06) — and the real cost line is the build timebox plus any M365 Copilot licenses.

Validate these estimates once live: Power Platform admin center → Licensing → Copilot Studio → consumption details, and the [Copilot Studio agent usage estimator](https://microsoft.github.io/copilot-studio-estimator/) pre-deployment.
