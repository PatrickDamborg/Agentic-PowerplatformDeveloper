---
name: xpm-resource-management
description: "Step-by-step guide for reading team rosters, checking resource allocations (proposed vs committed), adding team members or allocation rows in Projectum xPM via the Dataverse MCP, and configuring the Power Heatmap PCF component (placement, process mode, feature toggles, security roles). Use for Dataverse MCP operations against resource data AND for consultant setup/configuration of the heatmap UI."
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

---

## §Configuration — Power Heatmap Setup

Use this section when a consultant is installing or configuring the Power Heatmap PCF component in an xPM environment. This covers UI configuration, not Dataverse data operations.

> **Background knowledge:** Load the `resource-management` skill alongside this section for process context — resource types (generic/named/category), RBS, capacity concepts, stakeholder needs, and common customer failure modes. That knowledge informs which features to enable and how to challenge the customer's ask.

### Prerequisites

All three solutions must be imported before configuring:

| Solution | Minimum version | Notes |
|---|---|---|
| xPM Essentials | 3.0.0.8 | Base platform — import first |
| Power Heatmap PCF | latest | The interactive grid component |
| Resource Plan | latest | Provides configuration tables and security roles |

Import order: xPM Essentials → Power Heatmap → Resource Plan.

---

### Heatmap placement

Choose one placement based on the user's workflow. All three end with a "Create Configuration" button that loads a best-practice default.

| Placement | Use when | How |
|---|---|---|
| **Form tab** (Initiative / Program / Portfolio / Idea) | Users need a per-record resource view | Add tab → add subgrid → add `PowerHeatmap` component |
| **Dashboard** | Central cross-project heatmap | Create dashboard → add List component → add `PowerHeatmap` component |
| **Navigation link (table view)** | Alternative central view | Create view on `pum_resource` or `pum_commit` → note view GUID → add nav link with URL `/main.aspx?pagetype=entitylist&etn=pum_commit&viewid=<GUID>` |

After clicking "Create Configuration", open the gear icon (top-right) to adjust the default settings. Default config targets the Propose & Commit process.

---

### Process mode

Choose the process mode before enabling individual features — some features are mutually exclusive by mode.

**Propose + Commit (default)** — Project Managers propose generic resources; Line Managers commit named resources. The "Create Configuration" default uses this mode.

**Switch to Commit Only** — Line Managers commit named resources directly; no proposal workflow. Follow these 4 steps:

1. Set "Enable Propose Mode" radio button to "Commit Only (Forced)"; deselect "Commit cells read-only"
2. Enable "Commit Only Mode"
3. Disable "Proposed-Committed Cell Coloring"
4. *(Form heatmap only)* Remove the view from "Resource View for Picker" and disable the feature

Save and refresh. Existing commits from a prior Propose+Commit setup will remain visible as commit-only records.

---

### Resource data prerequisites

The heatmap only works with **Generic** and **Named** resource types in `pum_resources`.

| Field | Generic | Named | Notes |
|---|---|---|---|
| Resource Type | ✓ | ✓ | Set to Generic or Named |
| Name | ✓ | ✓ | Display name |
| Role | ✓ | ✓ | Used for filtering and candidate matching |
| Manager | ✓ | ✓ | Required for Filter by Manager feature |
| Calendar / Daily Capacity | ✓ | ✓ | Required for Resource Capacity feature |
| Related User | — | **required** | Maps the resource to a Dataverse system user |
| Related Generic Resource | — | **required** | Named resource won't appear in Add Resource picker without this |

**Named resources** can be synced from Power Hub / Microsoft Entra ID or created manually. **Generic resources** are always created manually.

**Critical error:** If a user's resource record is missing the Related User field, the grid will refuse to load with this exact message:
> *"Unable to Load. Your user profile is missing required information. The 'Related User' field must be configured. Please contact your system administrator to complete your user setup."*

---

### Security roles

The Resource Plan solution ships three add-on roles. These extend existing xPM Essentials roles — assign them in addition to, not instead of, core roles.

| Role | Assign to | Permissions |
|---|---|---|
| **xPM Proposer** | Project Managers | Create and maintain resource proposals |
| **xPM Committer** | Line Managers, Portfolio Managers | Commit named resources to proposals or initiatives |
| **xPM Resource Administrator** | Resource data owners | Create and maintain resource records, manage capacity data |

xPM Committer intentionally does not grant access to resource master data — that is xPM Resource Administrator's domain.

---

### Feature configuration reference

Open the gear icon in the heatmap to access the configuration panel. Features are grouped below with purpose, when to enable, and incompatibilities.

#### Visualization & Layout

| Feature | Purpose | When to enable | Incompatible with |
|---|---|---|---|
| **Setup Markers** | Add named date markers to the timeline (e.g. "Phase 1 Start") | Key milestones or phase gates teams need to see at a glance | None |
| **Dashboard Full Container Size** | Expand heatmap to fill all available container space | Large datasets or extended timelines needing maximum screen space | Fixed Container Height |
| **Show Group By** *(deprecated)* | Dropdown to group by Work Element, Resource, Manager, or Role | Users need to pivot between organizational views | None |
| **Fixed Container Height** | Set a specific height (e.g. `50vh`, `600px`) | Heatmap must coexist with other content on the same page | Dashboard Full Container Size |

#### Resource Management

| Feature | Purpose | When to enable | Incompatible with |
|---|---|---|---|
| **Use Resource Capacity** *(deprecated)* | Use each resource's configured hours/day instead of the 8h default | Mixed contract terms (full-time, part-time, contractors) | None |
| **Filter Resources by Manager** | Show only the current user's direct reports | Line managers should only see their own team | Get Resources from View · Resource Plan on Form |
| **Enhanced LM Add Resource Dialog** | Advanced picker showing demand, availability, and overcommit warnings; two actions: "Add & Commit" vs "Add Without Commit" | LMs need full demand/availability context when adding resources | None |

#### Planning & Allocation Modes

| Feature | Purpose | When to enable | Incompatible with |
|---|---|---|---|
| **Enable Allocation Mode** | Top-down manual allocation mode (no formal assignments required) | Planning for initiatives that don't yet have project assignments | Get Resources from View (on forms) |
| **Resource Plan on Form** | Show only resources linked to the current record | Users open the heatmap from a record form and need a focused view | Get Resources from View · Filter Resources by Manager; requires exactly one table selected |
| **Make the Heatmap Read-Only** | Disable all edits — no add/edit/delete | Audit, reporting, or stakeholder review scenarios | None |

#### Proposed & Committed Allocations

| Feature | Purpose | When to enable | Incompatible with |
|---|---|---|---|
| **Enable Propose Mode** | Dual-track view: proposed (tentative) + committed (confirmed) side by side | Formal approval/commitment workflow between PMs and LMs | Commit Only Mode |
| **Show Only Unmatched Resources** | Hide resources where propose = commit; show only mismatches | Review cycles focused on unresolved proposals | Requires Enable Propose Mode |
| **Proposed-Committed Cell Coloring** | Green = matched · Yellow = partial · Red = uncommitted | Instant visual feedback on approval status | Requires Enable Propose Mode |
| **Commit Only Mode** | Named resources + committed allocations only; no generics or proposals | Professional services / consulting firms with direct assignment workflows | Enable Propose Mode |

#### Data & Filtering

| Feature | Purpose | When to enable | Incompatible with |
|---|---|---|---|
| **Get Resources from View** | Load resources from a specific Dataverse view (e.g. "Active Developers") | Specialized heatmaps for different teams, regions, or skill sets | Filter Resources by Manager · Resource Plan on Form |
| **Resource View for Picker** | Filter the add-resource dialog to a specific Dataverse view | Guide users to only add resources from a particular team or role | None |

#### Financial View

| Feature | Purpose | When to enable | Notes |
|---|---|---|---|
| **Financial View (Hours/Cost Toggle)** | Toggle between hours and cost/currency | Financial planning alongside capacity planning | Requires `pum_rate` and `pum_rate_currency` fields on resources, or a Default Rate configured |
| **Assignment Conversion** | Import existing project assignments as proposed allocations | Transitioning from project-level assignments to portfolio-level planning | None |
| **Propose to Financials Conversion** | Export proposals to financial cost records | Feeding allocation data into budgeting or financial reporting systems | None |

#### Advanced

| Feature | Purpose | When to enable |
|---|---|---|
| **Enable Resource Plan** | Configures the resource plan relationship for linking resources to specific records | When explicit resource plan records are needed separate from project assignments |

#### Monitoring & Telemetry

| Feature | Purpose | When to enable |
|---|---|---|
| **Disable Sentry Logging** | Suppress all error logging and telemetry to Sentry | Dev/test environments — prevent test errors from polluting production telemetry |
| **Sentry Configuration** | Tune sample rates: Traces (1–20%), Replay Session, Replay On Error (100% recommended), Profiles; select specific users for 100% tracing | Production environments where Sentry quota or cost needs management |

---

### Compatibility matrix

**Mutual exclusions — cannot use together:**
- Dashboard Full Container Size ↔ Fixed Container Height
- Enable Propose Mode ↔ Commit Only Mode
- Filter Resources by Manager ↔ Get Resources from View
- Filter Resources by Manager ↔ Resource Plan on Form
- Get Resources from View ↔ Resource Plan on Form

**Feature requirements — one requires another:**
- Show Only Unmatched Resources → Enable Propose Mode must be on
- Proposed-Committed Cell Coloring → Enable Propose Mode must be on

**Form-specific constraints:**
- Resource Plan on Form → exactly one table selected
- Enable Allocation Mode on forms → incompatible with Get Resources from View

---

### Troubleshooting

| Symptom | Root cause | Fix |
|---|---|---|
| Grid refuses to load; "Related User" error | User's `pum_Resource` record is missing the Related User lookup | Admin sets Related User on the resource record in xPM |
| Generic resource appears when adding a named resource via "Add Resource" | Named resource has itself set as its own Related Generic Resource | Remove the self-reference on the resource record |
| Named resource not visible in "Add Resource" picker | Missing Related Generic Resource on the named resource | Set a Related Generic Resource on the named resource record |
| Data not saved after editing | Sync in progress | Wait for the spinner to stop before refreshing the page |
