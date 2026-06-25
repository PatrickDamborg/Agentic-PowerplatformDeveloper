---
name: miro-design
description: Create Miro diagrams in Patrick's established visual style. Load when asked to draw, diagram, visualize, sketch, or map any system architecture, workflow, or data flow on Miro.
user_invocable: true
---

# Miro Design Skill

Derived from live analysis of the **pda-Cowork** board (frames: NGI proposed layout, NGI Option A, NGI Option B, Frame 1). Use this style for all new diagrams unless the user explicitly asks for a different approach.

## Board

**pda-Cowork**: https://miro.com/app/board/uXjVHbNxD_s=/

Always add new frames to this board unless the user specifies otherwise.

---

## Visual Grammar

### Layout template — always 3 horizontal layers

```
┌─────────────────────────────────────────────────────────────┐
│  [Service A]        [Service B]       [Service C]           │  ← Layer 1: context labels (infrastructure)
│- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - │  ← dashed separator line
│                                                             │
│  [Step 1] ──────▶ [Step 2] ──────▶ [Step 3] ──────▶ [End]  │  ← Layer 2: process pipeline (main flow)
│                       │                                     │
│               ┌───────┘                                     │
│  - - - - - - -│- - - - - - - - - - - - - - - - - - - - - - │
│         [Dataverse / Storage]                               │  ← Layer 3: data persistence
└─────────────────────────────────────────────────────────────┘
```

- Flow direction: **always left-to-right**
- Layer 1 contains service/platform name labels only (no process logic)
- Layer 2 is the primary process pipeline — sequential steps with labeled arrows
- Layer 3 is data storage and quality metrics (Dataverse, confidence scores, logs)
- Vertical connections drop from Layer 2 into Layer 3 (e.g., "Store confidence score")

### Boxes / nodes

| Type | Shape | Border | Fill | Use for |
|------|-------|--------|------|---------|
| Process step | Rectangle | Solid, thin | White/none | Individual actions: "Extract Data", "Generate XML" |
| Entry point | Rectangle | Solid | **Yellow** | Input sources: shared mailbox, email trigger |
| Success destination | Rectangle | Solid | **Green** | Final output systems: "Auto release order", "Business Central" |
| Logical group / container | Rectangle | **Dashed** | None/transparent | AI execution envs, cloud platforms: "Copilot Studio", "AI Builder" |
| Infrastructure label | Text only | None | None | Service names in Layer 1 |

### Arrows

| Pattern | When to use |
|---------|-------------|
| `──────▶` solid, unidirectional | Standard flow between sequential steps |
| `◀──────▶` bidirectional | Feedback loops / two-way data exchange in early stages |
| Labeled arrow | When the data type matters: write the label above/below the arrow mid-point |

**Common arrow labels:** `Structured data` · `XML file` · `Call LLM` · `Validate XML` · `Input to` · `Attachment`

### Confidence scores

Every diagram that involves AI extraction tracks confidence. Always add:
- A branch arrow from the extraction/generation step → "Store confidence score" → Dataverse (Layer 3)
- The Dataverse entity should show the confidence field: e.g., `SalesOrderLine (name, confidence score)`

---

## Naming Conventions

### Frame names
`<Project> <variant>` — e.g., `NGI Option A`, `NGI option B`, `NGI proposed layout`
- One "proposed layout" frame = the recommended/final version
- Lettered options = alternatives under consideration

### Step labels
Short, action-verb phrases in title case:
- `Trigger Flow` · `Retrieve Attachment` · `Extract Data` · `Generate XML` · `Store File` · `Handoff`
- AI component labels include the model/service: `Extract Data (AI Builder)` · `Claude Analyzer`

### Container labels
Platform name only, no verbs: `Power Automate` · `Copilot Studio` · `AI Builder` · `Code Interpreter`

### Dataverse entity labels
`EntityName (field1, field2, confidence score)` — always show confidence if present.

---

## How to Create a Diagram

### Step 1 — Frame

Create a new frame on the pda-Cowork board. Set title to `<Project> <variant>`. Recommended frame size: 2400 × 900 px.

```
mcp__claude_ai_Miro__diagram_create  (or layout_create for complex multi-frame)
```

### Step 2 — Lay out Layer 1 (context labels)

Place plain text labels at y ≈ top-quarter of the frame, spaced evenly left-to-right. These are the service names that act as "swim lane" headers. No boxes — text only.

Then draw a **dashed horizontal line** spanning the full frame width immediately below the labels.

### Step 3 — Build the pipeline (Layer 2)

Place rectangular nodes evenly spaced left-to-right in the vertical center of the frame:
- Entry point → yellow fill
- Process steps → white, solid border
- Success/output → green fill
- Dashed-border containers wrap related steps (e.g., all AI steps inside one dashed box)

Connect with arrows. Label arrows where the data type is non-obvious.

### Step 4 — Data layer (Layer 3)

Draw a second dashed separator line near the bottom third. Place Dataverse/storage nodes below it. Drop vertical arrows from relevant Layer 2 steps to these nodes.

Include a `Flow Log (sales_order, session_id, error, success)` entity in any diagram that involves automation flows.

### Step 5 — Review checklist

- [ ] Entry point is yellow
- [ ] Final destination(s) are green
- [ ] At least one dashed container wraps AI/cloud services
- [ ] Bidirectional arrows used where there is a feedback loop
- [ ] Confidence score tracked (if AI extraction involved)
- [ ] Arrow labels present on any arrow whose payload is not obvious
- [ ] Frame named `<Project> <variant>`

---

## Miro MCP Tools

| Task | Tool |
|------|------|
| Find / open board | `board_search_boards` (query: "pda-Cowork") |
| See what's on the board | `context_explore` |
| Read a frame's content | `context_get` with `?moveToWidget=<frame_id>` |
| Create a diagram | `diagram_create` |
| Read diagram DSL | `diagram_get_dsl` |
| Create a layout | `layout_create` |
| Read layout DSL | `layout_get_dsl` |
| List raw items | `board_list_items` |

Always call `context_explore` before creating anything — check for an existing frame with the same name first.

---

## Gotchas

- **Dashed containers ≠ swim lanes.** They are execution environment markers (e.g., "everything inside this dashed box runs in AI Builder"). Don't turn them into hard swim lane rows.
- **Bidirectional arrows only at early stages.** Downstream steps (store, handoff) are always one-way.
- **Layer 1 labels are not boxes.** They're plain text, no border. Using boxes there creates visual noise.
- **Frame 1 on the board is a generic scratchpad** (title "Frame 1") — don't use it as a style reference; it's a data-model/entity diagram, not a workflow diagram.
