<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_propose`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_propose -->

# PumPropose (`pum_propose`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 850 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `_owningbusinessunit_value` | Lookup | ✓ | Lookup → businessunit; write `OwningBusinessUnit@odata.bind` = `/businessunits({id})` |
| `pum_proposeid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `_createdby_value` | Lookup |  | Lookup → systemuser; write `CreatedBy@odata.bind` = `/systemusers({id})` |
| `createdon` | DateTime |  | date-time (ISO 8601) |
| `_createdonbehalfby_value` | Lookup |  | Lookup → systemuser; write `CreatedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `importsequencenumber` | Integer |  | range -2147483648..2147483647 |
| `_modifiedby_value` | Lookup |  | Lookup → systemuser; write `ModifiedBy@odata.bind` = `/systemusers({id})` |
| `modifiedon` | DateTime |  | date-time (ISO 8601) |
| `_modifiedonbehalfby_value` | Lookup |  | Lookup → systemuser; write `ModifiedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `overriddencreatedon` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_end` | DateTime |  | date-time (ISO 8601) |
| `_pum_idea_value` | Lookup |  | Lookup → pum_idea; write `pum_Idea@odata.bind` = `/pum_ideas({id})` |
| `_pum_initiative_value` | Lookup |  | Lookup → pum_initiative; write `pum_Initiative@odata.bind` = `/pum_initiatives({id})` |
| `_pum_portfolio_value` | Lookup |  | Lookup → pum_portfolio; write `pum_Portfolio@odata.bind` = `/pum_portfolios({id})` |
| `_pum_program_value` | Lookup |  | Lookup → pum_program; write `pum_Program@odata.bind` = `/pum_programs({id})` |
| `_pum_resource_value` | Lookup |  | Lookup → pum_resource; write `pum_Resource@odata.bind` = `/pum_resources({id})` |
| `_pum_resourceplan_value` | Lookup |  | Lookup → pum_resourceplan; write `pum_ResourcePlan@odata.bind` = `/pum_resourceplans({id})` |
| `pum_seeddata` | String |  | max length 100 |
| `pum_start` | DateTime |  | date-time (ISO 8601) |
| `pum_state` | Picklist |  |  |
| `pum_work` | Decimal |  | range 0..100000000000; 2 decimals |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_state` choices

| Value | Label |
|---|---|
| 493840000 | ⏳ Proposed |
| 493840001 | ✅ Approved |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
