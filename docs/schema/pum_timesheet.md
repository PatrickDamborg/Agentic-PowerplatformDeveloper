<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_timesheet`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_timesheet -->

# PumTimesheet (`pum_timesheet`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 850 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_timesheetid` | Uniqueidentifier | ✓ |  |
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
| `_pum_approvedby_value` | Lookup |  | Lookup → systemuser; write `pum_Approvedby@odata.bind` = `/systemusers({id})` |
| `pum_approvedon` | DateTime |  | date-time (ISO 8601) |
| `_pum_resource_value` | Lookup |  | Lookup → systemuser; write `pum_Resource@odata.bind` = `/systemusers({id})` |
| `pum_status` | Picklist |  |  |
| `pum_submittedon` | DateTime |  | date-time (ISO 8601) |
| `pum_weekstart` | DateTime (date-only) |  | date (ISO 8601) |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_status` choices

| Value | Label |
|---|---|
| 100000000 | Draft |
| 100000001 | Submitted |
| 100000002 | Approved |
| 100000003 | Rejected |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
