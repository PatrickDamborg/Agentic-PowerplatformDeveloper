<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_tasklink`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_tasklink -->

# PumTasklink (`pum_tasklink`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String |  | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_tasklinkid` | Uniqueidentifier | ✓ |  |
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
| `pum_crosslink` | Boolean |  |  |
| `pum_durationunit` | String |  | max length 100 |
| `pum_elapsedduration` | Boolean |  |  |
| `pum_laginminutes` | Integer |  | range -2147483648..2147483647 |
| `pum_laglead` | String |  | max length 100 |
| `pum_linktype` | String |  | max length 100 |
| `_pum_predecessor_value` | Lookup |  | Lookup → pum_gantttask; write `pum_Predecessor@odata.bind` = `/pum_gantttasks({id})` |
| `pum_seeddata` | String |  | max length 100 |
| `pum_softlink` | Boolean |  |  |
| `_pum_successor_value` | Lookup |  | Lookup → pum_gantttask; write `pum_Successor@odata.bind` = `/pum_gantttasks({id})` |
| `_pum_templatetasklink_id_value` | Lookup |  | Lookup → pum_powergantttemplate; write `pum_templatetasklink_id@odata.bind` = `/pum_powergantttemplates({id})` |
| `_pum_version_value` | Lookup |  | Lookup → pum_ganttversion; write `pum_Version@odata.bind` = `/pum_ganttversions({id})` |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
