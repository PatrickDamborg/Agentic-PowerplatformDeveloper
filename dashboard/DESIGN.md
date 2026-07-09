# pda_agentmonitor — Agent Activity Dashboard

Deployed as the Dataverse HTML web resource `pda_agentmonitor` (org `pdausa`, solution
`xPM - AI Use Cases demo`), surfaced as the "Agent Dashboard" subarea under the xPM
area in the **Projectum xPM Essentials** model-driven app's sitemap.

Branded "Your agents, at work" — a live view of every Copilot Studio agent and
agent-powered workflow run, with the ability to fire a run directly from the list.

## Data model

| Table | Role |
|---|---|
| `pda_monitoredagent` | Registry of agents shown on the dashboard. `pda_agenttype` (Copilot Studio Agent / Workflow), `pda_scope` (Initiative / Program / Portfolio — which table the fire picker queries), `pda_targetid` (bot id or workflow GUID). |
| `pda_agentrun` | One row per fired/triggered run. `pda_status` (Running/Completed, patched by the agent's own flow — unreliable, see below), `pda_starttime` (only set when *this dashboard* fires a run — blank for rows created by the agent's own trigger), lookups `pda_Initiative`/`pda_Program`/`pda_Portfolio`/`pda_xPMAgent`. |
| `flowrun` (standard) | Platform-populated ground truth for Workflow-type agents — `starttime`/`endtime`/`status` ("Succeeded"/"Failed"/"Cancelled"), keyed by `_workflow_value`. Used to correct `pda_agentrun.pda_status` since the agent's own flow doesn't reliably patch it back on completion. |
| `pum_initiative` / `pum_program` / `pum_portfolio` | Scope target tables for the fire picker. |

## Fire flow

Firing an agent does **not** call any HTTP trigger or workflow API. It only creates a
`pda_agentrun` row (`pda_name`, `pda_agentid`, `pda_status=Running`, `pda_message`
with a `fireId`, plus the scope lookup bind). Each agent's own flow/topic is
configured separately (manually, outside this dashboard) to trigger off new rows in
that table — the dashboard's responsibility stops at record creation.

Two entry points, both converging on the same create call:
- Per-row **Trigger** button on an Agents-pane row (any active `pda_monitoredagent`
  row — not gated by agent type) — skips straight to the scope picker for that agent.
- Toolbar **Start agent** button — picks the agent first, then scope.

## Auth

`Xrm.WebApi` (the signed-in user's own session, via the hosting model-driven app) is
the primary transport for every read and write — no separate sign-in. MSAL + `fetch`
is a fallback only, for the case of opening this HTML file outside the hosting app
(no saved MSAL config exists today, so this path is currently unreachable in
practice). Detection: `getXrm()` checks `window.Xrm` then `window.parent.Xrm`.

## Status resolution — read this before touching timestamps

`pda_agentrun.pda_status` alone cannot be trusted: it's supposed to be patched back
to Completed by the agent's own flow, but that patch step silently fails often enough
that rows get stuck on "Running" indefinitely. `resolveWorkflowStatus()` corrects
this for Workflow-type agents by matching each run to the closest `flowrun` row
(within a 15-minute window) by start time, and trusting `flowrun.status`/`endtime`
instead.

**`pda_agentrun.pda_starttime` is not reliably populated** — it's only set by this
dashboard's own fire path (`createAgentRun`/`startRun`). Rows created by an agent's
own configured trigger (i.e. most real production usage) leave it blank. The fix:
always fall back to `createdon` (`effectiveStartTime = r.pda_starttime || r.createdon`)
for both the flowrun-match input and the displayed run timestamp — `createdon` is
always populated and tracks `flowrun.starttime` within seconds. Any future change
that reads `pda_agentrun` timestamps must preserve this fallback.

## Agents-pane card

- Header: agent name + task count only — no Workflow/Copilot Studio type badge (removed,
  didn't fit alongside longer agent names).
- Task line: the **scoped record** the current run applies to (`pda_entity`, e.g.
  "Initiative: CRM Integration & Automation"), falling back to the run title if empty.
- Trigger button enabled for any row backed by an active `pda_monitoredagent` record
  (`canTrigger = !!(agent && agent.id)`); disabled for legacy/orphan rows derived
  purely from run history with no matching monitored-agent record.

## Bundle format / dev workflow

`dashboard/index.html` is the only file tracked in git — a single-file "packed"
bundle (`<script type="__bundler/manifest">`, gzip+base64 resources unpacked at
runtime via `DecompressionStream`). `dashboard/.unpacked/` (gitignored — regenerate,
don't rely on it surviving between clones) holds the human-editable extraction:

```
node dashboard/unpack.mjs   # index.html -> .unpacked/ (incl. readable template.html)
# edit .unpacked/template.html and .unpacked/<hash>.js
node dashboard/pack.mjs     # .unpacked/ -> index.html (backs up old to index.prev.html)
```

Never hand-edit the packed `index.html` directly.

## Deploy

No build/package step beyond `pack.mjs` above. Push the updated `dashboard/index.html`
straight to the web resource via the Dataverse Web API (PATCH `content` on
`webresourceset(e742d295-8565-f111-ab0d-0022480a51dc)`, then `POST PublishXml`) — see
`.claude/skills/dataverse-api/SKILL.md` for the PATCH/If-Match pattern. There is no
deploy script in this repo for this specific web resource (a prior one,
`upload-agent-monitor.ps1`, was lost — see git history / commit `004f76c`); deploys
are done via ad-hoc PowerShell against the Web API.

## Known gaps

- The MSAL/standalone fallback path is untested in practice (no saved config exists)
  and reads/writes a different shape (`pda_activitylogs`, which doesn't exist) in one
  leftover code path (`fetchActivities`) — dead code, safe to ignore unless someone
  actually needs to open this file outside the hosting app.
- No automated tests. Verification is manual: `pack.mjs` → deploy → Playwright CLI or
  `claude-in-chrome` against the live app.
