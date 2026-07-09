# /diagram-swimlane — Create a swimlane diagram

Creates a swimlane diagram showing how multiple actors hand off work across a use case or process flow. Best for the 5 xPM PoC end-to-end flows.

Usage: `/diagram-swimlane` (prompts for use case) or `/diagram-swimlane <use case name>` (uses appended text directly).

---

## Step 1 — Discover the Excalidraw MCP tool surface

Call the MCP discovery endpoint to list available tools. Do not hardcode tool names.

If the MCP is not connected: "Run `/mcp` to authenticate, then retry."

---

## Step 2 — Get the use case or process

If the user appended text after `/diagram-swimlane`, use that. Otherwise ask:

> "Which use case or process? (e.g., 'PoC 02 — Status Report Drafter end-to-end', 'Idea Intake approval loop')"

---

## Step 3 — Identify actors and steps

Look up the relevant procedure from `.claude/skills/` (the use-case SKILL.md) or from `deliverables/doc-agent/DESIGN-LOG.md` if a decision entry describes the flow.

Standard actor set for xPM PoC swimlanes:

| Actor | Lane label |
|---|---|
| Project Manager / PMO Director | PM |
| Copilot Studio agent | PMO Agent |
| Power Automate flow | Agent Flow |
| Dataverse / MCP | Dataverse |
| Microsoft Teams | Teams |

Add or remove lanes based on what the specific use case involves.

---

## Step 4 — Apply Power Platform icons to lane headers

For each lane that represents a Power Platform component, reference `.claude/skills/diagramming/references/power-platform-icons.md` and use the correct icon in the lane header alongside the label.

---

## Step 5 — Create the swimlane diagram

Use the discovered Excalidraw MCP tools. Label each step with the action taken (e.g., "Calls GetInitiativeDetails flow", "Returns 5-dimension draft", "Explicit approval in chat"). Mark approval gates and decision points clearly.

---

## Step 6 — Return the result

Report the Excalidraw link and suggested filename: `diagrams/<poc-number>-swimlane-<short-name>.excalidraw`

Ask: "Log this in DESIGN-LOG.md?"
