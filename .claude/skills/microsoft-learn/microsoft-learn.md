---
name: microsoft-learn
description: When to use each Microsoft Learn MCP tool. Load when deciding which MCP skill to invoke for a Microsoft technology question.
---

# Microsoft Learn MCP Skills

Use the Microsoft Learn MCP server skills based on the task at hand:

- **`microsoft-code-reference`** — Use when writing, debugging, or reviewing code that touches any Microsoft SDK, .NET library, Azure client library, or Microsoft API. Catches hallucinated methods, wrong signatures, and deprecated patterns. If the task involves producing or fixing Microsoft-related code, use this skill.
- **`microsoft-docs`** — Use when the question is about understanding concepts, configuration, limits, quotas, best practices, or tutorials for any Microsoft technology (Azure, .NET, M365, Power Platform, Dataverse, etc.). Facts and concepts, not code.
- **`microsoft-skill-creator`** — Use when generating or scaffolding a custom agent skill for a specific Microsoft technology. Investigates the topic via official docs, then produces a hybrid skill with local knowledge and dynamic lookups.
