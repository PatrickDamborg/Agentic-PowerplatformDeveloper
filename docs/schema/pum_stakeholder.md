<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_stakeholder`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_stakeholder -->

# PumStakeholder (`pum_stakeholder`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_stakeholderid` | Uniqueidentifier | ✓ |  |
| `pum_stakeholdertype` | Picklist | ✓ |  |
| `statecode` | State | ✓ |  |
| `_context_msdyn_project_value` | Lookup |  | Lookup → msdyn_project; write `context_msdyn_project@odata.bind` = `/msdyn_projects({id})` |
| `_createdby_value` | Lookup |  | Lookup → systemuser; write `CreatedBy@odata.bind` = `/systemusers({id})` |
| `createdon` | DateTime |  | date-time (ISO 8601) |
| `_createdonbehalfby_value` | Lookup |  | Lookup → systemuser; write `CreatedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `importsequencenumber` | Integer |  | range -2147483648..2147483647 |
| `_modifiedby_value` | Lookup |  | Lookup → systemuser; write `ModifiedBy@odata.bind` = `/systemusers({id})` |
| `modifiedon` | DateTime |  | date-time (ISO 8601) |
| `_modifiedonbehalfby_value` | Lookup |  | Lookup → systemuser; write `ModifiedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `overriddencreatedon` | DateTime (date-only) |  | date (ISO 8601) |
| `_owningbusinessunit_value` | Lookup |  | Lookup → businessunit; write `OwningBusinessUnit@odata.bind` = `/businessunits({id})` |
| `pum_emailexternal` | String |  | format: email; max length 200 |
| `pum_influence` | Picklist |  |  |
| `_pum_initiative_value` | Lookup |  | Lookup → pum_initiative; write `pum_Initiative@odata.bind` = `/pum_initiatives({id})` |
| `pum_interest` | Picklist |  |  |
| `_pum_program_value` | Lookup |  | Lookup → pum_program; write `pum_Program@odata.bind` = `/pum_programs({id})` |
| `pum_seeddata` | String |  | max length 100 |
| `pum_stakeholder_id` | String |  | max length 100 |
| `pum_stakeholderinitials` | String |  | max length 4000 |
| `_pum_userinternal_value` | Lookup |  | Lookup → systemuser; write `pum_UserInternal@odata.bind` = `/systemusers({id})` |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `pum_stakeholdertype` choices

| Value | Label |
|---|---|
| 493840000 | Internal |
| 493840001 | External |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `pum_influence` choices

| Value | Label |
|---|---|
| 493840001 | 1 - Low |
| 493840002 | 2 - Medium |
| 493840003 | 3 - High |

### `pum_interest` choices

| Value | Label |
|---|---|
| 493840001 | 1 - Low |
| 493840002 | 2 - Medium |
| 493840003 | 3 - High |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
