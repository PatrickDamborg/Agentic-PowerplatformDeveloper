---
name: xpm-processes
description: "Step-by-step procedural guide for AI agents conducting PPM processes in Projectum xPM Essentials via the Dataverse MCP. Load whenever an agent needs to read, create, or update xPM records (projects, status reports, resources) through the Dataverse MCP. Covers the full process lifecycle — correct sequence of operations, required fields, and business rules. Use proactively any time the user or agent asks about xPM workflows, status reporting, resource allocation, or project data in Projectum."
---

# xPM Processes — Agent Procedural Guide

This skill teaches agents **how to execute** xPM business processes using the Dataverse MCP. It complements the `xpm` schema reference (entity names, picklist values, discovery patterns) — load that skill too when you need low-level field names.

## How to use this skill

1. Identify the process area from the table below.
2. Read the linked reference file for that area before executing any Dataverse operations.
3. Follow the step sequence exactly — xPM tables have creation-order dependencies that will cause failures if skipped.

---

## Process Index

| Process | When to use | Reference file |
|---------|------------|----------------|
| **Browse portfolio hierarchy** | User asks to list portfolios, programs, or initiatives | `references/projects.md` → §Read |
| **Create an initiative** | User wants to create a new project / initiative | `references/projects.md` → §Create Initiative |
| **Update initiative status fields** | User wants to change % complete, phase, owner | `references/projects.md` → §Update |
| **Create a status report** | User wants to log a periodic status update with KPIs | `references/status-reporting.md` → §Create |
| **Read status history** | User asks "what is the current status of X?" | `references/status-reporting.md` → §Read |
| **List team members / resources** | User asks who is assigned to a project | `references/resource-management.md` → §Team Members |
| **Check resource allocations** | User asks about capacity, proposed vs committed hours | `references/resource-management.md` → §Allocations |
| **Add a team member** | User wants to assign someone to a project | `references/resource-management.md` → §Add Team Member |
| **Configure heatmap placement** | Consultant placing heatmap on a form, dashboard, or nav link | `references/resource-management.md` → §Configuration |
| **Choose process mode** | Switching between Propose+Commit and Commit Only | `references/resource-management.md` → §Configuration |
| **Configure heatmap features** | Enabling/disabling feature toggles or checking incompatibilities | `references/resource-management.md` → §Configuration |
| **Set up resources / assign security roles** | Resource data prerequisites or role assignment for heatmap users | `references/resource-management.md` → §Configuration |

---

## Dataverse MCP — operation reference

When the Dataverse MCP is wired into the agent, it exposes these operations. Use the correct one for each step:

| Operation | Use for |
|-----------|---------|
| `searchQuery` | Free-text lookup — find a project by name, find a resource by person name |
| `listRows` | Structured query — get all risks for initiative X, list open status reports |
| `getRow` | Fetch a single record by GUID — follow up after a searchQuery to get all fields |
| `createRow` | Create a new record |
| `updateRow` | Patch one or more fields on an existing record |

**Rule:** Always resolve names to GUIDs before creating linked records. Use `searchQuery` or `listRows` first, then extract the GUID, then pass it to `createRow` / `updateRow` as an `@odata.bind` reference.

---

## xPM hierarchy — read this before any create operation

```
Portfolio
  └── Program  (pum_Portfolio lookup)
        └── Initiative  (pum_Program lookup)
```

A record at any level can also link directly to a Portfolio. Programs and Initiatives are optional in the hierarchy — an Initiative may exist with no Program if it belongs directly to a Portfolio.

Before creating an Initiative, confirm whether it belongs to a Program or directly to a Portfolio, then resolve the correct GUID.

---

## Cross-cutting rules

- **Never hardcode GUIDs.** Discover them at runtime via `searchQuery` or `listRows`.
- **OData bind syntax for lookups.** When linking a parent record use `"pum_Program@odata.bind": "/pum_programs(<guid>)"` — not a bare GUID field.
- **Confirm before mutating.** For `createRow` and `updateRow`, surface the record details to the user and ask for confirmation before submitting.
- **Status report creation order.** A `pum_StatusReporting` record must link to an existing Initiative or Program. Resolve that parent first.
- **Resource plan creation order.** `pum_ResourcePlan` → `pum_Propose` / `pum_Commit` — the plan header must exist before creating allocation rows.
