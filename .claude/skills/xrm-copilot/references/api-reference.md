# Xrm.Copilot — API Reference

Exact signatures from Microsoft Learn (fetched 2026-06-30). Every method is async; both
`await fn(...)` and `fn(...).then(successCallback, errorCallback)` are valid. `successCallback` /
`errorCallback` are always optional in practice (await the Promise instead) — they are listed below
where the docs list them.

> **Preview** (supplemental terms, not for production): `executePrompt`, `executeEvent`,
> `updateContext`, `MCSResponse`. All others are GA.

---

## executePrompt(promptText) — preview

Executes the Microsoft Copilot Studio topic whose **trigger query** matches `promptText`.

```
Xrm.Copilot.executePrompt(promptText).then(successCallback, errorCallback);
```

| Parameter | Type | Required | Description |
|-----------|------|:---:|-------------|
| `promptText` | string | Yes | Text registered as a trigger query in the MCS topic. |

**Returns:** `Promise<MCSResponse[]>`

```javascript
const response = await Xrm.Copilot.executePrompt("hello");
// response[0].text -> "Hello, how can I help you today?"
```

Example service response:

```json
[
  {
    "type": "message",
    "timestamp": "2025-02-05T16:46:07.77+00:00",
    "replyToId": "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb",
    "attachments": [],
    "textFormat": "markdown",
    "text": "Hello, how can I help you today?",
    "speak": "Hello, how can I help?"
  }
]
```

---

## executeEvent(eventName, eventParameters) — preview

Executes the MCS topic registered for `eventName`, passing `eventParameters`.

```
Xrm.Copilot.executeEvent(eventName, eventParameters).then(successCallback, errorCallback);
```

| Parameter | Type | Required | Description |
|-----------|------|:---:|-------------|
| `eventName` | string | Yes | Event name registered in the MCS topic. |
| `eventParameters` | object (topic-defined) | Yes | Parameters the topic expects. Inside the topic, read them via `Activity.Value` (use a Parse value node). |

**Returns:** `Promise<MCSResponse[]>`

```javascript
const response = await Xrm.Copilot.executeEvent(
    "Microsoft.PowerApps.Copilot.RelatedActivities",
    { id: "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb" }
);
// response[0].type === "event"; response[0].value holds the OData payload
```

### App context available to the topic

When you call `executeEvent`/`executePrompt`, the topic receives these Copilot Studio global variables:

| Variable | Description |
|----------|-------------|
| `Global.PA__Copilot_Model_PageContext.pageContext.id.guid` | Record id on the main form |
| `Global.PA__Copilot_Model_PageContext.pageContext.entityTypeName` | Table logical name of the main page |
| `Global.PA__Copilot_Model_PageContext.pageContext.pageName` | Main page name |
| `Global.PA__Copilot_Model_PageContext.pageContext.pageType` | Main page type |
| `Global.PA__Copilot_Model_AppUniqueNameContext.appUniqueNameContext.appUniqueName` | Model-driven app unique name |

---

## isM365CopilotEnabled()

Returns whether M365 Copilot is enabled in the current environment.

```
Xrm.Copilot.isM365CopilotEnabled().then(successCallback, errorCallback);
```

**Returns:** `Promise<boolean>` — `true` if enabled.

**Remarks:** Enablement is computed from a feature kill switch, license + environment-setting +
Dataverse-indexing checks, an optional app-level override, and a gradual-rollout flag. **Result is
cached ~30 minutes**; concurrent calls are deduplicated. **All other M365 Copilot methods check this
first and no-op if it is `false`** — so gate your UI on it.

```javascript
if (await Xrm.Copilot.isM365CopilotEnabled()) {
    // show Copilot controls
}
```

---

## openM365CopilotPanel()

Opens the M365 Copilot side panel (initializes it if already open).

```
Xrm.Copilot.openM365CopilotPanel().then(successCallback, errorCallback);
```

**Returns:** `Promise<void>` · No-op if Copilot isn't enabled.

---

## sendPromptToM365Copilot(promptText, options?)

Sends a prompt to the M365 Copilot side panel; Copilot processes and responds on the user's behalf.

```
Xrm.Copilot.sendPromptToM365Copilot(promptText, options).then(successCallback, errorCallback);
```

| Parameter | Type | Required | Description |
|-----------|------|:---:|-------------|
| `promptText` | string | Yes | Prompt text to send to the panel. |
| `options` | `SendPromptToM365CopilotOptions` | No | Target agent / auto-submit behavior. |

**Returns:** `Promise<void>` · No-op if Copilot isn't enabled.

```javascript
await Xrm.Copilot.sendPromptToM365Copilot(
    "Summarize the recent activity for this account.",
    { gptId: "dddddddd-3333-4444-5555-eeeeeeeeeeee", autoSubmit: false }
);
```

### SendPromptToM365CopilotOptions

| Property | Type | Description |
|----------|------|-------------|
| `gptId` | string | Target a specific M365 Copilot agent. Omit for the default Copilot experience. |
| `autoSubmit` | boolean | `false` = place text in the input box without submitting (user can edit). Default `true`. |

---

## updateContext(context) — preview

Sends updated app context to the M365 Copilot side panel.

```
Xrm.Copilot.updateContext(context).then(successCallback, errorCallback);
```

| Parameter | Type | Required | Description |
|-----------|------|:---:|-------------|
| `context` | `PowerAppsContent` | Yes | The current app context to send. |

**Returns:** `Promise<void>` · No-op if Copilot isn't enabled.
**Remarks:** Base fields (`appId`, `appType`, `orgId`, `geo`, `schemaVersion`) are merged
automatically — don't set them. (Author-built agents can't yet use this context to optimize answers.)

```javascript
await Xrm.Copilot.updateContext({
    entity: "account",
    filterXML: "<fetch><entity name='account'><filter><condition attribute='statecode' operator='eq' value='0'/></filter></entity></fetch>"
});
```

### PowerAppsContent (all properties optional)

| Property | Type | Description |
|----------|------|-------------|
| `schemaVersion` | string | Content schema version (auto-merged). |
| `appType` | `"ModelApp" \| "CanvasApp" \| "CodeApp"` | App type (auto-merged). |
| `appId` | string | App id (auto-merged). |
| `orgId` | string | Org id (auto-merged). |
| `geo` | string | Environment geo (auto-merged). |
| `entity` | string | Logical name of the primary table for the current page. |
| `filterXML` | string | FetchXML scoping the data context. |
| `filterId` | string | Id of a saved view/filter. |
| `extendedContext` | `Array<Record<string, unknown>>` | Arbitrary extra key-value context. |
| `telemetryContext` | `{ clientSessionId?: string; clientRequestId?: string }` | Telemetry correlation ids. |
| `selectedRecords` | `{ selectedContents: ISelectedRecordContents[] }` | Records the user has selected. |
| `messageAnnotationAppContext` | string | App-context annotation for message rendering. |

---

## getCurrentAgent()

Returns the active M365 Copilot agent, or `undefined` if the agent state isn't known yet.

```
Xrm.Copilot.getCurrentAgent().then(successCallback, errorCallback);
```

**Returns:** `Promise<M365CopilotAgent | undefined>` · No-op if Copilot isn't enabled.

```javascript
const agent = await Xrm.Copilot.getCurrentAgent();
if (agent && agent.agentId) {
    // an agent is active: agent.mode is "agentPage" or "mentioned"
} else if (agent) {
    // user is on mainline M365 Copilot (agentId === null, mode === null)
} else {
    // agent state not yet determined
}
```

### M365CopilotAgent

| Property | Type | Description |
|----------|------|-------------|
| `agentId` | `string \| null` | Active agent id, or `null` on mainline M365 Copilot. |
| `mode` | `M365CopilotAgentMode \| null` | How the agent is referenced, or `null` when none is active. |

`agentId` and `mode` are paired: both set → agent active; both `null` → mainline Copilot.

### M365CopilotAgentMode

| Value | Description |
|-------|-------------|
| `"agentPage"` | The user is on the agent's home page. |
| `"mentioned"` | The agent is the @-mention target for the next turn. |

---

## Action handlers

Customize what built-in M365 Copilot actions do (e.g. open a record in a side pane instead of
navigating away). Multiple handlers can be registered per `actionId` and run sequentially; the same
function reference is ignored if added twice. All no-op if Copilot isn't enabled.

### Built-in action IDs

| Action ID | Description | Data payload |
|-----------|-------------|--------------|
| `MS.PA.CopilotChat.OpenRecord` | Opens a record | `entity` (string, table logical name), `recordId` (string) |
| `MS.PA.CopilotChat.NavigateToView` | Navigates to a view | `entity` (string), `fetchXml` (string) |

### addActionHandler(actionId, actionHandler)

```
Xrm.Copilot.addActionHandler(actionId, actionHandler).then(successCallback, errorCallback);
```

| Parameter | Type | Required | Description |
|-----------|------|:---:|-------------|
| `actionId` | string | Yes | Unique id of the action to handle. |
| `actionHandler` | Function | Yes | Invoked with the action's data payload when triggered. |

**Returns:** `Promise<void>`

```javascript
const handler = async ({ entity, recordId }) => {
    const pane = Xrm.App.sidePanes.createPane({ canClose: true });
    await pane.navigate({ pageType: "entityrecord", entityName: entity, entityId: recordId });
};
await Xrm.Copilot.addActionHandler("MS.PA.CopilotChat.OpenRecord", handler);
```

### removeActionHandler(actionId, actionHandler)

Removes the **specific function reference** passed to `addActionHandler` (other handlers for the same
`actionId` are unaffected).

```
Xrm.Copilot.removeActionHandler(actionId, actionHandler).then(successCallback, errorCallback);
```

**Returns:** `Promise<void>`

### addDefaultActionHandlers(actionId) / removeDefaultActionHandlers(actionId)

Restore / remove the platform-default handler for a **built-in** `actionId`. To fully replace default
behavior: `removeDefaultActionHandlers(id)` then `addActionHandler(id, yourHandler)`.

```
Xrm.Copilot.addDefaultActionHandlers(actionId).then(successCallback, errorCallback);
Xrm.Copilot.removeDefaultActionHandlers(actionId).then(successCallback, errorCallback);
```

`actionId` (string, required) must be one of the built-in action IDs above. Both return
`Promise<void>` and no-op if Copilot isn't enabled. `removeDefaultActionHandlers` does not affect
custom handlers.

```javascript
// Replace default record navigation with custom behavior
await Xrm.Copilot.removeDefaultActionHandlers("MS.PA.CopilotChat.OpenRecord");
await Xrm.Copilot.addActionHandler("MS.PA.CopilotChat.OpenRecord", async ({ entity, recordId }) => {
    /* custom implementation */
});
```

---

## MCSResponse — preview

Returned by `executeEvent` and `executePrompt`. Only `type` is always present.

| Property | Type | Description |
|----------|------|-------------|
| `type` | string | **Required.** Response type (e.g. `"message"`, `"event"`). |
| `id` | string | Unique id of the response. |
| `locale` | string | Locale (language/region). |
| `replyToId` | string | Id of the message this replies to. |
| `timestamp` | string | Response timestamp. |
| `speak` | string | Text for speech synthesis. |
| `text` | string | Text content. |
| `textFormat` | `"plain" \| "markdown" \| "xml"` | Format of `text`. |
| `suggestedActions` | `{ actions: any[]; to?: string[] }` | Suggested user actions. |
| `value` | unknown | Custom payload (e.g. OData result for an event). |
| `valueType` | string | Type of `value`. |
| `name` | string | Response/action name. |
| `attachmentLayout` | `"list" \| "carousel"` | Attachment layout. |
| `attachments` | `Attachment[]` | Attachments. |

**Attachment:** `{ content: unknown /* required */, contentType?: string }`

---

## Source pages

All under `https://learn.microsoft.com/en-us/power-apps/developer/model-driven-apps/clientapi/reference/xrm-copilot/`:
`executeprompt`, `executeevent`, `mcsresponse`, `sendprompttom365copilot`,
`sendprompttom365copilotoptions`, `ism365copilotenabled`, `openm365copilotpanel`, `getcurrentagent`,
`m365copilotagent`, `m365copilotagentmode`, `updatecontext`, `powerappscontent`, `addactionhandler`,
`removeactionhandler`, `adddefaultactionhandlers`, `removedefaultactionhandlers`.
