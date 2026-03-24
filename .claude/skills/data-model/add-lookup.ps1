#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Create a lookup (Many-to-One) relationship between two Dataverse tables.
.DESCRIPTION
    Generic script to create a lookup column on a child table that references a parent table.
    All values are parameterized — no hard-coded prefixes, solutions, or entity names.
.PARAMETER ParentTable
    Logical name of the parent (referenced) table (e.g. "account").
.PARAMETER ChildTable
    Logical name of the child (referencing) table (e.g. "pda_steeringgroup").
.PARAMETER LookupSchemaName
    Schema name for the lookup column on the child table (e.g. "pda_AccountId").
.PARAMETER LookupDisplayName
    Display name for the lookup column (e.g. "Account").
.PARAMETER RelationshipSchemaName
    Schema name for the relationship (e.g. "pda_account_steeringgroup").
.PARAMETER SolutionName
    Solution unique name.
.PARAMETER CascadeAssign
    Cascade behavior for Assign (default: "NoCascade").
.PARAMETER CascadeDelete
    Cascade behavior for Delete (default: "RemoveLink").
.EXAMPLE
    pwsh .claude/skills/data-model/add-lookup.ps1 -ParentTable "account" -ChildTable "pda_steeringgroup" `
        -LookupSchemaName "pda_AccountId" -LookupDisplayName "Account" `
        -RelationshipSchemaName "pda_account_steeringgroup" -SolutionName "MySolution"
#>
param(
    [Parameter(Mandatory)][string]$ParentTable,
    [Parameter(Mandatory)][string]$ChildTable,
    [Parameter(Mandatory)][string]$LookupSchemaName,
    [Parameter(Mandatory)][string]$LookupDisplayName,
    [Parameter(Mandatory)][string]$RelationshipSchemaName,
    [Parameter(Mandatory)][string]$SolutionName,
    [string]$CascadeAssign = "NoCascade",
    [string]$CascadeDelete = "RemoveLink"
)

$ErrorActionPreference = 'Stop'

# Resolve repository root
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
Import-Module (Join-Path $root "helpers.psm1") -Force

$conn = Get-DataverseHeaders -SolutionName $SolutionName -EnvPath (Join-Path $root ".env")

$body = @{
    "@odata.type"            = "Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata"
    SchemaName               = $RelationshipSchemaName
    ReferencedEntity         = $ParentTable
    ReferencingEntity        = $ChildTable
    CascadeConfiguration     = @{
        Assign   = $CascadeAssign
        Delete   = $CascadeDelete
        Merge    = "NoCascade"
        Reparent = "NoCascade"
        Share    = "NoCascade"
        Unshare  = "NoCascade"
    }
    Lookup                   = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.LookupAttributeMetadata"
        SchemaName    = $LookupSchemaName
        DisplayName   = @{
            "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
            LocalizedLabels = @(@{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                Label         = $LookupDisplayName
                LanguageCode  = 1033
            })
        }
        RequiredLevel = @{ Value = "None" }
    }
} | ConvertTo-Json -Depth 20

Write-Host "Creating lookup: $ChildTable -> $ParentTable (via $LookupSchemaName)..." -ForegroundColor Cyan

$result = Invoke-DataverseRequest -Method POST -Endpoint "RelationshipDefinitions" -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $body

Write-Host "Lookup created successfully." -ForegroundColor Green
Write-Host "  Relationship : $RelationshipSchemaName" -ForegroundColor White
Write-Host "  LookupColumn : $LookupSchemaName" -ForegroundColor White
Write-Host "  $ChildTable -> $ParentTable" -ForegroundColor White

# Publish both entities
Write-Host "Publishing customizations..." -ForegroundColor Cyan
$publishBody = @{
    ParameterXml = "<importexportxml><entities><entity>$ChildTable</entity><entity>$ParentTable</entity></entities></importexportxml>"
} | ConvertTo-Json
Invoke-DataverseRequest -Method POST -Endpoint "PublishXml" -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $publishBody
Write-Host "Published." -ForegroundColor Green
