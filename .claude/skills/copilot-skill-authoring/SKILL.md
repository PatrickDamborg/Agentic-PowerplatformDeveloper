---
name: copilot-skill-authoring
description: "How to create skill files (.md with YAML frontmatter) for the Copilot Studio agent skill uploader. Use whenever the user wants to create a new skill for a Copilot Studio agent, package domain knowledge as an uploadable skill file, or structure a skill with a main SKILL.md and supporting reference files."
---

> **Not the same thing as Dataverse Business Skills.** This skill covers *writing* skill content (frontmatter + structure). For *programmatically creating/updating/syncing* Business Skill records in Dataverse (a real, solution-aware, API-accessible entity — distinct from Copilot Studio's portal-only Agent Skills upload), see the `business-skills` skill.

# Copilot Studio Skill Authoring

Skills for the Copilot Studio agent experience are Markdown files with YAML frontmatter. When uploaded, they give an agent focused domain knowledge or procedural guidance for a specific area.

---

## File requirements

Every skill file must:
- Be a `.md` file
- Start with YAML frontmatter containing `name` and `description`
- Use a **single-line quoted string** for `description` — do NOT use multiline `>-` block syntax, as the Copilot Studio parser rejects it

```markdown
---
name: my-skill-name
description: "One-sentence description of what this skill covers and when to use it."
---

# Skill content here...
```

---

## Skill structure patterns

### Single file (simple skills)
A single `.md` file covering one focused domain. Upload directly.

### Multi-file package (complex skills)
A root `SKILL.md` as the entry point, plus reference files for sub-topics:

```
my-skill/
├── SKILL.md                  ← uploaded as the "index" skill
└── references/
    ├── topic-a.md            ← each gets its own frontmatter and is uploaded separately
    ├── topic-b.md
    └── topic-c.md
```

Each reference file also needs its own `name` and `description` frontmatter so it can be uploaded as a standalone skill. The root SKILL.md references them by name in a table so the agent knows when to load which file.

---

## Writing good skill content

**Structure each skill around a process or domain**, not a data dump. Include:
- When to use this skill (already in the description, but reinforce in the body)
- Step-by-step sequences for the key operations
- Table of relevant fields, picklist values, or API parameters
- Common gotchas section at the bottom

**Description field** — this is what the agent uses to decide whether to load the skill. Make it specific and action-oriented. Include the trigger context ("Use when an agent needs to…") and the outcome ("…so it can execute X process correctly").

**Naming convention:**
- `name` field: kebab-case, prefixed with the domain (e.g. `xpm-projects`, `xpm-status-reporting`)
- File name: match the `name` field + `.md`

---

## Example — domain skill package

Root SKILL.md:
```markdown
---
name: xpm-processes
description: "Procedural guide for PPM processes in Projectum xPM via the Dataverse MCP. Load when an agent needs to read or write project, status, or resource data."
---

## Process Index
| Process | Reference file |
|---------|---------------|
| Create / read initiatives | xpm-projects |
| Status reporting | xpm-status-reporting |
| Resource allocation | xpm-resource-management |
```

Reference file (`references/projects.md`):
```markdown
---
name: xpm-projects
description: "How to read, create, and update Portfolios, Programs, and Initiatives in xPM via the Dataverse MCP."
---

## §Read
...

## §Create
...
```

---

## Upload checklist

- [ ] `name` field present in frontmatter
- [ ] `description` is a single-line quoted string
- [ ] File is `.md` extension
- [ ] If part of a package: each reference file also has its own frontmatter
- [ ] Description says both *what* the skill covers and *when* to use it
