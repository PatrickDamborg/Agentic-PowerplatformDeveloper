---
name: status-report-drafter
description: 'Draft a 5-dimension KPI status report for one xPM initiative from live schedule, risk, and cost data, then save it after explicit approval. Load when the user asks to draft/write/prepare/generate a status report or project update, "report on project health", "how is my project doing", a KPI or traffic-light report. Do NOT load for portfolio-wide summaries (use portfolio-summary), resource-gap analysis (resource-capacity), or document gathering (information-gatherer). Operates on the initiative the orchestrator has already resolved. Uses the pum_skill_fetch_status_data flow tool for all data — never raw Dataverse queries. Writes one row to pum_StatusReporting, only after the user approves the draft shown in chat.'
---

# Status Report Drafter

Draft a 5-dimension KPI status report grounded in live xPM data and save it to `pum_statusreportings` only after explicit approval.

> Guardrails, approval rules, and Dataverse tool discipline are in the agent instructions. Data-model details: `dataverse-mcp`. **The orchestrator has already resolved the target initiative** (name + id); if it has not, resolve it per the base instructions before Step 1.
>
> **Performance note:** this skill used to run 6–8 sequential Dataverse queries, each costing a full generative-orchestration turn (minutes of wait). It now makes exactly **one** tool call — `pum_skill_fetch_status_data` — which fetches every dimension and applies the deterministic ratings server-side in a single Power Automate flow. Do not fall back to `read_query`/`list_rows` for status-report data; that reintroduces the latency this redesign removed. Dataverse MCP stays available for ad-hoc questions the flow doesn't answer.

---

## Step 1 — Call the fetch-status-data tool (one call, not four)

Call `pum_skill_fetch_status_data` once with the resolved initiative id:

```
pum_skill_fetch_status_data(initiativeId: "<id>", mode: "auto")
```

- `mode: "auto"` (default) returns a cached draft if one exists and is fresh; the response's `source` field tells you which (`"cache"` or `"fresh"`).
- Use `mode: "fresh"` when the user explicitly asks to refresh, or when they question the freshness of a cached answer.

The tool returns one JSON payload with `timeline`, `financials`, `scope`, `quality`, `resources`, `overall` (each with `rating`, `ratingInt`, and dimension-specific evidence numbers), `trend` (prior report context), and `dataGaps` (array of honesty notes for any N/A or absence-based rating). **Do not call `read_query`/`list_rows` against `pum_gantttasks`, `pum_risks`, `pum_pf_powerfinancialsdatas`, `pum_proposes`/`pum_commits`, or `pum_statusreportings` for this skill** — the flow already did it.

---

## Step 2 — Review the ratings (not compute them)

The ratings arrive **pre-computed and deterministic** — your job flips from *calculating* them to **reviewing** them:

1. Sanity-check each `ratingInt` against its evidence numbers using `references/5-dimension-rules.md`. Example: if `timeline.overdueCount` is 0 but `timeline.rating` isn't Green, that's a contradiction — flag it in the draft rather than silently overriding it.
2. Read `dataGaps` — surface every entry to the user verbatim or near-verbatim; these mark N/A dimensions and Green-by-absence-of-evidence cases.
3. Read `trend` — if `hasPriorReport` is true, note any dimension that moved (e.g. Financials was Green last time, now Yellow).

---

## Step 3 — Show the draft, then ask once

```
STATUS REPORT DRAFT — [initiativeName]      Data as of: [computedOn] ([source: cache — say "refresh" for live data | fresh])

FINANCIALS  [timeline.rating]  [one line citing timeline.overdueCount, timeline.worstOverdueDays, etc.]
SCOPE       [scope.rating]     [one line citing scope.openRiskCount, scope.highRiskCount, scope.openChangeRequestCount]
QUALITY     [quality.rating]   [one line citing quality.qualityLessonCount, quality.qualityRiskCount]
TIMELINE    [timeline.rating]  [one line citing timeline.incompleteCount, timeline.overdueCount, timeline.worstOverdueDays]
RESOURCES   [resources.rating] [one line citing resources.proposedHours, resources.committedHours, resources.gapPct]
OVERALL     [overall.rating]   [one line]

Highlights:  [what's going well — from the evidence numbers and topRisks]
Lowlights:   [issues/blockers — from dataGaps, topRisks, overdue evidence]
Next period: [timeline.nextMilestoneDate, or note if none found]

Sources: pum_skill_fetch_status_data (pum_initiatives, pum_gantttasks, pum_risks, pum_changerequests, pum_lessonslearneds, pum_pf_powerfinancialsdatas, pum_proposes, pum_commits, pum_statusreportings)
```

The justifications are the wow moment — each cites actual numbers ("Timeline: Yellow — 4 of 31 tasks incomplete, worst overdue by 18 days"). Never write a justification without grounding it in the payload. Then ask: **"Shall I save this as a status report record in xPM?"** and wait.

---

## Step 4 — Save on explicit approval

Only on an unambiguous "yes", using the `ratingInt` values straight from the payload (no translation needed — the flow already computed them):

```
create_record(table: "pum_statusreportings", body: {
  "pum_name": "<initiativeName> - Status <YYYY-MM-DD>",
  "pum_Initiative@odata.bind": "/pum_initiatives(<id>)",
  "pum_statusdate": "<YYYY-MM-DD>",
  "pum_kpinewsummary": <overall.ratingInt>, "pum_kpinewcost": <financials.ratingInt>,
  "pum_kpinewschedule": <timeline.ratingInt>, "pum_kpinewscope": <scope.ratingInt>,
  "pum_kpinewresources": <resources.ratingInt>, "pum_kpinewquality": <quality.ratingInt>,
  "pum_budget": <financials.budget>, "pum_actualcost": <financials.actuals>,
  "pum_currentphase": "<currentPhase>",
  "pum_comment": "<synthesized highlights/lowlights/next-period narrative>",
  "pum_kpinewcostcomment": "<one-line Financials justification>",
  "pum_kpinewschedulecomment": "<one-line Timeline justification>",
  "pum_kpinewscopecomment": "<one-line Scope justification>",
  "pum_kpinewqualitycomment": "<one-line Quality justification>",
  "pum_kpinewresourcescomment": "<one-line Resources justification>"
})
```

**KPI integers (verified live against pdausa — do not use any other mapping):** Green **493840003**, Yellow **493840002**, Red **493840001**, N/A/Not Set **493840000**. Set only `pum_kpinew*` — never `pum_kpicurrent*` (xPM rolls those forward automatically from submitted reports). There are **no** `pum_highlights`/`pum_lowlights`/`pum_nextperiodplan` fields on this table — the overall narrative goes in `pum_comment`; per-dimension one-liners go in the matching `pum_kpinew*comment` field. Omit any N/A dimension's rating field rather than defaulting it to Green. After saving, return the record name and how to find it (initiative → Status Reports tab).

---

## Empty-data rules

The flow already applies these — this table is for your review step, not for you to re-derive them:

| Situation | Flow's behavior |
|-----------|------------------|
| No incomplete/overdue Gantt tasks | Timeline = Green (flow does not currently distinguish "no data" from "nothing overdue" for this dimension — documented simplification) |
| No open risks or change requests | Scope = Green, with a `dataGaps` entry noting absence-of-evidence, not confirmed clean status |
| No financial data (`pum_pf_powerfinancialsdatas` budget sum is null) | Financials = N/A, `dataGaps` entry added |
| No resource plan data (`pum_proposes` sum is null) | Resources = N/A, `dataGaps` entry added |
| No prior status report | `trend.hasPriorReport` = false; skip trend narrative |

Always surface `dataGaps` verbatim. An honest N/A beats a fabricated rating.

---

## Generative vs deterministic
- **Deterministic** (computed in the flow, never recompute): every `ratingInt` — see `references/5-dimension-rules.md` to verify, not to recalculate.
- **Generative** (agent writes, grounded in the payload's evidence numbers): the one-line justifications, Highlights, Lowlights, Next period, and the `pum_comment`/`pum_kpinew*comment` narrative text saved in Step 4.

## Reference files
- `references/5-dimension-rules.md` — deterministic rating logic per KPI dimension (as implemented in `pum_skill_fetch_status_data`)
