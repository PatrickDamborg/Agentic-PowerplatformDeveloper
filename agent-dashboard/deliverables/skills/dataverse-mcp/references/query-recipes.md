---
name: dataverse-mcp-query-recipes
description: 'SQL SELECT patterns for the most common xPM Dataverse queries. Reference for the dataverse-mcp skill. Covers: initiatives with red KPIs, overdue tasks per initiative, top risks by score, proposed vs committed hours gap, stale status reports, unowned risks, ideas by business driver, portfolio roll-up.'
---

# Dataverse MCP — Query Recipes

All queries use SQL SELECT syntax as accepted by the `read_query` tool. Verify column names with `describe` before running in a new environment — column names are stable across environments but picklist integer values may differ.

---

## 1. Initiatives with at least one red KPI

Finds all initiatives whose latest status report has any `KPINew*` dimension rated Red (493840002).

```sql
SELECT
    i.pum_name              AS initiative,
    sr.pum_reportdate       AS report_date,
    sr.pum_kpinewsummary    AS summary_kpi,
    sr.pum_kpinewcost       AS cost_kpi,
    sr.pum_kpinewschedule   AS schedule_kpi,
    sr.pum_kpinewscope      AS scope_kpi,
    sr.pum_kpinewresources  AS resources_kpi,
    sr.pum_kpinewquality    AS quality_kpi
FROM pum_Initiative i
JOIN pum_StatusReporting sr
    ON sr._pum_initiative_value = i.pum_initiativeid
WHERE
    sr.pum_reportdate = (
        SELECT MAX(sr2.pum_reportdate)
        FROM pum_StatusReporting sr2
        WHERE sr2._pum_initiative_value = i.pum_initiativeid
    )
    AND (
        sr.pum_kpinewsummary   = 493840002
        OR sr.pum_kpinewcost   = 493840002
        OR sr.pum_kpinewschedule = 493840002
        OR sr.pum_kpinewscope  = 493840002
        OR sr.pum_kpinewresources = 493840002
        OR sr.pum_kpinewquality = 493840002
    )
ORDER BY sr.pum_reportdate DESC
```

**KPI picklist:** Green = 493840000, Yellow = 493840001, Red = 493840002, N/A = 493840003.

---

## 2. Overdue tasks per initiative

Tasks where finish date is in the past and percent complete is below 100.

```sql
SELECT
    i.pum_name          AS initiative,
    t.pum_name          AS task_name,
    t.pum_finishdate    AS due_date,
    t.pum_percentcomplete AS pct_complete,
    DATEDIFF(day, t.pum_finishdate, GETDATE()) AS days_overdue
FROM pum_GanttTask t
JOIN pum_Initiative i
    ON t._pum_initiative_value = i.pum_initiativeid
WHERE
    t.pum_finishdate < GETDATE()
    AND t.pum_percentcomplete < 100
    AND t.pum_tasktype <> 493840001   -- exclude Phase summary rows
ORDER BY days_overdue DESC
```

Note: `pum_GanttTask` can also link to `pum_Program` or `pum_Portfolio` via separate lookup fields. Run `describe` to confirm the exact navigation property names in the target environment.

---

## 3. Overdue task count grouped by initiative

Summary roll-up for a watchdog digest.

```sql
SELECT
    i.pum_name              AS initiative,
    COUNT(t.pum_gantttaskid) AS overdue_task_count,
    MAX(DATEDIFF(day, t.pum_finishdate, GETDATE())) AS worst_overdue_days
FROM pum_GanttTask t
JOIN pum_Initiative i
    ON t._pum_initiative_value = i.pum_initiativeid
WHERE
    t.pum_finishdate < GETDATE()
    AND t.pum_percentcomplete < 100
    AND t.pum_tasktype <> 493840001
GROUP BY i.pum_initiativeid, i.pum_name
ORDER BY overdue_task_count DESC
```

---

## 4. Top risks by composite score (probability x impact)

Many xPM environments store risk score as a computed or separate field. If no score field exists, proxy with probability and impact picklists.

```sql
SELECT
    i.pum_name          AS initiative,
    r.pum_name          AS risk_name,
    r.pum_probability   AS probability,
    r.pum_impact        AS impact,
    r.pum_riskowner     AS owner,
    r.pum_reviewdate    AS review_date
FROM pum_Risk r
JOIN pum_Initiative i
    ON r._pum_initiative_value = i.pum_initiativeid
WHERE r.statecode = 0   -- active risks only
ORDER BY r.pum_probability DESC, r.pum_impact DESC
```

Verify field names with `describe pum_Risk` — probability and impact may be picklists or decimals depending on the environment.

---

## 5. Risks with no owner or past review date

Used in the watchdog sweep.

```sql
SELECT
    i.pum_name          AS initiative,
    r.pum_name          AS risk_name,
    r.pum_reviewdate    AS review_date,
    r.pum_riskowner     AS owner
FROM pum_Risk r
LEFT JOIN pum_Initiative i
    ON r._pum_initiative_value = i.pum_initiativeid
WHERE
    r.statecode = 0
    AND (
        r.pum_riskowner IS NULL
        OR r.pum_reviewdate < GETDATE()
    )
ORDER BY r.pum_reviewdate ASC
```

---

## 6. Proposed vs committed hours gap per resource plan

The core resource-capacity query. Returns the gap (proposed minus committed) per resource plan for a future date window.

```sql
SELECT
    i.pum_name              AS initiative,
    rp.pum_name             AS resource_plan,
    SUM(p.pum_hours)        AS proposed_hours,
    ISNULL(SUM(c.pum_hours), 0) AS committed_hours,
    SUM(p.pum_hours) - ISNULL(SUM(c.pum_hours), 0) AS gap_hours
FROM pum_ResourcePlan rp
JOIN pum_Initiative i
    ON rp._pum_initiative_value = i.pum_initiativeid
LEFT JOIN pum_Propose p
    ON p._pum_resourceplan_value = rp.pum_resourceplanid
    AND p.pum_startdate >= GETDATE()
LEFT JOIN pum_Commit c
    ON c._pum_resourceplan_value = rp.pum_resourceplanid
    AND c.pum_startdate >= GETDATE()
GROUP BY i.pum_initiativeid, i.pum_name, rp.pum_resourceplanid, rp.pum_name
HAVING SUM(p.pum_hours) - ISNULL(SUM(c.pum_hours), 0) > 0
ORDER BY gap_hours DESC
```

For next-quarter scope, replace `GETDATE()` with the quarter start date and add an upper-bound condition on `pum_finishdate`.

---

## 7. Initiatives with no status report in the last 30 days

Stale-reporting sweep for the watchdog.

```sql
SELECT
    i.pum_name          AS initiative,
    MAX(sr.pum_reportdate) AS last_report_date,
    DATEDIFF(day, MAX(sr.pum_reportdate), GETDATE()) AS days_since_report
FROM pum_Initiative i
LEFT JOIN pum_StatusReporting sr
    ON sr._pum_initiative_value = i.pum_initiativeid
WHERE i.statecode = 0   -- active initiatives only
GROUP BY i.pum_initiativeid, i.pum_name
HAVING
    MAX(sr.pum_reportdate) IS NULL
    OR DATEDIFF(day, MAX(sr.pum_reportdate), GETDATE()) > 30
ORDER BY days_since_report DESC
```

---

## 8. Initiatives per portfolio (hierarchy roll-up)

```sql
SELECT
    port.pum_name       AS portfolio,
    prog.pum_name       AS program,
    i.pum_name          AS initiative,
    i.pum_percentcomplete AS pct_complete
FROM pum_Initiative i
LEFT JOIN pum_Program prog
    ON i._pum_program_value = prog.pum_programid
LEFT JOIN pum_Portfolio port
    ON prog._pum_portfolio_value = port.pum_portfolioid
        OR i._pum_portfolio_value = port.pum_portfolioid
ORDER BY portfolio, program, initiative
```

---

## 9. Ideas grouped by Business Driver (Investment Category)

```sql
SELECT
    ic.pum_name         AS business_driver,
    COUNT(id.pum_ideaid) AS idea_count
FROM pum_Idea id
LEFT JOIN pum_InvestmentCategory ic
    ON id._pum_investmentcategory_value = ic.pum_investmentcategoryid
GROUP BY ic.pum_investmentcategoryid, ic.pum_name
ORDER BY idea_count DESC
```

---

## 10. Open risks per initiative (count and worst severity)

```sql
SELECT
    i.pum_name          AS initiative,
    COUNT(r.pum_riskid) AS open_risk_count
FROM pum_Risk r
JOIN pum_Initiative i
    ON r._pum_initiative_value = i.pum_initiativeid
WHERE r.statecode = 0
GROUP BY i.pum_initiativeid, i.pum_name
ORDER BY open_risk_count DESC
```

---

## Usage notes

- Always run `describe` on any table before using a recipe for the first time in a session — confirm the column names match your environment.
- Picklist integer values for `pum_kpinew*` fields are universal (defined by Projectum): Green = 493840000, Yellow = 493840001, Red = 493840002, N/A = 493840003.
- For risk and task picklists not listed here, query the metadata endpoint or run `describe` and inspect the OptionSet.
- The `read_query` tool accepts Dataverse SQL SELECT syntax. Subqueries, all JOIN types, GROUP BY/HAVING, UNION and TOP are supported; CTEs (`WITH`), DML (INSERT, UPDATE, DELETE) and DDL are not. Avoid `SELECT *` — it degrades performance and can halve the query timeout. Dates come back in UTC.
