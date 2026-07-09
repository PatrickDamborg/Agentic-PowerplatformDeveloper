<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_assignment`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_assignment -->

# PumAssignment (`pum_assignment`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_taskname` | String | ✓ | **NAME**; max length 200 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_assignmentid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
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
| `pum_assignmentactualwork` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_assignmentrate` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `pum_assignmentwork` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `_pum_asstask_value` | Lookup |  | Lookup → pum_gantttask; write `pum_AssTask@odata.bind` = `/pum_gantttasks({id})` |
| `_pum_initiative_value` | Lookup |  | Lookup → pum_initiative; write `pum_Initiative@odata.bind` = `/pum_initiatives({id})` |
| `pum_kanbanstatus` | Picklist |  |  |
| `pum_percentcomplete` | Integer |  | range 0..100 |
| `_pum_portfolio1_value` | Lookup |  | Lookup → pum_portfolio; write `pum_Portfolio1@odata.bind` = `/pum_portfolios({id})` |
| `pum_priority` | Integer |  | range -2147483648..2147483647 |
| `_pum_program1_value` | Lookup |  | Lookup → pum_program; write `pum_Program1@odata.bind` = `/pum_programs({id})` |
| `_pum_resource_value` | Lookup |  | Lookup → pum_resource; write `pum_Resource@odata.bind` = `/pum_resources({id})` |
| `pum_seeddata` | String |  | max length 100 |
| `_pum_user_value` | Lookup |  | Lookup → systemuser; write `pum_User@odata.bind` = `/systemusers({id})` |
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

### `pum_kanbanstatus` choices

| Value | Label |
|---|---|
| 493840000 | 1. To Do |
| 493840001 | 2. In Progress |
| 493840002 | 3. Done |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
