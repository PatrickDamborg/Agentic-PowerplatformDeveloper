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
- **Fire** an agent with one click — an HTTP POST to the workflow's
  *When an HTTP request is received* trigger URL.
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

### 1. Config table `pda_monitoredagent` (existing) — one new column

| Display | Logical name | Type | Notes |
|---|---|---|---|
| Trigger URL | `pda_triggerurl` | Text (URL), 2000 | Full HTTP trigger URL of the agent workflow, incl. the `sig=` query parameter |

Existing columns used: `pda_name`, `pda_agenttype` (100000000 Copilot Studio /
100000001 Autonomous), `pda_targetid` (the workflow GUID). The dashboard queries
only Autonomous rows.

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
**read + write** on `pda_agentaction`.

## Workflow author contract

How to wire an agent workflow (Copilot Studio → **Workflows**, the new experience)
into the dashboard:

1. **Trigger** — *When an HTTP request is received*. The dashboard POSTs with
   `Content-Type: text/plain` (see CORS below), so the body arrives as a **string**.
   Make the first node a Compose with `json(triggerBody())` to get
   `{ "fireId": "…", "agentId": "…", "firedBy": "dashboard" }`.
2. **Optional Response node** (recommended) — status `202`, header
   `Access-Control-Allow-Origin: https://<yourorg>.crm.dynamics.com` (or `*` while
   demoing), body echoing the fireId. With it, the dashboard confirms the fire
   instantly; without it, confirmation comes from polling (below).
3. **Log each meaningful step** — Dataverse *Add a new row* to `pda_agentaction`
   (`pda_runid` = fireId, Action Type = Step, Status = Running,
   `pda_starttime` = `utcNow()`), do the work, then *Update a row*
   (Status = Completed/Failed, `pda_endtime` = `utcNow()`, error text in Detail on
   the failure branch). These rows are what streams into the sidepane.
4. **Ask for approval/input** — *Add a new row* (Action Type = Approval or Input,
   Status = WaitingForInput, the question in Detail), then a **Do until**
   `pda_responseoption ne null` loop (*Get a row by ID* + 20 s Delay, timeout
   `PT2H`). The PM answers in the sidepane (the dashboard PATCHes the row);
   branch on Approved/Rejected and read `pda_response` for their comment.

### Firing & CORS — why text/plain

Workflow HTTP triggers never answer the browser's OPTIONS preflight, so the
dashboard sends a **simple request** (`text/plain`, no custom headers), which
browsers deliver without preflight. If your workflow has the CORS Response node
(step 2), the dashboard reads the response and confirms immediately. If not, the
browser hides the response (the POST is still delivered!) — the dashboard then
polls `pda_agentaction` (by fireId) and `flowruns` (by start time) for up to 60 s
to confirm the run started. **It never retries the POST** — a retry would
double-trigger the run.

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

1. Add the `pda_triggerurl` column and create `pda_agentaction` (tables above).
2. Build one sample agent workflow per the contract (trigger-parse → CORS
   Response → 2-3 logged steps → one Do-until approval).
3. Upload `dist/pda_agentdashboard.html`, publish, open in the app.
4. Grant the security roles listed above.
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
