---
name: xpm
description: Projectum xPM Essentials — entity reference, picklist values, and runtime discovery patterns for any customer environment.
---

# xPM Essentials Skill

Reference guide for working with Projectum xPM Essentials across any environment. **Never hardcode GUIDs** — always discover them at runtime using the query patterns below.

## Entity Reference

| Display Name | OData Entity Set | Primary Key Field |
|---|---|---|
| Initiative | `pum_initiatives` | `pum_initiativeid` |
| Stakeholder | `pum_stakeholders` | `pum_stakeholderid` |
| Risk | `pum_risks` | `pum_riskid` |
| Change Request | `pum_changes` | `pum_changeid` |
| Lesson Learned | `pum_lessons` | `pum_lessonid` |
| Dependency | `pum_dependencies` | `pum_dependencyid` |
| Gantt Version | `pum_ganttversions` | `pum_ganttversion` |
| Gantt Task | `pum_gantttasks` | `pum_gantttaskid` |
| Task Link | `pum_tasklinks` | `pum_tasklinkid` |
| Financial Structure | `pum_financialstructures` | `pum_financialstructureid` |
| Cost Plan Version | `pum_pf_costplan_versions` | `pum_pf_costplan_versionid` |
| Cost Specification | `pum_pf_costspecifications` | `pum_pf_costspecificationid` |
| Cost Area | `pum_pf_costareas` | `pum_pf_costareaid` |
| Cost Category | `pum_pf_costcategories` | `pum_pf_costcategoryid` |
| Cost Type | `pum_pf_costtypes` | `pum_pf_costtypeid` |
| Financial Data Row | `pum_pf_powerfinancialsdatas` | `pum_pf_powerfinancialsdataid` |

---

## Picklist Values (Universal to All xPM Environments)

These option set values are defined by Projectum and are the same in every environment.

### Stakeholder
| Field | Value | Label |
|---|---|---|
| `pum_stakeholdertype` | 493840000 | Internal |
| `pum_stakeholdertype` | 493840001 | External |
| `pum_influence` | 493840001 | Low |
| `pum_influence` | 493840002 | Medium |
| `pum_influence` | 493840003 | High |
| `pum_interest` | 493840001 | Low |
| `pum_interest` | 493840002 | Medium |
| `pum_interest` | 493840003 | High |

### Gantt Task
| Field | Value | Label |
|---|---|---|
| `pum_tasktype` | 493840000 | Task |
| `pum_tasktype` | 493840001 | Phase (project summary row) |
| `pum_tasktype` | 493840002 | Milestone |
| `pum_tasktype` | 493840003 | Project Summary (top-level) |

> For unknown picklist values (risks, changes, etc.) query the metadata:
> `GET /EntityDefinitions(LogicalName='pum_risks')/Attributes(LogicalName='pum_status')/Microsoft.Dynamics.CRM.PicklistAttributeMetadata?$select=OptionSet`

---

## Runtime Discovery Patterns

Always run these queries at the start of a session before creating xPM records.

### Initiatives
```
GET /pum_initiatives?$select=pum_initiativeid,pum_name&$orderby=pum_name
```

### Financial Reference Data (must exist before creating financial rows)
```powershell
# Financial Structure (usually only one per environment)
GET /pum_financialstructures?$select=pum_financialstructureid,pum_name

# Cost Areas
GET /pum_pf_costareas?$select=pum_pf_costareaid,pum_name

# Cost Categories
GET /pum_pf_costcategories?$select=pum_pf_costcategoryid,pum_name

# Cost Types
GET /pum_pf_costtypes?$select=pum_pf_costtypeid,pum_name
```

### xPM App ID
```
GET /appmodules?$filter=contains(tolower(uniquename),'xpm')&$select=appmoduleid,uniquename,name
```

### Initiative Form IDs
```
GET /systemforms?$filter=objecttypecode eq 'pum_initiative'&$select=formid,name,formactivationstate
```
Use `formid` as a URL parameter to open a specific form: `main.aspx?...&formid=<guid>`

---

## Financial Data — Critical Rules

The Power Financials v2 PCF reads the **Money** field, not the Decimal field. Always set both:

```powershell
$body = @{
    pum_pf_year     = $Year          # int (e.g. 2025)
    pum_pf_month    = 0              # 0 = full year; 1–12 for monthly
    pum_pf_valuedec = [double]$Value # Decimal field (required by some reports)
    pum_pf_value    = [double]$Value # Money field (required by the PCF)
    "pum_pf_initiative@odata.bind"        = "/pum_initiatives($IniId)"
    "pum_pf_costplan_version@odata.bind"  = "/pum_pf_costplan_versions($CpvId)"
    "pum_pf_costspecification@odata.bind" = "/pum_pf_costspecifications($SpecId)"
    "pum_pf_costarea@odata.bind"          = "/pum_pf_costareas($AreaId)"
    "pum_pf_costcategory@odata.bind"      = "/pum_pf_costcategories($CatId)"
    "pum_pf_costtype@odata.bind"          = "/pum_pf_costtypes($TypeId)"
    "pum_FinancialStructure@odata.bind"   = "/pum_financialstructures($FsId)"
}
```

**Financial entity hierarchy** (create in this order):
1. Financial Structure — usually pre-existing, just discover the ID
2. Cost Plan Version — one per initiative, linked to financial structure
3. Financial Data Rows — linked to initiative + CPV + all five reference entities

---

## Dependency Lookups (Polymorphic)

Dependencies use polymorphic navigation properties. Bind syntax:

```powershell
$body = @{
    "pum_From_pum_initiative@odata.bind" = "/pum_initiatives($fromId)"
    "pum_To_pum_initiative@odata.bind"   = "/pum_initiatives($toId)"
}
```

---

## Gantt Entity Hierarchy

Create in this order:
1. `pum_ganttversions` — one per initiative, linked via `pum_Initiative@odata.bind`
2. `pum_gantttasks` — linked to gantt version via `pum_GanttVersion@odata.bind`
3. `pum_tasklinks` — predecessor/successor links between tasks

---

## Common Gotchas

- **`pum_stakeholdertype`** only accepts `493840000` or `493840001` — no other values
- **`@()` array flattening in PowerShell** — use `,@(...)` (unary comma) inside outer arrays to prevent flattening
- **Financial PCF blank** — means either the Money field (`pum_pf_value`) is null, or the PCF needs Projectum service authentication (separate from Dataverse auth)
- **Cost Plan Version defaults** — set `pum_pf_costplan_version_default = $true` and `pum_planofrecord = $true` on the primary CPV per initiative; avoid creating duplicates across script runs
