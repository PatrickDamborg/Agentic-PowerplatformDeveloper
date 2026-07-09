<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_dependency`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_dependency -->

# PumDependency (`pum_dependency`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String |  | **NAME**; max length 500 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_dependencyid` | Uniqueidentifier | ✓ |  |
| `pum_duedate` | DateTime (date-only) | ✓ | date (ISO 8601) |
| `_pum_from_value` | Lookup | ✓ | Lookup → pum_idea, pum_initiative, pum_program; write `pum_From@odata.bind` = `/pum_ideas({id})`, `/pum_initiatives({id})`, `/pum_programs({id})` |
| `_pum_to_value` | Lookup | ✓ | Lookup → pum_idea, pum_initiative, pum_program; write `pum_To@odata.bind` = `/pum_ideas({id})`, `/pum_initiatives({id})`, `/pum_programs({id})` |
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
| `pum_category` | Picklist |  |  |
| `pum_kpi` | Picklist |  |  |
| `pum_seeddata` | String |  | max length 100 |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_category` choices

| Value | Label |
|---|---|
| 493840000 | Resource-based |
| 493840001 | Schedule-based |
| 493840002 | Technical |
| 493840003 | Customer/Stakeholder |

### `pum_kpi` choices

| Value | Label |
|---|---|
| 493840001 | ⚪ Not Set |
| 100000001 | 🟢 On Track |
| 100000002 | 🟡 Needs Attention |
| 100000003 | 🔴 Delayed with major issues |
| 100000005 | ✅ Completed |
| 100000004 | ⚪ Not Relevant |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
