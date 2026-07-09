---
name: business-skills
description: "Programmatically create, update, and solution-associate Dataverse Business Skill records (and their reference-file resources) from local SKILL.md files. Use when asked to add/sync/upload skills to a Dataverse solution, push SKILL.md content into an agent's business skills, or when the user says 'business skills' specifically (not Copilot Studio's portal-only Agent Skills upload feature — see copilot-skill-authoring for that). Covers the skill/skillresource entity schema, the API create/update/file-upload pattern, and the reusable sync-skill.ps1 script."
---

# Business Skills — Dataverse Entity Sync

Business Skills are a **native, solution-aware Dataverse entity** (not the Copilot Studio "Agent Skills" portal upload feature, which has no API and is a separate concept — see `copilot-skill-authoring` for authoring that format). They can be created, updated, and added to solutions entirely through the Web API, which this skill documents.

**When the user says "business skills" or "the skills you uploaded to the environment"**, they mean these Dataverse records — not files on disk, not a Copilot Studio portal upload. Confirm which one is meant if ambiguous; the two are easy to conflate.

---

## Entity schema

Discovered by querying `EntityDefinitions?$filter=...` for logical names containing `skill` — do this again if the schema seems to have changed (this is a newer, June-2026-era Dataverse feature).

| Entity | Entity set | Key fields |
|---|---|---|
| `skill` ("Business Skill") | `skills` | `skillid` (PK), `name`, `uniquename`, `description`, `body` (full markdown, **frontmatter stripped**) |
| `skillresource` ("Business Skill Resource") | `skillresources` | `skillresourceid` (PK), `skillid` (lookup → `skill`, nav property is lowercase `skillid`, so bind as `skillid@odata.bind`), `filename`, `uniquename`, `filecontent` (File column — see upload pattern below) |

Solution component types (for verifying membership via `solutioncomponents?$filter=_solutionid_value eq <id>`): **`skill` = 10425**, **`skillresource` = 10426**. Confirmed by diffing component counts before/after a sync — re-verify if these ever seem off, since these aren't in the standard documented `componenttype` global choice list (it's a newer type).

A skill/resource not yet added to any custom solution shows `solutionid` = `fd140aae-4df4-11dd-bd17-0019b9312238` (the well-known **Default Solution** GUID) — that's the "needs to be created/added" signal, not an error.

---

## Solution association — no AddSolutionComponent needed

Don't hunt for an `AddSolutionComponentRequest` componenttype value for these entities. Per Microsoft's own guidance, the simpler and more reliable path — already the convention throughout this repo (`Get-DataverseHeaders -SolutionName X` sets the header for every create-table/create-flow/add-columns/create-env-variable script) — works here too:

**Set the `MSCRM.SolutionUniqueName` header on the CREATE (or UPDATE) request itself.** This both creates/updates the row *and* registers it as a member of that solution, in one call. `Get-DataverseHeaders -SolutionName <solution>` in `helpers.psm1` already does this.

For an **existing** record you're only adding to a *new* solution (no content change needed), PATCH any field to itself with the header set — that's enough to register membership. `sync-skill.ps1` does this automatically whenever it updates a resource row.

---

## Frontmatter → `body`

`skill.body` holds the SKILL.md content **without** the YAML frontmatter block — the record's own `name`/`uniquename`/`description` fields cover what the frontmatter would have said. Stripping is a simple, reliable operation: split on the first two lines that are exactly `---`, keep everything after the second.

**Do not try to auto-parse `name`/`description` out of the YAML frontmatter with a regex.** Real descriptions use YAML single-quoted strings with `''`-escaped apostrophes and sometimes span multiple lines — read the file yourself (you already have it in context most of the time) and pass clean `-DisplayName`/`-Description` values to the script. This is far more reliable than a generic YAML parser for the small number of fields involved, and it's what actually worked in practice.

---

## File content upload (skillresource)

`filecontent` is a **File column** — it is not set via a normal field PATCH. Upload it as a separate call after the row exists:

```
PATCH {baseurl}/skillresources({id})/filecontent
Content-Type: application/octet-stream
x-ms-file-name: <filename>
<raw file bytes as the request body>
```

Returns `204 No Content` on success. `sync-skill.ps1` handles this automatically for every `.md` file in a `references/` folder.

---

## Using the script

`sync-skill.ps1` handles one skill (+ optional reference files) per invocation — create or update, decided by whether `-ExistingSkillId` is passed.

```
# New skill, no reference files
pwsh .claude/skills/business-skills/sync-skill.ps1 `
    -SkillMdPath "deliverables/skills/portfolio-summary/SKILL.md" `
    -DisplayName "Portfolio summary skill" `
    -UniqueName "xPM_portfolioSummary" `
    -Description "<clean plain-text description, hand-extracted from frontmatter>" `
    -SolutionName "xPMAIUseCasesdemo"

# Update an existing skill and sync its reference files (matched/updated by filename, created if new)
pwsh .claude/skills/business-skills/sync-skill.ps1 `
    -SkillMdPath "deliverables/skills/status-report-drafter/SKILL.md" `
    -DisplayName "Status reporting skill" `
    -UniqueName "xPM_statusReporting" `
    -Description "<...>" `
    -SolutionName "xPMAIUseCasesdemo" `
    -ExistingSkillId "3a325ea4-7874-f111-ab0e-0022480412bf" `
    -ReferencesFolder "deliverables/skills/status-report-drafter/references"
```

**Before running for an "update" case**, look up the existing ID first — don't guess:
```
skills?$filter=uniquename eq '<UniqueName>'&$select=skillid
```
**Before running for a batch of new skills**, check none already exist with a broad list:
```
skills?$select=skillid,name,uniquename&$top=50
```

---

## Verification

After syncing, confirm solution membership rather than trusting the create/update calls silently succeeded:
```
solutioncomponents?$filter=_solutionid_value eq <solutionid>&$select=componenttype,objectid
```
Group by `componenttype` and diff the before/after counts for 10425 (skills) and 10426 (resources) against how many you synced. Check specific `objectid`s are present if you want certainty on individual records.

---

## Gotchas

- `skillresource.skillid` bind property is `skillid@odata.bind` (lowercase) — confirmed via `EntityDefinitions(LogicalName='skillresource')/ManyToOneRelationships`, don't assume PascalCase like some other xPM lookups use.
- A skill record that already exists and is stale (e.g. an old SKILL.md version uploaded from a prior session) will silently keep serving wrong instructions to any agent using it until you update it — when syncing a skill that already exists in the environment, always check whether its `body` is current, not just whether the row exists.
- `filecontent` uploads are binary-safe but markdown is plain UTF-8 text — no encoding gymnastics needed, `[System.IO.File]::ReadAllBytes` and the raw PATCH body is sufficient.
