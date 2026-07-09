<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_pf_powerfinancialsdata`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_pf_powerfinancialsdata -->

# PumPfPowerfinancialsdata (`pum_pf_powerfinancialsdata`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_pf_powerfinancialsdata_name` | String |  | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `_pum_pf_costcategory_value` | Lookup | ✓ | Lookup → pum_pf_costcategory; write `pum_pf_costcategory@odata.bind` = `/pum_pf_costcategories({id})` |
| `_pum_pf_costtype_value` | Lookup | ✓ | Lookup → pum_pf_costtype; write `pum_pf_costtype@odata.bind` = `/pum_pf_costtypes({id})` |
| `pum_pf_month` | Integer | ✓ | range -2147483648..2147483647 |
| `pum_pf_powerfinancialsdataid` | Uniqueidentifier | ✓ |  |
| `pum_pf_value` | Money | ✓ | range -922337203685477..922337203685477; 4 decimals |
| `pum_pf_year` | Integer | ✓ | range -2147483648..2147483647 |
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
| `pum_amount` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `_pum_customcosthierarchy_value` | Lookup |  | Lookup → pum_customcosthierarchy; write `pum_CustomCostHierarchy@odata.bind` = `/pum_customcosthierarchies({id})` |
| `_pum_financialstructure_value` | Lookup |  | Lookup → pum_financialstructure; write `pum_FinancialStructure@odata.bind` = `/pum_financialstructures({id})` |
| `_pum_pf_costarea_value` | Lookup |  | Lookup → pum_pf_costarea; write `pum_pf_costarea@odata.bind` = `/pum_pf_costareas({id})` |
| `pum_pf_costareadef` | Integer |  | range -2147483648..2147483647 |
| `pum_pf_costcategorydef` | Integer |  | range -2147483648..2147483647 |
| `pum_pf_costlevelmapping_customcolumns` | String |  | max length 100 |
| `_pum_pf_costplan_version_value` | Lookup |  | Lookup → pum_pf_costplan_version; write `pum_pf_costplan_version@odata.bind` = `/pum_pf_costplan_versions({id})` |
| `_pum_pf_costspecification_value` | Lookup |  | Lookup → pum_pf_costspecification; write `pum_pf_costspecification@odata.bind` = `/pum_pf_costspecifications({id})` |
| `pum_pf_costspecificationdef` | Integer |  | range -2147483648..2147483647 |
| `pum_pf_costtypedef` | Integer |  | range -2147483648..2147483647 |
| `_pum_pf_initiative_value` | Lookup |  | Lookup → pum_initiative; write `pum_pf_initiative@odata.bind` = `/pum_initiatives({id})` |
| `_pum_pf_program_value` | Lookup |  | Lookup → pum_program; write `pum_pf_program@odata.bind` = `/pum_programs({id})` |
| `pum_pf_valuedec` | Decimal |  | range -100000000000..100000000000; 10 decimals |
| `pum_rateunit` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_seeddata` | String |  | max length 100 |
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

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
