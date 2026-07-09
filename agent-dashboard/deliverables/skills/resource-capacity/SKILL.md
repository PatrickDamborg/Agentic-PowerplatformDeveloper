---
name: resource-capacity
description: 'Surface proposed-vs-committed staffing gaps, rank work by uncovered demand, and suggest candidate resources for the biggest holes. Load when the user asks about resources, capacity, staffing, allocation, hours, gaps, committed vs proposed, overcommitment, "who is available", "where will staffing hurt", utilisation, or the bench. Do NOT load to summarize a project (portfolio-summary), draft a status report (status-report-drafter), or gather documents (information-gatherer). Read-only — never writes. Scopes to the entity the orchestrator resolved, or runs portfolio-wide if none was named.'
---

# Resource & Capacity

Surface the gap between **proposed** (asked) and **committed** (promised) allocations, rank by uncovered demand, and suggest candidates for the biggest hole. Read-only.

> Guardrails and Dataverse tool discipline are in the agent instructions. Data-model details: `dataverse-mcp`. **Scope:** if the orchestrator resolved an initiative/program/portfolio, filter to it; otherwise run portfolio-wide. State which scope and time horizon you used — default to the next quarter and say so.

Hierarchy (read-only — never create): `pum_Initiative → pum_ResourcePlan (header) → pum_Propose (asked) + pum_Commit (promised)`. Propose and Commit share the same field structure.

---

## Step 1 — Confirm the allocation schema

```
describe(table: "pum_Propose")
describe(table: "pum_Commit")
```
Verify the hours field (expect `pum_hours`), the date range fields (`pum_startdate`, `pum_finishdate`), and the resource-plan and initiative lookups. Field names are stable across environments but must be confirmed.

---

## Step 2 — Aggregate proposed vs committed

For the time window (next quarter unless the user specifies). Add `AND i.pum_initiativeid = '<id>'` when scoped to a resolved entity.

```sql
SELECT
  i.pum_name AS initiative, rp.pum_name AS resource_plan,
  SUM(p.pum_hours) AS proposed_hours,
  ISNULL(SUM(c.pum_hours), 0) AS committed_hours,
  SUM(p.pum_hours) - ISNULL(SUM(c.pum_hours), 0) AS gap_hours
FROM pum_ResourcePlan rp
JOIN pum_Initiative i ON rp._pum_initiative_value = i.pum_initiativeid
LEFT JOIN pum_Propose p ON p._pum_resourceplan_value = rp.pum_resourceplanid
  AND p.pum_startdate >= '<window_start>' AND p.pum_finishdate <= '<window_end>'
LEFT JOIN pum_Commit c ON c._pum_resourceplan_value = rp.pum_resourceplanid
  AND c.pum_startdate >= '<window_start>' AND c.pum_finishdate <= '<window_end>'
GROUP BY i.pum_initiativeid, i.pum_name, rp.pum_resourceplanid, rp.pum_name
HAVING SUM(p.pum_hours) > 0
ORDER BY gap_hours DESC
```
For "next quarter", compute start = first day of next calendar quarter, end = last day.

---

## Step 3 — Rank, then find candidates for the worst gap

**3a.** Present the top-10 gap table (Initiative · Proposed hrs · Committed hrs · Gap hrs).

**3b.** For the largest gap, find the needed role from its Propose records:
```sql
SELECT res.pum_name AS resource_name, r.pum_name AS role, p.pum_hours AS proposed_hours
FROM pum_Propose p
JOIN pum_Resource res ON p._pum_resource_value = res.pum_resourceid
LEFT JOIN pum_Role r ON res._pum_role_value = r.pum_roleid
WHERE p._pum_resourceplan_value = '<top_gap_plan_id>' AND p.pum_startdate >= '<window_start>'
```

**3c.** Find candidates with that role and spare capacity (low committed hours for the period):
```sql
SELECT res.pum_name AS candidate, r.pum_name AS role,
  ISNULL(SUM(c.pum_hours), 0) AS already_committed
FROM pum_Resource res
LEFT JOIN pum_Role r ON res._pum_role_value = r.pum_roleid
LEFT JOIN pum_Commit c ON c._pum_resource_value = res.pum_resourceid
  AND c.pum_startdate >= '<window_start>' AND c.pum_finishdate <= '<window_end>'
WHERE r.pum_roleid = '<needed_role_id>' AND res.pum_isgeneric = 0
GROUP BY res.pum_resourceid, res.pum_name, r.pum_name
ORDER BY already_committed ASC
```
Present the top 3–5.

---

## Step 4 — Present, with the wow moment

1. **Headline** — "Over [horizon], [N] [initiatives/this initiative] carry [X] hours of demand that was proposed but never committed — invisible in standard reports."
2. **Gap table** — top 10 by `gap_hours`.
3. **Worst gap deep-dive** — which work, hours uncovered, role needed.
4. **Candidates** — who could fill the biggest hole, with their current committed load.
5. **Sources** — tables queried and record counts.

The wow moment is the silent overcommitment: proposed-but-never-committed demand that no standard utilisation report shows side by side.

---

## Edge cases

| Situation | Action |
|-----------|--------|
| No ResourcePlan rows | "No resource plans exist — capacity analysis needs plans set up in xPM first." |
| Propose exists, zero Commit | Whole proposed amount is the gap — the maximum-uncovered scenario; highlight it |
| No resources match the needed role | Report the gap and role; note none found; suggest an admin check the Role field on Resource records |
| User names a specific person | Query `pum_Commit` by `_pum_resource_value`; sum hours across initiatives for the period |

This skill never writes. If asked to assign someone or change a plan, decline and explain that allocation changes are made in xPM; offer the gap data as the basis for that decision.
