---
name: dataverse-mcp-xpm-cheat-sheet
description: 'Quick reference for Projectum xPM Essentials entity names, OData entity sets, primary keys, hierarchy chains, and deprecated tables. Use alongside the dataverse-mcp skill when constructing queries or creating records. Covers: strategy chain (OKR), work funnel (Idea to Portfolio), schedule, resources, governance, financials, deprecated tables.'
---

# xPM Cheat Sheet — Entity Names, Keys, and Hierarchies

Quick-reference for every session. Verify column names with `describe` before querying; this sheet gives you the right starting points.

---

## Strategy chain (OKR)

```
pum_StrategicObjectives
    └── pum_KeyResults
            └── pum_Portfolio   (linked via pum_PrimaryObjective)
```

---

## Work funnel

```
pum_Idea  →  pum_Initiative  →  pum_Program  →  pum_Portfolio
              (pum_LinkedIdea)   (pum_Program)   (pum_Portfolio)
```

An Initiative may link directly to a Portfolio without a Program in between.

---

## Core entity reference

### Hierarchy

| Display Name | OData Entity Set | Primary Key | Notes |
|---|---|---|---|
| Portfolio | `pum_portfolios` | `pum_portfolioid` | Top of the work funnel |
| Program | `pum_programs` | `pum_programid` | Groups Initiatives under a Portfolio |
| Initiative | `pum_initiatives` | `pum_initiativeid` | Core project record |
| Idea | `pum_ideas` | `pum_ideaid` | Pre-initiative intake; links to Initiative via `pum_LinkedIdea` |
| Investment Category (Business Driver) | `pum_investmentcategories` | `pum_investmentcategoryid` | Strategy classification for Ideas and Initiatives |
| Strategic Objective | `pum_strategicobjectives` | `pum_strategicobjectiveid` | OKR top level |
| Key Result | `pum_keyresults` | `pum_keyresultid` | OKR second level |

### Schedule

| Display Name | OData Entity Set | Primary Key | Notes |
|---|---|---|---|
| Gantt Task | `pum_gantttasks` | `pum_gantttaskid` | Links to Initiative, Program, or Portfolio |
| Work Package | `pum_workpackages` | `pum_workpackageid` | Groups tasks |
| Assignment | `pum_assignments` | `pum_assignmentid` | Resource-to-task assignment |
| Gantt Version | `pum_ganttversions` | `pum_ganttversion` | Schedule baseline/version |
| Task Link | `pum_tasklinks` | `pum_tasklinkid` | Predecessor/successor |

### Resources

| Display Name | OData Entity Set | Primary Key | Notes |
|---|---|---|---|
| Resource | `pum_resources` | `pum_resourceid` | Named person or generic role |
| Role | `pum_roles` | `pum_roleid` | Job role / skill category |
| RBS (org unit) | `pum_rbss` | `pum_rbsid` | Resource Breakdown Structure |
| Resource Plan | `pum_resourceplans` | `pum_resourceplanid` | Header per Initiative |
| Propose | `pum_proposes` | `pum_proposeid` | Planned (asked) allocation |
| Commit | `pum_commits` | `pum_commitid` | Confirmed allocation |
| Team Members | `pum_teammemberss` | `pum_teammembersid` | Project roster (double-s is correct) |

### Governance

| Display Name | OData Entity Set | Primary Key | Notes |
|---|---|---|---|
| Status Report | `pum_statusreportings` | `pum_statusreportingid` | KPI snapshot; `pum_kpinew*` / `pum_kpicurrent*` fields |
| Risk | `pum_risks` | `pum_riskid` | |
| Change Request | `pum_changerequests` | `pum_changerequestid` | Verified live 2026-07-03 — an earlier version of this doc said `pum_changes`, which does not exist. Almost no custom fields beyond `pum_initiative` lookup; use standard `statecode eq 0` for "open" |
| Lesson Learned | `pum_lessonslearneds` | `pum_lessonslearnedid` | Verified live 2026-07-03 — an earlier version of this doc said `pum_lessons`, which does not exist. `pum_learningcategory` has no "Quality" option (Project Management/Team Collaboration/Risks and Issues/Skills and Knowledge only); `pum_impact` (Positive/Negative/Neutral) is the closer quality-proxy signal |
| Dependency | `pum_dependencies` | `pum_dependencyid` | Inter-initiative dependency |
| Stakeholder | `pum_stakeholders` | `pum_stakeholderid` | |

### Financials

| Display Name | OData Entity Set | Primary Key | Notes |
|---|---|---|---|
| Financial Structure | `pum_financialstructures` | `pum_financialstructureid` | Usually one per environment |
| Cost Plan Version | `pum_pf_costplan_versions` | `pum_pf_costplan_versionid` | One per initiative |
| Cost Specification | `pum_pf_costspecifications` | `pum_pf_costspecificationid` | |
| Cost Area | `pum_pf_costareas` | `pum_pf_costareaid` | |
| Cost Category | `pum_pf_costcategories` | `pum_pf_costcategoryid` | |
| Cost Type | `pum_pf_costtypes` | `pum_pf_costtypeid` | |
| Financial Data Row | `pum_pf_powerfinancialsdatas` | `pum_pf_powerfinancialsdataid` | Always set both `pum_pf_value` (Money) and `pum_pf_valuedec` (Decimal) |

---

## Status Report KPI fields

| Dimension | "New" field (this period) | "Current" field (running) |
|-----------|--------------------------|--------------------------|
| Overall Summary | `pum_kpinewsummary` | `pum_kpicurrentsummary` |
| Cost | `pum_kpinewcost` | `pum_kpicurrentcost` |
| Schedule | `pum_kpinewschedule` | `pum_kpicurrentschedule` |
| Scope | `pum_kpinewscope` | `pum_kpicurrentscope` |
| Resources | `pum_kpinewresources` | `pum_kpicurrentresources` |
| Quality | `pum_kpinewquality` | `pum_kpicurrentquality` |

Only set the `pum_kpinew*` fields when creating a status report. xPM updates the `pum_kpicurrent*` fields automatically.

Other real fields on `pum_statusreportings` (no `pum_reportdate`/`pum_highlights`/`pum_lowlights`/`pum_nextperiodplan` exist): `pum_statusdate` (report date), `pum_comment` (overall narrative), `pum_kpinew{cost,schedule,scope,quality,resources}comment` (per-dimension one-liners, no summary comment field), `pum_budget`/`pum_actualcost` (Money), `pum_scheduleprogress` (Integer), `pum_currentphase` (String), `pum_statuscategory` (Picklist: Bi-Weekly Status=493840000 / Gate Decision=493840001).

### KPI picklist values

**Verified live against pdausa on 2026-07-03** — this is the reverse of what this document previously stated. Confirm against a live environment before assuming this holds everywhere ("universal" was an unverified assumption).

| Integer | Label |
|---------|-------|
| 493840000 | Not Set |
| 493840001 | Red |
| 493840002 | Yellow |
| 493840003 | Green |

---

## Gantt Task type picklist

| Integer | Label |
|---------|-------|
| 493840000 | Task |
| 493840001 | Phase (project summary row) |
| 493840002 | Milestone |
| 493840003 | Project Summary (top-level) |

When querying overdue tasks, exclude `pum_tasktype = 493840001` (Phase rows) to avoid false positives.

---

## Deprecated tables — never use

| Table | Reason |
|-------|--------|
| `pum_GanttTeam` | Deprecated — do not query, create, or update |
| `pum_Ganttuser` | Deprecated — do not query, create, or update |

---

## xPM total scope

The pdausa solution snapshot (2026-04-21) contains **77 `pum_` tables**. The tables listed above cover the areas relevant to all five PoCs. For full schema exploration, use `search` to enumerate all tables in the session.
