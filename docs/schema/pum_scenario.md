<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_scenario`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_scenario -->

# PumScenario (`pum_scenario`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 850 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `_owningbusinessunit_value` | Lookup | ✓ | Lookup → businessunit; write `OwningBusinessUnit@odata.bind` = `/businessunits({id})` |
| `pum_scenarioid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `_context_portfolio_value` | Lookup |  | Lookup → pum_portfolio; write `context_Portfolio@odata.bind` = `/pum_portfolios({id})` |
| `_createdby_value` | Lookup |  | Lookup → systemuser; write `CreatedBy@odata.bind` = `/systemusers({id})` |
| `createdon` | DateTime |  | date-time (ISO 8601) |
| `_createdonbehalfby_value` | Lookup |  | Lookup → systemuser; write `CreatedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `importsequencenumber` | Integer |  | range -2147483648..2147483647 |
| `_modifiedby_value` | Lookup |  | Lookup → systemuser; write `ModifiedBy@odata.bind` = `/systemusers({id})` |
| `modifiedon` | DateTime |  | date-time (ISO 8601) |
| `_modifiedonbehalfby_value` | Lookup |  | Lookup → systemuser; write `ModifiedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `overriddencreatedon` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_capturedat` | DateTime |  | date-time (ISO 8601) |
| `pum_columncount` | Integer |  | range 0..1000 |
| `pum_planofrecord` | Boolean |  |  |
| `pum_profilekey` | String |  | max length 100 |
| `_pum_scenariobaseline_value` | Lookup |  | Lookup → pum_scenariobaseline; write `pum_ScenarioBaseline@odata.bind` = `/pum_scenariobaselines({id})` |
| `pum_scenarioconfigjson` | Memo |  | max length 100000 |
| `pum_scenarioconstraintlimit` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_scenarioconstrainttype` | Picklist |  |  |
| `pum_scenariodeltasjson` | Memo |  | max length 100000 |
| `pum_scenariogranularity` | Picklist |  |  |
| `pum_scenarioname` | String |  | max length 850 |
| `pum_selectedcount` | Integer |  | range 0..1000000 |
| `pum_status` | Picklist |  |  |
| `pum_testrunid` | String |  | max length 64 |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_scenarioconstrainttype` choices

| Value | Label |
|---|---|
| 493840000 | None |
| 493840001 | Budget |
| 493840002 | ResourceCapacity |

### `pum_scenariogranularity` choices

| Value | Label |
|---|---|
| 493840000 | Month |
| 493840001 | Quarter |

### `pum_status` choices

| Value | Label |
|---|---|
| 493840000 | Draft |
| 493840001 | In Review |
| 493840002 | Approved |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
