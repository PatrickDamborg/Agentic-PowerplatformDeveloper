# xPM AI — Portfolio Chart Capability (Copilot Studio code interpreter)

How to give the xPM PMO Assistant **rendered chart images** — ranked bar charts of the initiatives with the most urgent risks, the biggest budget overruns, or the worst schedule slippage — using Copilot Studio's **code interpreter**.

> This is a build spec for the colleague doing the Copilot Studio build, in the style of `COLLEAGUE-WORK-PACKAGE.md`. It adds an optional visual layer to **PoC 01 (Ask Your Portfolio)** / the `portfolio-summary` skill. It is not one of the six core PoCs.

---

## 1. Read this first — three honest caveats

The capability is real and GA, but it does **not** work the way "skills can run Python" suggests. Know these before you commit demo time:

1. **It is not the SKILL.md `scripts/` folder.** Copilot Studio does not execute a `.py` you bundle in a skill. The Python path is the **code interpreter** capability, surfaced through a **prompt → agent flow → Adaptive Card**. (The `scripts/` mechanism only runs in the Claude Code demo agent, a different runtime.)
2. **The chart engine is GPT‑4.1 / GPT‑4o, not Claude.** Code interpreter runs on its own model regardless of the agent's model. It also bills as **premium generative AI** (Copilot Credits) — fine for a demo, but it's not zero-rated the way licensed conversational turns are.
3. **Teams rendering needs validating.** Microsoft's code-interpreter FAQ states images "are not rendered in the Teams and Microsoft 365 Copilot channel" *directly*. The supported workaround is to return the chart as base64 and render it in an **Adaptive Card `Image` element with a `data:` URI** (the pattern below). Teams caps a **bot-message card at ~100 KB**, so the encoded PNG must stay small. **Test this in the actual Teams channel before relying on it live**; §6 gives the hosted-URL fallback if a chart is too big.

A line chart, by the way, is the wrong shape for "most urgent risks" or "biggest overruns" — those are rankings **across** initiatives, so they are **horizontal bar charts**. Keep a line chart for a trend over time (e.g. portfolio KPI across the last N reporting periods).

---

## 2. Architecture

```
User: "chart the initiatives with the most urgent risks"
        │  (portfolio-summary skill soft-points at this tool)
        ▼
[ Agent flow tool: "Portfolio Risk Chart" ]
   ├─ Run a prompt  ── code-interpreter prompt, grounded on pum_risk + pum_initiative
   │                     → Insights (text)  +  Base64 image
   └─ Respond to the agent
         outputs:  Summary = Insights,  GraphBase64 = Base64 image
        ▼
[ Completion → Send an adaptive card (Power Fx formula) ]
   Image url = "data:image/png;base64," & Topic.Output.GraphBase64
   + TextBlock = Topic.Output.Summary
        ▼
   Card renders in Teams  (validate size ≤ ~100 KB — §6)
```

Three things to build, in order: **(A)** the code-interpreter prompt, **(B)** the agent-flow tool that wraps it, **(C)** the Adaptive Card on the flow's completion. Then point the skill at it.

---

## 3. Build A — the code-interpreter prompt (flagship: Risk Exposure)

In Copilot Studio: **Tools → + New tool → Prompt** (or Prompt builder), name it `Portfolio Risk Chart prompt`, and **turn on Code interpreter** in the prompt's settings.

**Ground it on Dataverse** (`/` → Knowledge → Dataverse):
- **`pum_risk`** — fields: risk name, the initiative lookup, the probability field, the impact field, `statecode`. **Filter** `statecode = 0` (open risks only).
- **`pum_initiative`** — fields: initiative name.

> Verify the real column names with `describe` at build — the risk→initiative lookup and the probability/impact fields are environment-specific. Do not hardcode. (Same discovery-first rule as the rest of the build.)

**Prompt instructions** (paste into the prompt body):

```copilot
1. You are given, from Dataverse:
   - Open risks (pum_risk): risk name, the linked initiative, a probability score,
     and an impact score. Only active risks are in scope (statecode = 0).
   - Initiatives (pum_initiative): initiative name.

2. Your tasks:
   - Join each risk to its initiative. For each initiative, compute a risk-exposure
     score = the sum over its open risks of (probability × impact). Treat probability
     and impact as numeric 1–5 scores; if they arrive as option-set labels, map
     Low/Medium/High/Critical to 1/2/3/4 before multiplying.
   - Rank initiatives by exposure descending and keep the top 8.
   - Plot a HORIZONTAL bar chart, highest exposure at the top, one bar per initiative,
     bar length = exposure score, the score labelled at the end of each bar.
   - Style it to the Context& brand (no red — it is not in the palette): white figure on
     a light-grey "card" (#F1F5F7); dark-blue bars (#043F9C) with the worst (top) bar
     highlighted in brand orange (#FF922D); grey (#3D424B) value labels and axis text;
     light-grey (#C9D6DE) x-gridlines; left-aligned title; a clean sans-serif font
     (prefer "Aktiv Grotesk", fall back to Segoe UI / Arial / DejaVu Sans). Title:
     "Initiatives by risk exposure — open risks (probability × impact)".
     Keep the figure no wider than 800 px and use a tight layout so the encoded image
     stays small.

3. Return:
   - The chart as a base64-encoded PNG image.
   - A 2–3 sentence insight summary naming the top initiative and its exposure, and the
     single most urgent open risk (risk name + initiative). Do not invent data; if there
     are no open risks in scope, say so plainly instead of drawing an empty chart.
```

**Test** the prompt (it reads live Dataverse). Under **Model response → Output**, confirm you get both the base64 image and the insight text. **Save**.

> **Style reference:** the bundled-Python charts now live inside the merged `portfolio-summary` skill — `deliverables/skills/portfolio-summary/scripts/portfolio_charts.py` is the canonical, verified-rendering implementation of this exact Context& look (matplotlib rcParams, colours, spines, label styling). Copy its `_apply_brand_style()` / `_style_axes()` / `_bar_colors()` approach into the code-interpreter prompt so the flow-path charts are pixel-consistent with the bundled-Python ones.

---

## 4. Build B — the agent-flow tool that wraps the prompt

**Tools → + New tool → Agent flow** (trigger is *When an agent calls the flow*):

1. **Insert → Run a prompt** → select `Portfolio Risk Chart prompt`.
2. **Insert → Respond to the agent**, then **Add an output** twice:
   - `Summary` (Text) → dynamic value = the prompt's **Insights** output.
   - `GraphBase64` (Text) → expression = the prompt's **Base64 image** output.
3. **Save draft**, name the flow **`Portfolio Risk Chart`** on the Overview tab.

---

## 5. Build C — render the card on completion

On the flow's **Tools** entry → **Completion → After running → Send an adaptive card (specify below)** → **Adaptive card to display using a Power Fx formula → Formula**, paste:

```powerfx
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.5",
  "body": [
    {
      "type": "TextBlock",
      "text": "Risk exposure by initiative",
      "weight": "Bolder",
      "size": "Medium",
      "wrap": true
    },
    {
      "type": "Image",
      "url": "data:image/png;base64," & Topic.Output.GraphBase64,
      "altText": "Bar chart: risk exposure by initiative",
      "msTeams": { "allowExpand": true }
    },
    {
      "type": "TextBlock",
      "text": Topic.Output.Summary,
      "wrap": true
    }
  ]
}
```

`allowExpand` gives the PM a click-to-zoom (Stageview) on the chart. `Topic.Output.GraphBase64` / `Topic.Output.Summary` are the two flow outputs from Build B — rename to match if you named them differently. **Save and publish.**

---

## 6. Teams validation and the size fallback

1. **Validate in Teams, not just the test canvas.** The test canvas renders data URIs reliably; the Teams channel is the real test. Run the prompt against the demo data and confirm the card image appears in the Teams chat.
2. **Keep the PNG small.** The whole card must stay under the **~100 KB** bot-message limit. The prompt already constrains width to 800 px and tight layout; if the card fails to render, the base64 is almost certainly too big.
3. **Fallback — host the image by URL.** If the chart is too large for a data URI, have the flow write the PNG to a hosted location (SharePoint document library, a Dataverse file column, or blob with a tokenised URL) and set the Adaptive Card `Image.url` to that **https URL** instead of the `data:` URI. No size limit applies to a referenced URL. This is more build, so only do it if the data-URI path fails validation.

---

## 7. Clone the pattern for the other two charts

Same three-build pattern; only the **grounding** and the **prompt maths** change. Build these as separate prompt+flow tools so each has a clean description for the orchestrator to route on. **Apply the same Context& styling** as the risk chart above (white card on #F1F5F7, dark-blue #043F9C bars, worst bar in #FF922D, grey #3D424B labels, #C9D6DE gridlines, left-aligned title) so all three look identical.

| Tool | Ground on | Prompt computes (top 8, horizontal bars) |
|---|---|---|
| **`Portfolio Budget Chart`** | `pum_pf_costplan_versions`, `pum_pf_powerfinancialsdatas`, `pum_initiative` | Overrun per initiative = (committed/actual − planned) ÷ planned, as a %. Rank by overrun desc; show only initiatives over plan. Bars in #043F9C with the worst in #FF922D (no red). Title "Initiatives by budget overrun (% over plan)". |
| **`Portfolio Schedule Chart`** | `pum_gantttask`, `pum_initiative` | Per initiative: count of overdue tasks (finish < today, % complete < 100) and worst days-late. Bar length = overdue count; label the worst days-late. Rank by overdue count desc; bars in #043F9C with the worst in #FF922D. Title "Initiatives by schedule slippage (overdue tasks)". |

Remember `pum_gantttask` can link to Initiative, **Program, or Portfolio** — ground and join on all three relevant lookups, or you'll miss portfolio-level tasks (the same gap that left Schedule empty in the first portfolio-summary test).

---

## 8. How the agent picks the chart

This flow-tool route is an alternative to the bundled-Python charts that now ship inside the merged `portfolio-summary` skill (see its Step 4). Use the flow tools only if you specifically want the Dataverse-grounded prompt → Adaptive Card path; otherwise the bundled-Python skill already renders the same charts. The orchestrator selects a matching flow tool from its name + description when the user asks to "chart / graph / plot / visualise" risk, budget, or schedule. No hand-scripted routing — give each flow tool a specific description ("Render a ranked bar chart of initiatives by open-risk exposure", etc.) so they don't shadow each other.

The chart is an **add-on to**, not a replacement for, the text+table summary: lead with the grounded summary and Sources (which work in every channel), then offer/append the chart. If the chart tool fails or the image won't render, the conversation still stands on the text answer.

---

## 9. Acceptance criteria

1. Asking the published agent to "chart the initiatives with the most urgent risks" returns an Adaptive Card with a horizontal bar chart, ranked descending, plus a 2–3 sentence insight naming the top initiative and the single most urgent risk — both verifiable against `pum_risk` / `pum_initiative`.
2. The chart renders in the **Teams** channel (not only the test canvas), or the hosted-URL fallback (§6) is in place.
3. The insight text invents nothing; with no open risks in scope, the agent says so and draws no empty chart.
4. The budget and schedule clone tools each return a correctly ranked chart from live data.
5. No data is written at any point — these tools are read-only.

---

## Sources (Microsoft Learn / Teams platform, verified June 2026)
1. Add the code interpreter capability (Python sandbox, charts, downloadable files): learn.microsoft.com/microsoft-365/copilot/extensibility/code-interpreter
2. Use code interpreter in prompts — **Scenario 2: visual summary of Dataverse tables** (the prompt → agent flow → Adaptive Card pattern and the Power Fx formula): learn.microsoft.com/microsoft-copilot-studio/code-interpreter-prompts-examples
3. FAQ for code interpreter (GPT‑4.1, premium billing, "images not rendered in Teams/M365 Copilot channel" limitation): learn.microsoft.com/microsoft-copilot-studio/faq-code-interpreter
4. Code interpreter on structured data / SharePoint sources, GA Nov 2025: learn.microsoft.com/power-platform/release-plan/2025wave2/microsoft-copilot-studio/use-code-interpreter-customer-uploaded-files-agent-conversations
5. Format cards in Teams (message size limits: 28 KB Incoming Webhook / 100 KB bot; Stageview `allowExpand`): learn.microsoft.com/microsoftteams/platform/task-modules-and-cards/cards/cards-format
