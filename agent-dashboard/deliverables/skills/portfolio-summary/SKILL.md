---
name: portfolio-summary
description: 'Produce a structured, data-grounded summary of one xPM entity and the projects beneath it — a portfolio''s programs and initiatives, a program''s initiatives, or a single initiative — and append the charts that are relevant to that portfolio (rendered by executing the bundled scripts/portfolio_charts.py in code interpreter). Load when the user asks to summarize, give an overview/briefing, "how is X doing", "where do things stand", a health rollup, or a state-of-the-portfolio. Do NOT load to draft a status report record (status-report-drafter), analyse staffing gaps (resource-capacity), capture an idea (idea-intake), or fetch documents (information-gatherer). Read-only. Operates on the entity the orchestrator has already resolved.'
---

# Portfolio / Project Summary

Summarize a resolved xPM entity and the work beneath it: health rollup, schedule, top risks, financial envelope — then append the **relevant charts** for the portfolio by executing the bundled `scripts/portfolio_charts.py`. Read-only; always cites sources.

> Guardrails and Dataverse tool discipline are in the agent instructions. Data-model and recipes: `dataverse-mcp` and its `references/`. **The orchestrator has already resolved the target entity** (type + name + id). If it has not, resolve it per the base instructions first.

---

## Step 1 — Set the summary scope from the entity type

| Resolved entity | Roll up |
|---|---|
| Portfolio (`pum_Portfolio`) | its Programs and their Initiatives |
| Program (`pum_Program`) | its Initiatives |
| Initiative (`pum_Initiative`) | the initiative itself |

Confirm the child relationship column with `describe` before the first query (typically `_pum_portfolio_value` on programs/initiatives, `_pum_program_value` on initiatives). Never assume column names.

---

## Step 2 — Gather the rollup (read_query)

Pull only what the summary reports, one concern at a time:

1. **Inventory** — count and list child initiatives (and programs) in scope, with name, phase, % complete.
2. **Health** — the latest `pum_StatusReporting` row per initiative; tally KPI colours (Green 493840000 / Yellow …001 / Red …002 / N/A …003).
3. **Schedule** — overdue `pum_GanttTask` (finish date passed, % complete < 100), grouped per initiative; next milestones.
4. **Risk** — open `pum_Risk` (`statecode = 0`), top items by probability × impact.
5. **Financials** — latest `pum_pf_costplan_versions` and summed value from `pum_pf_powerfinancialsdatas` for the scope, if present.

Initiatives with no status report in 30+ days are a finding — surface them, don't skip them. See `dataverse-mcp/references/query-recipes.md` for ready patterns.

---

## Step 3 — Compose the summary

The reader is a portfolio manager scanning in Teams. Make the bottom line obvious at a glance: a RAG badge in the header, a scannable initiative table, then the few things that need a decision. Use **Markdown** — tables, bold, and emoji all render in Teams and in the test canvas.

**RAG legend** — map each `pum_StatusReporting` KPI colour: 🟢 Green `493840000` · 🟡 Yellow `…001` · 🔴 Red `…002` · ⚪ N/A or no report `…003`. Roll the worst dimension up to the initiative; roll the worst initiative up to the portfolio header badge.

Use this shape (fill from query results — the example values are illustrative):

```md
## 📊 [Entity name] — [Portfolio / Program / Initiative] summary

**Overall: 🔴 At Risk**  ·  6 initiatives  ·  2 programs

> One sentence: the overall state and the single most important signal the PM must act on.

### Initiatives
| Initiative | Phase | Health | Top signal |
|---|---|:---:|---|
| EU FMD Serialisation Platform | Active | 🔴 | Schedule red — 4 of 31 tasks overdue, worst 18d |
| Cold Chain IoT Monitoring Platform | Active | 🔴 | Top risk unowned |
| GxP Quality Management System | Active | 🟢 | On track |
| Regulatory Reporting Automation | Proposed | ⚪ | Not yet reporting |

### ⚠️ Needs attention
1. **EU FMD Serialisation Platform** — schedule red, 4 of 31 tasks overdue (worst 18d late).
2. **Cold Chain IoT Monitoring Platform** — top risk *[name]* has no owner.
3. **Pipeline** — 2 initiatives still Proposed / Under Evaluation; may affect delivery sequencing.

### At a glance
- **Schedule:** X initiatives with overdue tasks; most overdue: [initiative], [N] days late.
- **Risks:** [N] open; top: [name] (prob×impact), owner [name].
- **Financials:** 3,550,000 DKK portfolio budget; initiative budgets not yet set.

---
*Sources: pum_portfolio, pum_program, pum_initiative, pum_statusreporting — 6 initiatives, N reports, K risks, T tasks examined*
```

### Formatting rules
- **One RAG badge in the header**, derived from the worst initiative — never make the PM infer the bottom line.
- **The initiative table is the centrepiece:** ≤10 rows, one RAG cell each, and a *Top signal* that is a number or a fact ("4 of 31 tasks overdue"), never an adjective ("struggling"). Record names, never GUIDs.
- **Needs attention = the decisions**, max 3, each ending in the figure behind it.
- **No inline citation markers.** Never append footnote numbers to values: write `3,550,000 DKK`, not `3,550,0005`; `At Risk`, not `At Risk.3`. All sourcing lives only in the italic *Sources* line at the bottom.
- **Money:** thousands separators + currency code. A literal `0` means "not set" — say so, don't print a bare `0`.
- **Missing concern:** show the line with "— no data on record"; never omit it silently and never imply health you did not measure.

---

## Step 4 — Append the relevant charts (execute the bundled script)

After the text summary, render the charts that this portfolio actually has data for, by reading and executing the bundled `scripts/portfolio_charts.py` in code interpreter. The sandbox has no network, so **you fetch the data and inject it; the script only draws.**

**Only when the scope has ≥2 initiatives** (a portfolio or a program). For a single-initiative summary, skip charts — a one-bar ranking is meaningless. End Step 3 there.

1. **Gather the chart data with the Dataverse MCP** (read-only; `describe` before you query — reuse what Step 2 already pulled where possible):
   - **High (4) risks per initiative** → `HIGH_RISK_DATA`: `describe pum_risk` to find the severity / risk-level option-set field and the option value whose label is `4. High` (confirm the integer — don't assume). `read_query`: count open risks (`statecode = 0`) at that severity, grouped by the linked initiative, within scope. Rows: `{"initiative": name, "high_risks": count}`.
   - **Budget overrun per initiative** → `OVERRUN_DATA`: planned vs actual cost per initiative from the cost-plan tables (`pum_pf_costplan_versions` / `pum_pf_powerfinancialsdatas`, joined to `pum_initiative`). Rows: `{"initiative": name, "planned": n, "actual": n}`.
   - **Phase composition** → `PHASE_DATA`: count of initiatives per `pum_phase` in scope (discover the phase option labels at runtime). Rows: `{"phase": label, "count": n}`. This is the **fallback** chart.

2. **Read** `scripts/portfolio_charts.py` (it holds the chart code and the three data lists near the top).

3. **Inject the live data:** replace `HIGH_RISK_DATA`, `OVERRUN_DATA`, and `PHASE_DATA` with the rows from step 1, keeping the exact shapes. Set `CURRENCY` if you know it. Use initiative names, never GUIDs.

4. **Execute the script.** It renders the **relevant** charts only: `high_risk_by_initiative.png` if any initiative has High risks, `budget_overrun_by_initiative.png` if any is over plan, and — only if neither of those qualifies — the `phase_composition.png` fallback so there is always at least one visual. It prints a one-line summary of each.

5. **Append the rendered chart(s)** below the text summary, each with a one-line caption. The summary's `Sources:` line already covers the tables; add the chart tables (`pum_risk`, cost-plan tables, `pum_initiative`) if not already listed.

**Behaviour rules**
- **Text summary leads, charts follow.** The Step 3 summary + Sources render in every channel; charts are appended. If code interpreter is unavailable or an image fails to render, deliver the text summary and note the charts could not be produced — never block the summary on a chart.
- **Don't fabricate a chart in prose.** If you can't execute the script, say the chart is unavailable; do not hand-draw ASCII bars.
- **Read-only.** Querying and drawing only — never create, update, or delete records.

---

## Empty / thin data

| Situation | Action |
|---|---|
| Entity has no children in scope | State it plainly; summarize the entity's own fields only; skip charts |
| No status reports anywhere in scope | Report "no status reporting on record" as the headline finding |
| A query fails | Summarize from the remaining concerns and name the one that failed; retry it once |
| No risk/overrun data, but initiatives exist | The script renders the `phase_composition.png` fallback so the summary still has a chart |

Never fill a gap with assumptions. An honest "no data for X" is part of the summary.
