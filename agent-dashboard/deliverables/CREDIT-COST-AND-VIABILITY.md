# Copilot Credit Cost & Business Case Viability — the six xPM AI use cases

**Author:** Patrick Damborg
**Date:** June 2026
**Rates verified against:** Microsoft Learn, June 2026 (links in Sources)

---

## 1. The billing model in one page

Copilot Studio bills everything in **Copilot Credits**. Rates apply to all Copilot Studio-provided models — including Claude Sonnet 4.6 — and differ only for bring-your-own-model setups (not used here).

| Agent feature | Credits | Used in our build by |
|---|---|---|
| Classic answer | 1 | Topic-triggered flow calls |
| Generative answer | 2 | Every conversational agent reply |
| Agent action | 5 | Every tool call the agent makes (MCP tools, flows via generative orchestration, triggers, deep-reasoning steps) |
| Tenant graph grounding | 10 | Not used (we ground in Dataverse, not Graph) |
| Agent flow / workflow actions | 13 per 100 actions (≈0.13 each) | Every step in the PoC 02/03 flows and the PoC 06 workflow |
| AI tools — standard prompt | 15 per 10 responses (≈1.5 each) | Prompt node in the Status Report Drafter flow |

**Money:**

- Pay-as-you-go: **$0.01 per credit** (Azure subscription)
- Capacity pack: **$200/month per 25,000 credits** (≈$0.008/credit, tenant-wide, resets monthly)
- Pre-purchase plan (P3): tiered discounts at enterprise volume — irrelevant at our volumes

**The three levers that change everything:**

1. **M365 Copilot licensed users are zero-rated.** Employee-facing agent usage by a user holding an M365 Copilot license consumes no credits (fair-use limits apply). A pilot group of licensed PMs runs the conversational PoCs at effectively $0.
2. **Test runs are free.** The flow designer and the agent test chat don't consume capacity — the entire build and demo phase costs ~nothing in credits.
3. **Dataverse MCP from outside Copilot Studio** (the Claude Code demo) bills separately since 15 Dec 2025: `search_data` at the tenant-graph rate (10), all other tools at the basic AI-tools rate (≈0.1–1) — also waived for M365 Copilot USL holders.

---

## 2. Cost model per use case

Assumptions: a mid-size PMO on pdausa-like data — 20 active PMs/stakeholders, 30 reporting initiatives, 20 ideas/month, weekly watchdog, 3 large-project business cases/month. Costs shown at the **unlicensed worst case** (pay-as-you-go, $0.01/credit); with M365 Copilot licensed users, the conversational rows go to ≈$0. Per-run figures are pre-build estimates ±50% — generative orchestration can plan more or fewer tool calls per turn. Validate with the [Copilot Studio agent usage estimator](https://microsoft.github.io/copilot-studio-estimator/) and PPAC consumption reporting once live.

| # | Use case | Credit anatomy per run | Credits/run | Runs/month | Credits/month | $/month (PAYG) |
|---|---|---|---|---|---|---|
| 01 | Ask Your Portfolio | 3–4 MCP tool calls (15–20) + generative answer (2) per question | ~20/question | 300 questions | ~6,000 | ~$60 |
| 02 | Status Report Drafter | resolve (5) + drafter flow (5 + ~10 actions ≈1.3) + prompt node (1.5) + draft & confirm answers (4) + write flow (5.5) | ~25 | 30 drafts | ~750 | ~$7.50 |
| 03 | Idea Intake | 3 interview turns (6) + duplicate check (5) + 2 discovery queries (10) + proposal (2) + create flow (5.3) + confirm (2) | ~30 | 20 ideas | ~600 | ~$6 |
| 04 | Resource & Capacity | 2 describes (10) + 3 aggregate queries (15) + candidates (5) + answer (2) + follow-up | ~40 | 8 analyses | ~320 | ~$3 |
| 05 | Portfolio Watchdog | trigger (5) + 3 sweeps (15) + digest (2) + Teams post (5) | ~27 | 4–5 runs | ~120 | ~$1.20 |
| 06 | Business Case Approval | ~12 workflow actions (1.6) + agent node = full agent run: ~6 tool calls + answer (32) + M365 Copilot node (license-covered) + approval & posts (in actions) | ~35 | 3 cases | ~105 | ~$1 |
| | **Total** | | | | **~7,900** | **~$79** |

**Readings:**

- **The whole six-PoC portfolio runs on less than a third of one $200 capacity pack.** At PAYG it is ~$79/month worst case; with a licensed pilot group it rounds to zero.
- **PoC 01 dominates consumption** (~75%) because it scales with curiosity, not with process events. It is also the row most likely to be zero-rated, since the people asking are exactly the people you'd give M365 Copilot.
- **The autonomous PoCs (05, 06) are the cheapest to run** — workflow actions cost ≈0.13 credits, so deterministic orchestration is nearly free; the only meaningful cost is the agent-node reasoning step.
- **PoC 06 nuance:** the Microsoft 365 Copilot node requires the run-as account to hold an M365 Copilot license — which simultaneously zero-rates that node's usage. The license ($30/user/month) is a prerequisite cost, not a per-run cost, and one license covers all runs.
- Not in credits: Dataverse storage, the M365 Copilot licenses themselves, and the build timeboxes — see §3.

---

## 3. Business case viability per use case

Value assumptions: loaded PM/PMO cost $90/h; figures are gross value at the stated volumes. The structural point first: **credit consumption is noise** — the real costs of each use case are the build timebox (consultancy weeks) and, where applicable, M365 Copilot licenses. Viability therefore hinges on time saved and decision quality, never on credits.

### PoC 01 — Ask Your Portfolio — **Strong (sell first)**

- **Value:** 10–15 min saved per answered question vs. digging through views/exports ≈ $15–22/question; at 300 questions/month ≈ **$4,500–6,700/month** gross. Honest discount: not every question replaces manual work — even at 25% substitution it clears $1,100/month against a 1-week build.
- **Risks:** value collapses if data quality is poor (answers grounded in stale data erode trust fast); adoption is behavioural.
- **Verdict:** cheapest build, fastest proof, the foundation every other PoC reuses. Its real job is de-risking the platform decision for ~1 week of effort.

### PoC 02 — Status Report Drafter — **Strong (flagship ROI)**

- **Value:** 30–60 min saved per report × 30 reports/month = 15–30 h ≈ **$1,350–2,700/month**, plus harder-to-price consistency: every report cites data, no dimension skipped, trend always compared. Against a 3-week build, payback is ~2–4 months on time savings alone.
- **Risks:** low — the write is approval-gated, the rules deterministic. Main failure mode is thin schedule/risk data making drafts hollow.
- **Verdict:** the strongest standalone business case in the catalogue. This is the one to anchor pricing on.

### PoC 03 — Idea Intake & Qualification — **Medium (strategic, not financial)**

- **Value:** hard savings are modest — 15–20 min triage/dedup per idea × 20 ideas ≈ **$450–600/month**. The real value is funnel quality: strategy-linked ideas from day one, and duplicate prevention — a single avoided duplicate project is worth more than a year of everything else here.
- **Risks:** value depends on idea volume and on the organisation actually using Strategic Objectives/Business Drivers.
- **Verdict:** weak as a standalone ROI sale, good as the "strategy alignment" story in a bundle. Sell where intake volume is real.

### PoC 04 — Resource & Capacity Assistant — **Medium (conditional)**

- **Value:** episodic but large per event — surfacing proposed-vs-committed gaps before they become delays. One caught staffing gap on one initiative can be worth weeks of delay cost. Steady-state hard savings are small (~8 analyses/month).
- **Risks:** the hardest data dependency in the catalogue — requires Propose/Commit rows to be maintained. Where resource management is immature, the agent truthfully reports "no data," which demos honesty but sells nothing.
- **Verdict:** sell only into organisations with active xPM resource planning; qualify this hard in pre-sales.

### PoC 05 — Portfolio Watchdog — **Strong (the retention play)**

- **Value:** replaces 1–2 h/week of PMO chasing ≈ **$360–720/month**, plus earlier intervention on overdue work and a data-hygiene flywheel (named-and-shamed stale reports get updated). Cost to run: ~$1/month.
- **Risks:** digest fatigue if not severity-capped (the 10-item cap is the mitigation); needs the Teams channel norm to stick.
- **Verdict:** the best value-to-cost ratio in the catalogue and the stickiness mechanism — a weekly artifact in the PMO channel that keeps the subscription renewed.

### PoC 06 — Business Case Approval — **Medium standalone / High strategic**

- **Value:** at 3 cases/month the direct time saving is small (~30 min of exec reading + PMO chasing per gate ≈ **$150–300/month**). The real value is **gate cycle-time**: business cases that wait days-to-weeks for a steering review get decided in hours, and on large projects the option value of starting weeks earlier dwarfs every figure above. Add the audit trail (summary, approver, timestamp, outcome — all recorded) for governance-heavy buyers.
- **Costs & risks:** one M365 Copilot license for the run-as account ($30/month, also zero-rates the node); built on the Workflows public preview — not production-supported yet, acceptable for demo/PoC, flag it in any sale; the BPF stage-advance is environment-fiddly (already scoped as the 6-week deliverable).
- **Verdict:** don't sell it on hours saved — sell it as the proof that xPM can run **autonomous, human-gated governance**. It is the demo closer and the differentiator competitors can't show; commercially it belongs in the 6-week tier as the upsell after 01/02 land.

### Portfolio read

| # | Use case | Standalone ROI | Strategic value | Sell as |
|---|---|---|---|---|
| 01 | Ask Your Portfolio | High | Foundation | First — the 1-week wedge |
| 02 | Status Report Drafter | **Highest** | High | The anchor of the offer |
| 03 | Idea Intake | Low–Medium | Medium | Bundle filler where intake is real |
| 04 | Resource & Capacity | Conditional | Medium | Qualified deals only |
| 05 | Portfolio Watchdog | High | Retention | The subscription hook |
| 06 | Business Case Approval | Low–Medium | **Highest** | The vision closer / upsell |

Recommended motion: lead demos with 02 (ROI) and close with 06 (vision); land 01+02 as the first engagement; attach 05 in month two; hold 03/04 for qualified fits.

### Time-to-wage translation (the customer-facing ROI table)

The version used on the offering deck's RETURN ON INVESTMENT slide. Deliberately conservative mid-range figures at the same volumes as §2; the $90/h loaded rate is a placeholder — swap in the customer's own rate live and the table reprices itself.

| # | Use case | Time saved | Runs/mo | Hours/mo | Value @ $90/h |
|---|---|---|---|---|---|
| 01 | Ask Your Portfolio | 5 min net/question¹ | 300 | 25 h | $2,250 |
| 02 | Status Report Drafter | 45 min/report | 30 | 22.5 h | $2,025 |
| 03 | Idea Intake | 20 min/idea | 20 | 6.7 h | $600 |
| 04 | Resource & Capacity | 2 h/gap analysis² | 8 | 16 h | $1,440 |
| 05 | Portfolio Watchdog | 1.5 h chasing/week | 4–5 | 6.5 h | $585 |
| 06 | Business Case Approval | 30 min/stage gate³ | 3 | 1.5 h | $135 |
| | **Total** | | | **~78 h** | **~$7,000/month** |

¹ Assumes one in four questions replaces ~20 minutes of manual digging — the 25% substitution discount from the PoC 01 verdict above.
² The manual equivalent of a proposed-vs-committed gap analysis (assemble, aggregate, rank) — only claim this where resource plans are maintained.
³ Hours understate PoC 06: its real value is stage-gate cycle-time (days-to-weeks faster decisions on large projects) and the audit trail.

Headline contrast for the slide pair: **~$7,000/month of wage-time back vs ~$79/month of running credits — roughly 90× — and ~$84,000/year.**

---

## Sources

- [Billing rates and management](https://learn.microsoft.com/microsoft-copilot-studio/requirements-messages-management) — Copilot Credit rate card, billing examples, M365 Copilot zero-rating, agent flow enforcement
- [Copilot Credits overview](https://learn.microsoft.com/microsoft-copilot-studio/copilot-credits-overview) — $0.01 PAYG, $200/25,000 pack, P3 plans
- [Agent flows and workflows overview](https://learn.microsoft.com/microsoft-copilot-studio/flows-overview) — workflow/flow action billing, free test runs
- [Connect to Dataverse with MCP](https://learn.microsoft.com/power-apps/maker/data-platform/data-platform-mcp) — MCP billing outside Copilot Studio, license waivers
- [Copilot Studio agent usage estimator](https://microsoft.github.io/copilot-studio-estimator/) — for validating these estimates pre-deployment
