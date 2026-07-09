<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_calendar`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_calendar -->

# PumCalendar (`pum_calendar`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 850 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `_owningbusinessunit_value` | Lookup | ✓ | Lookup → businessunit; write `OwningBusinessUnit@odata.bind` = `/businessunits({id})` |
| `pum_calendarid` | Uniqueidentifier | ✓ |  |
| `pum_defaultdailycapacityhours` | Decimal | ✓ | range 0..100000000000; 2 decimals |
| `statecode` | State | ✓ |  |
| `_createdby_value` | Lookup |  | Lookup → systemuser; write `CreatedBy@odata.bind` = `/systemusers({id})` |
| `createdon` | DateTime |  | date-time (ISO 8601) |
| `_createdonbehalfby_value` | Lookup |  | Lookup → systemuser; write `CreatedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `importsequencenumber` | Integer |  | range -2147483648..2147483647 |
| `_modifiedby_value` | Lookup |  | Lookup → systemuser; write `ModifiedBy@odata.bind` = `/systemusers({id})` |
| `modifiedon` | DateTime |  | date-time (ISO 8601) |
| `_modifiedonbehalfby_value` | Lookup |  | Lookup → systemuser; write `ModifiedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `overriddencreatedon` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_enablenationalholiday` | Boolean |  |  |
| `pum_enablespecificdailycapacityhours` | Boolean |  |  |
| `pum_enddate` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_fridaycapacityhours` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_fridaycapacityhoursmanually` | Decimal |  | range 0..100000000000; 2 decimals |
| `pum_mondaycapacityhours` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_mondaycapacityhoursmanually` | Decimal |  | range 0..100000000000; 2 decimals |
| `pum_saturdaycapacityhours` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_saturdaycapacityhoursmanually` | Decimal |  | range 0..100000000000; 2 decimals |
| `pum_startdate` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_sundaycapacityhours` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_sundaycapacityhoursmanually` | Decimal |  | range 0..100000000000; 2 decimals |
| `pum_thursdaycapacityhours` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_thursdaycapacityhoursmanually` | Decimal |  | range 0..100000000000; 2 decimals |
| `pum_tuesdaycapacityhours` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_tuesdaycapacityhoursmanually` | Decimal |  | range 0..100000000000; 2 decimals |
| `pum_wednesdaycapacityhours` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_wednesdaycapacityhoursmanually` | Decimal |  | range 0..100000000000; 2 decimals |
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
