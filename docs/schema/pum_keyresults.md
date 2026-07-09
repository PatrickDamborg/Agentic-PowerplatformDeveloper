<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_keyresults`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_keyresults -->

# PumKeyresults (`pum_keyresults`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_keyresultsid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `context_aigoalsummary` | Memo |  | max length 40000 |
| `context_aiprogresssummary` | Memo |  | max length 20000 |
| `_context_portfolio_value` | Lookup |  | Lookup → pum_portfolio; write `context_Portfolio@odata.bind` = `/pum_portfolios({id})` |
| `_context_pum_idea_value` | Lookup |  | Lookup → pum_idea; write `context_pum_Idea@odata.bind` = `/pum_ideas({id})` |
| `_context_pum_program_value` | Lookup |  | Lookup → pum_program; write `context_pum_Program@odata.bind` = `/pum_programs({id})` |
| `_createdby_value` | Lookup |  | Lookup → systemuser; write `CreatedBy@odata.bind` = `/systemusers({id})` |
| `createdon` | DateTime |  | date-time (ISO 8601) |
| `_createdonbehalfby_value` | Lookup |  | Lookup → systemuser; write `CreatedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `importsequencenumber` | Integer |  | range -2147483648..2147483647 |
| `_modifiedby_value` | Lookup |  | Lookup → systemuser; write `ModifiedBy@odata.bind` = `/systemusers({id})` |
| `modifiedon` | DateTime |  | date-time (ISO 8601) |
| `_modifiedonbehalfby_value` | Lookup |  | Lookup → systemuser; write `ModifiedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `overriddencreatedon` | DateTime (date-only) |  | date (ISO 8601) |
| `_owningbusinessunit_value` | Lookup |  | Lookup → businessunit; write `OwningBusinessUnit@odata.bind` = `/businessunits({id})` |
| `processid` | Uniqueidentifier |  |  |
| `pum_currentvalue` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_description` | String |  | max length 500 |
| `pum_duedate` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_improvementdelta` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_measureasa` | Picklist |  |  |
| `pum_performance` | Picklist |  |  |
| `pum_realization` | String |  | max length 150 |
| `pum_realizationwholenumber` | Integer |  | range -2147483648..2147483647 |
| `pum_seeddata` | String |  | max length 100 |
| `pum_startdate` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_startvalue` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `_pum_strategicobjectives_value` | Lookup |  | Lookup → pum_strategicobjectives; write `pum_StrategicObjectives@odata.bind` = `/pum_strategicobjectiveses({id})` |
| `pum_targetvalue` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `_stageid_value` | Uniqueidentifier |  | Lookup → processstage; write `stageid@odata.bind` = `/processstages({id})` |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `traversedpath` | String |  | max length 1250 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_measureasa` choices

| Value | Label |
|---|---|
| 493840000 | % Percentage |
| 493840001 | # Numerical |
| 493840002 | Currency |

### `pum_performance` choices

| Value | Label |
|---|---|
| 493840000 | 🟢 On Track |
| 493840001 | 🟡 Needs Attention |
| 493840002 | 🔴 Off Track |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
