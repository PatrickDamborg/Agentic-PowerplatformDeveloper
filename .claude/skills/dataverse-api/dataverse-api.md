---
name: dataverse-api
description: Rules for making Dataverse Web API calls. Load when writing or debugging any REST/OData call to Dataverse.
---

# Dataverse API Usage

Before making ANY Dataverse Web API call:

1. **Reference the official docs first** — Use the Microsoft Learn MCP tools (`microsoft-code-reference` or `microsoft-docs`) to look up the exact API format for the operation. Never guess JSON payloads or endpoint patterns. The docs contain the correct headers, body structure, and odata types.

2. **Verify entity logical names** — Before referencing any table in a relationship, lookup, or query, confirm the exact logical name by querying `EntityDefinitions` (e.g., filter by `LogicalName` containing the expected prefix). Do not assume spelling — names may differ from what the user says (e.g., `pum_resource` not `pum_ressource`).

3. **Publisher prefix is immutable** — The publisher prefix is baked into SchemaName at creation time and cannot be changed afterward. If the wrong prefix is used, the only fix is to delete and recreate. Always confirm the prefix before creating any component.
