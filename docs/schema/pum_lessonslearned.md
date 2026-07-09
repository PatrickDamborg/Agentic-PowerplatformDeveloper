<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_lessonslearned`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_lessonslearned -->

# PumLessonslearned (`pum_lessonslearned`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 850 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_lessonslearnedid` | Uniqueidentifier | ✓ |  |
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
| `pum_description` | Memo |  | max length 2000 |
| `pum_impact` | Picklist |  |  |
| `_pum_initiative_value` | Lookup |  | Lookup → pum_initiative; write `pum_Initiative@odata.bind` = `/pum_initiatives({id})` |
| `pum_learningcategory` | Picklist |  |  |
| `pum_seeddata` | String |  | max length 100 |
| `_pum_task_value` | Lookup |  | Lookup → task; write `pum_Task@odata.bind` = `/tasks({id})` |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_impact` choices

| Value | Label |
|---|---|
| 493840000 | Positive |
| 493840001 | Negative |
| 493840002 | Neutral |

### `pum_learningcategory` choices

| Value | Label |
|---|---|
| 493840000 | Project Management |
| 493840001 | Team Collaboration |
| 493840002 | Risks and Issues |
| 493840003 | Skills and Knowledge |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
