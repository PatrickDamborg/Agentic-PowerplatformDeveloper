# xPM Demo Recorder

Automated, reproducible demo videos for the xPM / Copilot Studio agents.
Capture a flow once with **Playwright**, regenerate a polished, narrated video
on demand with **[playwright-recast](https://github.com/thepatriczek/playwright-recast)**.

When the agent or UI changes, you don't re-record — you re-run.

## How it works

```
  Playwright (codegen → run with video+trace on)
        │   writes trace.zip + .webm, plus narrate()/highlight()/zoom()/click() markers
        ▼
  playwright-recast  (render.mjs)
        │   speeds up idle time, burns subtitles, adds cursor/zoom/click polish,
        │   optional AI voiceover
        ▼
  demo.mp4
```

## Prerequisites

- Node 18+ (you have 24)
- `ffmpeg` + `ffprobe` on PATH (`brew install ffmpeg` — already installed)

## One-time setup

```bash
cd demo/recorder
npm install
npx playwright install chromium
```

## Workflow

### 1. Capture your login (once per environment, refresh when it expires)

```bash
npm run login
```

A browser opens. Sign in to Power Platform / Copilot Studio with MFA as normal,
then close the window. Your session is saved to `.auth/state.json` (gitignored)
so demos never have to show or script the login.

### 2. Author the flow with codegen

```bash
npm run codegen
```

Click through the real demo path. Playwright generates selectors live — copy the
ones you need into [`demos/xpm-mcp-agent.spec.ts`](demos/xpm-mcp-agent.spec.ts),
keeping the `narrate()` / `highlight()` / `zoom()` / `click()` wrapper lines that
make the video look good. The placeholders in that file are marked `TODO(codegen)`.

### 3. Record + render

```bash
npm run demo            # record, then render → demo.mp4

# or step by step:
npm run record          # drive the UI, capture trace + video
npm run render          # build demo.mp4 from the latest capture
```

### 4. Add AI voiceover (optional)

```bash
OPENAI_API_KEY=sk-... npm run render
```

Narration text comes from the `narrate()` calls in the spec — the same text used
for subtitles becomes the spoken track, re-timed to the real audio length.

## Pointing at a specific agent / environment

```bash
DEMO_AGENT_URL="https://copilotstudio.microsoft.com/.../canvas" npm run demo
DEMO_BASE_URL="https://make.powerapps.com" ...
DEMO_OUTPUT="./xpm-status-demo.mp4" npm run render
```

The default `DEMO_AGENT_URL` already points at the **xPM - MCP Agent**
(`a5d3909a-b17e-49ee-80b2-ea3902e1f70d`) in the `pdausa` environment.

## Files

| File | Purpose |
|------|---------|
| `playwright.config.ts` | Capture config — video on, trace on, fixed viewport, reuses saved login |
| `demos/fixtures.ts` | Wires recast helpers into Playwright |
| `demos/xpm-mcp-agent.spec.ts` | The authored demo flow (template — adapt selectors via codegen) |
| `render.mjs` | Trace → polished mp4 pipeline |
| `narration/` | Optional external `.srt` files if you prefer scripted narration over inline `narrate()` |

## Adding more demos

Drop another `*.spec.ts` in `demos/`, import the helpers from `./fixtures`, and
follow the same narrate/act/highlight rhythm. `render.mjs` always renders the
most recent capture; set `DEMO_OUTPUT` to keep them separate.
