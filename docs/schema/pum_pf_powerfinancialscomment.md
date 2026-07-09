<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_pf_powerfinancialscomment`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_pf_powerfinancialscomment -->

# PumPfPowerfinancialscomment (`pum_pf_powerfinancialscomment`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_pf_powerfinancialscomment` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_pf_commentlevel` | Integer | ✓ | range -2147483648..2147483647 |
| `pum_pf_powerfinancialscommentid` | Uniqueidentifier | ✓ |  |
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
| `_pum_customcosthierarchy_value` | Lookup |  | Lookup → pum_customcosthierarchy; write `pum_CustomCostHierarchy@odata.bind` = `/pum_customcosthierarchies({id})` |
| `_pum_financialstructure_value` | Lookup |  | Lookup → pum_financialstructure; write `pum_FinancialStructure@odata.bind` = `/pum_financialstructures({id})` |
| `_pum_pf_costcategoryid_value` | Lookup |  | Lookup → pum_pf_costcategory; write `pum_pf_costcategoryid@odata.bind` = `/pum_pf_costcategories({id})` |
| `_pum_pf_costplan_version_comments_value` | Lookup |  | Lookup → pum_pf_costplan_version; write `pum_pf_costplan_version_comments@odata.bind` = `/pum_pf_costplan_versions({id})` |
| `_pum_pf_costspecificationid_value` | Lookup |  | Lookup → pum_pf_costspecification; write `pum_pf_costspecificationid@odata.bind` = `/pum_pf_costspecifications({id})` |
| `_pum_pf_initiative_comment_value` | Lookup |  | Lookup → pum_initiative; write `pum_pf_initiative_comment@odata.bind` = `/pum_initiatives({id})` |
| `_pum_pf_program_comment_value` | Lookup |  | Lookup → pum_program; write `pum_pf_program_comment@odata.bind` = `/pum_programs({id})` |
| `statuscode` | Status |  |  |
| `timezoneruleversionnumber` | Integer |  | range -1..2147483647 |
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
