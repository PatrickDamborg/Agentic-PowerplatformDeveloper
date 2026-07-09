<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_risk`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_risk -->

# PumRisk (`pum_risk`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_riskid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `context_aigrounding` | Picklist |  |  |
| `_context_msdyn_project_value` | Lookup |  | Lookup → msdyn_project; write `context_msdyn_project@odata.bind` = `/msdyn_projects({id})` |
| `_createdby_value` | Lookup |  | Lookup → systemuser; write `CreatedBy@odata.bind` = `/systemusers({id})` |
| `createdon` | DateTime |  | date-time (ISO 8601) |
| `_createdonbehalfby_value` | Lookup |  | Lookup → systemuser; write `CreatedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `exchangerate` | Decimal |  | range 1e-10..100000000000; 10 decimals |
| `importsequencenumber` | Integer |  | range -2147483648..2147483647 |
| `_modifiedby_value` | Lookup |  | Lookup → systemuser; write `ModifiedBy@odata.bind` = `/systemusers({id})` |
| `modifiedon` | DateTime (date-only) |  | date (ISO 8601) |
| `_modifiedonbehalfby_value` | Lookup |  | Lookup → systemuser; write `ModifiedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `overriddencreatedon` | DateTime (date-only) |  | date (ISO 8601) |
| `_owningbusinessunit_value` | Lookup |  | Lookup → businessunit; write `OwningBusinessUnit@odata.bind` = `/businessunits({id})` |
| `pum_id` | String |  | max length 100 |
| `_pum_initiative_value` | Lookup |  | Lookup → pum_initiative; write `pum_Initiative@odata.bind` = `/pum_initiatives({id})` |
| `_pum_portfolio_value` | Lookup |  | Lookup → pum_portfolio; write `pum_Portfolio@odata.bind` = `/pum_portfolios({id})` |
| `pum_probability` | Picklist |  |  |
| `_pum_program_value` | Lookup |  | Lookup → pum_program; write `pum_Program@odata.bind` = `/pum_programs({id})` |
| `pum_riskcost` | Money |  | range -922337203685477..922337203685477; 0 decimals |
| `pum_riskdescription` | String |  | max length 100 |
| `pum_riskduedate` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_riskimpact` | Picklist |  |  |
| `pum_riskmitigation` | Memo |  | max length 2000 |
| `pum_risksid` | String |  | max length 100 |
| `pum_riskstatus` | Picklist |  |  |
| `pum_risktype` | Picklist |  |  |
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

### `context_aigrounding` choices

| Value | Label |
|---|---|
| 236150000 | Yes |
| 236150001 | No |

### `pum_probability` choices

| Value | Label |
|---|---|
| 976880000 | 0% |
| 976880001 | 20% |
| 976880002 | 40% |
| 976880003 | 60% |
| 976880004 | 80% |
| 976880005 | 100% |

### `pum_riskimpact` choices

| Value | Label |
|---|---|
| 976880000 | 1 - Very low |
| 976880001 | 2 - Low |
| 976880002 | 3 - Medium |
| 976880003 | 4 - High |
| 976880004 | 5 - Extreme |

### `pum_riskstatus` choices

| Value | Label |
|---|---|
| 493840000 | 🔍 Identified |
| 493840001 | 🅰️ Active |
| 493840002 | 🟩 Mitigated |
| 493840003 | ✔️ Resolved |
| 436130000 | ⚠️ Issue |

### `pum_risktype` choices

| Value | Label |
|---|---|
| 493840000 | Initiative |
| 493840001 | Program |
| 493840002 | Portfolio |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
