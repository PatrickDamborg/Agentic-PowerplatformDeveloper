<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_feature`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_feature -->

# PumFeature (`pum_feature`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_featureid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `_createdby_value` | Lookup |  | Lookup → systemuser; write `CreatedBy@odata.bind` = `/systemusers({id})` |
| `createdon` | DateTime |  | date-time (ISO 8601) |
| `_createdonbehalfby_value` | Lookup |  | Lookup → systemuser; write `CreatedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `importsequencenumber` | Integer |  | range -2147483648..2147483647 |
| `_modifiedby_value` | Lookup |  | Lookup → systemuser; write `ModifiedBy@odata.bind` = `/systemusers({id})` |
| `modifiedon` | DateTime |  | date-time (ISO 8601) |
| `_modifiedonbehalfby_value` | Lookup |  | Lookup → systemuser; write `ModifiedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `overriddencreatedon` | DateTime (date-only) |  | date (ISO 8601) |
| `_owningbusinessunit_value` | Lookup |  | Lookup → businessunit; write `OwningBusinessUnit@odata.bind` = `/businessunits({id})` |
| `pum_category` | Picklist |  |  |
| `pum_description` | Memo |  | max length 2000 |
| `_pum_epic_value` | Lookup |  | Lookup → pum_epic; write `pum_Epic@odata.bind` = `/pum_epics({id})` |
| `pum_estimatedfinish` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_estimatedstart` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_estimatehours` | Integer |  | range -2147483648..2147483647 |
| `pum_kanbanstatus` | Picklist |  |  |
| `_pum_product_value` | Lookup |  | Lookup → pum_product; write `pum_Product@odata.bind` = `/pum_products({id})` |
| `pum_seeddata` | String |  | max length 100 |
| `pum_urlagiletool` | String |  | format: url; max length 100 |
| `pum_workitemid` | String |  | max length 100 |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_category` choices

| Value | Label |
|---|---|
| 493840000 | Category A |
| 493840001 | Category B |
| 493840002 | Category C |

### `pum_kanbanstatus` choices

| Value | Label |
|---|---|
| 493840000 | 1. Backlog |
| 493840001 | 2. In Progress |
| 493840002 | 3. Done |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
