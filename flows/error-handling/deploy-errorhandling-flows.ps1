#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy pda_ErrorLog_Write and pda_ErrorLog_Notify child flows.
.DESCRIPTION
    Imports both flow JSON definitions into Dataverse, links them to the
    PowerAutomateErrorHandling solution, and leaves them in Draft state.

    Prerequisite: run create-connection-reference.ps1 first so that the
    connection references for Dataverse and Office 365 Outlook exist.

.PARAMETER DataverseConnRefName
    Logical name of the connection reference for the Dataverse connector,
    e.g. "pda_sharedcommondataserviceforapps". Created by create-connection-reference.ps1.

.PARAMETER Office365ConnRefName
    Logical name of the connection reference for Office 365 Outlook,
    e.g. "pda_sharedoffice365". Created by create-connection-reference.ps1.

.PARAMETER EnvPath
    Path to the env file. Defaults to the root 'env' file.

.PARAMETER SolutionUniqueName
    Target solution. Defaults to PowerAutomateErrorHandling.
#>
param(
    [Parameter(Mandatory)][string]$DataverseConnRefName,
    [Parameter(Mandatory)][string]$Office365ConnRefName,
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

$flowDir = $PSScriptRoot

$flows = @(
    [PSCustomObject]@{
        UniqueName  = "pda_ErrorLog_Write"
        DisplayName = "pda_ErrorLog_Write"
        File        = Join-Path $flowDir "pda_ErrorLog_Write.json"
        # Replace ONLY the Dataverse connection placeholder
        Replacements = @{
            "REPLACE_WITH_DATAVERSE_CONNECTION_NAME" = $DataverseConnRefName
        }
    }
    [PSCustomObject]@{
        UniqueName  = "pda_ErrorLog_Notify"
        DisplayName = "pda_ErrorLog_Notify"
        File        = Join-Path $flowDir "pda_ErrorLog_Notify.json"
        Replacements = @{
            "REPLACE_WITH_OFFICE365_CONNECTION_NAME" = $Office365ConnRefName
        }
    }
)

foreach ($f in $flows) {
    Write-Host "`n--- $($f.DisplayName) ---" -ForegroundColor Yellow

    # Read JSON and substitute connection-reference placeholders
    $raw = Get-Content $f.File -Raw
    foreach ($kv in $f.Replacements.GetEnumerator()) {
        $raw = $raw.Replace($kv.Key, $kv.Value)
    }

    # Strip top-level _comment keys (if any) before serialising
    $def = $raw | ConvertFrom-Json
    $clientDataObj = [ordered]@{}
    foreach ($prop in $def.PSObject.Properties) {
        if ($prop.Name -ne '_comment') { $clientDataObj[$prop.Name] = $prop.Value }
    }
    $clientData = $clientDataObj | ConvertTo-Json -Depth 50 -Compress

    # Check if flow already exists
    $existing = $null
    try {
        $checkResp = Invoke-RestMethod -Method Get `
            -Uri "$baseUrl/workflows?`$filter=uniquename eq '$($f.UniqueName)'&`$select=workflowid,statecode" `
            -Headers $headers
        if ($checkResp.value.Count -gt 0) { $existing = $checkResp.value[0] }
    } catch {
        Write-Warning "Could not check existence: $_"
    }

    $flowId = $null

    if ($existing) {
        $flowId = $existing.workflowid
        Write-Host "  Exists ($flowId) — updating..." -ForegroundColor Gray

        if ($existing.statecode -eq 1) {
            Write-Host "  Deactivating first..." -ForegroundColor Gray
            Invoke-RestMethod -Method Patch `
                -Uri "$baseUrl/workflows($flowId)" -Headers $headers `
                -Body '{"statecode":0,"statuscode":1}' | Out-Null
            Start-Sleep -Seconds 2
        }

        Invoke-RestMethod -Method Patch `
            -Uri "$baseUrl/workflows($flowId)" -Headers $headers `
            -Body (@{ clientdata = $clientData } | ConvertTo-Json -Compress) | Out-Null
        Write-Host "  Updated." -ForegroundColor Green
    } else {
        $createBody = @{
            name          = $f.DisplayName
            uniquename    = $f.UniqueName
            category      = 5
            type          = 1
            mode          = 0
            primaryentity = "none"
            clientdata    = $clientData
            languagecode  = 1033
        } | ConvertTo-Json -Compress

        $createHeaders = $headers.Clone()
        $createHeaders["Prefer"] = "return=representation"

        try {
            $resp   = Invoke-RestMethod -Method Post -Uri "$baseUrl/workflows" `
                          -Headers $createHeaders -Body $createBody
            $flowId = $resp.workflowid
            Write-Host "  Created! WorkflowId: $flowId" -ForegroundColor Green
        } catch {
            Write-Host "  CREATE FAILED!" -ForegroundColor Red
            if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
            else { Write-Host $_ -ForegroundColor Red }
            continue
        }
    }

    # Link to solution
    $addBody = @{
        ComponentId           = $flowId
        ComponentType         = 29
        SolutionUniqueName    = $SolutionUniqueName
        AddRequiredComponents = $false
    } | ConvertTo-Json
    try {
        Invoke-RestMethod -Method Post -Uri "$baseUrl/AddSolutionComponent" `
            -Headers $headers -Body $addBody | Out-Null
        Write-Host "  Linked to solution." -ForegroundColor Green
    } catch {
        Write-Host "  Warning: could not link to solution (may already be there)." -ForegroundColor Yellow
    }

    Write-Host "  Flow ID: $flowId" -ForegroundColor Cyan
}

Write-Host "`nDone. Both flows are in Draft state." -ForegroundColor Green
Write-Host "Activate them in make.powerautomate.com after binding connection references." -ForegroundColor Yellow
