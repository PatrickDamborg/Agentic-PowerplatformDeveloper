---
name: data-model
description: Rules for creating or modifying Dataverse schema (tables, columns, lookups, relationships). Load when doing any schema work.
---

# Data Model Management

When creating or modifying Dataverse schema (tables, columns, lookups, relationships):

1. **Use `MSCRM.SolutionUniqueName` header** — Always include this header on POST requests to `EntityDefinitions`, `RelationshipDefinitions`, and `Attributes` endpoints. This associates the component with the solution at creation time. Do NOT create components first and add them to a solution separately via `AddSolutionComponent`.

2. **Publish after schema changes** — After creating or modifying tables, columns, or relationships, call `PublishXml` to make changes visible in the application:
   ```
   POST {url}/PublishXml
   {"ParameterXml": "<importexportxml><entities><entity>{logicalname}</entity></entities></importexportxml>"}
   ```

3. **Form changes via maker portal** — Do not manipulate form XML programmatically via the API. Adding subgrids, sections, or controls to forms is fragile via API and risks corrupting form XML. Always recommend the user do form layout changes in the Power Apps maker portal.
