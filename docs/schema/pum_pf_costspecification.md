<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_pf_costspecification`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_pf_costspecification -->

# PumPfCostspecification (`pum_pf_costspecification`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_costspecification` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_pf_costspecificationdef` | Integer | ✓ | range -2147483648..2147483647 |
| `pum_pf_costspecificationid` | Uniqueidentifier | ✓ |  |
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
| `pum_aggregationfortotals` | Picklist |  |  |
| `pum_costunitdefinition` | Picklist |  |  |
| `_pum_defaultfinancialunit_value` | Lookup |  | Lookup → pum_pf_unit; write `pum_DefaultFinancialUnit@odata.bind` = `/pum_pf_units({id})` |
| `_pum_financialstructure_value` | Lookup |  | Lookup → pum_financialstructure; write `pum_FinancialStructure@odata.bind` = `/pum_financialstructures({id})` |
| `_pum_parentcostspecification_value` | Lookup |  | Lookup → pum_pf_costspecification; write `pum_ParentCostSpecification@odata.bind` = `/pum_pf_costspecifications({id})` |
| `pum_pf_costspec_order` | Integer |  | range -2147483648..2147483647 |
| `_pum_pf_costspec_pf_costarea_value` | Lookup |  | Lookup → pum_pf_costarea; write `pum_pf_costspec_pf_costarea@odata.bind` = `/pum_pf_costareas({id})` |
| `_pum_pf_costspec_pf_costcategory_value` | Lookup |  | Lookup → pum_pf_costcategory; write `pum_pf_costspec_pf_costcategory@odata.bind` = `/pum_pf_costcategories({id})` |
| `_pum_pf_initiative_costspecification_value` | Lookup |  | Lookup → pum_initiative; write `pum_pf_initiative_costspecification@odata.bind` = `/pum_initiatives({id})` |
| `_pum_program_value` | Lookup |  | Lookup → pum_program; write `pum_Program@odata.bind` = `/pum_programs({id})` |
| `_pum_transactioncurrency_pum_pf_costsp_value` | Lookup |  | Lookup → transactioncurrency; write `pum_TransactionCurrency_pum_pf_costsp@odata.bind` = `/transactioncurrencies({id})` |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_aggregationfortotals` choices

| Value | Label |
|---|---|
| 493840000 | SUM |
| 493840001 | AVERAGE |
| 493840002 | HIDE |

### `pum_costunitdefinition` choices

| Value | Label |
|---|---|
| 493840000 | Positive numbers |
| 493840001 | Negative numbers |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
