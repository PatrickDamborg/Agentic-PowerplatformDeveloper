---
name: xpm-status-reporting
description: "Step-by-step guide for reading status history and creating status reports (KPI traffic-light snapshots) in Projectum xPM via the Dataverse MCP. Use when an agent needs to log a status update or answer questions about current project health."
---

# xPM — Status Reporting Processes

Covers the `pum_StatusReporting` table. Load this file when an agent reads or creates status reports.

---

## Table map

| Entity set | Primary key | Parent links |
|-----------|-------------|-------------|
| `pum_statusreportings` | `pum_statusreportingid` | `_pum_initiative_value`, `_pum_program_value` |

---

## KPI field reference

Each status report captures a KPI snapshot. Fields follow the pattern `KPI<New|Current><Dimension>`.

| Dimension | "New" field (this report) | "Current" field (running status) |
|-----------|--------------------------|----------------------------------|
| Overall Summary | `pum_kpinewsummary` | `pum_kpicurrentsummary` |
| Cost | `pum_kpinewcost` | `pum_kpicurrentcost` |
| Schedule | `pum_kpinewschedule` | `pum_kpicurrentschedule` |
| Scope | `pum_kpinewscope` | `pum_kpicurrentscope` |
| Resources | `pum_kpinewresources` | `pum_kpicurrentresources` |
| Quality | `pum_kpinewquality` | `pum_kpicurrentquality` |

All KPI fields are **picklists** with traffic-light values. **Verified live against pdausa on 2026-07-03** — this is the reverse of the mapping this document previously stated:

| Value | Label |
|-------|-------|
| 493840000 | Not Set |
| 493840001 | Red |
| 493840002 | Yellow |
| 493840003 | Green |

The "New" fields represent the status being reported in this period. The "Current" fields are typically updated by xPM automatically to reflect the latest submitted report — in most cases only set the "New" fields when creating.

**No `pum_reportdate`, `pum_highlights`, `pum_lowlights`, or `pum_nextperiodplan` fields exist** on `pum_statusreportings` (a prior version of this doc assumed them). The real fields are: `pum_statusdate` (report date), `pum_comment` (general/overall narrative), and per-dimension `pum_kpinew{cost,schedule,scope,quality,resources}comment` (there is no summary comment field). Other real columns: `pum_budget`/`pum_actualcost` (Money), `pum_scheduleprogress` (Integer), `pum_currentphase` (String), `pum_statuscategory` (Picklist: Bi-Weekly Status=493840000 / Gate Decision=493840001).

---

## §Read — status history

### Get the latest status report for an initiative
```
listRows(
  entityName: "pum_statusreportings",
  $filter: "_pum_initiative_value eq <initiativeGuid>",
  $select: "pum_statusreportingid,pum_name,pum_statusdate,pum_kpinewsummary,pum_kpinewcost,pum_kpinewschedule,pum_kpinewscope,pum_kpinewresources,pum_kpinewquality,pum_comment",
  $orderby: "pum_statusdate desc",
  $top: 1
)
```

### Get status history (last 5 reports)
```
listRows(
  entityName: "pum_statusreportings",
  $filter: "_pum_initiative_value eq <initiativeGuid>",
  $select: "pum_statusreportingid,pum_name,pum_statusdate,pum_kpinewsummary,pum_kpinewcost,pum_kpinewschedule",
  $orderby: "pum_statusdate desc",
  $top: 5
)
```

### Translate a KPI picklist value to a label (for display)

| Integer | Display |
|---------|---------|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Red |
| 493840002 | 🟡 Yellow |
| 493840003 | 🟢 Green |

Always translate values before presenting to the user — raw integers are not meaningful.

---

## §Create — new status report

**Step 1 — Resolve the parent initiative or program**

If not already known, search for it:
```
searchQuery(
  search: "<project name>",
  entities: [{ Name: "pum_initiative", SearchColumns: ["pum_name"], SelectColumns: ["pum_initiativeid","pum_name"] }]
)
```

**Step 2 — Collect KPI values from the user**

Ask the user to rate each relevant dimension (Green / Yellow / Red / N/A). Also collect:
- `pum_comment` — overall narrative: what went well, issues/blockers, next-period plan, all in one field (no separate highlights/lowlights/next-period-plan fields exist)
- per-dimension one-liners, if given: `pum_kpinewcostcomment`, `pum_kpinewschedulecomment`, `pum_kpinewscopecomment`, `pum_kpinewqualitycomment`, `pum_kpinewresourcescomment`
- `pum_statusdate` — date of this report (default: today)

**Step 3 — Confirm with the user** — surface the full report card before submitting.

**Step 4 — Create**
```
createRow(
  entityName: "pum_statusreportings",
  body: {
    "pum_name": "<Initiative Name> - Status <YYYY-MM-DD>",
    "pum_Initiative@odata.bind": "/pum_initiatives(<initiativeGuid>)",
    "pum_statusdate": "YYYY-MM-DD",
    "pum_kpinewsummary": 493840003,    // Green
    "pum_kpinewcost":     493840002,    // Yellow
    "pum_kpinewschedule": 493840003,    // Green
    "pum_kpinewscope":    493840003,    // Green
    "pum_kpinewresources":493840003,    // Green
    "pum_comment":        "<overall narrative text>"
  }
)
```

Omit KPI fields the user rated as "Not applicable" or left blank — do not default to Green.

---

## Common gotchas

- A status report must link to either an Initiative (`pum_Initiative@odata.bind`) or a Program (`pum_Program@odata.bind`) — not both. Initiative-level reports are most common.
- `pum_name` is the display name for the report record. Use a consistent format (e.g. `"Alpha Project - Status 2026-06-04"`) so the report list is readable.
- Do not set `pum_kpicurrent*` fields manually — xPM updates them automatically from submitted reports. Only set `pum_kpinew*`.
- `pum_statusdate` should be the date the report covers (end of reporting period), not necessarily today.
- **KPI integers are Green=493840003 / Yellow=493840002 / Red=493840001 / Not Set=493840000** — verified live against pdausa 2026-07-03. This is the reverse of what an earlier version of this document stated.
