# xPM AI Demo Agent — setup & runbook

A ready-to-run Claude Code agent that demos the five PoCs from the *AI in Projectum xPM* offering deck against the **pdausa** environment, live, over the Dataverse MCP server.

## What's in this folder

| File | Purpose |
|---|---|
| `CLAUDE.md` | The agent script. Claude Code loads it automatically when you start a session in this folder — persona, guardrails, data-model cheat sheet, and the five demo playbooks. |
| `.mcp.json` | Project-scoped MCP config pointing at the pdausa Dataverse MCP server. Claude Code picks it up automatically. |

## One-time setup (15 minutes)

1. **Enable the MCP server on the environment** (admin, once):
   Power Platform admin center → Manage → Environments → *pdausa* → Settings → Product → Features → enable **Dataverse Model Context Protocol**, and make sure non-Microsoft clients (Claude) are on the allowed-clients list.
   Optional: also enable the *Preview version* toggle and switch the URL in `.mcp.json` to `/api/mcp_preview` to demo the newest tools.

2. **Verify the org URL**: open the environment in the admin center and check the actual hostname. `pdausa.crm.dynamics.com` assumes a US region — European orgs typically end in `crm4.dynamics.com`. Edit `.mcp.json` if needed.

3. **Start Claude Code in this folder**:
   ```bash
   cd xpm-ai-demo-agent
   claude
   ```
   On first use, run `/mcp` and complete the browser sign-in (OAuth with your Entra ID account). The agent acts with **your** Dataverse permissions — use an account that has the xPM security roles you want to demonstrate.

4. **Smoke test**: type `Are you ready?` — the agent should confirm the connection and report how many initiatives it can see.

## Running a demo

Just say which one:

| Say | You get | Writes data? |
|---|---|---|
| `run demo 1` | Ask Your Portfolio — live Q&A over initiatives, KPIs, risks | No |
| `run demo 2` | Status Report Drafter — full draft, then asks before saving | One record, after your approval |
| `run demo 3` | Idea Intake — interview, duplicate check, strategy-linked idea | One record, after your approval |
| `run demo 4` | Resource & Capacity — proposed vs committed gaps | No |
| `run demo 5` | Portfolio Watchdog — Monday-morning exception digest | No |

Free-form questions work too — the agent will discover tables itself. That's often the strongest moment: take a question from the audience.

## Before presenting — checklist

- [ ] Sandbox has representative data (a handful of initiatives with status reports, risks, tasks, resource plans). Thin data kills demos 1, 4 and 5.
- [ ] Your account's security roles are what you want to show — the agent sees exactly what you see, nothing more.
- [ ] Auth is fresh (`/mcp` shows connected) — tokens expire; re-auth before walking into the room.
- [ ] You know the cost story: MCP calls from Claude consume Copilot credits (billing started 15 Dec 2025). Fine for demos, but have the answer ready when someone asks.

## Cleanup after demos 2–3

The agent reports the GUID of any record it creates. Delete demo records via the xPM app afterwards (the agent itself is not allowed to delete — that's a deliberate guardrail and part of the pitch).
