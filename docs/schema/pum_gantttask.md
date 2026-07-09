<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_gantttask`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_gantttask -->

# PumGantttask (`pum_gantttask`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 200 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_gantttaskid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `context_taskbudget` | Money |  | range 0..922337203685477; 2 decimals |
| `_createdby_value` | Lookup |  | Lookup → systemuser; write `CreatedBy@odata.bind` = `/systemusers({id})` |
| `createdon` | DateTime |  | date-time (ISO 8601) |
| `_createdonbehalfby_value` | Lookup |  | Lookup → systemuser; write `CreatedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `exchangerate` | Decimal |  | range 1e-10..100000000000; 12 decimals |
| `importsequencenumber` | Integer |  | range -2147483648..2147483647 |
| `_modifiedby_value` | Lookup |  | Lookup → systemuser; write `ModifiedBy@odata.bind` = `/systemusers({id})` |
| `modifiedon` | DateTime |  | date-time (ISO 8601) |
| `_modifiedonbehalfby_value` | Lookup |  | Lookup → systemuser; write `ModifiedOnBehalfBy@odata.bind` = `/systemusers({id})` |
| `overriddencreatedon` | DateTime (date-only) |  | date (ISO 8601) |
| `_owningbusinessunit_value` | Lookup |  | Lookup → businessunit; write `OwningBusinessUnit@odata.bind` = `/businessunits({id})` |
| `pum_actual_dec` | Decimal |  | range -100000000000..100000000000; 4 decimals |
| `pum_actualfinish` | DateTime |  | date-time (ISO 8601) |
| `pum_actualstart` | DateTime |  | date-time (ISO 8601) |
| `pum_actworktask` | Integer |  | range -2147483648..2147483647 |
| `pum_baseline1description` | String |  | max length 250 |
| `pum_baseline1duration` | Integer |  | range 0..2147483647 |
| `pum_baseline1finish` | DateTime |  | date-time (ISO 8601) |
| `pum_baseline1name` | String |  | max length 100 |
| `pum_baseline1start` | DateTime |  | date-time (ISO 8601) |
| `pum_baseline2description` | String |  | max length 250 |
| `pum_baseline2duration` | Integer |  | range 0..2147483647 |
| `pum_baseline2finish` | DateTime |  | date-time (ISO 8601) |
| `pum_baseline2name` | String |  | max length 100 |
| `pum_baseline2start` | DateTime |  | date-time (ISO 8601) |
| `pum_baseline3description` | String |  | max length 100 |
| `pum_baseline3duration` | Integer |  | range 0..2147483647 |
| `pum_baseline3finish` | DateTime |  | date-time (ISO 8601) |
| `pum_baseline3name` | String |  | max length 100 |
| `pum_baseline3start` | DateTime |  | date-time (ISO 8601) |
| `pum_baseline4description` | String |  | max length 100 |
| `pum_baseline4duration` | Integer |  | range 0..2147483647 |
| `pum_baseline4finish` | DateTime |  | date-time (ISO 8601) |
| `pum_baseline4name` | String |  | max length 100 |
| `pum_baseline4start` | DateTime |  | date-time (ISO 8601) |
| `pum_baseline5description` | String |  | max length 100 |
| `pum_baseline5duration` | Integer |  | range 0..2147483647 |
| `pum_baseline5finish` | DateTime |  | date-time (ISO 8601) |
| `pum_baseline5name` | String |  | max length 100 |
| `pum_baseline5start` | DateTime |  | date-time (ISO 8601) |
| `pum_changedhash` | String |  | max length 250 |
| `pum_constraintdate` | DateTime |  | date-time (ISO 8601) |
| `pum_constrainttype` | Picklist |  |  |
| `pum_critical_manual` | Picklist |  |  |
| `pum_deadline` | DateTime |  | date-time (ISO 8601) |
| `pum_dependsafter` | String |  | max length 100 |
| `pum_duration` | Integer |  | range 0..2147483647 |
| `pum_durationunit` | String |  | max length 100 |
| `pum_elapsedduration` | Boolean |  |  |
| `pum_enablesplit` | Boolean |  |  |
| `pum_enddate` | DateTime |  | date-time (ISO 8601) |
| `pum_gantttasktextid` | String |  | max length 4000 |
| `pum_gantttemplateflow` | Boolean |  |  |
| `_pum_ganttversion_value` | Lookup |  | Lookup → pum_ganttversion; write `pum_GanttVersion@odata.bind` = `/pum_ganttversions({id})` |
| `pum_hiddenactualwork` | Decimal |  | range -100000000000..100000000000; 4 decimals |
| `pum_ignoretasksequence` | Boolean |  |  |
| `_pum_initiative_value` | Lookup |  | Lookup → pum_initiative; write `pum_initiative@odata.bind` = `/pum_initiatives({id})` |
| `pum_kanbanprogresscomplete` | Integer |  | range -2147483648..2147483647 |
| `pum_kanbanstatus` | Picklist |  |  |
| `pum_lastpublishedversion` | String |  | max length 850 |
| `pum_notes` | String |  | max length 4000 |
| `_pum_originaltaskid_version_value` | Lookup |  | Lookup → pum_gantttask; write `pum_OriginalTaskId_Version@odata.bind` = `/pum_gantttasks({id})` |
| `pum_parenttaskid` | String |  | max length 100 |
| `pum_percentcomplete` | Integer |  | range 0..100 |
| `pum_percentcompletekanban` | Integer |  | range -2147483648..2147483647 |
| `pum_plannertaskid` | String |  | max length 512 |
| `_pum_portfolio_value` | Lookup |  | Lookup → pum_portfolio; write `pum_portfolio@odata.bind` = `/pum_portfolios({id})` |
| `_pum_powergantttemplate_id_value` | Lookup |  | Lookup → pum_powergantttemplate; write `pum_powergantttemplate_id@odata.bind` = `/pum_powergantttemplates({id})` |
| `pum_priority` | Integer |  | range -2147483648..2147483647 |
| `_pum_program_value` | Lookup |  | Lookup → pum_program; write `pum_program@odata.bind` = `/pum_programs({id})` |
| `pum_remaining_work_dec` | Decimal |  | range -100000000000..100000000000; 4 decimals |
| `pum_remainingwork` | Integer |  | range -2147483648..2147483647 |
| `pum_seeddata` | String |  | max length 100 |
| `pum_sortorder` | String |  | max length 100 |
| `pum_startdate` | DateTime |  | date-time (ISO 8601) |
| `_pum_systemuser_value` | Lookup |  | Lookup → systemuser; write `pum_SystemUser@odata.bind` = `/systemusers({id})` |
| `pum_taskcategory` | Picklist |  |  |
| `pum_taskformatting` | String |  | max length 2000 |
| `pum_taskindex` | String |  | max length 100 |
| `pum_tasksequence` | Decimal |  | range 0..100000000000; 9 decimals |
| `pum_tasksortingprogram` | Integer |  | range -2147483648..2147483647 |
| `pum_tasktype` | Picklist |  |  |
| `pum_userpriority` | Integer |  | range -2147483648..2147483647 |
| `pum_wbs` | String |  | max length 100 |
| `pum_work` | Integer |  | range -2147483648..2147483647 |
| `pum_work_dec` | Decimal |  | range -100000000000..100000000000; 4 decimals |
| `_pum_workpackage_value` | Lookup |  | Lookup → pum_workpackage; write `pum_WorkPackage@odata.bind` = `/pum_workpackages({id})` |
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

### `pum_constrainttype` choices

| Value | Label |
|---|---|
| 493840000 | ALAP |
| 493840001 | ASAP |
| 493840002 | FNET |
| 493840003 | FNLT |
| 493840004 | MFO |
| 493840005 | MSO |
| 493840006 | SNET |
| 493840007 | SNLT |

### `pum_critical_manual` choices

| Value | Label |
|---|---|
| 493840000 | Yes |

### `pum_kanbanstatus` choices

| Value | Label |
|---|---|
| 493840000 | 1. To Do |
| 493840001 | 2. In Progress |
| 493840002 | 3. Done |

### `pum_taskcategory` choices

| Value | Label |
|---|---|
| 493840000 | Tasks |
| 493840001 | Legal |
| 493840002 | Gate |
| 493840003 | Key Milestone |
| 493840004 | Key Deliverable |

### `pum_tasktype` choices

| Value | Label |
|---|---|
| 493840000 | task |
| 493840001 | project |
| 493840002 | milestone |
| 493840003 | projectSummary |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
