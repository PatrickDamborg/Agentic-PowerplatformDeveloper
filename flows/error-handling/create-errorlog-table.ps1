#!/usr/bin/env pwsh
param(
    [string]$EnvPath   = "",
    [string]$SolutionName = "PowerAutomateErrorHandling",
    [string]$Prefix    = "pda"
)

$ErrorActionPreference = "Stop"

# Find helpers.psm1 by walking up from script location
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
Import-Module (Join-Path $root "helpers.psm1") -Force

if (-not $EnvPath) {
    # Prefer root-level 'env' file (no dot), fall back to '.env'
    $envCandidate = Join-Path $root "env"
    $EnvPath = if (Test-Path $envCandidate) { $envCandidate } else { Join-Path $root ".env" }
}

$conn = Get-DataverseHeaders -SolutionName $SolutionName -EnvPath $EnvPath
$headers  = $conn.Headers
$baseUrl  = $conn.BaseUrl
Write-Host "Connected: $baseUrl  Solution: $SolutionName" -ForegroundColor Cyan

$schemaName  = "${Prefix}_ErrorLog"
$logicalName = $schemaName.ToLower()

# ── Step 1: Create table ─────────────────────────────────────────────────────
Write-Host "`nCreating table '$schemaName'..." -ForegroundColor Yellow

function New-Label([string]$text) {
    @{
        "@odata.type"   = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels = @(@{
            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
            Label         = $text
            LanguageCode  = 1033
        })
    }
}

$tableBody = @{
    "@odata.type"         = "Microsoft.Dynamics.CRM.EntityMetadata"
    SchemaName            = $schemaName
    DisplayName           = New-Label "Error Log"
    DisplayCollectionName = New-Label "Error Logs"
    Description           = New-Label "Centralised error log written by the pda_ErrorLog_Write child flow."
    OwnershipType         = "UserOwned"
    IsActivity            = $false
    HasActivities         = $false
    HasNotes              = $false
    PrimaryNameAttribute  = "${Prefix}_name".ToLower()
    Attributes            = @(@{
        "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
        SchemaName    = "${Prefix}_Name"
        AttributeType = "String"
        MaxLength     = 200
        FormatName    = @{ Value = "Text" }
        DisplayName   = New-Label "Name"
        Description   = New-Label "[Severity] FlowName — FailedStep (auto-composed by the child flow)"
        IsPrimaryName = $true
        RequiredLevel = @{ Value = "ApplicationRequired" }
    })
} | ConvertTo-Json -Depth 20

Invoke-DataverseRequest -Method POST -Endpoint "EntityDefinitions" `
    -BaseUrl $baseUrl -Headers $headers -Body $tableBody | Out-Null
Write-Host "  Table created." -ForegroundColor Green

$attrEndpoint = "EntityDefinitions(LogicalName='$logicalName')/Attributes"

# ── Step 2: String columns ────────────────────────────────────────────────────
$stringCols = @(
    @{ Schema = "FlowName";       Label = "Flow Name";       Desc = "Name of the flow that failed"; MaxLen = 200; Format = "Text" }
    @{ Schema = "RunId";          Label = "Run ID";          Desc = "Power Automate run identifier"; MaxLen = 100; Format = "Text" }
    @{ Schema = "RunUrl";         Label = "Run URL";         Desc = "Deep link to the failed flow run"; MaxLen = 500; Format = "Url" }
    @{ Schema = "FailedStep";     Label = "Failed Step";     Desc = "Name of the action that threw the error"; MaxLen = 200; Format = "Text" }
    @{ Schema = "ErrorCode";      Label = "Error Code";      Desc = "Error code returned by the failed action"; MaxLen = 100; Format = "Text" }
    @{ Schema = "CorrelationId";  Label = "Correlation ID";  Desc = "Caller-supplied correlation ID for tracing across flows"; MaxLen = 100; Format = "Text" }
    @{ Schema = "ParentRunId";    Label = "Parent Run ID";   Desc = "Run ID of the originating parent flow"; MaxLen = 100; Format = "Text" }
)

foreach ($col in $stringCols) {
    $body = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
        SchemaName    = "${Prefix}_$($col.Schema)"
        AttributeType = "String"
        MaxLength     = $col.MaxLen
        FormatName    = @{ Value = $col.Format }
        DisplayName   = New-Label $col.Label
        Description   = New-Label $col.Desc
        RequiredLevel = @{ Value = "None" }
    } | ConvertTo-Json -Depth 20
    Invoke-DataverseRequest -Method POST -Endpoint $attrEndpoint `
        -BaseUrl $baseUrl -Headers $headers -Body $body | Out-Null
    Write-Host "  + $($col.Label)" -ForegroundColor White
}

# ── Step 3: Memo columns (large text) ─────────────────────────────────────────
$memoCols = @(
    @{ Schema = "ErrorMessage";    Label = "Error Message";    Desc = "Full error body from the failed action"; MaxLen = 100000 }
    @{ Schema = "ContextJson";     Label = "Context JSON";     Desc = "Free-form JSON context supplied by the calling flow"; MaxLen = 100000 }
    @{ Schema = "ResolutionNotes"; Label = "Resolution Notes"; Desc = "Operator notes recorded when resolving this error"; MaxLen = 2000 }
)

foreach ($col in $memoCols) {
    $body = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.MemoAttributeMetadata"
        SchemaName    = "${Prefix}_$($col.Schema)"
        AttributeType = "Memo"
        MaxLength     = $col.MaxLen
        Format        = "TextArea"
        DisplayName   = New-Label $col.Label
        Description   = New-Label $col.Desc
        RequiredLevel = @{ Value = "None" }
    } | ConvertTo-Json -Depth 20
    Invoke-DataverseRequest -Method POST -Endpoint $attrEndpoint `
        -BaseUrl $baseUrl -Headers $headers -Body $body | Out-Null
    Write-Host "  + $($col.Label)" -ForegroundColor White
}

# ── Step 4: Severity picklist ──────────────────────────────────────────────────
Write-Host "  Adding Severity picklist..." -ForegroundColor White
$severityBody = @{
    "@odata.type" = "Microsoft.Dynamics.CRM.PicklistAttributeMetadata"
    SchemaName    = "${Prefix}_Severity"
    AttributeType = "Picklist"
    DisplayName   = New-Label "Severity"
    Description   = New-Label "Error severity level"
    RequiredLevel = @{ Value = "ApplicationRequired" }
    OptionSet     = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.OptionSetMetadata"
        IsGlobal      = $false
        OptionSetType = "Picklist"
        Options       = @(
            @{ Value = 100000000; Label = New-Label "Info" }
            @{ Value = 100000001; Label = New-Label "Warning" }
            @{ Value = 100000002; Label = New-Label "Error" }
            @{ Value = 100000003; Label = New-Label "Critical" }
        )
    }
} | ConvertTo-Json -Depth 20

Invoke-DataverseRequest -Method POST -Endpoint $attrEndpoint `
    -BaseUrl $baseUrl -Headers $headers -Body $severityBody | Out-Null
Write-Host "  + Severity" -ForegroundColor White

# ── Step 5: Resolved boolean ───────────────────────────────────────────────────
$resolvedBody = @{
    "@odata.type"  = "Microsoft.Dynamics.CRM.BooleanAttributeMetadata"
    SchemaName     = "${Prefix}_Resolved"
    AttributeType  = "Boolean"
    DefaultValue   = $false
    DisplayName    = New-Label "Resolved"
    Description    = New-Label "Whether an operator has resolved this error"
    RequiredLevel  = @{ Value = "None" }
    OptionSet      = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.BooleanOptionSetMetadata"
        TrueOption    = @{
            Value = 1
            Label = New-Label "Resolved"
        }
        FalseOption   = @{
            Value = 0
            Label = New-Label "Open"
        }
    }
} | ConvertTo-Json -Depth 20

Invoke-DataverseRequest -Method POST -Endpoint $attrEndpoint `
    -BaseUrl $baseUrl -Headers $headers -Body $resolvedBody | Out-Null
Write-Host "  + Resolved (boolean)" -ForegroundColor White

# ── Step 6: Publish ────────────────────────────────────────────────────────────
Write-Host "`nPublishing..." -ForegroundColor Yellow
$publishBody = @{
    ParameterXml = "<importexportxml><entities><entity>$logicalName</entity></entities></importexportxml>"
} | ConvertTo-Json
Invoke-DataverseRequest -Method POST -Endpoint "PublishXml" `
    -BaseUrl $baseUrl -Headers $headers -Body $publishBody | Out-Null

Write-Host "`npda_errorlog table ready." -ForegroundColor Green
Write-Host "  Schema : $schemaName" -ForegroundColor White
Write-Host "  Columns: Name, FlowName, RunId, RunUrl, FailedStep, ErrorCode," -ForegroundColor White
Write-Host "           CorrelationId, ParentRunId, ErrorMessage, ContextJson," -ForegroundColor White
Write-Host "           ResolutionNotes, Severity, Resolved" -ForegroundColor White
