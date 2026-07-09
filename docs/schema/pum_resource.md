<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_resource`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_resource -->

# PumResource (`pum_resource`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_resourceid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `_createdby_value` | Lookup |  | Lookup → systemuser; write `CreatedBy@odata.bind` = `/systemusers({id})` |
| `createdon` | DateTime |  | date-time (ISO 8601) |
| `_createdonbehalfby_value` | Lookup |  | Lookup → systemuser; write `CreatedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `exchangerate` | Decimal |  | range 1e-10..100000000000; 10 decimals |
| `importsequencenumber` | Integer |  | range -2147483648..2147483647 |
| `_modifiedby_value` | Lookup |  | Lookup → systemuser; write `ModifiedBy@odata.bind` = `/systemusers({id})` |
| `modifiedon` | DateTime |  | date-time (ISO 8601) |
| `_modifiedonbehalfby_value` | Lookup |  | Lookup → systemuser; write `ModifiedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `new_issynthetic` | Boolean |  |  |
| `overriddencreatedon` | DateTime (date-only) |  | date (ISO 8601) |
| `_owningbusinessunit_value` | Lookup |  | Lookup → businessunit; write `OwningBusinessUnit@odata.bind` = `/businessunits({id})` |
| `pum_additionalrbs` | String |  | max length 4000 |
| `pum_azureid` | String |  | max length 100 |
| `_pum_calendar_value` | Lookup |  | Lookup → pum_calendar; write `pum_Calendar@odata.bind` = `/pum_calendars({id})` |
| `pum_company` | String |  | max length 500 |
| `pum_dailycapacityhours` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_department` | String |  | max length 500 |
| `pum_earliestavailable` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_email` | String |  | format: email; max length 200 |
| `pum_firstname` | String |  | max length 200 |
| `pum_jobtitle` | String |  | max length 250 |
| `pum_lastname` | String |  | max length 250 |
| `pum_latestavailable` | DateTime (date-only) |  | date (ISO 8601) |
| `_pum_manager_value` | Lookup |  | Lookup → pum_resource; write `pum_Manager@odata.bind` = `/pum_resources({id})` |
| `pum_rate` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `_pum_rbs_value` | Lookup |  | Lookup → pum_rbs; write `pum_RBS@odata.bind` = `/pum_rbses({id})` |
| `_pum_relatedgenericresource_value` | Lookup |  | Lookup → pum_resource; write `pum_RelatedGenericResource@odata.bind` = `/pum_resources({id})` |
| `_pum_relateduser_value` | Lookup |  | Lookup → systemuser; write `pum_RelatedUser@odata.bind` = `/systemusers({id})` |
| `pum_resourcetype` | Picklist |  |  |
| `_pum_role_value` | Lookup |  | Lookup → pum_role; write `pum_Role@odata.bind` = `/pum_roles({id})` |
| `pum_seeddata` | String |  | max length 100 |
| `pum_syncsource` | Picklist |  |  |
| `pum_userprincipalname` | String |  | max length 250 |
| `pum_usertype` | String |  | max length 100 |
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

### `pum_resourcetype` choices

| Value | Label |
|---|---|
| 493840000 | Named |
| 493840001 | Generic |
| 493840002 | Role |
| 493840003 | Category |

### `pum_syncsource` choices

| Value | Label |
|---|---|
| 493840000 | Power PPM |
| 493840001 | Team Planner |
| 493840004 | Time for Teams |
| 493840002 | Microsoft Entra Id |
| 493840003 | Custom |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
