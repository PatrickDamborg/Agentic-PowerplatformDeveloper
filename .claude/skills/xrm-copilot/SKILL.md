---
name: xrm-copilot
description: "Call the Xrm.Copilot Client API (Microsoft 365 Copilot + Copilot Studio) from model-driven apps, and scaffold artifacts that use it. Load when invoking Copilot Studio topics from app code (executePrompt/executeEvent), driving the M365 Copilot side panel (open/sendPrompt/updateContext), customising Copilot actions (action handlers), or building a form script, HTML web resource, or PCF control that calls Xrm.Copilot."
---

# Xrm.Copilot — Client API for M365 Copilot & Copilot Studio

`Xrm.Copilot` is the model-driven app **Client API** for interacting with Microsoft 365 Copilot and
Microsoft Copilot Studio (MCS) from app code. Use this skill to call the API, or to build a form
script, HTML web resource, or PCF control around it.

## Critical: this is a client-side JavaScript API, not a REST endpoint

`Xrm.Copilot` lives on the global `Xrm` object inside the **model-driven app runtime (browser)**.
There is **no server / PowerShell / OData way to call it** — you "execute an endpoint" by running
JavaScript inside a *running* model-driven app. Where that JS lives decides how you reach the API
(full detail in `references/access-patterns.md`):

| Host | How to reach the API | Best for |
|------|----------------------|----------|
| **Form script** (JS web resource) | `Xrm.Copilot.*` (global) | Quickest; event/ribbon-triggered logic |
| **HTML web resource** | `parent.Xrm.Copilot.*` | Custom UI page / dashboard tile |
| **PCF control** | `(window as any).Xrm?.Copilot` (guarded) | Reusable bound control |
| **Command bar command** | `Xrm.Copilot.*` from the command function | Button-triggered actions |

Every method is **async (Promise-based)**. Both `await fn(...)` and `fn(...).then(success, error)` work.

## All methods no-op unless M365 Copilot is enabled

Gate everything on `isM365CopilotEnabled()`. The panel methods *silently do nothing* when Copilot
isn't enabled in the environment, so build UI that degrades gracefully (the PCF/HTML templates show
how). The enablement result is cached ~30 minutes.

## Two capability groups

**1. Copilot Studio topic execution (preview)** — call an MCS topic from app code and use its answer:
- `executePrompt(promptText)` → runs the topic whose trigger query matches → `MCSResponse[]`
- `executeEvent(eventName, eventParameters)` → runs the topic by registered event name → `MCSResponse[]`
- The topic receives app context automatically (record id, table, app name) as Copilot Studio global
  variables — see `executeEvent` in the reference.

**2. M365 Copilot side-panel control** — drive the Copilot panel from the app:
- `isM365CopilotEnabled()` · `openM365CopilotPanel()` · `sendPromptToM365Copilot(text, options?)`
- `updateContext(context)` (preview) · `getCurrentAgent()`
- Action handlers: `addActionHandler` / `removeActionHandler` / `addDefaultActionHandlers` / `removeDefaultActionHandlers`

> **Preview APIs** (supplemental terms; not for production): `executePrompt`, `executeEvent`,
> `updateContext`, and the `MCSResponse` shape. The rest are GA.

## Decision guide

- *Need an answer/data back from an agent or topic?* → `executePrompt` / `executeEvent`, render the `MCSResponse[]`.
- *Want to open/seed the M365 Copilot panel?* → `openM365CopilotPanel` then `sendPromptToM365Copilot`.
- *Want the panel to know the current record/view?* → `updateContext`.
- *Want to override what a built-in Copilot action does (e.g. open record in a side pane)?* → action handlers.

## Method index → exact signatures in `references/api-reference.md`

| Method | Returns | Preview | One-liner |
|--------|---------|:---:|-----------|
| `executePrompt(promptText)` | `MCSResponse[]` | ✔ | Run MCS topic by trigger query |
| `executeEvent(eventName, eventParameters)` | `MCSResponse[]` | ✔ | Run MCS topic by event name |
| `isM365CopilotEnabled()` | `boolean` | | Is Copilot enabled here (cached ~30 min) |
| `openM365CopilotPanel()` | `void` | | Open the side panel |
| `sendPromptToM365Copilot(text, options?)` | `void` | | Send a prompt to the panel |
| `updateContext(context)` | `void` | ✔ | Push app context to the panel |
| `getCurrentAgent()` | `M365CopilotAgent \| undefined` | | Active agent (or mainline / unknown) |
| `addActionHandler(actionId, handler)` | `void` | | Register a custom action handler |
| `removeActionHandler(actionId, handler)` | `void` | | Remove a custom action handler |
| `addDefaultActionHandlers(actionId)` | `void` | | Restore platform-default handlers |
| `removeDefaultActionHandlers(actionId)` | `void` | | Remove platform-default handlers |

Interfaces: `MCSResponse`, `SendPromptToM365CopilotOptions`, `M365CopilotAgent`,
`M365CopilotAgentMode`, `PowerAppsContent` — all in `references/api-reference.md`.

## Reference & build files

- `references/api-reference.md` — exact signatures, params, returns, remarks, examples (every method + interface).
- `references/access-patterns.md` — how to reach `Xrm.Copilot` from each host, with guards and gotchas.
- Shipping web resources: use the `deploy` skill (Web API). Shipping PCF: `pcf-scripts` build → solution → import, using `pac` only for the scoped PCF scaffolding/dev-loop exception (see root `AGENTS.md`) — never for data, metadata, solution, or security operations.
- `templates/form-script.js` — drop-in JS web resource (both capability groups).
- `templates/copilot-page.html` — HTML web resource page (MCS prompt box + panel-control buttons).
- `templates/pcf/` — buildable PCF control (ContextAnd namespace, mirrors the repo's PdfViewer).

## Source

Microsoft Learn: <https://learn.microsoft.com/en-us/power-apps/developer/model-driven-apps/clientapi/reference/xrm-copilot>
