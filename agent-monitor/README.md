# Context& Agent Monitor — Dataverse Web Resource

A single-file HTML web resource (`agent-monitor.html`) that gives a live overview of what your **Copilot Studio agents** and **autonomous agents** (Power Automate cloud flows / agent flows) have been triggered and what they're currently working on.

Which agents appear on the dashboard is controlled entirely by a **Dataverse config table** — end users add or deactivate rows, no code changes needed.

## How it works

| Dashboard data | Dataverse source | Notes |
|---|---|---|
| Agent metadata, publish state | `bot` (Copilot) | Read via Web API |
| Agent sessions | `conversationtranscript` | Written **after** a session ends — activity appears with a short delay |
| Flow metadata | `workflow` | |
| Flow run history, status, errors, duration | `flowrun` | Elastic table; **solution cloud flows only**; 28-day retention by default (`FlowRunTimeToLiveInSeconds` on Organization); `modernflowtype` distinguishes Power Automate flows from Copilot Studio agent flows |

All calls are read-only, made with the signed-in user's privileges via the standard Dataverse Web API — users only see what their security role allows. Note that `flowrun` records are user-owned by the flow's owner, so grant org-level read on Flow Run (or use a role like Environment Maker) for a shared monitoring view.

## Setup (one time)

### 1. Create the config table

In [make.powerapps.com](https://make.powerapps.com) → **Tables** → **New table** (inside a solution with publisher prefix `cxa`, or adjust names below):

| Column | Schema name | Type | Purpose |
|---|---|---|---|
| Name | `cxa_name` | Text (primary) | Display name shown on the dashboard card |
| Agent Type | `cxa_agenttype` | Choice | `Copilot Studio Agent` = **100000000**, `Cloud Flow` = **100000001** |
| Target Id | `cxa_targetid` | Text | GUID of the agent (`botid`) or flow (`workflowid`) |

Table schema name: `cxa_monitoredagent` (entity set `cxa_monitoredagents`).

> Different prefix, names, or choice values? Edit the `CONFIG` block at the top of the script in `agent-monitor.html` — everything is parameterised there.

### 2. Find the GUIDs

- **Copilot Studio agent**: in Copilot Studio → your agent → **Settings → Advanced → Metadata**, or query `https://<org>.crm.dynamics.com/api/data/v9.2/bots?$select=name` and copy `botid`.
- **Cloud flow**: open the flow in the solution; the `workflowid` is in the URL, or query `.../api/data/v9.2/workflows?$select=name&$filter=category eq 5`.

### 3. Add rows

One row per agent/flow to monitor. **Deactivate** a row to remove it from the dashboard (inactive rows are ignored).

### 4. Upload the web resource

1. In your solution → **New → More → Web resource**, type **Webpage (HTML)**, name e.g. `cxa_/agentmonitor.html`, upload `agent-monitor.html`.
2. Publish.
3. Open directly at `https://<org>.crm.dynamics.com/WebResources/cxa_/agentmonitor.html`, or add it to a model-driven app (dashboard, custom page iframe, or sitemap subarea of type Web Resource).

### 5. Optional: deep links

Set `CONFIG.environmentId` (Power Platform admin center → Environments → Environment ID) to make run rows link to Power Automate run details and agent cards link to Copilot Studio.

## Using the dashboard

- **KPI strip** — monitored agents, runs in progress now, runs/sessions today, failures today.
- **Cards** — one per monitored agent; pulsing dot + "Working now" when a run is in progress (or an agent session just landed), orange when there are failures today. Click a card for the detail drawer with recent runs/sessions, durations, and error messages.
- **Filters** — All / Copilot agents / Flows chips + name search.
- **Auto-refresh** — every 60 s (configurable), pausable; pauses while the tab is hidden.
- **Demo mode** — opened outside Dataverse (or with `?demo=1`) it shows fictional sample data so you can preview the layout locally.

## Known limitations

- Cloud flow run history in Dataverse exists only for **solution-aware** flows, and the environment must have FlowRun ingestion enabled (it is by default; check PPAC → Environment → Settings → Features → *Cloud flow run history in Dataverse*).
- Copilot Studio transcripts are written after a conversation/run ends, so "working now" for Copilot agents means "active within the last 30 minutes" rather than literally mid-session.
- FlowRun is not 100 % lossless (per Microsoft docs); for audit-grade telemetry use Application Insights.
