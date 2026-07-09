<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_statusreporting`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_statusreporting -->

# PumStatusreporting (`pum_statusreporting`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_statusreportingid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `context_approvedfinish` | DateTime (date-only) |  | date (ISO 8601) |
| `context_approvedstart` | DateTime (date-only) |  | date (ISO 8601) |
| `context_author` | String |  | max length 100 |
| `context_executivesummary` | Memo |  | max length 50000 |
| `context_roi` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `_createdby_value` | Lookup |  | Lookup → systemuser; write `CreatedBy@odata.bind` = `/systemusers({id})` |
| `createdon` | DateTime (date-only) |  | date (ISO 8601) |
| `_createdonbehalfby_value` | Lookup |  | Lookup → systemuser; write `CreatedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `exchangerate` | Decimal |  | range 1e-10..100000000000; 10 decimals |
| `importsequencenumber` | Integer |  | range -2147483648..2147483647 |
| `_modifiedby_value` | Lookup |  | Lookup → systemuser; write `ModifiedBy@odata.bind` = `/systemusers({id})` |
| `modifiedon` | DateTime |  | date-time (ISO 8601) |
| `_modifiedonbehalfby_value` | Lookup |  | Lookup → systemuser; write `ModifiedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `overriddencreatedon` | DateTime (date-only) |  | date (ISO 8601) |
| `_owningbusinessunit_value` | Lookup |  | Lookup → businessunit; write `OwningBusinessUnit@odata.bind` = `/businessunits({id})` |
| `pum_actualcost` | Money |  | range -922337203685477..922337203685477; 0 decimals |
| `pum_budget` | Money |  | range -922337203685477..922337203685477; 0 decimals |
| `pum_comment` | String |  | max length 4000 |
| `pum_currentphase` | String |  | max length 150 |
| `_pum_initiative_value` | Lookup |  | Lookup → pum_initiative; write `pum_Initiative@odata.bind` = `/pum_initiatives({id})` |
| `pum_kpicurrentcost` | Picklist |  |  |
| `pum_kpicurrentquality` | Picklist |  |  |
| `pum_kpicurrentresources` | Picklist |  |  |
| `pum_kpicurrentschedule` | Picklist |  |  |
| `pum_kpicurrentscope` | Picklist |  |  |
| `pum_kpicurrentsummary` | Picklist |  |  |
| `pum_kpinewcost` | Picklist |  |  |
| `pum_kpinewcostcomment` | String |  | max length 4000 |
| `pum_kpinewquality` | Picklist |  |  |
| `pum_kpinewqualitycomment` | String |  | max length 4000 |
| `pum_kpinewresources` | Picklist |  |  |
| `pum_kpinewresourcescomment` | String |  | max length 4000 |
| `pum_kpinewschedule` | Picklist |  |  |
| `pum_kpinewschedulecomment` | String |  | max length 4000 |
| `pum_kpinewscope` | Picklist |  |  |
| `pum_kpinewscopecomment` | String |  | max length 4000 |
| `pum_kpinewsummary` | Picklist |  |  |
| `_pum_program_value` | Lookup |  | Lookup → pum_program; write `pum_Program@odata.bind` = `/pum_programs({id})` |
| `pum_scheduleprogress` | Integer |  | range -2147483648..2147483647 |
| `pum_seeddata` | String |  | max length 100 |
| `pum_statuscategory` | Picklist |  |  |
| `pum_statusdate` | DateTime (date-only) |  | date (ISO 8601) |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `_transactioncurrencyid_value` | Lookup |  | Lookup → transactioncurrency; write `TransactionCurrencyId@odata.bind` = `/transactioncurrencies({id})` |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_kpicurrentcost` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpicurrentquality` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpicurrentresources` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpicurrentschedule` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpicurrentscope` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpicurrentsummary` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpinewcost` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpinewquality` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpinewresources` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpinewschedule` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpinewscope` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpinewsummary` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_statuscategory` choices

| Value | Label |
|---|---|
| 493840000 | Bi-Weekly Status |
| 493840001 | Gate Decision |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
