# xPM AI — Design Log

This file is the authoritative record of every design decision and configuration choice made while building the xPM AI Copilot Studio demo.

**Rules:**
- Entries are appended in chronological order. Nothing is edited or deleted.
- Each entry follows the standard template (see `templates/decision-entry.md`).
- The doc-agent writes here automatically after meaningful build steps, or on demand.
- `[NEW FEATURE]` entries flag Microsoft/Dataverse platform changes relevant to the build.
- This file is raw source material. A human polishes it into customer-facing documentation separately.

---

## Seeded Example Entries

### 2026-06-10 — Architecture decision — single agent vs orchestrator pattern

**Decision / Configuration**
Chose a **single Copilot Studio agent** using the native **Instructions + Skills** pattern over the orchestrator + connected-agents topology.

- Agent type: single conversational agent
- Feature used: Copilot Studio Skills (agentskills.io standard, same SKILL.md format as Claude Code)
- Model: Claude Sonnet 4.6 (selected via the new inline model picker)
- Narrative generation: Prompt node (GA May 2026)

**Rationale**
The new Copilot Studio Skills feature subsumes the routing function previously performed by a separate orchestrator agent. Because each capability is now packaged as a SKILL.md-compatible skill and invoked directly by the single agent, there is no need for a top-level orchestrator to dispatch to specialist sub-agents. The new inline model picker and Prompt node further reduce the need for separate agents by allowing model selection and freeform LLM calls within a single agent's topics.

**Alternatives Considered**
- **Orchestrator + 3 connected agents (existing repo YAML):** The previous design used a parent orchestrator that routed to three specialist agents (status reporting, risk analysis, schedule variance). Rejected because: (1) the Skills feature makes the routing layer redundant, (2) three connected agents means three sets of topics and triggers to maintain, (3) cross-agent context passing added latency and complexity, (4) the existing YAML would require significant rework to accommodate the new model picker.

**References**
- Copilot Studio: Settings > Skills (left nav)
- agentskills.io standard documentation
- Existing repo: `/agents/` YAML files (superseded)
- Microsoft Learn: "Overview of Copilot Studio agent skills"

**Risks / Watch-outs**
- The Skills feature was in preview as of early 2026 — confirm GA status before demo.
- SKILL.md format alignment between Claude Code and Copilot Studio needs to be verified; any divergence in the spec will require a wrapper.
- If the demo needs to be packaged as a managed solution and deployed to multiple environments, a single-agent topology is simpler to export but skills must be included as solution components — confirm each skill is solution-aware.

---

### 2026-06-10 — Tool choice — Prompt node vs AI Builder custom prompt for status-report narrative

**Decision / Configuration**
Chose the **native Copilot Studio Prompt node** (GA May 2026) over an AI Builder custom prompt (`msdyn_aimodel`) for generating the status-report narrative text.

- Node type: Prompt node (inserted inline in the "Generate Status Report" topic)
- Model: Claude Sonnet 4.6 (selected inline within the node)
- Prompt authored: directly in the node's prompt editor within Copilot Studio

**Rationale**
The Prompt node requires no separate authoring portal, no additional connection reference (`shared_cdsai`), and allows the model to be selected and swapped inline without leaving the agent canvas. It reached GA in May 2026, making it a supported choice for a production demo. AI Builder custom prompts require authoring in the AI Builder portal, creating a separate `msdyn_aimodel` record, and managing a `shared_cdsai` connection reference in the solution — all of which increase setup friction and solution packaging complexity for a demo context.

**Alternatives Considered**
- **AI Builder custom prompt (`msdyn_aimodel`):** Would be the preferred choice if the prompt needs to be packaged as a reusable, independently versioned solution component that can be imported across multiple environments without the agent. In this demo, the prompt is specific to the agent and does not need to be shared, so the overhead is not justified. Remains an option if requirements change (e.g. the same prompt is needed in a Power Automate flow outside the agent).

**References**
- Copilot Studio canvas: Topic "Generate Status Report" > Add node > Prompt
- Microsoft Learn: "Use the Prompt node in Copilot Studio" (May 2026 release notes)
- AI Builder portal: make.powerapps.com > AI Builder > Models

**Risks / Watch-outs**
- Prompt node prompts are stored inside the agent solution component — they are not independently versionable. If prompt iteration becomes heavy, consider migrating to an AI Builder custom prompt for better change tracking.
- Model availability inside the Prompt node depends on the environment's AI capacity allocation — confirm Claude Sonnet 4.6 is available in the target demo environment before the demo day.

---

## Entries

New entries appended below by the doc-agent.

### 2026-06-26 — Diagram — Orchestrator Agent & Skills architecture

**Decision / Configuration**
Created the full-stack architecture diagram for the `xPM PMO Assistant` orchestrator and its skills (Excalidraw).

- Type: Architecture diagram (layered, top-to-bottom), built via the Excalidraw MCP per the `diagramming` skill / `/diagram-architecture` command.
- Scene name: `xPM — Orchestrator Agent & Skills (Architecture)`
- Scene ID: `74PwxJSBj9F`
- Link: https://app.excalidraw.com/s/5x8Gj4Muy2G/74PwxJSBj9F
- Reference filename: `diagrams/architecture-orchestrator-and-skills.excalidraw`
- Layers shown: Channels (Teams · M365 Copilot · xPM app) → Orchestrator (Copilot Studio · Claude Sonnet 4.6, two-move resolve→route logic + guardrails strip) → 6 Skills (`portfolio-summary`, `status-report-drafter`, `idea-intake`, `resource-capacity`, `information-gatherer`, `dataverse-mcp`) → MCP tools (Dataverse MCP Server `pdausa` · Work IQ MCP) → Data (`pum_*` tables · M365 sources).
- Write-skills (`status-report-drafter` → `pum_StatusReporting`, `idea-intake` → `pum_Idea`) flagged amber + approval-gated. Read-only blue, MCP teal, data/reference grey. Colour legend included.
- Autonomous workflows (`portfolio-watchdog` PoC 05, `business-case-approval` PoC 06) shown in a dashed, greyed side panel as out-of-scope for the conversational orchestrator.

**Rationale**
The single-agent (skills-in-one-agent) topology was previously described only in prose across `COPILOT-STUDIO-INSTRUCTIONS.md` and the `skills/*/SKILL.md` files. A single visual centred on the orchestrator and the skills it routes to supports the colleague work package and the customer story. Labels match the project names verbatim (skill folder names, `pum_*` tables, MCP tool names).

**Alternatives Considered**
- **Focused agent+skills-only diagram:** Rejected — user chose the full-stack scope (channels → agent → skills → MCP → data) for context.
- **Omit autonomous workflows:** Rejected — user chose to include them, greyed and dashed, to show the complete capability set without implying they sit in the conversational loop.

**References**
- Source of truth: `deliverables/COPILOT-STUDIO-INSTRUCTIONS.md` §1 (skill table) and §3 (base block); `deliverables/skills/*/SKILL.md`
- Skill/commands: `.claude/skills/diagramming/`, `.claude/commands/diagram-architecture.md`
- Icon reference: `.claude/skills/diagramming/references/power-platform-icons.md`
- Excalidraw scene ID `74PwxJSBj9F` (workspace `5x8Gj4Muy2G`)

**Risks / Watch-outs**
- Not yet visually verified: the Excalidraw MCP `take_screenshot` tool returned a server-side output-validation error and the Chrome extension was not connected at creation time. Element placement is confirmed from the API response, but arrow routing (straight fan-in to the MCP layer) and any label overflow should be eyeballed in Excalidraw and adjusted if needed.
- Icons are labelled colour-coded shapes, not official Power Platform SVG icons — this MCP does not support image embedding. If the diagram becomes external-facing, re-create the component nodes with the official icon pack per the icon reference.

---

### 2026-06-29 — Capability decision — rendered portfolio charts via Copilot Studio code interpreter

**Decision / Configuration**
Added an optional visual layer to `portfolio-summary` / PoC 01: ranked **bar charts** (initiatives by open-risk exposure, budget overrun, schedule slippage) rendered as images. Path chosen: **code-interpreter prompt (grounded on Dataverse) → agent flow (Run a prompt → Respond) → Adaptive Card with a `data:` URI Image**, per Microsoft Learn scenario 2. Build spec written to `deliverables/CHART-CAPABILITY.md`; `portfolio-summary/SKILL.md` soft-points at the chart tools.

- Chart type corrected from the user's initial "line chart" to **horizontal bar** — the asks ("most urgent risks", "biggest overruns") are rankings across initiatives, not trends over time.
- Charts are an **add-on**: the text+table summary + Sources always leads (renders in every channel); the chart is appended and never blocks the answer.

**Rationale**
The user asked for charts on the premise that "skills can execute Python". True in the Claude Code demo harness (`scripts/` + Bash), but **not** how Copilot Studio works — there the Python path is the code-interpreter capability, invoked via a prompt/flow, not a bundled script. The code-interpreter route is the supported, sellable Copilot Studio mechanism and produces deterministic computation + a real chart image.

**Alternatives Considered**
- **Markdown/unicode bar charts in the skill text:** rejected by the user in favour of a real rendered image; remains the zero-infra, every-channel fallback if the image path proves fragile.
- **Real matplotlib chart in the Claude Code demo agent (`scripts/`):** works in that harness but not in the Copilot Studio Teams build, which is the actual deliverable target.

**References**
- Build spec: `deliverables/CHART-CAPABILITY.md`
- Microsoft Learn: code interpreter prompts examples (scenario 2 — Dataverse visual summary, Power Fx Adaptive Card formula); FAQ for code interpreter (GPT‑4.1, premium billing, Teams image-render limitation)
- Teams platform: Format cards in Teams (28 KB Incoming Webhook / 100 KB bot-message size limits)

**Risks / Watch-outs**
- **Teams rendering is unverified.** Microsoft's FAQ says code-interpreter images don't render directly in the Teams/M365 Copilot channel; the `data:`-URI Adaptive Card is the workaround but the whole card must stay under ~100 KB (bot message). Validate in the real Teams channel before the demo; fallback is to host the PNG and reference it by https URL (CHART-CAPABILITY.md §6).
- **Not Claude, not zero-rated.** Code interpreter runs on GPT‑4.1/GPT‑4o and bills as premium generative AI — a caveat for both the "all-Claude" narrative and the credit-cost model in `CREDIT-COST-AND-VIABILITY.md`.
- **`pum_gantttask` linkage:** the schedule chart must join Initiative, Program, AND Portfolio lookups, or it repeats the empty-Schedule gap seen in the first `portfolio-summary` test.

---

### 2026-06-29 — Skill build — portfolio-charts: bundled-Python skill, Context&-branded charts

**Decision / Configuration**
Built `portfolio-charts` as a **bundled-Python skill** (zip: `SKILL.md` + `scripts/portfolio_charts.py`), following the "new agent setup" proven by Microsoft's `hello-python-script` example: the SKILL.md instructs the agent to **read `scripts/portfolio_charts.py` and execute it** in code interpreter. Two ranked horizontal bar charts — initiatives by open "4. High" risks, and by budget overrun (% over plan). Deliverable: `deliverables/portfolio-charts.zip`.

- **Data flow:** the code-interpreter sandbox has no network, so the script can't call the Dataverse MCP. The SKILL.md has the agent query Dataverse (MCP), inject the rows into the script's `HIGH_RISK_DATA` / `OVERRUN_DATA` lists, then execute. Field names (the "4. High" option value, cost-plan columns) are discovered with `describe` at runtime, never hardcoded.
- **Style:** Context& brand (per `.claude/skills/context-brand/SKILL.md`) — white card on `#F1F5F7`, dark-blue bars `#043F9C` with the **worst bar highlighted in brand orange `#FF922D`**, grey `#3D424B` labels, light `#C9D6DE` gridlines, Aktiv Grotesk with graceful fallback. Verified rendering; ~37–40 KB per PNG (well under the ~100 KB Teams card limit).

**Rationale**
The user confirmed the agent should follow the new bundled-Python skill setup and that charts must use the Context& brand, not Microsoft Fluent. Brand has **no red**, so RAG-style severity colouring was replaced with a monochrome dark-blue + orange-highlight-the-worst pattern — modern, legible, and on-brand.

**Alternatives Considered**
- **Microsoft Fluent 2 styling:** rejected by the user in favour of Context& brand (these charts can appear in external-facing material).
- **Code-interpreter prompt + agent flow + Adaptive Card** (per `CHART-CAPABILITY.md`): still valid for the Dataverse-grounded flow path, but the bundled-Python skill is simpler to import and test and is what the user adopted.

**References**
- `deliverables/skills/portfolio-charts/SKILL.md` + `scripts/portfolio_charts.py`; packaged `deliverables/portfolio-charts.zip`
- Brand source: `.claude/skills/context-brand/SKILL.md`
- New-setup template: Microsoft `hello-python-script` example skill

**Risks / Watch-outs**
- **Empty against current pdausa data:** 0 High risks and no cost actuals today, so the live charts will correctly skip until that data exists. Use the sample-data smoke test (*"Run the portfolio charts script with its sample data"*) to confirm rendering.
- **Font:** Aktiv Grotesk is licensed and absent from the sandbox; charts fall back to a clean sans (DejaVu Sans). Not pixel-identical to brand type, but close. Don't bundle the font (licensing).
- **Teams image rendering** still carries the code-interpreter caveat — validate in the Teams channel; the PNGs are small enough for the card limit.

---

### 2026-06-29 — Skill consolidation — charts merged into portfolio-summary (one bundled-Python skill)

**Decision / Configuration**
Merged the charting capability into `portfolio-summary` so a portfolio summary **appends the charts relevant to that portfolio**. `portfolio-summary` is now a bundled-Python skill packaged as `deliverables/portfolio-summary.zip` (`SKILL.md` + `scripts/portfolio_charts.py`).

- **Chart set:** High-(4) risks, budget overrun, and a **phase-composition fallback** (no schedule chart — user's choice). "Relevant" = the script renders a chart only when its injected data is non-empty; the phase chart renders only when neither risk nor overrun qualifies, guaranteeing at least one visual.
- **Flow:** the skill's Step 4 reuses the summary's MCP queries, gathers the per-initiative chart arrays, injects them into the script, executes it, and appends the rendered PNGs after the text summary. Charts only when scope has ≥2 initiatives (a one-bar ranking is meaningless for a single initiative).
- **Retired:** the standalone `portfolio-charts` skill/folder, `portfolio-charts.zip`, and `portfolio-summary/SKILL-v2.md` — one skill, no routing overlap.
- Verified: normal run renders risk + overrun; with both empty the phase fallback renders; all PNGs < 40 KB.

**Rationale**
The user wanted the summarisation itself to contain the portfolio's relevant charts, not a separate "make me a chart" request. One bundled-Python skill is the simplest thing to import and avoids two skills shadowing each other on chart-style prompts.

**Alternatives Considered**
- **Keep `portfolio-charts` standalone alongside the merged summary:** rejected by the user (chose "one merged skill, retire the rest").
- **Include a schedule-slippage chart:** dropped by the user from the chart set.

**References**
- `deliverables/skills/portfolio-summary/SKILL.md` (Step 4) + `scripts/portfolio_charts.py` (`chart_high_risks` / `chart_overruns` / `chart_phase_composition`); packaged `deliverables/portfolio-summary.zip`
- Brand source: `.claude/skills/context-brand/SKILL.md`; style reference now cited from this skill in `CHART-CAPABILITY.md`

**Risks / Watch-outs**
- Same data gap as before: against current pdausa data the risk/overrun charts are empty, so a real summary would show the **phase-composition fallback** until risk/cost data is seeded.
- Every portfolio/program summary now triggers code interpreter (GPT‑4.1, premium credits, added latency) to draw the charts — acceptable for the demo; note it if cost/perf matters at scale.
- Budget-overrun "actual" cost field in xPM is environment-specific — discover it with `describe` at build; if actuals aren't tracked, the overrun chart stays empty and the fallback covers it.
