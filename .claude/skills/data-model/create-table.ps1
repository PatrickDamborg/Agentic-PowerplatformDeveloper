#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Create a Dataverse table with a primary name column.
.DESCRIPTION
    Generic, reusable script for creating a Dataverse custom table.
    All values are parameterized — no hard-coded prefixes, solutions, or entity names.
.PARAMETER Prefix
    Publisher prefix (e.g. "pda", "contoso"). Do NOT include trailing underscore.
.PARAMETER TableName
    Table name without prefix (e.g. "SteeringGroup"). PascalCase.
.PARAMETER DisplayName
    Human-readable display name (e.g. "Steering Group").
.PARAMETER DisplayNamePlural
    Plural display name (e.g. "Steering Groups").
.PARAMETER PrimaryColumnName
    Display name for the primary name column (default: "Name").
.PARAMETER PrimaryColumnLength
    Max length of primary name column (default: 200).
.PARAMETER Description
    Optional table description.
.PARAMETER SolutionName
    Solution unique name to associate the table with.
.PARAMETER OwnershipType
    "UserOwned" or "OrganizationOwned" (default: "UserOwned").
.EXAMPLE
    pwsh .claude/skills/data-model/create-table.ps1 -Prefix "pda" -TableName "SteeringGroup" `
        -DisplayName "Steering Group" -DisplayNamePlural "Steering Groups" -SolutionName "MySolution"
#>
param(
    [Parameter(Mandatory)][string]$Prefix,
    [Parameter(Mandatory)][string]$TableName,
    [Parameter(Mandatory)][string]$DisplayName,
    [Parameter(Mandatory)][string]$DisplayNamePlural,
    [string]$PrimaryColumnName = "Name",
    [int]$PrimaryColumnLength = 200,
    [string]$Description = "",
    [Parameter(Mandatory)][string]$SolutionName,
    [ValidateSet("UserOwned","OrganizationOwned")][string]$OwnershipType = "UserOwned"
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

$schemaName = "${Prefix}_${TableName}"
$primaryColSchema = "${Prefix}_${PrimaryColumnName}"

$body = @{
    "@odata.type"       = "Microsoft.Dynamics.CRM.EntityMetadata"
    SchemaName          = $schemaName
    DisplayName         = @{
        "@odata.type"        = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels      = @(@{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = $DisplayName
            LanguageCode  = 1033
        })
    }
    DisplayCollectionName = @{
        "@odata.type"        = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels      = @(@{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = $DisplayNamePlural
            LanguageCode  = 1033
        })
    }
    Description         = @{
        "@odata.type"        = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels      = @(@{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = $Description
            LanguageCode  = 1033
        })
    }
    OwnershipType       = $OwnershipType
    IsActivity          = $false
    HasActivities       = $false
    HasNotes            = $false
    PrimaryNameAttribute = $primaryColSchema.ToLower()
    Attributes          = @(@{
        "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
        SchemaName    = $primaryColSchema
        AttributeType = "String"
        MaxLength     = $PrimaryColumnLength
        FormatName    = @{ Value = "Text" }
        DisplayName   = @{
            "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
            LocalizedLabels = @(@{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                Label         = $PrimaryColumnName
                LanguageCode  = 1033
            })
        }
        IsPrimaryName = $true
        RequiredLevel = @{ Value = "ApplicationRequired" }
    })
} | ConvertTo-Json -Depth 20

Write-Host "Creating table '$schemaName' in solution '$SolutionName'..." -ForegroundColor Cyan

$result = Invoke-DataverseRequest -Method POST -Endpoint "EntityDefinitions" -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $body

Write-Host "Table '$schemaName' created successfully." -ForegroundColor Green
Write-Host "  LogicalName: $($schemaName.ToLower())" -ForegroundColor White
Write-Host "  PrimaryColumn: $($primaryColSchema.ToLower())" -ForegroundColor White

# Publish
Write-Host "Publishing customizations..." -ForegroundColor Cyan
$publishBody = @{
    ParameterXml = "<importexportxml><entities><entity>$($schemaName.ToLower())</entity></entities></importexportxml>"
} | ConvertTo-Json
Invoke-DataverseRequest -Method POST -Endpoint "PublishXml" -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $publishBody
Write-Host "Published." -ForegroundColor Green
