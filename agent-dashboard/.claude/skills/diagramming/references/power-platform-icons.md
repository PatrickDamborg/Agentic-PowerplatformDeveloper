---
name: power-platform-icons
description: 'Official Microsoft Power Platform icon reference for use in Excalidraw diagrams. Maps each component to its icon name and usage guidance. Icon pack (SVG) last updated December 2025.'
---

# Power Platform Icon Reference

**Official pack (SVG, December 2025):**
`https://download.microsoft.com/download/498606aa-6d27-4f13-aa5c-1401078c153b/Power-Platform-icons-scalable.zip`

**Source page:** `https://learn.microsoft.com/en-us/power-platform/guidance/icons`

**Usage rules (from Microsoft):**
- Always show the product name near the icon in diagrams.
- Do not crop, flip, rotate, or distort icons.
- Do not use icons to represent a non-Microsoft product.

---

## Icon map — components used in the xPM AI demo

| Component | Icon name in pack | Use in diagram when… |
|---|---|---|
| **Microsoft Copilot Studio** | `Microsoft Copilot Studio` | Representing the PMO Agent or any Copilot Studio agent node |
| **Power Automate** | `Microsoft Power Automate` | Representing an agent flow, workflow, or automation step |
| **Dataverse** | `Microsoft Dataverse` | Representing the data layer, table queries, or MCP data source |
| **Microsoft Teams** | Use Microsoft 365 icon set (see below) | Representing the Teams channel where the agent is surfaced |
| **Microsoft 365 Copilot** | `Microsoft Copilot` | Representing the M365 Copilot channel / entry point |
| **Power Apps** | `Microsoft Power Apps` | Representing the xPM model-driven app (if shown) |
| **AI Builder** | `Microsoft AI Builder` | Representing the AI Builder Prompt node in a flow |
| **Microsoft Agent 365** | `Microsoft Agent 365` | Representing a connected or specialist agent (added Dec 2025) |
| **Power Platform** (generic) | `Microsoft Power Platform` | Top-level platform grouping in architecture overviews |

---

## Teams / M365 icons

Teams and M365 Copilot icons are part of the **Microsoft 365** icon set, not the Power Platform pack. Reference:
`https://learn.microsoft.com/en-us/microsoft-365/admin/misc/media-assets`

For diagrams, use the product name label if the exact icon is unavailable rather than substituting an incorrect icon.

---

## Applying icons in Excalidraw

When the Excalidraw MCP supports image/icon elements:
1. Reference the SVG by component name from the downloaded pack.
2. Place the icon at the component node; label with the exact component name directly below.
3. Keep icons at a consistent size within a single diagram (recommended: 40×40px or 48×48px for architecture diagrams; 32×32px for swimlane lane headers).

If the MCP does not support direct image embedding, use a clearly labelled rectangle/shape with the component name and note the intended icon in a comment or caption below the diagram.
