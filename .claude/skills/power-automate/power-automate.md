---
name: power-automate
description: Rules for building and modifying Power Automate cloud flows via the Dataverse Web API. Load when creating, updating, or debugging any cloud flow.
---

# Power Automate Cloud Flows

When building or modifying Power Automate cloud flows via the Dataverse Web API:

## Pre-requisites

1. **Schema dump first** — Before constructing any flow definition, run `pwsh flows/schema-dump.ps1` and read `schema_dump.json`. This provides exact table logical names, entity set names, column types, choice option values, and relationship navigation properties. Never guess these values.

2. **Use helpers module** — All flow scripts import `helpers.psm1`. Do not duplicate .env loading or token acquisition code.

## Flow Definition Rules

3. **Linear logic only** — Every action's `runAfter` must reference exactly one predecessor action (or `{}` for the first action after the trigger). Do not create parallel branches that reference earlier actions. Chain actions sequentially: A → B → C → D. If a condition (If/Switch) is needed, the next action after it uses `runAfter` on the condition, not on an action inside the condition. This prevents "phantom connectors" in the designer.

4. **Try/Catch pattern** — Wrap the main flow logic in a `Try_Scope` (type: Scope). Add a `Catch_Scope` with `runAfter: { "Try_Scope": ["Failed", "TimedOut"] }` for error handling. Optionally add a `Finally_Scope` that runs after both. This ensures the flow run shows as Succeeded even when individual actions fail.

5. **Environment variables for thresholds** — Never hard-code business values (days, counts, email addresses, feature flags). Create environment variables using `pwsh flows/create-env-variable.ps1` and reference them in flow expressions as `@parameters('schemaname (schemaname)')`.

6. **Dynamic values for record references** — Never hard-code record GUIDs (system users, resources, projects, assignments, etc.) in flow actions. Instead, resolve them dynamically at runtime:
   - Use trigger outputs for related record IDs (e.g., `triggerOutputs()?['body/_ownerid_value']` for the record owner)
   - Use **List Records** or **Get Record** actions to look up related records by filtering on a known value (e.g., find the `pum_resource` whose `_pum_user_value` matches the owner)
   - Reference action outputs in `@odata.bind` expressions: `entitysetname(@{outputs('Action_Name')?['body/primaryid']})`
   - For OData filters on lookup `_value` fields, do **not** wrap the GUID in quotes: `_pum_user_value eq @{outputs('Get_Owner')}` (not `'@{...}'`)

## API Details

7. **Cloud flows are `workflow` records** with `category = 5`. The definition lives in the `clientdata` field as a JSON string (Logic Apps workflow definition format).

8. **Solution association** — Always use `MSCRM.SolutionUniqueName` header when creating flows. Only solution-aware flows can be managed via API.

9. **Activation** — New flows are created in Draft state (`statecode=0`). Activate via `pwsh flows/toggle-flow.ps1`. Always deactivate before updating `clientdata`.

10. **Connection references** — Flow definitions reference connections via `connectionName` in the host block. Use `shared_commondataserviceforapps` for Dataverse connector actions. Connection references must exist in the solution.

## Multi-Agent Workflow

11. **Build-Debug loop** — Use `@flow-builder` to create/modify flows via API, then `@flow-debugger` to validate in the Power Automate designer via Chrome browser automation. The debugger checks for visual issues, run history errors, and performs test runs. Iterate until the flow passes all checks.

## Script Reference
| Script | Purpose |
|--------|---------|
| `flows/schema-dump.ps1` | Dump live schema to `schema_dump.json` |
| `flows/create-flow.ps1` | Create flow from definition JSON |
| `flows/get-flow.ps1` | Read flow definition by name/ID |
| `flows/list-flows.ps1` | List all cloud flows |
| `flows/update-flow.ps1` | Update flow definition (deactivates first) |
| `flows/toggle-flow.ps1` | Activate or deactivate a flow |
| `flows/create-env-variable.ps1` | Create environment variable |
| `flows/get-env-variables.ps1` | List environment variables |

## Template Reference
- `flows/templates/linear-trigger-actions.json` — Linear chain pattern
- `flows/templates/try-catch-scope.json` — Scope-based error handling
- `flows/templates/env-variable-reference.json` — Environment variable usage
