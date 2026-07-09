# /diagram-process — Create a process / flowchart diagram

Creates a linear process diagram with decision branches. Best for documenting what happens inside a single agent flow, a Power Automate flow, or a multi-step query sequence.

Usage: `/diagram-process` (prompts for process) or `/diagram-process <process name>` (uses appended text directly).

---

## Step 1 — Discover the Excalidraw MCP tool surface

Call the MCP discovery endpoint to list available tools. Do not hardcode tool names.

If the MCP is not connected: "Run `/mcp` to authenticate, then retry."

---

## Step 2 — Get the process

If the user appended text, use that. Otherwise ask:

> "Which process or flow? (e.g., 'Status Report Drafter agent flow — internal steps', 'Idea Intake duplicate check branch')"

---

## Step 3 — Identify steps and decision points

Look up the relevant procedure from the appropriate SKILL.md under `.claude/skills/` or from the build package at `deliverables/COLLEAGUE-WORK-PACKAGE.md`.

Standard flowchart shapes:
- Rectangle → action step
- Diamond → decision point (yes/no branch)
- Rounded rectangle → start / end
- Parallelogram → input / output (data in or out)

---

## Step 4 — Check for Power Platform components

If any step represents a Power Platform action (Prompt node, Dataverse connector action, Teams post), reference `.claude/skills/diagramming/references/power-platform-icons.md` and add the relevant icon next to that step's label.

---

## Step 5 — Create the flowchart

Use the discovered Excalidraw MCP tools. Flow direction: top to bottom. Label every decision diamond with a question (e.g., "User confirmed?"). Label every branch (Yes / No). Label every output step with the data returned (e.g., "Returns: {rag, narrative, milestoneSummary}").

---

## Step 6 — Return the result

Report the Excalidraw link and suggested filename: `diagrams/<poc-number>-process-<short-name>.excalidraw`

Ask: "Log this in DESIGN-LOG.md?"
