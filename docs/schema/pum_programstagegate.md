<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_programstagegate`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_programstagegate -->

# PumProgramstagegate (`pum_programstagegate`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `bpf_name` | String | ✓ | **NAME**; max length 100 |
| `businessprocessflowinstanceid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `_activestageid_value` | Lookup |  | Lookup → processstage; write `ActiveStageId@odata.bind` = `/processstages({id})` |
| `activestagestartedon` | DateTime (date-only) |  | date (ISO 8601) |
| `bpf_duration` | Integer |  | range 0..2147483647 |
| `_bpf_pum_programid_value` | Lookup |  | Lookup → pum_program; write `bpf_pum_programid@odata.bind` = `/pum_programs({id})` |
| `completedon` | DateTime (date-only) |  | date (ISO 8601) |
| `_createdby_value` | Lookup |  | Lookup → systemuser; write `CreatedBy@odata.bind` = `/systemusers({id})` |
| `createdon` | DateTime |  | date-time (ISO 8601) |
| `_createdonbehalfby_value` | Lookup |  | Lookup → systemuser; write `CreatedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `importsequencenumber` | Integer |  | range -2147483648..2147483647 |
| `_modifiedby_value` | Lookup |  | Lookup → systemuser; write `ModifiedBy@odata.bind` = `/systemusers({id})` |
| `modifiedon` | DateTime |  | date-time (ISO 8601) |
| `_modifiedonbehalfby_value` | Lookup |  | Lookup → systemuser; write `ModifiedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `_organizationid_value` | Lookup |  | Lookup → organization; write `OrganizationId@odata.bind` = `/organizations({id})` |
| `overriddencreatedon` | DateTime (date-only) |  | date (ISO 8601) |
| `_processid_value` | Lookup |  | Lookup → workflow; write `ProcessId@odata.bind` = `/workflows({id})` |
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

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Finished |
| 3 | Aborted |
