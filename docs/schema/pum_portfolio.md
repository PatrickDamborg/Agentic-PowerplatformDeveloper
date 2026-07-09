<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_portfolio`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_portfolio -->

# PumPortfolio (`pum_portfolio`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_portfolio` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_portfolioid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `context_aiportfoliostatus1` | Memo |  | max length 2000 |
| `context_aiportfoliostatus2` | Memo |  | max length 4000 |
| `context_aiportfoliostatus3` | Memo |  | max length 30000 |
| `context_kpifinancials` | Picklist |  |  |
| `context_kpifunnel` | Picklist |  |  |
| `context_kpihealth` | Picklist |  |  |
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
| `pum_aiportfolioreport` | Memo |  | max length 10000 |
| `pum_aiportfoliosummary` | Boolean |  |  |
| `pum_description` | String |  | max length 500 |
| `pum_kpi` | Picklist |  |  |
| `pum_linktocalendaryear` | Picklist |  |  |
| `pum_ofinitiatives` | Integer |  | range -2147483648..2147483647 |
| `pum_ofinitiatives_date` | DateTime |  | date-time (ISO 8601) |
| `pum_ofinitiatives_state` | Integer |  | range -2147483648..2147483647 |
| `pum_portfoliotype` | Picklist |  |  |
| `_pum_primaryobjective_value` | Lookup |  | Lookup → pum_strategicobjectives; write `pum_PrimaryObjective@odata.bind` = `/pum_strategicobjectiveses({id})` |
| `pum_saveduisettingsforroadmap` | Memo |  | max length 1048576 |
| `pum_seeddata` | String |  | max length 100 |
| `pum_totalbudget` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `pum_workiteminportfolio` | Picklist |  |  |
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

### `context_kpifinancials` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `context_kpifunnel` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `context_kpihealth` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpi` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_linktocalendaryear` choices

| Value | Label |
|---|---|
| 493840000 | 2021 |
| 493840001 | 2022 |
| 493840002 | 2023 |
| 493840003 | 2024 |
| 493840004 | 2025 |

### `pum_portfoliotype` choices

| Value | Label |
|---|---|
| 493840000 | Run |
| 493840001 | Grow |
| 493840002 | Transform |

### `pum_workiteminportfolio` choices

| Value | Label |
|---|---|
| 493840001 | Program |
| 493840000 | Initiatives |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
