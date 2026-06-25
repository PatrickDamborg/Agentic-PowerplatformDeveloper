#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Create connection references for pda_ErrorLog_Write and pda_ErrorLog_Notify.
.DESCRIPTION
    Creates two connection reference records in the PowerAutomateErrorHandling solution:
    - pda_sharedcommondataserviceforapps  (Dataverse)
    - pda_sharedoffice365                 (Office 365 Outlook)

    The Office 365 Outlook connection (OUTLOOK_CONNECTION_ID) must already exist in
    make.powerautomate.com. The Dataverse connection (DATAVERSE_CONNECTION_ID) is
    typically your existing service principal connection — run in the portal once to
    obtain its connection ID.

    Add to your env file before running:
        DATAVERSE_CONNECTION_ID=<guid-or-connection-name>
        OUTLOOK_CONNECTION_ID=<guid-or-connection-name>

.PARAMETER EnvPath
    Path to the env file. Defaults to the root 'env' file.

.PARAMETER SolutionUniqueName
    Target solution. Defaults to PowerAutomateErrorHandling.
#>
param(
    [string]$EnvPath            = "",
    [string]$SolutionUniqueName = "PowerAutomateErrorHandling"
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
Import-Module (Join-Path $root "helpers.psm1") -Force

if (-not $EnvPath) {
    $envCandidate = Join-Path $root "env"
    $EnvPath = if (Test-Path $envCandidate) { $envCandidate } else { Join-Path $root ".env" }
}

$conn    = Get-DataverseHeaders -SolutionName $SolutionUniqueName -EnvPath $EnvPath
$headers = $conn.Headers
$baseUrl = $conn.BaseUrl
Write-Host "Connected: $baseUrl  Solution: $SolutionUniqueName" -ForegroundColor Cyan

$dvConnId  = $env:DATAVERSE_CONNECTION_ID
$o365ConnId = $env:OUTLOOK_CONNECTION_ID

if (-not $dvConnId)  { throw "DATAVERSE_CONNECTION_ID is missing from env. Add it and re-run." }
if (-not $o365ConnId) { throw "OUTLOOK_CONNECTION_ID is missing from env. Create the Office 365 connection in make.powerautomate.com, copy its ID, add it to env, and re-run." }

function New-ConnectionReference([string]$logicalName, [string]$displayName, [string]$connectorId, [string]$connId) {
    # Check if already exists
    $existing = $null
    try {
        $check = Invoke-RestMethod -Method Get `
            -Uri "$baseUrl/connectionreferences?`$filter=connectionreferencelogicalname eq '$logicalName'&`$select=connectionreferenceid" `
            -Headers $headers
        if ($check.value.Count -gt 0) { $existing = $check.value[0] }
    } catch {}

    if ($existing) {
        Write-Host "  '$logicalName' already exists ($($existing.connectionreferenceid)) — skipping." -ForegroundColor Yellow
        return $logicalName
    }

    $body = @{
        connectionreferencelogicalname = $logicalName
        connectionreferencedisplayname = $displayName
        connectorid                    = $connectorId
        connectionid                   = $connId
    } | ConvertTo-Json

    $createHeaders = $headers.Clone()
    $createHeaders["Prefer"] = "return=representation"

    $resp = Invoke-RestMethod -Method Post `
        -Uri "$baseUrl/connectionreferences" -Headers $createHeaders -Body $body
    Write-Host "  Created '$logicalName'  ID: $($resp.connectionreferenceid)" -ForegroundColor Green
    return $logicalName
}

Write-Host "`nCreating connection references..." -ForegroundColor Yellow

$dvRefName   = New-ConnectionReference `
    -logicalName "pda_sharedcommondataserviceforapps" `
    -displayName "pda - Dataverse (Error Handling)" `
    -connectorId "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps" `
    -connId $dvConnId

$o365RefName = New-ConnectionReference `
    -logicalName "pda_sharedoffice365" `
    -displayName "pda - Office 365 Outlook (Error Handling)" `
    -connectorId "/providers/Microsoft.PowerApps/apis/shared_office365" `
    -connId $o365ConnId

Write-Host "`nConnection references ready." -ForegroundColor Green
Write-Host ""
Write-Host "Now run deploy-errorhandling-flows.ps1 with these values:" -ForegroundColor Cyan
Write-Host "  -DataverseConnRefName '$dvRefName'" -ForegroundColor White
Write-Host "  -Office365ConnRefName '$o365RefName'" -ForegroundColor White
Write-Host ""
Write-Host "Full command:" -ForegroundColor Cyan
Write-Host "  pwsh flows/error-handling/deploy-errorhandling-flows.ps1 \" -ForegroundColor White
Write-Host "    -DataverseConnRefName '$dvRefName' \" -ForegroundColor White
Write-Host "    -Office365ConnRefName '$o365RefName'" -ForegroundColor White
