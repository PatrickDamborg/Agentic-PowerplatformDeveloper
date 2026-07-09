<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_program`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_program -->

# PumProgram (`pum_program`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_program` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_programid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `context_mustrun` | Boolean |  |  |
| `context_roadmaprank` | Integer |  | range -2147483648..2147483647 |
| `context_roi` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `context_selected` | Boolean |  |  |
| `context_statuscomments` | Memo |  | max length 4000 |
| `context_totalbenefits3y` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `_createdby_value` | Lookup |  | Lookup → systemuser; write `CreatedBy@odata.bind` = `/systemusers({id})` |
| `createdon` | DateTime |  | date-time (ISO 8601) |
| `_createdonbehalfby_value` | Lookup |  | Lookup → systemuser; write `CreatedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `exchangerate` | Decimal |  | range 1e-10..100000000000; 10 decimals |
| `importsequencenumber` | Integer |  | range -2147483648..2147483647 |
| `_modifiedby_value` | Lookup |  | Lookup → systemuser; write `ModifiedBy@odata.bind` = `/systemusers({id})` |
| `modifiedon` | DateTime |  | date-time (ISO 8601) |
| `_modifiedonbehalfby_value` | Lookup |  | Lookup → systemuser; write `ModifiedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `overriddencreatedon` | DateTime (date-only) |  | date (ISO 8601) |
| `_owningbusinessunit_value` | Lookup |  | Lookup → businessunit; write `OwningBusinessUnit@odata.bind` = `/businessunits({id})` |
| `processid` | Uniqueidentifier |  |  |
| `_pum_category_value` | Lookup |  | Lookup → pum_investmentcategory; write `pum_Category@odata.bind` = `/pum_investmentcategories({id})` |
| `pum_currentstagetextfield` | String |  | max length 100 |
| `pum_description` | String |  | max length 100 |
| `pum_initiativescount` | Integer |  | range -2147483648..2147483647 |
| `pum_initiativescount_date` | DateTime |  | date-time (ISO 8601) |
| `pum_initiativescount_state` | Integer |  | range -2147483648..2147483647 |
| `_pum_keyresults_value` | Lookup |  | Lookup → pum_keyresults; write `pum_KeyResults@odata.bind` = `/pum_keyresultses({id})` |
| `pum_kpicost` | Picklist |  |  |
| `pum_kpiquality` | Picklist |  |  |
| `pum_kpiresources` | Picklist |  |  |
| `pum_kpiscope` | Picklist |  |  |
| `pum_kpisummary` | Picklist |  |  |
| `pum_kpisummarycomment` | String |  | max length 2000 |
| `pum_kpitimeline` | Picklist |  |  |
| `pum_mustrun` | Boolean |  |  |
| `pum_okr` | Boolean |  |  |
| `_pum_portfolio_value` | Lookup |  | Lookup → pum_portfolio; write `pum_Portfolio@odata.bind` = `/pum_portfolios({id})` |
| `pum_programfinish` | DateTime (date-only) |  | date (ISO 8601) |
| `_pum_programreadteam_value` | Lookup |  | Lookup → team; write `pum_ProgramReadTeam@odata.bind` = `/teams({id})` |
| `_pum_programreadwriteteam_value` | Lookup |  | Lookup → team; write `pum_ProgramReadWriteTeam@odata.bind` = `/teams({id})` |
| `pum_programstart` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_programstatus` | Picklist |  |  |
| `pum_progress` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_progress_date` | DateTime |  | date-time (ISO 8601) |
| `pum_progress_state` | Integer |  | range -2147483648..2147483647 |
| `pum_progressforviews` | String |  | max length 4000 |
| `pum_rank` | Integer |  | range -2147483648..2147483647 |
| `pum_roi` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_schedulecompletion` | Integer |  | range -2147483648..2147483647 |
| `pum_schedulecompletion_count` | Integer |  | range -2147483648..2147483647 |
| `pum_schedulecompletion_date` | DateTime |  | date-time (ISO 8601) |
| `pum_schedulecompletion_state` | Integer |  | range -2147483648..2147483647 |
| `pum_schedulecompletion_sum` | Decimal |  | range 0..1000000000; 2 decimals |
| `pum_seeddata` | String |  | max length 100 |
| `pum_selected` | Boolean |  |  |
| `_pum_sponsor_value` | Lookup |  | Lookup → systemuser; write `pum_Sponsor@odata.bind` = `/systemusers({id})` |
| `pum_status` | Picklist |  |  |
| `pum_totalactualcost` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `pum_totalactualcost_date` | DateTime |  | date-time (ISO 8601) |
| `pum_totalactualcost_state` | Integer |  | range -2147483648..2147483647 |
| `pum_totalbenefits3y` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `pum_totalbudget` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `pum_totalbudget_date` | DateTime |  | date-time (ISO 8601) |
| `pum_totalbudget_state` | Integer |  | range -2147483648..2147483647 |
| `pum_totalwork` | Integer |  | range -2147483648..2147483647 |
| `pum_totalwork_date` | DateTime |  | date-time (ISO 8601) |
| `pum_totalwork_state` | Integer |  | range -2147483648..2147483647 |
| `_stageid_value` | Uniqueidentifier |  | Lookup → processstage; write `stageid@odata.bind` = `/processstages({id})` |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `_transactioncurrencyid_value` | Lookup |  | Lookup → transactioncurrency; write `TransactionCurrencyId@odata.bind` = `/transactioncurrencies({id})` |
| `traversedpath` | String |  | max length 1250 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_kpicost` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpiquality` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpiresources` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpiscope` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpisummary` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpitimeline` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_programstatus` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_status` choices

| Value | Label |
|---|---|
| 493840005 | Proposed |
| 493840004 | Under Evaluation |
| 493840006 | Authorized |
| 493840000 | Active |
| 493840001 | On Hold / Suspended |
| 493840002 | Closing |
| 493840003 | Completed |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
