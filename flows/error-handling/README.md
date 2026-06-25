# Power Automate Error Handling — Child Flows

Two reusable child flows that centralise error logging and notification across any flow in the `PowerAutomateErrorHandling` solution.

## Child flows

| Flow | Purpose | Outputs |
|------|---------|---------|
| `pda_ErrorLog_Write` | Writes a row to `pda_errorlog` in Dataverse | `logId`, `logRecordUrl` |
| `pda_ErrorLog_Notify` | Sends an HTML email via Office 365 Outlook to pda@contextand.com | — |

## One-time setup (manual steps)

### 1 — Create the Dataverse table

```pwsh
pwsh flows/error-handling/create-errorlog-table.ps1
```

### 2 — Create Outlook connection in the portal

1. Sign in to [make.powerautomate.com](https://make.powerautomate.com) as **pda@contextand.com**.
2. Go to **Connections** → **+ New connection** → search **Office 365 Outlook** → create.
3. Copy the connection ID from the URL (the GUID after `/connections/`).
4. Also note your existing Dataverse connection ID.
5. Add both to your env file:

```
DATAVERSE_CONNECTION_ID=<your-dataverse-connection-id>
OUTLOOK_CONNECTION_ID=<your-outlook-connection-id>
```

### 3 — Create connection references

```pwsh
pwsh flows/error-handling/create-connection-reference.ps1
```

This prints the exact `deploy-errorhandling-flows.ps1` command to run next.

### 4 — Deploy flows

```pwsh
pwsh flows/error-handling/deploy-errorhandling-flows.ps1 \
  -DataverseConnRefName "pda_sharedcommondataserviceforapps" \
  -Office365ConnRefName "pda_sharedoffice365"
```

### 5 — Activate flows

In [make.powerautomate.com](https://make.powerautomate.com), open the `PowerAutomateErrorHandling` solution, find both flows, and turn them **On**.

> **Same-solution constraint:** The "Run a Child Flow" action only discovers flows within the same solution. Any parent flow that calls these must be a member of `PowerAutomateErrorHandling`.

---

## Error envelope (inputs to both flows)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `flowName` | string | ✅ | `workflow()?['tags']['flowDisplayName']` |
| `runId` | string | ✅ | `workflow()?['run']['name']` |
| `runUrl` | string | | `concat('https://make.powerautomate.com/environments/', ..., '/flows/', ..., '/runs/', workflow()?['run']['name'])` |
| `failedStep` | string | | Name of the failed action |
| `errorMessage` | string | ✅ | `first(result('Try_Scope'))?['error']?['message']` |
| `errorCode` | string | | `first(result('Try_Scope'))?['error']?['code']` |
| `severity` | string | ✅ | `Info` \| `Warning` \| `Error` \| `Critical` |
| `correlationId` | string | | Caller-supplied trace ID |
| `parentRunId` | string | | Run ID of originating parent flow |
| `contextJson` | string | | Stringified JSON with arbitrary context |

`pda_ErrorLog_Notify` also requires `logId` and `logRecordUrl` (returned by `pda_ErrorLog_Write`).

---

## Parent-flow Try/Catch pattern

Add this pattern to any flow in the `PowerAutomateErrorHandling` solution:

```
┌─ Scope: Try_Scope ─────────────────────────────────────────┐
│  [your main logic actions]                                  │
└─────────────────────────────────────────────────────────────┘
         ↓ runAfter: Try_Scope [Failed, TimedOut, Skipped]
┌─ Scope: Catch_Scope ───────────────────────────────────────┐
│  1. Compose: Build_Envelope                                 │
│     {                                                       │
│       "flowName":     "@workflow()?['tags']['flowDisplayName']", │
│       "runId":        "@workflow()?['run']['name']",        │
│       "failedStep":   "@first(result('Try_Scope'))?['name']", │
│       "errorMessage": "@first(result('Try_Scope'))?['error']?['message']", │
│       "errorCode":    "@first(result('Try_Scope'))?['error']?['code']", │
│       "severity":     "Error",                              │
│       "contextJson":  "<your stringified context>"          │
│     }                                                       │
│                                                             │
│  2. Run Child Flow: pda_ErrorLog_Write                      │
│     → input: @outputs('Build_Envelope')                     │
│                                                             │
│  3. Run Child Flow: pda_ErrorLog_Notify                     │
│     → input: @outputs('Build_Envelope')                     │
│       + logId:        @body('pda_ErrorLog_Write')?['logId'] │
│       + logRecordUrl: @body('pda_ErrorLog_Write')?['logRecordUrl'] │
└─────────────────────────────────────────────────────────────┘
```

### Email importance

- Severity `Error` or `Critical` → email Importance = **High**
- Severity `Info` or `Warning` → email Importance = **Normal**

---

## pda_errorlog table columns

| Column | Type | Notes |
|--------|------|-------|
| pda_name | String 200 (primary) | `[Severity] FlowName — FailedStep` |
| pda_flowname | String 200 | |
| pda_runid | String 100 | |
| pda_runurl | String 500 (Url) | |
| pda_failedstep | String 200 | |
| pda_errormessage | Memo 100k | |
| pda_errorcode | String 100 | |
| pda_severity | Picklist | Info / Warning / Error / Critical |
| pda_contextjson | Memo 100k | Free-form JSON |
| pda_correlationid | String 100 | |
| pda_parentrunid | String 100 | |
| pda_resolved | Boolean | Open / Resolved |
| pda_resolutionnotes | Memo 2000 | Operator notes |
