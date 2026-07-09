---
name: diagram-type-guide
description: 'Quick-reference guide for choosing the right diagram type for xPM AI documentation. Maps scenario to diagram type with a concrete xPM example for each.'
---

# Diagram Type Guide

## When to use which type

| Diagram type | Use when… | xPM example |
|---|---|---|
| **Swimlane** | Multiple actors take turns; there are handoffs, approvals, or parallel tracks | PoC 02 — PM asks → PMO Agent drafts → PM approves → flow creates record in Dataverse |
| **Architecture** | You need to show what components exist and how they connect (not time-ordered) | Single-agent architecture: Teams → PMO Agent → Skills → Flows → Dataverse MCP → pum_* tables |
| **Process / flowchart** | Single actor, linear steps, decision branches, loops | The Status Report Drafter flow: receive InitiativeId → query GanttTask → query Risk → Prompt node → return draft |
| **Entity relationship** | Showing Dataverse table relationships and foreign keys | pum_Initiative → pum_StatusReporting, pum_ResourcePlan → pum_Propose/pum_Commit |
| **Sequence** | Time-ordered message exchanges between two or more systems (more precise than swimlane) | Agent calls GetInitiativeDetails flow → flow queries Dataverse → flow returns JSON → agent drafts report |

---

## xPM diagram inventory (planned)

| Diagram | Type | PoC | Status |
|---|---|---|---|
| Single-agent architecture overview | Architecture | All | — |
| PoC 01 — Ask Your Portfolio flow | Swimlane | 01 | — |
| PoC 02 — Status Report Drafter end-to-end | Swimlane | 02 | — |
| PoC 02 — Status Report Drafter flow (internal) | Process | 02 | — |
| PoC 03 — Idea Intake conversation flow | Swimlane | 03 | — |
| PoC 04 — Resource gap query flow | Process | 04 | — |
| PoC 05 — Portfolio Watchdog digest flow | Process | 05 | — |
| xPM data model (resource hierarchy) | Entity relationship | 04 | — |

Update the Status column as diagrams are created and logged in DESIGN-LOG.md.
