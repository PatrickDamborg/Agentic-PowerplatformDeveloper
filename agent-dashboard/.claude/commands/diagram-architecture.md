# /diagram-architecture — Create an architecture diagram

Creates an architecture diagram showing system components and their connections. Best for the overall xPM AI demo architecture (agent + skills + flows + Dataverse).

Usage: `/diagram-architecture` (defaults to the full xPM demo architecture) or `/diagram-architecture <scope>` (narrows to a specific component or PoC).

---

## Step 1 — Discover the Excalidraw MCP tool surface

Call the MCP discovery endpoint to list available tools. Do not hardcode tool names.

If the MCP is not connected: "Run `/mcp` to authenticate, then retry."

---

## Step 2 — Get the scope

If the user appended text, use that as the scope. Otherwise use the default:

> Full xPM AI demo architecture: Teams + M365 Copilot → PMO Agent (Claude Sonnet 4.6) → 5 Skills → 4 Agent Flows + Dataverse MCP → Dataverse (pdausa, pum_* tables)

---

## Step 3 — Apply Power Platform icons

**This is mandatory for architecture diagrams.** Reference `.claude/skills/diagramming/references/power-platform-icons.md` and apply the correct icon to every Microsoft component:

| Component in diagram | Icon to use |
|---|---|
| PMO Agent (Copilot Studio) | Microsoft Copilot Studio |
| Agent flows (Power Automate) | Microsoft Power Automate |
| Dataverse / pum_* tables | Microsoft Dataverse |
| AI Builder Prompt node | Microsoft AI Builder |
| Teams channel | Microsoft Teams (M365 icon set) |
| M365 Copilot channel | Microsoft Copilot |
| xPM model-driven app | Microsoft Power Apps |

---

## Step 4 — Create the architecture diagram

Use the discovered Excalidraw MCP tools. Layout guidance:
- Entry points (Teams, M365 Copilot) at the top or left.
- PMO Agent in the centre.
- Skills and Flows branching from the agent.
- Data sources (Dataverse MCP, pum_* tables) at the bottom or right.
- Use arrows to show call direction; label arrows with the action (e.g., "calls", "queries", "returns draft").

---

## Step 5 — Return the result

Report the Excalidraw link and suggested filename: `diagrams/architecture-<scope>.excalidraw`

Ask: "Log this in DESIGN-LOG.md?"
