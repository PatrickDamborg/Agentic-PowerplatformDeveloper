# /diagram — Create a diagram using Excalidraw

General-purpose diagram command. Picks the best diagram type for what you describe and creates it via the Excalidraw MCP.

Usage: `/diagram` (prompts for description) or `/diagram <description>` (uses the appended text directly).

---

## Step 1 — Discover the Excalidraw MCP tool surface

Call the Excalidraw MCP discovery endpoint to list available tools. Do not assume tool names — they change. Show the user a one-line summary of available tools before continuing.

If the MCP is not connected, tell the user: "The Excalidraw MCP is not connected. Run `/mcp` to authenticate, then retry."

---

## Step 2 — Get the description

If the user appended text after `/diagram`, use that as the description. Otherwise ask:

> "What should I diagram? One sentence describing what you want to visualise."

---

## Step 3 — Select diagram type

Using the description, pick the most appropriate type from `.claude/skills/diagramming/SKILL.md`:
- Multiple actors / handoffs / approvals → **swimlane**
- System components and connections → **architecture**
- Linear steps with decision branches → **process/flowchart**

If unclear, name the type you've chosen and let the user redirect before creating.

---

## Step 4 — Check for Power Platform components

If the diagram will contain any of: Copilot Studio, Power Automate, Dataverse, Teams, M365 Copilot, Power Apps, AI Builder — reference `.claude/skills/diagramming/references/power-platform-icons.md` and use the correct icon for each.

---

## Step 5 — Create the diagram

Use the discovered Excalidraw MCP tools to create the diagram. Apply the naming conventions from `.claude/skills/diagramming/SKILL.md` (exact xPM table names, PoC labels, component names).

---

## Step 6 — Return the result

Report:
1. The Excalidraw link or diagram ID.
2. Suggested filename: `diagrams/<poc-number>-<type>-<short-description>.excalidraw`

Then ask: "Log this in DESIGN-LOG.md? I'll add a Diagram entry with the link and diagram type."
