---
name: xpm-projects
description: "Step-by-step guide for reading, creating, and updating Portfolios, Programs, and Initiatives in Projectum xPM via the Dataverse MCP. Use when an agent needs to browse the PPM hierarchy, create a new initiative, or update project fields."
---

# xPM — Project Hierarchy Processes

Covers Portfolio, Program, and Initiative records. Load this file when an agent needs to read or write the core PPM hierarchy.

---

## Table map

| Level | Entity set | Primary key | Display name field |
|-------|-----------|-------------|-------------------|
| Portfolio | `pum_portfolios` | `pum_portfolioid` | `pum_name` |
| Program | `pum_programs` | `pum_programid` | `pum_name` |
| Initiative | `pum_initiatives` | `pum_initiativeid` | `pum_name` |

---

## §Read — browsing the hierarchy

### List all portfolios
```
listRows(
  entityName: "pum_portfolios",
  $select: "pum_portfolioid,pum_name,pum_description,_pum_primaryobjective_value",
  $orderby: "pum_name asc"
)
```

### List programs under a portfolio
```
listRows(
  entityName: "pum_programs",
  $filter: "_pum_portfolio_value eq <portfolioGuid>",
  $select: "pum_programid,pum_name,_pum_sponsor_value,pum_phase"
)
```

### List initiatives under a program
```
listRows(
  entityName: "pum_initiatives",
  $filter: "_pum_program_value eq <programGuid>",
  $select: "pum_initiativeid,pum_name,pum_percentcomplete,pum_phase,_pum_sponsor_value,pum_startdate,pum_finishdate"
)
```

### Search for a project by name (free text)
```
searchQuery(
  search: "<user's project name>",
  entities: [{ Name: "pum_initiative", SearchColumns: ["pum_name","pum_description"], SelectColumns: ["pum_initiativeid","pum_name","pum_phase"] }]
)
```
Use the returned `pum_initiativeid` in subsequent operations.

---

## §Create Initiative

**Step 1 — Resolve the parent** (Program or Portfolio)

If the user provides a program name:
```
searchQuery(search: "<program name>", entities: [{ Name: "pum_program", SearchColumns: ["pum_name"], SelectColumns: ["pum_programid","pum_name"] }])
```

If the user provides a portfolio name instead:
```
searchQuery(search: "<portfolio name>", entities: [{ Name: "pum_portfolio", SearchColumns: ["pum_name"], SelectColumns: ["pum_portfolioid","pum_name"] }])
```

**Step 2 — Resolve the sponsor / owner** (optional but strongly recommended)

```
searchQuery(search: "<person name>", entities: [{ Name: "systemuser", SearchColumns: ["fullname"], SelectColumns: ["systemuserid","fullname"] }])
```

**Step 3 — Confirm details with the user** before creating. Show:
- Initiative name
- Parent program or portfolio
- Sponsor
- Start / finish dates
- Any other fields the user specified

**Step 4 — Create**
```
createRow(
  entityName: "pum_initiatives",
  body: {
    "pum_name": "<name>",
    "pum_Program@odata.bind": "/pum_programs(<programGuid>)",   // OR pum_Portfolio@odata.bind if no program
    "pum_Sponsor@odata.bind": "/systemusers(<userGuid>)",        // optional
    "pum_startdate": "YYYY-MM-DD",
    "pum_finishdate": "YYYY-MM-DD"
  }
)
```

Key optional fields:
| Field | Type | Notes |
|-------|------|-------|
| `pum_description` | string | Project description / scope |
| `pum_percentcomplete` | decimal | 0–100 |
| `pum_phase` | picklist | Discover valid values via metadata if unknown |
| `pum_Portfolio@odata.bind` | lookup | Direct portfolio link (if no program parent) |
| `pum_Category@odata.bind` | lookup → `pum_investmentcategories` | Business driver / investment category |

---

## §Update

Use `updateRow` to patch an existing initiative. Always fetch the current record first with `getRow` so you can confirm what will change.

**Step 1 — Confirm the record**
```
getRow(
  entityName: "pum_initiatives",
  id: "<initiativeGuid>",
  $select: "pum_initiativeid,pum_name,pum_percentcomplete,pum_phase,pum_startdate,pum_finishdate"
)
```

**Step 2 — Surface current values and the proposed change to the user.**

**Step 3 — Patch**
```
updateRow(
  entityName: "pum_initiatives",
  id: "<initiativeGuid>",
  body: {
    "pum_percentcomplete": 75
    // only include fields that are changing
  }
)
```

---

## Common gotchas

- `pum_Portfolio@odata.bind` and `pum_Program@odata.bind` are both optional on an Initiative, but at least one should be set so the record appears in the correct hierarchy view in xPM.
- The `pum_phase` picklist values vary by environment configuration. If the user supplies a phase name, discover valid values first:
  ```
  GET /EntityDefinitions(LogicalName='pum_initiative')/Attributes(LogicalName='pum_phase')/Microsoft.Dynamics.CRM.PicklistAttributeMetadata?$select=OptionSet
  ```
- Programs are optional — an Initiative can link directly to a Portfolio. Never assume a Program must exist.
