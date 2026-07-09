# xPM AI — Deliverables

Five outputs for building and running the xPM AI demo.

---

## 1. Colleague work package

**`COLLEAGUE-WORK-PACKAGE.md`**

A self-contained Copilot Studio build spec. Hand this to the colleague doing the demo build. Covers: objective, the single-agent architecture, all 6 PoCs with acceptance criteria, build sequence, prerequisites, out-of-scope, and definition of done.

---

## 2. Skill files

**`skills/`**

SKILL.md files in agentskills.io format. Two consumers: the Claude Code demo harness loads them automatically (`.claude/skills/` is a recognised location); the Copilot Studio agent loads the same files via its Skills panel.

| Folder | Purpose |
|---|---|
| `dataverse-mcp/` | Foundational: MCP tool surface, guardrails, session-start ritual, query recipes, xPM cheat sheet |
| `ask-portfolio/` | PoC 01 — live Q&A, read-only |
| `status-report-drafter/` | PoC 02 — 5-dimension draft + approval-gated save |
| `idea-intake/` | PoC 03 — interview → duplicate check → strategy-linked idea |
| `resource-capacity/` | PoC 04 — proposed-vs-committed gap |
| `portfolio-watchdog/` | PoC 05 — Monday exception digest, no writes |
| `business-case-approval/` | PoC 06 — autonomous business-case summary for a Teams approval; read-only skill, the surrounding Copilot Studio workflow handles trigger, approval, BPF advance and notifications |

---

## 3. Copilot Studio agent instructions

**`COPILOT-STUDIO-INSTRUCTIONS.md`**

Paste-ready instruction blocks for the agent's Instructions field, covering the Dataverse MCP across all six PoCs: a shared base block (tool selection, tool usage, guardrails), a routing block, and one task block per use case. Grounded in Microsoft Learn guidance (June 2026), including where and why we deliberately deviate from Microsoft's own sample instructions.

---

## 4. Credit cost & viability analysis

**`CREDIT-COST-AND-VIABILITY.md`**

Per-use-case Copilot Credit cost model (rates verified against Microsoft Learn, June 2026) and a business case viability verdict for each of the six PoCs, ending in a recommended sales motion. Use in pricing conversations and pre-sales qualification.

---

## 5b. Portfolio chart capability (optional add-on)

**`CHART-CAPABILITY.md`**

Build spec for rendered **bar charts** — initiatives ranked by open-risk exposure, budget overrun, or schedule slippage — via Copilot Studio **code interpreter** (prompt → agent flow → Adaptive Card). An optional visual layer on PoC 01 / `portfolio-summary`, not one of the six core PoCs. Covers the honest caveats (GPT‑4.1 not Claude, premium billing, Teams image-render limit + size fallback), the exact prompt, the flow steps, and the Power Fx card formula.

> The charts also ship as **bundled Python inside the merged `portfolio-summary` skill** — `portfolio-summary.zip` (`SKILL.md` + `scripts/portfolio_charts.py`) renders High-(4) risks, budget overrun, and a phase-composition fallback directly in the summary. This `CHART-CAPABILITY.md` route (prompt → flow → Adaptive Card) is the alternative for a Dataverse-grounded flow; both use the same Context& style.

---

## 5. Design / decision log

**`doc-agent/`**

Internal only — not customer-facing.

| File | Purpose |
|---|---|
| `AGENT.md` | Persona + instructions for the doc-agent. Load as a CLAUDE.md in this subfolder. |
| `DESIGN-LOG.md` | The living log. Append entries here as you build. Seeded with two real decisions from this project. |
| `templates/decision-entry.md` | Copy-paste template for a single entry. |

To activate the weekly "listen for new features" scan: follow the `/schedule` instructions in `AGENT.md`.
