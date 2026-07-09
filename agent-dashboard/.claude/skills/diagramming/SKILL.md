---
name: diagramming
description: 'Create diagrams using the Excalidraw MCP. Use when asked to diagram, visualise, draw, sketch, create a swimlane, flowchart, architecture diagram, or process flow — especially for xPM use cases, Copilot Studio agent architecture, Power Automate flows, and Dataverse data models. Always references the Power Platform icon library for Microsoft components.'
---

# Diagramming Skill

Creates diagrams via the Excalidraw MCP. Always consult `references/diagram-type-guide.md` to pick the right diagram type, and `references/power-platform-icons.md` for any Microsoft Power Platform component.

---

## Hard rules

1. **Discover the Excalidraw MCP tool surface at runtime.** Do not hardcode tool names. Call the MCP discovery endpoint (or equivalent list-tools call) at the start of every diagram session. The tool surface may have changed. Show the user which tools are available before proceeding.
2. **Use official Power Platform icons** for any Microsoft component. See `references/power-platform-icons.md`. The official SVG pack is at `https://download.microsoft.com/download/498606aa-6d27-4f13-aa5c-1401078c153b/Power-Platform-icons-scalable.zip` (updated December 2025).
3. **Label every component** with its exact name as used in the project — xPM table names (`pum_Initiative`, `pum_StatusReporting`), flow names, skill names, PoC labels.
4. **After creating a diagram,** report the Excalidraw link/ID and ask: "Log this diagram in DESIGN-LOG.md? (yes/no)"

---

## Diagram type selection

| Request contains… | Use this type | Command shortcut |
|---|---|---|
| flow between multiple people/systems, approval loop, handoff | Swimlane | `/diagram-swimlane` |
| system components, what connects to what, "architecture" | Architecture | `/diagram-architecture` |
| step-by-step sequence, decision point, "if/then" | Process/flowchart | `/diagram-process` |
| anything else | Ask the user to confirm type | `/diagram` |

Full guidance in `references/diagram-type-guide.md`.

---

## Project naming conventions

Use these names exactly — they appear in the build package and SKILL.md files.

**Actors / components:**
- `PM` (project manager — the human user)
- `PMO Agent` (the single Copilot Studio agent)
- `Status Report Drafter skill` / `Ask Your Portfolio skill` / etc.
- `Status Report Drafter flow` / `Idea Intake flow` / `Portfolio Watchdog flow`
- `Dataverse MCP`
- `pum_Initiative` / `pum_StatusReporting` / `pum_Risk` / `pum_GanttTask` / `pum_Idea` / `pum_Propose` / `pum_Commit`

**PoC labels (use consistently):**
- PoC 01 — Ask Your Portfolio
- PoC 02 — Status Report Drafter
- PoC 03 — Idea Intake and Qualification
- PoC 04 — Resource and Capacity Assistant
- PoC 05 — Portfolio Watchdog

---

## Output format

After a diagram is created, always provide:
1. The Excalidraw link or diagram ID.
2. A suggested reference filename: `diagrams/<poc-number>-<diagram-type>-<short-description>.excalidraw` (e.g., `diagrams/poc02-swimlane-status-report-flow.excalidraw`).
3. The log prompt: "Log this in DESIGN-LOG.md? I'll add a Diagram entry with the link."
