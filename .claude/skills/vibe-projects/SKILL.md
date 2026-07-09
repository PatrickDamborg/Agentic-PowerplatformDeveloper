---
name: vibe-projects
description: Spawn a new web resource / frontend project from the context-and/vibe-template GitHub template. Load whenever the user wants to start a new Dataverse web resource, dashboard, or other browser-based frontend — never hand-roll one from scratch.
---

# vibe-projects

New web resource / frontend projects in this org are spawned from the `context-and/vibe-template` GitHub template, never hand-rolled. The template is a React + Vite + TypeScript starter that bundles into a single self-contained `dist/index.html` and uploads as one Dataverse HTML web resource — the right shape for back-office views, dashboards, and wizards. If the work needs to bind to a column/dataset or replace a stock control, that's a PCF project instead (`pac pcf init` — see the `pac` exception in root `AGENTS.md`), not this template.

## Spawn a new project

```bash
gh repo create <org>/<project-name> --template context-and/vibe-template --private --clone
cd <project-name>
```

## Post-clone checklist

1. `npm install`
2. `npm run init-project` — interactive; writes publisher + solution naming into `webresources.config.json`. Run once per new clone.
3. Set up `.env` with a service-principal credential scoped to one Dataverse environment (never `DefaultAzureCredential`/`az` CLI — see root `AGENTS.md` → Never).
4. `npm run schema:refresh` — pulls a live schema reference into `docs/schema/` for the target environment (requires the internal `xpm-admin` toolkit; see the cloned repo's own `AGENTS.md` for setup).
5. `npm run dev` — starts against demo data with zero setup; wire up `.env` when ready for live data.

## Why this matters

The template enforces file-size and function-complexity budgets, bans `any`/`console.log`, requires a test alongside every reusable component/hook, and ships a committed per-table schema reference so field names are never guessed. Hand-rolling a project from scratch skips all of that. If the user insists on a from-scratch project, flag that it diverges from org convention before proceeding.

## Naming (Projectum dev work)

Publisher `Projectum` / prefix `pum`; solution `Pum{ProjectName}Solution`; web resource `pum_{snake_case_feature}`. For customer engagements, use that customer's own `/connect`-derived prefix instead (see root `AGENTS.md` → Context& / Projectum overlay).

## Full contract

The cloned project's own `AGENTS.md` (imported by its `CLAUDE.md`) is the canonical contract once you're inside it — code size budgets, the `.env` live/demo mode split, `npm run` script reference, and git hooks. Read it before making changes there.
