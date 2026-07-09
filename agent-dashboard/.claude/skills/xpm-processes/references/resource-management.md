---
name: xpm-resource-management
description: "Step-by-step guide for reading team rosters, checking resource allocations (proposed vs committed), and adding team members or allocation rows in Projectum xPM via the Dataverse MCP. Use when an agent needs to answer questions about who is assigned to a project or how hours are allocated."
---

# xPM — Resource Management Processes

Covers Resources, Team Members, Resource Plans, and Allocations (Propose/Commit). Load this file when an agent reads or writes resource-related data.

---

## Table map

| Entity set | Primary key | Purpose |
|-----------|-------------|---------|
| `pum_resources` | `pum_resourceid` | Named resources (people, generic roles) |
| `pum_teammemberss` | `pum_teammembersid` | Project team roster |
| `pum_resourceplans` | `pum_resourceplanid` | Resource plan header per project |
| `pum_proposes` | `pum_proposeid` | Proposed allocation rows |
| `pum_commits` | `pum_commitid` | Committed allocation rows |

---

## Key field reference

### pum_Resource
| Field | Type | Notes |
|-------|------|-------|
| `pum_name` | string | Resource display name |
| `_pum_relateduser_value` | lookup → SystemUser | Links to the Dataverse user record |
| `_pum_role_value` | lookup → pum_Role | Primary role |
| `_pum_rbs_value` | lookup → pum_rbs | Org unit (Resource Breakdown Structure) |
| `pum_isgeneric` | boolean | True = generic/placeholder resource |

### pum_TeamMembers
| Field | Type | Notes |
|-------|------|-------|
| `_pum_resource_value` | lookup → pum_Resource | The team member resource |
| `_pum_initiative_value` | lookup → pum_Initiative | Project this person belongs to |
| `_pum_program_value` | lookup → pum_Program | (if program-level) |

### pum_Propose / pum_Commit
| Field | Type | Notes |
|-------|------|-------|
| `_pum_resourceplan_value` | lookup → pum_ResourcePlan | Parent plan header |
| `_pum_resource_value` | lookup → pum_Resource | Allocated resource |
| `pum_hours` | decimal | Planned/committed hours |
| `pum_startdate` | date | Allocation period start |
| `pum_finishdate` | date | Allocation period end |
| `_pum_initiative_value` | lookup → pum_Initiative | Which project |

---

## §Team Members — read

### List team members on an initiative
```
listRows(
  entityName: "pum_teammemberss",
  $filter: "_pum_initiative_value eq <initiativeGuid>",
  $select: "pum_teammembersid,_pum_resource_value,pum_role",
  $expand: "pum_Resource($select=pum_name,pum_resourceid)"
)
```

> If `$expand` is not supported by the MCP tool, do a second `listRows` on `pum_resources` filtering by the resource GUIDs returned in the first call.

### Find a resource by person name
```
searchQuery(
  search: "<person name>",
  entities: [{ Name: "pum_resource", SearchColumns: ["pum_name"], SelectColumns: ["pum_resourceid","pum_name","pum_isgeneric"] }]
)
```

---

## §Add Team Member

**Step 1 — Resolve the initiative GUID** (if not already known)
```
searchQuery(search: "<project name>", entities: [{ Name: "pum_initiative", SearchColumns: ["pum_name"], SelectColumns: ["pum_initiativeid","pum_name"] }])
```

**Step 2 — Resolve the resource GUID**
```
searchQuery(search: "<person name>", entities: [{ Name: "pum_resource", SearchColumns: ["pum_name"], SelectColumns: ["pum_resourceid","pum_name"] }])
```

**Step 3 — Check they're not already on the team** (avoid duplicates)
```
listRows(
  entityName: "pum_teammemberss",
  $filter: "_pum_initiative_value eq <initiativeGuid> and _pum_resource_value eq <resourceGuid>",
  $select: "pum_teammembersid"
)
```
If a record is returned, the person is already a team member — inform the user instead of creating a duplicate.

**Step 4 — Confirm with the user**, then create:
```
createRow(
  entityName: "pum_teammemberss",
  body: {
    "pum_Initiative@odata.bind": "/pum_initiatives(<initiativeGuid>)",
    "pum_Resource@odata.bind": "/pum_resources(<resourceGuid>)"
  }
)
```

---

## §Allocations — read

Resource allocations live in `pum_proposes` (planned) and `pum_commits` (confirmed). Both share the same structure.

### Get proposed allocations for an initiative
```
listRows(
  entityName: "pum_proposes",
  $filter: "_pum_initiative_value eq <initiativeGuid>",
  $select: "pum_proposeid,_pum_resource_value,pum_hours,pum_startdate,pum_finishdate",
  $orderby: "pum_startdate asc"
)
```

### Get committed allocations for an initiative
```
listRows(
  entityName: "pum_commits",
  $filter: "_pum_initiative_value eq <initiativeGuid>",
  $select: "pum_commitid,_pum_resource_value,pum_hours,pum_startdate,pum_finishdate",
  $orderby: "pum_startdate asc"
)
```

### Summarise allocation for a specific resource across all projects
```
listRows(
  entityName: "pum_commits",
  $filter: "_pum_resource_value eq <resourceGuid>",
  $select: "pum_commitid,_pum_initiative_value,pum_hours,pum_startdate,pum_finishdate"
)
```
Sum `pum_hours` per initiative to get total committed hours per project.

---

## §Allocations — create

Resource plan allocation requires a plan header first.

### Step 1 — Find or create a ResourcePlan for the initiative

Check if one exists:
```
listRows(
  entityName: "pum_resourceplans",
  $filter: "_pum_initiative_value eq <initiativeGuid>",
  $select: "pum_resourceplanid,pum_name"
)
```

If none found, create one:
```
createRow(
  entityName: "pum_resourceplans",
  body: {
    "pum_name": "<Initiative Name> - Resource Plan",
    "pum_Initiative@odata.bind": "/pum_initiatives(<initiativeGuid>)"
  }
)
```

### Step 2 — Resolve the resource GUID (see §Team Members → Find a resource above)

### Step 3 — Confirm allocation details with the user:
- Resource name
- Hours
- Start / finish dates
- Proposed or committed?

### Step 4 — Create the allocation row
```
// For proposed:
createRow(
  entityName: "pum_proposes",
  body: {
    "pum_ResourcePlan@odata.bind": "/pum_resourceplans(<planGuid>)",
    "pum_Resource@odata.bind":     "/pum_resources(<resourceGuid>)",
    "pum_Initiative@odata.bind":   "/pum_initiatives(<initiativeGuid>)",
    "pum_hours":      40.0,
    "pum_startdate":  "YYYY-MM-DD",
    "pum_finishdate": "YYYY-MM-DD"
  }
)

// For committed: same but entityName = "pum_commits"
```

---

## Common gotchas

- `pum_teammemberss` — note the double-s in the entity set name. This is intentional.
- Propose and Commit are separate tables with identical structure. Proposed = planning intent; Committed = confirmed allocation. Ask the user which they want before creating.
- `pum_ResourcePlan` is a required parent for Propose/Commit rows. Never skip step 1 when creating allocations.
- A resource must already exist in `pum_resources` — you cannot create a Dataverse user as a resource via this process. If the person doesn't exist as a resource, inform the user and ask an admin to create the resource record in xPM first.
