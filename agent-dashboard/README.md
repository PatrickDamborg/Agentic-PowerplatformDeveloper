# MDA Agent Dashboard — Autonomous Agent Command Center

A model-driven-app dashboard for **firing and monitoring autonomous agents** built on
Copilot Studio's **new Workflows experience**. React 18 + Fluent UI v9, shipped as a
single self-contained Dataverse web resource — with the beloved pixel-art office
workers still doing the typing.

**What it does**

- Shows **only autonomous agents** (rows in `pda_monitoredagent` with
  `pda_agenttype` = Autonomous). The table keeps its Copilot Studio choice too —
  Copilot agents simply don't appear here (the legacy dashboard in
  [`agent-monitor/`](agent-monitor/) still covers them).
- **Fire** an agent with one click — the dashboard writes a "User" row to the
  out-of-box `agentconversationmessage` table, and the workflow's own
  Dataverse trigger ("When a row is added") reacts to it. No HTTP trigger, no
  OAuth, no secrets — see "Firing agents" below.
- Click a card → a **Fluent sidepane** opens with the actions the ongoing run is
  performing (live-polled from Dataverse), plus run history.
- When the workflow needs a decision, an **approval/input panel** appears right in
  the sidepane. Approve/reject with a comment; the workflow resumes.
- **Demo mode** (`?demo=1`, or opening the file outside Dataverse): four sample
  agents with an interactive fire + approval experience. Perfect for demos.

Everything is Dataverse-first: configuration, run telemetry, and approvals are
plain Dataverse rows read/written with the signed-in user's privileges.

---

## Build & deploy

```bash
npm install
npm run build       # → dist/pda_agentdashboard.html (single file, ~600 KB)
npm run verify      # Playwright end-to-end pass against the built file in demo mode
npm run dev         # local dev server (auto demo mode — no Xrm outside Dataverse)
```

Upload `dist/pda_agentdashboard.html` as a **web resource** named
`pda_agentdashboard.html`, publish, and open it from your model-driven app
(e.g. `/WebResources/pda_agentdashboard.html`). The legacy
`agent-monitor.html` web resource can stay deployed side-by-side.

## Dataverse schema

### 1. Config table `pda_monitoredagent` (existing)

Columns used: `pda_name`, `pda_agenttype` (100000000 Copilot Studio /
100000001 Autonomous), `pda_targetid` (the workflow GUID — this is also what
firing uses to tell the workflow's Dataverse trigger which agent a message is
for). The dashboard queries only Autonomous rows.

`pda_scope` (Choice: Initiative `100000000` · Program `100000001` · Portfolio
`100000002`) tells the dashboard's project-picker dialog which table to browse
before firing this agent, and which lookup column on `pda_agentruns` to bind
the selection to (see "Firing agents" below).

`pda_triggerurl` (Text (URL), 2000) still exists on this table from an earlier
HTTP-trigger design but is no longer used to fire agents (see "Firing agents"
below) — kept only in case a future agent is built as a classic HTTP-triggered
flow instead.

### 2. New table `pda_agentaction` — the workflow's live action log

Standard table, **organization-owned** (a shared monitoring view shouldn't depend
on row sharing).

| Display | Logical name | Type | Choices |
|---|---|---|---|
| Name (primary) | `pda_name` | Text 200 | step label, e.g. "Draft weekly summary" |
| Agent Id | `pda_agentid` | Text 100 | the workflow GUID (= `pda_targetid`) |
| Run Id | `pda_runid` | Text 100 | correlation id — the dashboard's `fireId`, or the run name |
| Action Type | `pda_actiontype` | Choice | Step `100000000` · Approval `100000001` · Input `100000002` |
| Status | `pda_status` | Choice | Running `100000000` · Completed `100000001` · Failed `100000002` · WaitingForInput `100000003` |
| Detail | `pda_detail` | Multiline 4000 | step detail / the question for the PM |
| Response | `pda_response` | Multiline 4000 | the PM's typed answer (dashboard writes) |
| Response Option | `pda_responseoption` | Choice | Approved `100000000` · Rejected `100000001` |
| Start Time | `pda_starttime` | DateTime | |
| End Time | `pda_endtime` | DateTime | |

Security roles: read on `pda_monitoredagent`, `workflow`, `flowrun`;
**read + write** on `pda_agentaction`; **create** on `pda_agentruns`
(the firing mechanism — see below).

## Firing agents

Clicking **Fire** opens a project-picker dialog first: it browses the table
matching the agent's `pda_scope` (Initiative → `pum_initiative`, Program →
`pum_program`, Portfolio → `pum_portfolio`) so the user can pick which record
this run applies to. Once a record is selected, the dashboard creates a row on
the custom `pda_agentruns` table:

| Column | Value |
|---|---|
| `pda_name` | agent name (e.g. "Status Reporting Agent") |
| `pda_agentid` | agent workflow ID (the unique workflow GUID) |
| `pda_message` | JSON string: `{ "fireId": "…", "agentId": "…", "firedBy": "dashboard" }` |
| `pda_xpmagent` | lookup bound to the monitored agent row — lets each workflow's trigger filter to runs meant for it |
| `pda_initiative` / `pda_program` / `pda_portfolio` | whichever lookup matches the agent's scope, bound to the record picked in the dialog |
| `pda_status` | `100000000` (Running, or appropriate initial status) |

`pda_initiative`, `pda_program`, and `pda_portfolio` are three separate
single-target lookups (Dataverse's Web API doesn't support turning a custom
lookup polymorphic after creation) — the dashboard only ever writes to the one
matching the firing agent's scope.

This row write happens under the **signed-in user's own session** (same-origin
Web API call, same as every other Dataverse write in this app) — no separate
token, no OAuth, no secret. `createdby`/`modifiedby` on the row are therefore
the real person who clicked Fire, not a shared service identity.

**Why a Dataverse trigger instead of HTTP?** An HTTP-triggered flow exposes a
public URL reachable from anywhere on the internet, which is why Microsoft now
requires OAuth on that trigger type — there's no way for a browser to safely hold
a credential to satisfy that from client-side code alone. A Dataverse trigger
was never a public endpoint in the first place: Dataverse notifies Power Automate
directly, backend-to-backend, using the same one-time interactive connector
consent every Dataverse trigger already needs. That sidesteps the OAuth problem
entirely instead of working around it.

The row write only confirms Dataverse accepted the run record — not that the
workflow has started (the Dataverse-trigger handoff isn't instantaneous). Actual
run confirmation still comes from polling `pda_agentaction`/`flowruns`, same as
before (`pollForRunEvidence` in `src/api/fireAgent.ts`).

## Workflow author contract

How to wire an agent workflow (Copilot Studio → **Workflows**, the new experience)
into the dashboard:

1. **Trigger** — *When a row is added in Dataverse*, table `pda_agentruns`.
   Add a filter condition on `pda_xpmagent` (the monitored agent lookup) equal
   to this agent's monitored-agent row, so it only reacts to runs meant for it.
   Parse `pda_message` (a JSON string) to get
   `{ "fireId": "…", "agentId": "…", "firedBy": "dashboard" }`, and read
   `pda_initiative`/`pda_program`/`pda_portfolio` (whichever matches this
   agent's `pda_scope`) for the record the run applies to.
2. **Log each meaningful step** — Dataverse *Add a new row* to `pda_agentaction`
   (`pda_runid` = fireId, Action Type = Step, Status = Running,
   `pda_starttime` = `utcNow()`), do the work, then *Update a row*
   (Status = Completed/Failed, `pda_endtime` = `utcNow()`, error text in Detail on
   the failure branch). These rows are what streams into the sidepane.
3. **Ask for approval/input** — *Add a new row* (Action Type = Approval or Input,
   Status = WaitingForInput, the question in Detail), then a **Do until**
   `pda_responseoption ne null` loop (*Get a row by ID* + 20 s Delay, timeout
   `PT2H`). The PM answers in the sidepane (the dashboard PATCHes the row);
   branch on Approved/Rejected and read `pda_response` for their comment.

### Where the sidepane's action feed comes from (pluggable)

Step-level run history of the new Workflows experience is currently only visible
in Copilot Studio's Activity panel — not via the Dataverse Web API. Providers are
tried in order (`src/data/actionProviders/`):

1. `pda_agentaction` — the contract table above (the intended, demo-perfect path)
2. `flowruns` — run-level fallback (one row per run) so the pane is never empty
3. designed empty state with wiring instructions

If a native Dataverse source for step-level workflow telemetry appears, add one
provider file — no UI changes.

### Approvals

The default approval path is the `pda_agentaction` row contract above — pure
Dataverse, works today. Microsoft's native surfaces were evaluated:
the new Workflows *request information* action is **Outlook-only** (not
embeddable), and Power Automate **Approvals** rows live in Dataverse
(`msdyn_flow_approval*`) and are readable — responding by creating
`msdyn_flow_approvalresponse` rows is implemented as a stub behind
`CONFIG.features.msdynApprovals` (default **off**) in
`src/data/approvals/msdynApprovalProvider.ts` until validated in the target
environment.

## Environment checklist (next session)

1. Create `pda_agentaction` and `pda_agentruns` (tables above; the latter needs
   a lookup `pda_xpmagent` → `pda_monitoredagent`).
2. Build one sample agent workflow per the contract (Dataverse row trigger on
   `pda_agentruns` → parse `pda_message` → 2-3 logged steps → one Do-until
   approval).
3. Upload `dist/pda_agentdashboard.html`, publish, open in the app.
4. Grant the security roles listed above (especially `create` on `pda_agentruns`).
5. Live tests: fire from the dashboard, watch the timeline stream, answer an
   approval end-to-end.
6. **Investigate:** do new-experience workflow runs land in `flowruns`? Does
   creating an `msdyn_flow_approvalresponse` row complete a real approval? Flip
   providers/flags accordingly.

## Repo layout

```
src/                   React + Fluent UI v9 app (see src/config.ts for all names/flags)
scripts/               build rename, sprite extraction, Playwright verification
dist/                  built web resource (committed for easy upload)
agent-monitor/         LEGACY vanilla-JS dashboard — still the UI for Copilot/chat agents
```
