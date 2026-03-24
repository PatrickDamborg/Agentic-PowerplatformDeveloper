#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Add one or more columns to an existing Dataverse table.
.DESCRIPTION
    Generic script that reads column definitions from a JSON file and creates
    them on the specified table. Supports String, Integer, Decimal, Boolean,
    DateTime, Money, Memo, and Choice (Picklist) column types.
.PARAMETER TableLogicalName
    Logical name of the target table (e.g. "pda_steeringgroup").
.PARAMETER ColumnsPath
    Path to a JSON file containing an array of column definitions.
    Each object needs: SchemaName, Type, DisplayName. Optional: MaxLength,
    MinValue, MaxValue, Options (for Choice), Description.
.PARAMETER SolutionName
    Solution unique name.
.EXAMPLE
    pwsh .claude/skills/data-model/add-columns.ps1 -TableLogicalName "pda_steeringgroup" `
        -ColumnsPath "./columns.json" -SolutionName "MySolution"

    columns.json example:
    [
      { "SchemaName": "pda_Role", "Type": "Choice", "DisplayName": "Role",
        "Options": [{"Label":"Critical","Value":100000000},{"Label":"Essential","Value":100000001}] },
      { "SchemaName": "pda_Notes", "Type": "Memo", "DisplayName": "Notes", "MaxLength": 4000 }
    ]
#>
param(
    [Parameter(Mandatory)][string]$TableLogicalName,
    [Parameter(Mandatory)][string]$ColumnsPath,
    [Parameter(Mandatory)][string]$SolutionName
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

if (-not (Test-Path $ColumnsPath)) { throw "Column definitions file not found: $ColumnsPath" }
$columns = Get-Content $ColumnsPath -Raw | ConvertFrom-Json

$typeMap = @{
    "String"   = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
    "Memo"     = "Microsoft.Dynamics.CRM.MemoAttributeMetadata"
    "Integer"  = "Microsoft.Dynamics.CRM.IntegerAttributeMetadata"
    "Decimal"  = "Microsoft.Dynamics.CRM.DecimalAttributeMetadata"
    "Boolean"  = "Microsoft.Dynamics.CRM.BooleanAttributeMetadata"
    "DateTime" = "Microsoft.Dynamics.CRM.DateTimeAttributeMetadata"
    "Money"    = "Microsoft.Dynamics.CRM.MoneyAttributeMetadata"
    "Choice"   = "Microsoft.Dynamics.CRM.PicklistAttributeMetadata"
}

$endpoint = "EntityDefinitions(LogicalName='$TableLogicalName')/Attributes"
$created = 0

foreach ($col in $columns) {
    $odataType = $typeMap[$col.Type]
    if (-not $odataType) { Write-Host "Unsupported type '$($col.Type)' for $($col.SchemaName), skipping." -ForegroundColor Yellow; continue }

    $attrBody = @{
        "@odata.type" = $odataType
        SchemaName    = $col.SchemaName
        DisplayName   = @{
            "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
            LocalizedLabels = @(@{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                Label         = $col.DisplayName
                LanguageCode  = 1033
            })
        }
        RequiredLevel = @{ Value = if ($col.Required) { "ApplicationRequired" } else { "None" } }
    }

    if ($col.Description) {
        $attrBody.Description = @{
            "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
            LocalizedLabels = @(@{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                Label         = $col.Description
                LanguageCode  = 1033
            })
        }
    }

    # Type-specific properties
    switch ($col.Type) {
        "String" {
            $attrBody.MaxLength = if ($col.MaxLength) { $col.MaxLength } else { 200 }
            $attrBody.FormatName = @{ Value = "Text" }
        }
        "Memo" {
            $attrBody.MaxLength = if ($col.MaxLength) { $col.MaxLength } else { 2000 }
            $attrBody.FormatName = @{ Value = "Text" }
        }
        "Integer" {
            $attrBody.MinValue = if ($null -ne $col.MinValue) { $col.MinValue } else { -2147483648 }
            $attrBody.MaxValue = if ($null -ne $col.MaxValue) { $col.MaxValue } else { 2147483647 }
        }
        "Decimal" {
            $attrBody.MinValue = if ($null -ne $col.MinValue) { $col.MinValue } else { -100000000000 }
            $attrBody.MaxValue = if ($null -ne $col.MaxValue) { $col.MaxValue } else { 100000000000 }
            $attrBody.Precision = if ($col.Precision) { $col.Precision } else { 2 }
        }
        "Money" {
            $attrBody.MinValue = if ($null -ne $col.MinValue) { $col.MinValue } else { 0 }
            $attrBody.MaxValue = if ($null -ne $col.MaxValue) { $col.MaxValue } else { 1000000000 }
            $attrBody.Precision = if ($col.Precision) { $col.Precision } else { 2 }
        }
        "Boolean" {
            $attrBody.OptionSet = @{
                TrueOption  = @{ Value = 1; Label = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; LocalizedLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = if ($col.TrueLabel) { $col.TrueLabel } else { "Yes" }; LanguageCode = 1033 }) } }
                FalseOption = @{ Value = 0; Label = @{ "@odata.type" = "Microsoft.Dynamics.CRM.Label"; LocalizedLabels = @(@{ "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"; Label = if ($col.FalseLabel) { $col.FalseLabel } else { "No" }; LanguageCode = 1033 }) } }
            }
        }
        "DateTime" {
            $attrBody.Format = if ($col.Format) { $col.Format } else { "DateOnly" }
        }
        "Choice" {
            $options = @()
            foreach ($opt in $col.Options) {
                $options += @{
                    Value = $opt.Value
                    Label = @{
                        "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
                        LocalizedLabels = @(@{
                            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                            Label         = $opt.Label
                            LanguageCode  = 1033
                        })
                    }
                }
            }
            $attrBody.OptionSet = @{
                IsGlobal = $false
                OptionSetType = "Picklist"
                Options  = $options
            }
        }
    }

    $json = $attrBody | ConvertTo-Json -Depth 20
    Write-Host "Creating column '$($col.SchemaName)' ($($col.Type))..." -ForegroundColor Cyan

    try {
        Invoke-DataverseRequest -Method POST -Endpoint $endpoint -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $json
        Write-Host "  Created '$($col.SchemaName)'." -ForegroundColor Green
        $created++
    }
    catch {
        Write-Host "  Failed: $_" -ForegroundColor Red
    }
}

# Publish
Write-Host "`nPublishing customizations for '$TableLogicalName'..." -ForegroundColor Cyan
$publishBody = @{
    ParameterXml = "<importexportxml><entities><entity>$TableLogicalName</entity></entities></importexportxml>"
} | ConvertTo-Json
Invoke-DataverseRequest -Method POST -Endpoint "PublishXml" -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $publishBody
Write-Host "Done. Created $created column(s)." -ForegroundColor Green
