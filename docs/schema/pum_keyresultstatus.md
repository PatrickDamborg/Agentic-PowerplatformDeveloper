<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_keyresultstatus`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_keyresultstatus -->

# PumKeyresultstatus (`pum_keyresultstatus`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_keyresultstatusid` | Uniqueidentifier | ✓ |  |
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
| `pum_comment` | String |  | max length 250 |
| `pum_improvementdelta` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `_pum_keyresults_value` | Lookup |  | Lookup → pum_keyresults; write `pum_KeyResults@odata.bind` = `/pum_keyresultses({id})` |
| `pum_newstatus` | Picklist |  |  |
| `pum_progressdelta` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_realization` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_realizationin` | String |  | max length 4000 |
| `pum_realizationwholenumber` | Integer |  | range 0..2147483647 |
| `pum_resulttarget` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_startvalue` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_statusdate` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_updated` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_updatestatus` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_newstatus` choices

| Value | Label |
|---|---|
| 493840000 | 🟢 On Track |
| 493840001 | 🟡 Needs Attention |
| 493840002 | 🔴 Off Track |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
