<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_pf_customcolumndata`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_pf_customcolumndata -->

# PumPfCustomcolumndata (`pum_pf_customcolumndata`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_customcolumnname` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_pf_customcolumndataid` | Uniqueidentifier | ✓ |  |
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
| `pum_decimal_value` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `_pum_financialstructure_value` | Lookup |  | Lookup → pum_financialstructure; write `pum_FinancialStructure@odata.bind` = `/pum_financialstructures({id})` |
| `_pum_pf_costcategory_value` | Lookup |  | Lookup → pum_pf_costcategory; write `pum_pf_CostCategory@odata.bind` = `/pum_pf_costcategories({id})` |
| `pum_pf_costleveltype` | Picklist |  |  |
| `_pum_pf_costmappingpolymorph_value` | Lookup |  | Lookup → pum_pf_costarea, pum_pf_costcategory, pum_pf_costspecification; write `pum_pf_costmappingpolymorph@odata.bind` = `/pum_pf_costareas({id})`, `/pum_pf_costcategories({id})`, `/pum_pf_costspecifications({id})` |
| `_pum_pf_costspecification_value` | Lookup |  | Lookup → pum_pf_costspecification; write `pum_pf_CostSpecification@odata.bind` = `/pum_pf_costspecifications({id})` |
| `pum_pf_customcolumndata_value` | String |  | max length 100 |
| `pum_pf_customcolumnrowid` | String |  | max length 256 |
| `_pum_pf_project_customcolumn_value` | Lookup |  | Lookup → pum_initiative; write `pum_pf_project_customcolumn@odata.bind` = `/pum_initiatives({id})` |
| `pum_pf_rowid` | String |  | max length 100 |
| `_pum_program_value` | Lookup |  | Lookup → pum_program; write `pum_Program@odata.bind` = `/pum_programs({id})` |
| `pum_valuedisplayname` | String |  | max length 100 |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_pf_costleveltype` choices

| Value | Label |
|---|---|
| 493840000 | 1 |
| 493840001 | 2 |
| 493840002 | 3 |
| 493840003 | 4 |
| 493840004 | 5 |
| 493840005 | 6 |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
