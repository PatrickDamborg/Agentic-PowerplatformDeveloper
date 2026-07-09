<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_rbs`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_rbs -->

# PumRbs (`pum_rbs`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_rbsid` | Uniqueidentifier | ✓ |  |
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
| `pum_fullrbs` | String |  | max length 1000 |
| `pum_level` | Integer |  | range 1..20 |
| `pum_level10name` | String |  | max length 100 |
| `pum_level11name` | String |  | max length 100 |
| `pum_level12name` | String |  | max length 100 |
| `pum_level1name` | String |  | max length 100 |
| `pum_level2name` | String |  | max length 100 |
| `pum_level3name` | String |  | max length 100 |
| `pum_level4name` | String |  | max length 100 |
| `pum_level5name` | String |  | max length 100 |
| `pum_level6name` | String |  | max length 100 |
| `pum_level7name` | String |  | max length 100 |
| `pum_level8name` | String |  | max length 100 |
| `pum_level9name` | String |  | max length 100 |
| `pum_manager` | String |  | max length 100 |
| `pum_manageremail` | String |  | max length 100 |
| `pum_managerid` | String |  | max length 100 |
| `_pum_parentname_value` | Lookup |  | Lookup → pum_rbs; write `pum_ParentName@odata.bind` = `/pum_rbses({id})` |
| `pum_referenceguid` | String |  | max length 100 |
| `pum_seperator` | Picklist |  |  |
| `pum_sort` | Integer |  | range -2147483648..2147483647 |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_seperator` choices

| Value | Label |
|---|---|
| 493840001 | . |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
