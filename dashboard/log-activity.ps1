#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Log an action to the ActivityLog Dataverse table.
.DESCRIPTION
    Creates a record in the ActivityLog table capturing what was done, why, how,
    and best-practice notes. Designed to be called by the AI agent after each
    significant action for traceability and educational purposes.
.PARAMETER Prefix
    Publisher prefix (e.g. "pda").
.PARAMETER SolutionName
    Solution unique name.
.PARAMETER Title
    Short summary of the action (max 500 chars).
.PARAMETER What
    Plain-language description of the operation performed.
.PARAMETER Why
    Business reason or design decision behind the action.
.PARAMETER How
    Technical details — API calls, scripts, configurations used.
.PARAMETER BestPractice
    Best-practice notes and recommendations.
.PARAMETER Category
    Action category. Valid values: SchemaChange, CloudFlow, SolutionOperation, Security, Configuration, DataMigration, Other.
.PARAMETER ActionStatus
    Outcome. Valid values: Completed, InProgress, Failed.
.PARAMETER Component
    The Dataverse component affected (e.g. "pda_project table", "risk-100 flow").
.PARAMETER ApiEndpoint
    The API endpoint or operation used.
.PARAMETER SessionId
    Groups actions from the same agent session.
.EXAMPLE
    pwsh dashboard/log-activity.ps1 -Prefix "pda" -SolutionName "PPMextension" `
        -Title "Created Project table" `
        -What "Created a new custom table pda_project with columns for name, status, and owner." `
        -Why "The customer needs to track projects with status reporting." `
        -How "Used POST to EntityDefinitions with MSCRM.SolutionUniqueName header." `
        -BestPractice "Always include the solution header so components are solution-aware from creation." `
        -Category "SchemaChange" -ActionStatus "Completed" `
        -Component "pda_project" -SessionId "session-001"
#>
param(
    [Parameter(Mandatory)][string]$Prefix,
    [Parameter(Mandatory)][string]$SolutionName,
    [Parameter(Mandatory)][string]$Title,
    [string]$What = "",
    [string]$Why = "",
    [string]$How = "",
    [string]$BestPractice = "",
    [ValidateSet("SchemaChange","CloudFlow","SolutionOperation","Security","Configuration","DataMigration","Other")]
    [string]$Category = "Other",
    [ValidateSet("Completed","InProgress","Failed")]
    [string]$ActionStatus = "Completed",
    [string]$Component = "",
    [string]$ApiEndpoint = "",
    [string]$SessionId = ""
)

$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
Import-Module (Join-Path $root "helpers.psm1") -Force

$conn = Get-DataverseHeaders -SolutionName $SolutionName -EnvPath (Join-Path $root ".env")

# Map friendly names to option set values
$categoryMap = @{
    "SchemaChange"      = 100000000
    "CloudFlow"         = 100000001
    "SolutionOperation" = 100000002
    "Security"          = 100000003
    "Configuration"     = 100000004
    "DataMigration"     = 100000005
    "Other"             = 100000006
}

$statusMap = @{
    "Completed"  = 100000000
    "InProgress" = 100000001
    "Failed"     = 100000002
}

$p = $Prefix.ToLower()

$record = @{
    "${p}_title"        = $Title
    "${p}_what"         = $What
    "${p}_why"          = $Why
    "${p}_how"          = $How
    "${p}_bestpractice" = $BestPractice
    "${p}_category"     = $categoryMap[$Category]
    "${p}_actionstatus" = $statusMap[$ActionStatus]
    "${p}_entity"       = $Component
    "${p}_apiendpoint"  = $ApiEndpoint
    "${p}_sessionid"    = $SessionId
    "${p}_executedon"   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    "${p}_environment"  = $conn.BaseUrl
}

$body = $record | ConvertTo-Json -Depth 5

$entitySetName = "${p}_activitylogs"

$result = Invoke-DataverseRequest -Method POST -Endpoint $entitySetName -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $body

Write-Host "Activity logged: $Title" -ForegroundColor Green
