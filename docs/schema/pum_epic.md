<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_epic`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_epic -->

# PumEpic (`pum_epic`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_epicid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `context_estimatedhours` | Integer |  | range -2147483648..2147483647 |
| `context_mustrun` | Boolean |  |  |
| `_context_pum_portfolio_value` | Lookup |  | Lookup → pum_portfolio; write `context_pum_Portfolio@odata.bind` = `/pum_portfolios({id})` |
| `context_roadmaprank` | Integer |  | range -2147483648..2147483647 |
| `context_roi` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `context_selected` | Boolean |  |  |
| `context_totalbenefits3y` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `context_totalbudget` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `_createdby_value` | Lookup |  | Lookup → systemuser; write `CreatedBy@odata.bind` = `/systemusers({id})` |
| `createdon` | DateTime |  | date-time (ISO 8601) |
| `_createdonbehalfby_value` | Lookup |  | Lookup → systemuser; write `CreatedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `exchangerate` | Decimal |  | range 1e-10..100000000000; 12 decimals |
| `importsequencenumber` | Integer |  | range -2147483648..2147483647 |
| `_modifiedby_value` | Lookup |  | Lookup → systemuser; write `ModifiedBy@odata.bind` = `/systemusers({id})` |
| `modifiedon` | DateTime |  | date-time (ISO 8601) |
| `_modifiedonbehalfby_value` | Lookup |  | Lookup → systemuser; write `ModifiedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `overriddencreatedon` | DateTime (date-only) |  | date (ISO 8601) |
| `_owningbusinessunit_value` | Lookup |  | Lookup → businessunit; write `OwningBusinessUnit@odata.bind` = `/businessunits({id})` |
| `pum_acceptancecriteria` | Memo |  | max length 4000 |
| `pum_currentstage` | Picklist |  |  |
| `pum_description` | Memo |  | max length 4000 |
| `pum_epicfinishdate` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_epicstartdate` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_marketfit` | Integer |  | range 0..10 |
| `pum_marketfitdescription` | Memo |  | max length 2000 |
| `_pum_product_value` | Lookup |  | Lookup → pum_product; write `pum_Product@odata.bind` = `/pum_products({id})` |
| `pum_revenuegrowth` | Integer |  | range 0..10 |
| `pum_revenuegrowthdescription` | Memo |  | max length 2000 |
| `pum_seeddata` | String |  | max length 100 |
| `pum_strategicfit` | Integer |  | range 0..10 |
| `pum_strategicfitdescription` | Memo |  | max length 2000 |
| `pum_urlagiletool` | String |  | format: url; max length 1000 |
| `pum_workitemid` | String |  | max length 100 |
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

### `pum_currentstage` choices

| Value | Label |
|---|---|
| 493840000 | 1. Funnel |
| 493840001 | 2. Reviewing |
| 493840002 | 3. Analyzing |
| 493840003 | 4. Backlog |
| 493840004 | 5. Implementing |
| 493840005 | 6. Done |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
