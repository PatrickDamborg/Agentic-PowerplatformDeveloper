<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_pf_customrowdata`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_pf_customrowdata -->

# PumPfCustomrowdata (`pum_pf_customrowdata`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_customrowname` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_pf_customrowdataid` | Uniqueidentifier | ✓ |  |
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
| `pum_columnid` | String |  | max length 100 |
| `_pum_costplanversion_value` | Lookup |  | Lookup → pum_pf_costplan_version; write `pum_costplanversion@odata.bind` = `/pum_pf_costplan_versions({id})` |
| `pum_pf_calculationformula` | String |  | max length 1000 |
| `_pum_pf_costmappingpolymorph_value` | Lookup |  | Lookup → pum_pf_costarea, pum_pf_costcategory, pum_pf_costspecification; write `pum_pf_costmappingpolymorph@odata.bind` = `/pum_pf_costareas({id})`, `/pum_pf_costcategories({id})`, `/pum_pf_costspecifications({id})` |
| `_pum_pf_costtype_value` | Lookup |  | Lookup → pum_pf_costtype; write `pum_pf_costtype@odata.bind` = `/pum_pf_costtypes({id})` |
| `pum_pf_customrowid` | String |  | max length 100 |
| `pum_pf_forbusinesscase` | Boolean |  |  |
| `pum_pf_month` | Integer |  | range -2147483648..2147483647 |
| `_pum_pf_project_customrow_value` | Lookup |  | Lookup → pum_initiative; write `pum_pf_project_customrow@odata.bind` = `/pum_initiatives({id})` |
| `pum_pf_stringvalue` | String |  | max length 100 |
| `pum_pf_unit` | String |  | max length 100 |
| `pum_pf_value` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_pf_valuedisplayname` | String |  | max length 256 |
| `_pum_pf_version_value` | Lookup |  | Lookup → pum_pf_costplan_version; write `pum_pf_version@odata.bind` = `/pum_pf_costplan_versions({id})` |
| `pum_pf_year` | Integer |  | range -2147483648..2147483647 |
| `_pum_program_value` | Lookup |  | Lookup → pum_program; write `pum_Program@odata.bind` = `/pum_programs({id})` |
| `pum_valuecur` | Money |  | range -922337203685477..922337203685477; 0 decimals |
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
