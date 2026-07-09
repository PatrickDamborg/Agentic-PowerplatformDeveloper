<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_initiative`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_initiative -->

# PumInitiative (`pum_initiative`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_initiativeid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `context_aifinancesummary` | Memo |  | max length 10000 |
| `context_airesourcesummary` | Memo |  | max length 8000 |
| `context_aischedulesummary` | Memo |  | max length 10000 |
| `context_approvalcomments` | String |  | max length 4000 |
| `context_approvaldate` | DateTime |  | date-time (ISO 8601) |
| `context_approvalstatus` | Picklist |  |  |
| `context_approvalsubmitstatus` | Picklist |  |  |
| `context_approved` | Boolean |  |  |
| `context_approvedby` | String |  | max length 100 |
| `context_approvedflow` | String |  | max length 100 |
| `context_country` | String |  | max length 200 |
| `context_createairisks` | String |  | max length 100 |
| `context_createreport` | String |  | max length 100 |
| `context_exeganttconfig` | Memo |  | max length 500000 |
| `context_markdownfinance` | Memo |  | max length 20000 |
| `context_moredetails` | Boolean |  |  |
| `context_mustrun` | Boolean |  |  |
| `context_nnfield` | String |  | format: url; max length 100 |
| `context_proposedhours` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `context_proposedhours_date` | DateTime |  | date-time (ISO 8601) |
| `context_proposedhours_state` | Integer |  | range -2147483648..2147483647 |
| `context_proposedhourssimple` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `context_regionalnews` | Memo |  | max length 50000 |
| `context_riskscore` | Integer |  | range 1..5 |
| `context_roadmaprank` | Integer |  | range -2147483648..2147483647 |
| `context_scheduledfinish` | DateTime |  | date-time (ISO 8601) |
| `context_scheduledfinish_date` | DateTime |  | date-time (ISO 8601) |
| `context_scheduledfinish_state` | Integer |  | range -2147483648..2147483647 |
| `context_scheduledfinishsimple` | DateTime (date-only) |  | date (ISO 8601) |
| `context_scheduledhoursimple` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `context_scheduledhourssimple` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `context_scheduledstart` | DateTime (date-only) |  | date (ISO 8601) |
| `context_scheduledstart_date` | DateTime |  | date-time (ISO 8601) |
| `context_scheduledstart_state` | Integer |  | range -2147483648..2147483647 |
| `context_scheduledstartsimple` | DateTime (date-only) |  | date (ISO 8601) |
| `context_selected` | Boolean |  |  |
| `context_totalresourcecommithours` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `context_totalresourcecommithours_date` | DateTime |  | date-time (ISO 8601) |
| `context_totalresourcecommithours_state` | Integer |  | range -2147483648..2147483647 |
| `context_totalschedulework` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `context_totalschedulework_date` | DateTime |  | date-time (ISO 8601) |
| `context_totalschedulework_state` | Integer |  | range -2147483648..2147483647 |
| `context_worktype` | String |  | max length 4000 |
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
| `processid` | Uniqueidentifier |  |  |
| `pum_actualcost` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `pum_agileproject` | String |  | max length 100 |
| `pum_budget` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `_pum_category_value` | Lookup |  | Lookup → pum_investmentcategory; write `pum_Category@odata.bind` = `/pum_investmentcategories({id})` |
| `pum_connectedplannerplan` | String |  | max length 512 |
| `pum_createasagile` | Picklist |  |  |
| `pum_createteam` | Boolean |  |  |
| `pum_currentstagetextfield` | String |  | max length 150 |
| `pum_description` | String |  | max length 500 |
| `pum_expectedbenefits` | Money |  | range -922337203685477..922337203685477; 0 decimals |
| `pum_generatereport` | Boolean |  |  |
| `pum_initiativefinish` | DateTime (date-only) |  | date (ISO 8601) |
| `_pum_initiativereadteam_value` | Lookup |  | Lookup → team; write `pum_InitiativeReadTeam@odata.bind` = `/teams({id})` |
| `_pum_initiativereadwriteteam_value` | Lookup |  | Lookup → team; write `pum_InitiativeReadWriteTeam@odata.bind` = `/teams({id})` |
| `pum_initiativestart` | DateTime (date-only) |  | date (ISO 8601) |
| `_pum_initiativetemplate_value` | Lookup |  | Lookup → pum_powergantttemplate; write `pum_Initiativetemplate@odata.bind` = `/pum_powergantttemplates({id})` |
| `pum_kanbanrank` | Integer |  | range -2147483648..2147483647 |
| `_pum_keyresults_value` | Lookup |  | Lookup → pum_keyresults; write `pum_KeyResults@odata.bind` = `/pum_keyresultses({id})` |
| `pum_kpicost` | Picklist |  |  |
| `pum_kpiquality` | Picklist |  |  |
| `pum_kpiresources` | Picklist |  |  |
| `pum_kpiscope` | Picklist |  |  |
| `pum_kpisummary` | Picklist |  |  |
| `pum_kpisummarycomment` | String |  | max length 2000 |
| `pum_kpisummaryforviews` | String |  | max length 100 |
| `pum_kpitimeline` | Picklist |  |  |
| `_pum_linkedidea_value` | Lookup |  | Lookup → pum_idea; write `pum_LinkedIdea@odata.bind` = `/pum_ideas({id})` |
| `pum_mustrun` | Boolean |  |  |
| `pum_newplannertasksparent` | String |  | max length 512 |
| `pum_okr` | Boolean |  |  |
| `pum_operationalproject` | Boolean |  |  |
| `_pum_portfolio_value` | Lookup |  | Lookup → pum_portfolio; write `pum_Portfolio@odata.bind` = `/pum_portfolios({id})` |
| `_pum_program_value` | Lookup |  | Lookup → pum_program; write `pum_program@odata.bind` = `/pum_programs({id})` |
| `pum_progressforrollup` | Integer |  | range -2147483648..2147483647 |
| `pum_projecttype` | Picklist |  |  |
| `pum_rank` | Integer |  | range -2147483648..2147483647 |
| `pum_realizedbenefits` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `pum_remotelinkagile` | String |  | format: url; max length 100 |
| `pum_roi` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_scheduleprogress` | Integer |  | range -2147483648..2147483647 |
| `pum_scheduleprogress_date` | DateTime |  | date-time (ISO 8601) |
| `pum_scheduleprogress_state` | Integer |  | range -2147483648..2147483647 |
| `pum_scheduleprogressin` | String |  | max length 4000 |
| `pum_scopequalified` | Boolean |  |  |
| `pum_seeddata` | String |  | max length 100 |
| `pum_selected` | Boolean |  |  |
| `pum_sharepointsite` | String |  | format: url; max length 500 |
| `_pum_sponsor_value` | Lookup |  | Lookup → systemuser; write `pum_Sponsor@odata.bind` = `/systemusers({id})` |
| `pum_stakeholderanalysis` | Boolean |  |  |
| `pum_status` | Picklist |  |  |
| `pum_strategicimpact` | Integer |  | range 1..10 |
| `pum_tasktool` | Picklist |  |  |
| `pum_teamschannel` | String |  | format: url; max length 500 |
| `pum_totalactualcost` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `pum_totalactualcost_date` | DateTime |  | date-time (ISO 8601) |
| `pum_totalactualcost_state` | Integer |  | range -2147483648..2147483647 |
| `pum_totalbudget` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `pum_totalbudget_date` | DateTime |  | date-time (ISO 8601) |
| `pum_totalbudget_state` | Integer |  | range -2147483648..2147483647 |
| `pum_totalexpectedbenefits` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `pum_totalexpectedbenefits_date` | DateTime |  | date-time (ISO 8601) |
| `pum_totalexpectedbenefits_state` | Integer |  | range -2147483648..2147483647 |
| `pum_totalforecast` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `pum_totalforecast_date` | DateTime |  | date-time (ISO 8601) |
| `pum_totalforecast_state` | Integer |  | range -2147483648..2147483647 |
| `pum_totalrealizedbenefits` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `pum_totalrealizedbenefits_date` | DateTime |  | date-time (ISO 8601) |
| `pum_totalrealizedbenefits_state` | Integer |  | range -2147483648..2147483647 |
| `pum_transferforexecutionagile` | Boolean |  |  |
| `_stageid_value` | Uniqueidentifier |  | Lookup → processstage; write `stageid@odata.bind` = `/processstages({id})` |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
| `_transactioncurrencyid_value` | Lookup |  | Lookup → transactioncurrency; write `TransactionCurrencyId@odata.bind` = `/transactioncurrencies({id})` |
| `traversedpath` | String |  | max length 1250 |
| `utcconversiontimezonecode` | Integer |  | range -1..2147483647 |
| `versionnumber` | BigInt |  | range -9223372036854775808..9223372036854775807 |

### `statecode` choices

| Value | Label |
|---|---|
| 0 | Active |
| 1 | Inactive |

### `context_approvalstatus` choices

| Value | Label |
|---|---|
| 236150000 | Not Submitted |
| 236150001 | Submit |

### `context_approvalsubmitstatus` choices

| Value | Label |
|---|---|
| 236150000 | ⏳ Processing |
| 236150001 | ✅ Approved |
| 236150002 | 🚫 Rejected |

### `pum_createasagile` choices

| Value | Label |
|---|---|
| 493840000 | Epic |
| 493840001 | Feature |
| 493840002 | Story |

### `pum_kpicost` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpiquality` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpiresources` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpiscope` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpisummary` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_kpitimeline` choices

| Value | Label |
|---|---|
| 493840000 | ⚪ Not Set |
| 493840001 | 🔴 Need help |
| 493840002 | 🟡 At risk |
| 493840003 | 🟢 No issue |

### `pum_projecttype` choices

| Value | Label |
|---|---|
| 493840000 | Small Initiative |
| 493840002 | Large Project |

### `pum_status` choices

| Value | Label |
|---|---|
| 493840005 | Proposed |
| 493840004 | Under Evaluation |
| 493840006 | Authorized |
| 493840000 | Active |
| 493840001 | On Hold / Suspended |
| 493840002 | Closing |
| 493840003 | Completed |

### `pum_tasktool` choices

| Value | Label |
|---|---|
| 493840000 | Gantt |
| 493840001 | Ms Project |
| 493840002 | Project For The Web |
| 493840003 | Jira |
| 493840004 | Azure DevOps |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
