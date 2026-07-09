# Agent Monitor — Browser Testing Loop

Automated browser testing as a **self-validation loop** for the coding agent: after a UI
change, the agent drives the browser itself (screenshots + console/network logs), validates,
and iterates — instead of the user manually testing and reporting back.

Tool: **Playwright MCP** (`@playwright/mcp`). General tooling for all web-resource work, not a one-off.

## Setup (already done)

- `.mcp.json` (repo root) registers the server:
  ```json
  "playwright": {
    "command": "npx",
    "args": ["-y", "@playwright/mcp@latest", "--allow-unrestricted-file-access"]
  }
  ```
  `--allow-unrestricted-file-access` is required because Playwright MCP blocks `file://`
  navigation by default; it enables the local demo loop.
- Chromium pre-installed: `npx playwright install chromium`.
- A full Claude Code session restart is required after editing `.mcp.json` for the server to
  register. Tools then appear as `mcp__playwright__*`.

## Running the loop

### Fast local UI loop (no auth) — preferred for UI work
1. `browser_navigate` to:
   `file:///C:/Users/Patrick/OneDrive%20-%20Context%26/xPM%20AI/agent-monitor/agent-monitor.html?demo=1`
2. `browser_take_screenshot` (`fullPage: true`) + `browser_console_messages` + `browser_network_requests`
3. Edit `agent-monitor.html` → re-navigate → re-check.

Demo mode (`?demo=1`, init logic at `agent-monitor.html` ~line 936) renders deterministic
sample data with **no network and no auth**. Expect 0 console errors and only Microsoft
telemetry beacons (`aria.microsoft.com`) in the network log.

### Live app loop (auth required)
- Navigate to the deployed web resource:
  `https://pdausa.crm.dynamics.com/WebResources/cxa_/agentmonitor.html`
  (or the Model-driven app page where it's embedded).
- The **user** completes the Microsoft / MFA login in the headed browser — Playwright launches
  its own browser context, so the user owns auth.
- Then screenshot / console / network as above.

### Data fixes (Dataverse)
**Standing rule:** when a root cause is a *data* problem, fix it in Dataverse via the
`Agentic-PowerplatformDeveloper` repo (service-principal token, app-user permissions):
- `C:\Users\Patrick\Agentic-PowerplatformDeveloper\connect.ps1` → client-credentials →
  writes `.token`
- Use sibling CRUD scripts / Dataverse Web API to read/patch rows, then re-verify in browser.

## Key prior finding — Copilot agents read OFFLINE

**Not a UI bug.** The dashboard derives Copilot liveness from the `conversationtranscript`
table (query at `agent-monitor.html` ~line 503), but Microsoft does **not** write
`conversationtranscript` records for **Microsoft 365 Copilot** agents (confirmed across
multiple MS Learn docs). Agents used only via M365 Copilot will therefore always read OFFLINE.

Real fixes:
- Re-source Copilot liveness from **Application Insights**, and/or
- Add an honest **"no transcript data"** UI state instead of implying the agent is offline.

Agent flows (`flowrun`) are unaffected. Secondary things to rule out before blaming the above:
environment transcript-saving toggle, Bot Transcript Viewer role, 20–60 min transcript latency,
wrong GUID in the `cxa_monitoredagent` config table.

## App / environment

- Org: `https://pdausa.crm.dynamics.com`
- Web resource: `cxa_/agentmonitor.html`
- Config table: `cxa_monitoredagent` (see README for schema)
