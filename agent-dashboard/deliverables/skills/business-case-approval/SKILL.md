---
name: business-case-approval
description: 'Summarize the business case of a Projectum xPM initiative from live data — description, strategy links, cost plan, top risks, and proposed resource demand — into a decision-ready structured summary for an approver. Load when the user asks to: summarize a business case, prepare a business case for approval, is this initiative ready for approval, business case summary, brief the approver, steering committee briefing for an initiative. Read-only: this skill writes nothing. In the Copilot Studio build it is invoked by the agent node inside the Business Case Approval workflow (PoC 06); the approval, BPF stage advance, and notifications are handled by the workflow, not this skill.'
---

# Business Case Approval — PoC 06

This skill produces a decision-ready, data-grounded summary of an initiative's business case. It is the reasoning step of the autonomous Business Case Approval workflow: the workflow triggers on the Business Case stage of the initiative business process flow, calls the agent with this skill via the **agent node**, hands the structured output to a **Microsoft 365 Copilot node** for message generation, and routes the result to the approver as a Teams approval.

The skill itself is **read-only**. It gathers, reasons, and summarizes. It never writes, never advances the BPF stage, and never sends messages — those are workflow actions.

---

## Prerequisites

Load the `dataverse-mcp` skill before executing this skill.

---

## The 3-step procedure

### Step 1 — Resolve the initiative

If invoked by the workflow, the initiative GUID is in the trigger payload — use it directly. If invoked conversationally with only a name:

```
searchQuery(
  search: "<initiative name>",
  entities: [{ Name: "pum_initiative", SearchColumns: ["pum_name","pum_description"], SelectColumns: ["pum_initiativeid","pum_name","pum_phase"] }]
)
```

If more than one candidate matches, ask which one — never guess.

### Step 2 — Gather the business case data (5 queries)

Run all five. Each feeds a section of the summary. `describe` `pum_Initiative` first to discover the business-case text fields present in this environment (description, scope, benefits — names vary by configuration); never assume column names.

**2a. Initiative core**
```sql
SELECT pum_name, pum_description, pum_phase, pum_percentcomplete,
       pum_startdate, pum_finishdate,
       _ownerid_value, _pum_sponsor_value,
       _pum_category_value, _pum_program_value, _pum_portfolio_value
FROM pum_Initiative
WHERE pum_initiativeid = '<guid>'
```

**2b. Strategy chain** — resolve the names behind the lookups:
- Business Driver: `pum_InvestmentCategory` record behind `_pum_category_value`.
- Strategic Objective: follow the portfolio's `pum_PrimaryObjective` to `pum_StrategicObjectives` (via the program's portfolio if there is no direct portfolio link).
- Original rationale: the linked idea, if any (`pum_Idea` via `pum_LinkedIdea`), for the problem statement the initiative was created to solve.

**2c. Financial envelope**
```sql
SELECT TOP 1 pum_pf_costplan_versionid, pum_name
FROM pum_pf_costplan_versions
WHERE _pum_initiative_value = '<guid>'
ORDER BY createdon DESC
```
Then aggregate `pum_pf_powerfinancialsdatas` for that version (`SUM(pum_pf_valuedec)`) for the total planned cost. Report the number, the currency if discoverable, and the cost plan version name.

**2d. Top open risks**
```sql
SELECT TOP 3 pum_name, pum_probability, pum_impact, pum_riskowner
FROM pum_Risk
WHERE _pum_initiative_value = '<guid>' AND statecode = 0
ORDER BY pum_probability DESC, pum_impact DESC
```

**2e. Proposed resource demand**
Resolve the initiative's `pum_ResourcePlan` header, then sum proposed effort from `pum_Propose` (and committed from `pum_Commit` if present) to state the demand: "~N hours proposed, M committed."

If any query returns nothing, say so in the relevant section. Do not invent data.

### Step 3 — Compose the structured summary

Produce exactly this structure — it is the output contract the workflow's agent node maps to its structured output, so the field names matter:

```
BUSINESS CASE SUMMARY — [Initiative Name]
Prepared: [today's date]   For approval by: [approver, if known]

summary:            [3–5 sentences: what the initiative is, the problem it solves
                     (from the linked idea if present), timeline envelope, current phase]
financialEnvelope:  [total planned cost from the latest cost plan version, or "No cost plan found"]
strategicAlignment: [Business Driver name + Strategic Objective name, one line each on the link]
topRisks:           [up to 3: name — probability/impact — owner or "no owner"]
resourceDemand:     [proposed vs committed hours, or "No resource plan found"]
recommendation:     [Approve / Approve with conditions / Needs work — one line citing
                     the specific data that drives the verdict]

sources: pum_Initiative, pum_InvestmentCategory, pum_StrategicObjectives,
         pum_pf_costplan_versions, pum_pf_powerfinancialsdatas, pum_Risk,
         pum_ResourcePlan, pum_Propose, pum_Commit
         [list only the tables actually queried; note record counts]
```

The recommendation is the wow moment, and it must be earned: "Approve with conditions — cost plan covers the full timeline, but the top risk (Vendor lock-in, high/high) has no owner." Never write a recommendation that does not cite retrieved data.

---

## Empty-data rules

| Situation | What to do |
|-----------|-----------|
| No description / business-case text on the initiative | Say "No business case narrative found on the record" in `summary`; build the rest from structure data |
| No cost plan version | `financialEnvelope` = "No cost plan found"; recommendation cannot be plain Approve |
| No Business Driver or Strategic Objective link | `strategicAlignment` = "Not linked to strategy"; flag it in the recommendation |
| No open risks | `topRisks` = "No open risks recorded"; treat as a positive signal but note if the register looks empty rather than clean |
| No resource plan | `resourceDemand` = "No resource plan found" |

An honest gap is better than a fabricated strength — the approver is making a real decision on this summary.

---

## Generative vs deterministic

- **Deterministic (the workflow's job, not yours):** the trigger condition (Send Approval = Yes and Approver populated), the Teams approval routing, the BPF stage advance on approval, the owner notification, and the Send Approval reset.
- **Generative (this skill):** the summary prose and the recommendation — grounded in the five queries.
- **Generative (downstream):** the Microsoft 365 Copilot node rewrites the structured output as the approver-facing message. It must not add facts; everything it says traces back to this skill's output.
