# Maker maintainability checklist

Walk this checklist before publishing any new or modified Copilot Studio skill. `validate-yaml.ps1` enforces the mechanical items; the judgement items require a human pass.

## Mechanical (enforced by the linter)

- [ ] Flow name follows `<prefix>_skill_<verb>_<noun>` (e.g. `pum_skill_create_risk`).
- [ ] Agent name follows `<prefix>_xpm_<role>` (e.g. `pum_xpm_risk_analyst`).
- [ ] Solution is `XPMCopilotSkills` (unmanaged).
- [ ] Every tool has a non-empty `description`.
- [ ] Every input parameter has a non-empty `description`.
- [ ] Every output property has a `description` in the output schema.
- [ ] Every connected-agent reference has a `description` the orchestrator can route on.
- [ ] No hard-coded record GUIDs in flow actions (resolved dynamically at runtime).
- [ ] No hard-coded business values (use environment variables).
- [ ] Connection references are used (not embedded connection ids).
- [ ] Flow wraps main logic in `Try_Scope`; `Catch_Scope` logs to `pum_activitylog`.

## Judgement (human review)

- [ ] The skill does exactly one verb. If you describe it as "and", split it.
- [ ] Descriptions read as prose a maker could understand without seeing the code — not field lists or abbreviations.
- [ ] Sample utterances exist in `skills-catalogue.md` and cover the happy path plus one edge case.
- [ ] The decision tree (`data-access-decision-tree.md`) was consulted; the tool choice is the first that satisfies the requirement.
- [ ] The connected agent the skill lives on is the right domain owner (risk / status / summary / …). Don't attach cross-cutting skills to the orchestrator.
- [ ] Env variable names are stable — renaming later breaks flows across environments.
- [ ] The flow's `Respond to Copilot` output schema returns only fields the agent will actually use. Every extra field adds routing surface.

## Release

- [ ] `validate-yaml.ps1` exits 0 for the affected files.
- [ ] Flow is added to `XPMCopilotSkills` via `add-to-solution.ps1`.
- [ ] `skills-catalogue.md` updated with a new row (or existing row edited).
- [ ] Agent YAML pushed back to Copilot Studio via the VS Code extension.
- [ ] Manual smoke test in Copilot Studio: at least one happy-path utterance and one that should be refused / clarified.
