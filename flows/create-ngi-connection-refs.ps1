#!/usr/bin/env pwsh
<#
.SYNOPSIS
    OBSOLETE — no longer needed for pda_NGI_SalesOrderProcessing.
.DESCRIPTION
    This script was written to create a separate AI Builder connection reference
    (shared_aibuilder connector). It is no longer required.

    The "Run a prompt" AI Builder action uses the shared_commondataserviceforapps
    connector (operationId: aibuilderpredict_customprompt), not a dedicated AI Builder
    connector. The Dataverse connection reference (pum_sharedcommondataserviceforapps_1479b)
    is already present in the NGISalesorder solution and covers both Dataverse operations
    and AI Builder prompt execution.

    You do NOT need to run this script before deploying the flow.

.PARAMETER EnvPath
    Path to the env file. Defaults to root ./env.
.PARAMETER AIBuilderConnectionId
    No longer used.
.PARAMETER SolutionUniqueName
    Target solution. Defaults to NGISalesorder.
#>
param(
    [string]$EnvPath                = (Join-Path $PSScriptRoot ".." "env"),
    [Parameter(Mandatory = $true)]
    [string]$AIBuilderConnectionId,
    [string]$SolutionUniqueName     = "NGISalesorder"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot ".." "helpers.psm1") -Force

Write-Host "`n=== Authenticating ===" -ForegroundColor Cyan
$conn    = Get-DataverseHeaders -SolutionName $SolutionUniqueName -EnvPath $EnvPath
$headers = $conn.Headers
$baseUrl = $conn.BaseUrl
Write-Host "Connected to: $baseUrl" -ForegroundColor Green

$logicalName = "pda_ngi_sharedaibuilder"
$connectorId = "/providers/Microsoft.PowerApps/apis/shared_aibuilder"

Write-Host "`n=== Checking for existing AI Builder connection reference ===" -ForegroundColor Cyan
$checkUrl = "$baseUrl/connectionreferences?`$filter=connectionreferencelogicalname eq '$logicalName'"
$existing = $null
try {
    $checkResp = Invoke-RestMethod -Method Get -Uri $checkUrl -Headers $headers
    if ($checkResp.value -and $checkResp.value.Count -gt 0) {
        $existing = $checkResp.value[0]
    }
} catch {
    Write-Warning "Could not check for existing connection reference: $_"
}

if ($existing) {
    Write-Host "  Already exists: $($existing.connectionreferencelogicalname)" -ForegroundColor Green
} else {
    Write-Host "  Creating connection reference '$logicalName'..." -ForegroundColor Gray

    $createBody = @{
        connectionreferencelogicalname = $logicalName
        connectorid                    = $connectorId
        connectionid                   = $AIBuilderConnectionId
    } | ConvertTo-Json -Compress

    $createHeaders = $headers.Clone()
    $createHeaders["Prefer"] = "return=representation"

    $createResp = Invoke-RestMethod -Method Post -Uri "$baseUrl/connectionreferences" -Headers $createHeaders -Body $createBody
    $refId      = $createResp.connectionreferenceid
    Write-Host "  Created ID: $refId" -ForegroundColor Gray

    # Add to solution
    $addBody = @{
        ComponentId           = $refId
        ComponentType         = 10067
        SolutionUniqueName    = $SolutionUniqueName
        AddRequiredComponents = $false
    } | ConvertTo-Json
    try {
        Invoke-RestMethod -Method Post -Uri "$baseUrl/AddSolutionComponent" -Headers $headers -Body $addBody | Out-Null
        Write-Host "  Added to solution $SolutionUniqueName." -ForegroundColor Green
    } catch {
        Write-Warning "  Could not add to solution: $_"
    }
}

Write-Host "`n╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  AI Builder connection reference ready" -ForegroundColor White
Write-Host "  Logical name: $logicalName" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Now run:" -ForegroundColor Yellow
Write-Host "  pwsh flows/deploy-ngi-salesorder.ps1 -AIBuilderConnRefLogicalName `"$logicalName`"" -ForegroundColor White
