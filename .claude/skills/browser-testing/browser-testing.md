---
name: browser-testing
description: Use the Claude-in-Chrome MCP to verify Dataverse records, PCF components, and model-driven app state. Load this skill before any browser-based verification.
---

# Browser Testing Skill

Use Chrome browser automation to verify Dataverse UI state — record creation, PCF rendering, form data, and app navigation.

## Before Every Browser Session

Chrome MCP tools are deferred and must be loaded before use:

```
ToolSearch: select:mcp__claude-in-chrome__tabs_context_mcp
ToolSearch: select:mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__read_page
```

**Always call `tabs_context_mcp` first** to get current tab IDs. Never reuse tab IDs from a previous session — they will be invalid.

---

## Navigating to Dataverse Records

### Standard record URL
```
https://<org>.crm.dynamics.com/main.aspx?forceUCI=1&pagetype=entityrecord&etn=<entity>&id=<guid>
```

### Open a specific form (avoid app-redirect loops)
```
https://<org>.crm.dynamics.com/main.aspx?forceUCI=1&pagetype=entityrecord&etn=<entity>&id=<guid>&formid=<formguid>
```

> Without `formid`, navigating from within an app context redirects back to that app's default form. Use `formid` to force a specific form regardless of app context.

### Discover form IDs before navigating
```
GET /systemforms?$filter=objecttypecode eq '<entity>'&$select=formid,name,formactivationstate
```

### xPM Essentials app — open initiative in xPM context
```
https://<org>.crm.dynamics.com/main.aspx?appid=<xpmAppId>&pagetype=entityrecord&etn=pum_initiative&id=<guid>
```
The xPM app form has tabs: Details, Team Members, Timeline, Task Board, KPI Status, Lessons Learned, Dependencies, Documents — **no Financials tab**.  
For the Financials tab use the **Project** form directly with `formid`.

---

## Screenshot Workflow

```
1. navigate → wait 3s → screenshot         (check page loaded)
2. left_click (tab/button) → wait 2s → screenshot   (check state change)
3. zoom [x0,y0,x1,y1]                       (inspect small UI regions)
```

Always wait after navigation and after clicks — Power Apps forms load asynchronously.

---

## Handling Sign-in Dialogs

The Power Financials v2 PCF and some other components trigger a "Sign in to continue" dialog when they need external service authentication. **Dismiss it (click X), never click Sign in** — the OAuth flow will block the browser extension.

After dismissing, the PCF may show blank or "This component needs to be configured" — this is the unauthenticated fallback state, not a data problem.

---

## Reading Console Messages

Load the tool first:
```
ToolSearch: select:mcp__claude-in-chrome__read_console_messages
```

Console tracking starts when the tool is first called. **Refresh the page after loading** to capture messages from page load.

Filter to avoid noise:
```json
{ "pattern": "error|Error|PCF|financial", "onlyErrors": true }
```

---

## Verifying Records Were Created

Faster than UI: query Dataverse directly via PowerShell to confirm record counts and field values before opening the browser. Use the browser to verify visual rendering only.

```powershell
# Quick record count check
$url = "$baseUrl/<entityset>?`$filter=_<lookupfield>_value eq '$id'&`$select=<fields>&`$count=true"
Invoke-RestMethod -Uri $url -Headers $headers | Select-Object '@odata.count'
```

---

## Common Issues

| Symptom | Cause | Fix |
|---|---|---|
| Blank Financials tab | PCF needs Projectum auth | User must sign in to Projectum service |
| "This component needs to be configured" | PCF not configured on form | Configure in form designer (make.powerapps.com) |
| URL redirects back to xPM app | `appid` in browser session cookie | Add `formid=` parameter to force the form |
| Extension disconnected after F5 | Extension loses connection on hard reload | Call `tabs_context_mcp` again to reconnect |
| "Sign in to continue" blocks UI | PCF OAuth prompt | Dismiss (X), never click Sign in |
