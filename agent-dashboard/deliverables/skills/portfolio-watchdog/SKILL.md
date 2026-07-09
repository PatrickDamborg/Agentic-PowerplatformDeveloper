---
name: portfolio-watchdog
description: 'Run a scheduled Monday-morning exception digest across the xPM portfolio: overdue tasks, stale status reports, and unowned risks. Produces a severity-ranked digest of up to 10 items. Load when the user asks for: watchdog, Monday scan, Monday morning scan, exception digest, overdue tasks, stale reports, unowned risks, weekly digest, portfolio exceptions, run the scan, what needs attention, portfolio health digest, schedule scan. Never writes any data.'
---

# Portfolio Watchdog — PoC 05

This skill runs three read-only sweeps of the xPM portfolio and produces a severity-ranked exception digest formatted for a PMO Teams channel. It never writes any data.

---

## Prerequisites

Load the `dataverse-mcp` skill before executing this skill.

---

## The procedure

Run all three sweeps, then compose the digest. The sweeps can be run in parallel (three `read_query` calls).

---

### Sweep 1 — Overdue tasks grouped by initiative

```sql
SELECT
    i.pum_name              AS initiative,
    COUNT(t.pum_gantttaskid) AS overdue_count,
    MAX(DATEDIFF(day, t.pum_finishdate, GETDATE())) AS worst_days_overdue,
    MIN(t.pum_name)         AS example_task
FROM pum_GanttTask t
JOIN pum_Initiative i
    ON t._pum_initiative_value = i.pum_initiativeid
WHERE
    t.pum_finishdate < GETDATE()
    AND t.pum_percentcomplete < 100
    AND t.pum_tasktype <> 493840001
GROUP BY i.pum_initiativeid, i.pum_name
ORDER BY worst_days_overdue DESC
```

---

### Sweep 2 — Initiatives with no status report in 30+ days

```sql
SELECT
    i.pum_name              AS initiative,
    MAX(sr.pum_reportdate)  AS last_report,
    DATEDIFF(day, MAX(sr.pum_reportdate), GETDATE()) AS days_since_report
FROM pum_Initiative i
LEFT JOIN pum_StatusReporting sr
    ON sr._pum_initiative_value = i.pum_initiativeid
WHERE i.statecode = 0
GROUP BY i.pum_initiativeid, i.pum_name
HAVING
    MAX(sr.pum_reportdate) IS NULL
    OR DATEDIFF(day, MAX(sr.pum_reportdate), GETDATE()) > 30
ORDER BY days_since_report DESC
```

---

### Sweep 3 — Risks with no owner or past review date

```sql
SELECT
    i.pum_name          AS initiative,
    r.pum_name          AS risk_name,
    r.pum_riskowner     AS owner,
    r.pum_reviewdate    AS review_date,
    CASE
        WHEN r.pum_riskowner IS NULL THEN 'No owner'
        WHEN r.pum_reviewdate < GETDATE() THEN 'Review overdue'
        ELSE 'Unknown'
    END AS issue_type
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

### Compose the digest

Combine results from all three sweeps. Assign a severity to each item:

| Severity | Criteria |
|----------|----------|
| High | Worst overdue > 30 days; OR no status report > 60 days; OR unowned risk with review > 14 days overdue |
| Medium | Overdue tasks worst 8–30 days; OR no status report 31–60 days; OR risk review overdue 1–14 days |
| Low | Overdue tasks worst ≤ 7 days; OR no status report exactly 30–35 days; OR risk review overdue today |

Rank all items by severity (High first), then by the numeric indicator (days overdue, days since report). Take the top 10 items across all three sweep types.

Format each item identically:

```
[SEVERITY] [TYPE] — [Record name]
Issue: [one sentence describing the specific problem with numbers]
Action: [one sentence suggested next step]
```

Present the full digest in this structure:

```
PORTFOLIO WATCHDOG DIGEST — [date]
Checked: [N] initiatives, [M] tasks, [P] risks across 3 sweeps.

--- HIGH PRIORITY ---
[items]

--- MEDIUM PRIORITY ---
[items]

--- LOW PRIORITY ---
[items]

Total exceptions found: [X]
No records were written.
```

---

### Close the digest

Always end with:

> "In the 6-week PoC, this digest posts itself to the PMO channel every Monday at 07:00 — and drafts the follow-up change requests for approval."

This positions the demo output as a preview of the production capability.

---

## Wow moment

The digest format. It must look exactly like something a PMO would want in their Teams channel — not a data dump, but a ranked, actionable list with severity labels, clear issue descriptions, and concrete next steps. The production version posts this autonomously every Monday morning with zero manual effort.

---

## Hard rules for this skill

1. **Never call `create_record`, `update_record`, or `delete_record`.** This skill is strictly read-only.
2. If the user asks to save the digest, act on a risk, or create a change request from the digest, decline explicitly: "The watchdog digest is read-only — I don't write any records. The 6-week PoC would add an approval flow for follow-up actions."
3. If the user asks to schedule this scan, explain that the 6-week PoC includes configuring a Monday 07:00 autonomous run in Copilot Studio.

---

## Empty-result handling

| Situation | Digest entry |
|-----------|-------------|
| No overdue tasks found | "No overdue tasks in the portfolio this week." — treat as a positive signal |
| No stale reports found | "All active initiatives have a status report within the last 30 days." |
| No unowned risks found | "All open risks have an owner and a current review date." |
| All three sweeps return nothing | Report a clean portfolio: "No exceptions found this week. Portfolio is in good shape." |

Never invent exceptions. An empty sweep is a good result.

---

## Production 6-week PoC additions

Explicitly tell the user what the production build would add beyond this demo:

- Automated posting to a designated PMO Teams channel every Monday at 07:00 via a Copilot Studio scheduled agent flow
- Draft follow-up change requests and task reassignments for the top High-severity items, queued for PM approval
- Week-over-week trend tracking (exceptions resolved vs new exceptions)
- Configurable thresholds (e.g., change the "stale report" threshold from 30 days to 14 days)
- Solution-packaged and transport-ready for deployment to production environments
