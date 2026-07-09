<!-- GENERATED — do not edit by hand.
     Source: live EntityDefinitions for `pum_idea`
     Env:    https://esben.crm.dynamics.com
     Date:   2026-06-16
     Regenerate: uv run python cli.py gen-schema pum_idea -->

# PumIdea (`pum_idea`)

Read-shape from the Web API: lookups appear as `_<name>_value`; write them via `@odata.bind`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `pum_name` | String | ✓ | **NAME**; max length 100 |
| `_ownerid_value` | Owner | ✓ | Lookup → systemuser, team; write `OwnerId@odata.bind` = `/systemusers({id})`, `/teams({id})` |
| `pum_ideaid` | Uniqueidentifier | ✓ |  |
| `statecode` | State | ✓ |  |
| `context_annualbenefits` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `context_approvers` | Memo |  | max length 10000 |
| `context_businessproblemopportunity` | Memo |  | max length 4000 |
| `context_changemanagementreq` | Boolean |  |  |
| `context_comments` | Memo |  | max length 2000 |
| `context_confidencelevel` | Picklist |  |  |
| `context_costavoidance` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `context_costsavings` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `context_currentstatedescription` | Memo |  | max length 4000 |
| `context_decision` | String |  | max length 100 |
| `context_decisiondate` | String |  | max length 100 |
| `context_discountrate` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `context_gatesummary` | Memo |  | max length 15000 |
| `context_internaleffortfte` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `context_justification` | Memo |  | max length 4000 |
| `context_mitigationapproach` | Memo |  | max length 5000 |
| `context_npv` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `context_onetimecostscapex` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `context_ongoingcostsopex` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `context_orgimpact` | Memo |  | max length 5000 |
| `context_paybackperiod` | Decimal |  | range -100000000000..100000000000; 1 decimals |
| `context_regulatorymandatorydriver` | Boolean |  |  |
| `context_revenuegrowth` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `context_riskofinaction` | Picklist |  |  |
| `context_roiadvanced` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `context_stage` | String |  | max length 1000 |
| `context_top3risks` | Memo |  | max length 5000 |
| `context_totalinvestment` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `context_vendorextcosts` | Money |  | range -922337203685477..922337203685477; 2 decimals |
| `context_votecount` | Integer |  | range 0..2147483647 |
| `context_whathappensifwedonothing` | Memo |  | max length 5000 |
| `context_whoisimpacted` | Picklist |  |  |
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
| `pum_benefitsestimate` | Money |  | range 0..922337203685477; 0 decimals |
| `pum_budgetestimate` | Money |  | range 0..922337203685477; 0 decimals |
| `_pum_category_value` | Lookup |  | Lookup → pum_investmentcategory; write `pum_Category@odata.bind` = `/pum_investmentcategories({id})` |
| `pum_createinitiative` | Boolean |  |  |
| `pum_description` | String |  | max length 4000 |
| `pum_hasinitiative` | Boolean |  |  |
| `pum_ideascore` | Integer |  | range 0..5 |
| `pum_ideatype` | Picklist |  |  |
| `pum_index` | Decimal |  | range -100000000000..100000000000; 4 decimals |
| `_pum_linkedinitiative_value` | Lookup |  | Lookup → pum_initiative; write `pum_LinkedInitiative@odata.bind` = `/pum_initiatives({id})` |
| `pum_mustrun` | Boolean |  |  |
| `_pum_portfolio_value` | Lookup |  | Lookup → pum_portfolio; write `pum_Portfolio@odata.bind` = `/pum_portfolios({id})` |
| `_pum_primaryobjective_value` | Lookup |  | Lookup → pum_strategicobjectives; write `pum_PrimaryObjective@odata.bind` = `/pum_strategicobjectiveses({id})` |
| `pum_proposedend` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_proposedstart` | DateTime (date-only) |  | date (ISO 8601) |
| `pum_rank` | Integer |  | range -2147483648..2147483647 |
| `pum_rating` | Picklist |  |  |
| `pum_revenuecomments` | Memo |  | max length 2000 |
| `pum_revenuegrowth` | Integer |  | range 0..10 |
| `pum_roi` | Decimal |  | range -100000000000..100000000000; 2 decimals |
| `pum_seeddata` | String |  | max length 100 |
| `pum_selected` | Boolean |  |  |
| `pum_strategicfit` | Integer |  | range 0..10 |
| `pum_strategycomments` | Memo |  | max length 2000 |
| `pum_ybenefitsestimate` | Money |  | range -922337203685477..922337203685477; 0 decimals |
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

### `context_confidencelevel` choices

| Value | Label |
|---|---|
| 236150000 | Low |
| 236150001 | Medium |
| 236150002 | High |

### `context_riskofinaction` choices

| Value | Label |
|---|---|
| 236150000 | Low |
| 236150001 | Medium |
| 236150002 | High |

### `context_whoisimpacted` choices

| Value | Label |
|---|---|
| 236150000 | Functions |
| 236150001 | Customers |
| 236150002 | Regions |

### `pum_ideatype` choices

| Value | Label |
|---|---|
| 493840000 | TBD |
| 493840001 | Run |
| 493840002 | Grow |
| 493840003 | Transform |

### `pum_rating` choices

| Value | Label |
|---|---|
| 493840000 | ⭐️ |
| 493840001 | ⭐️⭐️ |
| 493840002 | ⭐️⭐️⭐️ |
| 493840003 | ❔ |

### `statuscode` choices

| Value | Label |
|---|---|
| 1 | Active |
| 2 | Inactive |
