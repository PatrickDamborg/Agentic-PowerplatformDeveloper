---
name: status-report-5-dimension-rules
description: 'Deterministic rating rules for each of the 5 KPI dimensions in the xPM Status Report Drafter skill. Apply these rules mechanically to live data — the traffic-light outcome is not generative. Covers: Timeline, Financials, Scope, Quality, Resources, and Overall Summary. Used by the status-report-drafter skill.'
---

# Status Report — 5-Dimension Rating Rules

**These rules are implemented in `pum_skill_fetch_status_data`** (the flow tool called in Step 1 of the status-report-drafter procedure) — use this document to **verify** the flow's ratings against their evidence numbers, not to recompute them by hand. The one-line justification prose is generative; the colour is not.

Two documented simplifications the flow makes relative to the full rules below (accepted for the demo build — see the xPM AI project plan):
- **Timeline** does not distinguish "no schedule data at all" from "zero overdue tasks" — both rate Green. A true N/A path for Timeline is not implemented.
- **Quality**'s Lessons Learned signal uses `pum_impact = Negative` (there is no dedicated "Quality" learning category in the live schema) instead of a category filter, and does not implement the "no lessons data at all → N/A" branch — it only distinguishes "negative signal present" (Yellow/Red) from "no negative signal found" (Green).

---

## Dimension 1 — Timeline

Inputs from `pum_GanttTask`:
- `overdue_count` — tasks with `pum_finishdate < today` and `pum_percentcomplete < 100`
- `total_incomplete` — all incomplete tasks
- `worst_overdue_days` — maximum of `(today − pum_finishdate)` across overdue tasks

| Condition | Rating |
|-----------|--------|
| `overdue_count = 0` | Green |
| `overdue_count > 0` AND overdue tasks ≤ 10% of `total_incomplete` AND `worst_overdue_days ≤ 7` | Yellow |
| `overdue_count > 0` AND (overdue tasks > 10% of `total_incomplete` OR `worst_overdue_days > 7`) | Yellow |
| `overdue_count > 0` AND (overdue tasks > 25% of `total_incomplete` OR `worst_overdue_days > 30`) | Red |
| No GanttTask records found | N/A |

Simplified decision tree:
1. Zero overdue tasks → Green.
2. Any overdue tasks with worst overdue > 30 days OR more than 25% of tasks overdue → Red.
3. Any overdue tasks, but within the thresholds above → Yellow.
4. No schedule data → N/A.

---

## Dimension 2 — Financials

Inputs from `pum_pf_powerfinancialsdatas` (or cost plan version):
- `budget` — approved budget (baseline cost plan)
- `actuals` — actual spend to date
- `forecast` — forecast at completion

| Condition | Rating |
|-----------|--------|
| Forecast ≤ budget | Green |
| Forecast > budget by 0–10% | Yellow |
| Forecast > budget by more than 10% | Red |
| No financial data found | N/A |

If only actuals are available (no forecast):
- Actuals ≤ budget and % complete ≥ % budget consumed → Green
- Actuals > budget by 0–10% → Yellow
- Actuals > budget by > 10% → Red

If no cost data exists in `pum_pf_*` tables, set N/A. Do not infer cost health from other fields.

---

## Dimension 3 — Scope

Inputs from `pum_Risk` and `pum_ChangeRequest`:
- `open_high_risk_count` — open risks with high probability AND high impact
- `open_change_request_count` — open `pum_ChangeRequest` records linked to the initiative

| Condition | Rating |
|-----------|--------|
| Zero open risks and zero open change requests | Green |
| Open risks present but none with both high probability AND high impact | Yellow |
| One or more open risks with high probability AND high impact | Red |
| Open change requests present (scope is being renegotiated) | Yellow (at minimum) |
| No risk or change request data | Green (absence of evidence = no scope concern; note this explicitly) |

The agent must note when scope = Green due to absence of data, not confirmed clean status.

---

## Dimension 4 — Quality

Inputs: this dimension is primarily informed by the narrative context. In the absence of a dedicated quality metric in standard xPM Essentials, use the following proxy rules:

| Signal | Rating implication |
|--------|--------------------|
| Lessons Learned records with `pum_category` = quality issue, created in last 30 days | Negative signal → Yellow or Red |
| Open risks tagged with quality-related keywords (query `pum_Risk.pum_name` with `search_data`) | Negative signal → Yellow |
| No quality-related lessons or risks | Green |
| No data at all in `pum_LessonsLearned` for this initiative | N/A |

Default rule when no quality-specific data exists: set Quality = N/A and note the reason. Do not default to Green without evidence.

---

## Dimension 5 — Resources (optional but recommended)

Inputs from `pum_Propose` and `pum_Commit` (via `pum_ResourcePlan`):
- `gap_hours` = SUM of proposed hours − SUM of committed hours for current + next period

| Condition | Rating |
|-----------|--------|
| `gap_hours = 0` (all proposed hours are committed) | Green |
| `gap_hours > 0` AND gap ≤ 20% of total proposed hours | Yellow |
| `gap_hours > 0` AND gap > 20% of total proposed hours | Red |
| No resource plan or allocation data found | N/A |

---

## Overall Summary

The Overall rating is derived from the other five dimensions — it is never independently green if any component is red.

| Condition | Rating |
|-----------|--------|
| All rated dimensions are Green | Green |
| Any rated dimension is Yellow, none are Red | Yellow |
| Any rated dimension is Red | Red |
| All dimensions are N/A | N/A (unusual — flag to the user) |

The overall narrative (Highlights, Lowlights, Next period) should be consistent with the overall colour. A Green overall with a pessimistic narrative is a contradiction — revisit the dimension ratings.

---

## Rating translation table

**Verified live against pdausa on 2026-07-03** (confirmed identical across all six `pum_kpinew*`/`pum_kpicurrent*` fields on `pum_statusreportings`). This is the reverse of what earlier versions of this document and related repo docs assumed — if you see 493840000=Green/493840001=Yellow/493840002=Red anywhere else in this repo, that reference is stale.

| Integer | Display in chat |
|---------|----------------|
| 493840000 | ⚪ N/A / Not Set |
| 493840001 | 🔴 Red (Need help) |
| 493840002 | 🟡 Yellow (At risk) |
| 493840003 | 🟢 Green (No issue) |

Always translate before presenting to the user. Never show raw integers in the draft.
