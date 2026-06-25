#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys pda_NGI_SalesOrderProcessing to the NGISalesorder solution.
.DESCRIPTION
    Creates or updates the NGI Sales Order Processing flow in Dataverse.
    All connection references use logical names baked into the flow JSON — no substitution required.
    AI Builder actions run through the existing shared_commondataserviceforapps connection reference;
    no separate AI Builder connection reference is needed.

    Pre-requisites (run first):
      1. pwsh flows/create-ngi-env-variables.ps1
      2. Author Prompt 1 and Prompt 2 in AI Builder portal; update env vars with their GUIDs

.PARAMETER EnvPath
    Path to the env file. Defaults to root ./env.
.PARAMETER SolutionUniqueName
    Target solution. Defaults to NGISalesorder.
.EXAMPLE
    pwsh flows/deploy-ngi-salesorder.ps1
#>
param(
    [string]$EnvPath             = (Join-Path $PSScriptRoot ".." "env"),
    [string]$SolutionUniqueName  = "NGISalesorder"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot ".." "helpers.psm1") -Force

# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
Write-Host "`n=== Authenticating ===" -ForegroundColor Cyan
$conn    = Get-DataverseHeaders -SolutionName $SolutionUniqueName -EnvPath $EnvPath
$headers = $conn.Headers
$baseUrl = $conn.BaseUrl
Write-Host "Connected to: $baseUrl" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Load and patch flow definition
# ---------------------------------------------------------------------------
$definitionFile = Join-Path $PSScriptRoot "ngi" "ngi_SalesOrderProcessing.json"
Write-Host "`n=== Loading flow definition ===" -ForegroundColor Cyan

$raw = Get-Content $definitionFile -Raw

# Strip _comment keys and serialize as clientdata
$def = $raw | ConvertFrom-Json
$clientDataObj = [ordered]@{}
foreach ($prop in $def.PSObject.Properties) {
    if ($prop.Name -ne '_comment') {
        $clientDataObj[$prop.Name] = $prop.Value
    }
}
$clientData = $clientDataObj | ConvertTo-Json -Depth 50 -Compress

# ---------------------------------------------------------------------------
# Check for existing flow
# ---------------------------------------------------------------------------
$uniqueName = "pda_NGI_SalesOrderProcessing"
$displayName = "NGI Sales Order Processing"

Write-Host "`n=== Checking for existing flow ===" -ForegroundColor Cyan
$checkUrl = "$baseUrl/workflows?`$filter=uniquename eq '$uniqueName'&`$select=workflowid,uniquename,statecode"
$existing = $null
try {
    $checkResp = Invoke-RestMethod -Method Get -Uri $checkUrl -Headers $headers
    if ($checkResp.value -and $checkResp.value.Count -gt 0) {
        $existing = $checkResp.value[0]
    }
} catch {
    Write-Warning "Could not check for existing flow: $_"
}

# ---------------------------------------------------------------------------
# Create or update
# ---------------------------------------------------------------------------
if ($existing) {
    $flowId = $existing.workflowid
    Write-Host "  Found existing flow ID: $flowId (statecode=$($existing.statecode))" -ForegroundColor Gray

    if ($existing.statecode -eq 1) {
        Write-Host "  Deactivating before update..." -ForegroundColor Gray
        $deactivateBody = @{ statecode = 0; statuscode = 1 } | ConvertTo-Json
        Invoke-RestMethod -Method Patch -Uri "$baseUrl/workflows($flowId)" -Headers $headers -Body $deactivateBody | Out-Null
        Start-Sleep -Seconds 2
    }

    $updateBody = @{ clientdata = $clientData } | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Patch -Uri "$baseUrl/workflows($flowId)" -Headers $headers -Body $updateBody | Out-Null
    Write-Host "  Updated successfully." -ForegroundColor Green
} else {
    $createBody = @{
        name          = $displayName
        uniquename    = $uniqueName
        category      = 5
        type          = 1
        mode          = 0
        primaryentity = "none"
        clientdata    = $clientData
        languagecode  = 1033
    } | ConvertTo-Json -Compress

    $createHeaders = $headers.Clone()
    $createHeaders["Prefer"] = "return=representation"

    $createResp = Invoke-RestMethod -Method Post -Uri "$baseUrl/workflows" -Headers $createHeaders -Body $createBody
    $flowId = $createResp.workflowid
    Write-Host "  Created with ID: $flowId" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Add to solution
# ---------------------------------------------------------------------------
Write-Host "`n=== Adding to solution $SolutionUniqueName ===" -ForegroundColor Cyan
$addBody = @{
    ComponentId            = $flowId
    ComponentType          = 29
    SolutionUniqueName     = $SolutionUniqueName
    AddRequiredComponents  = $false
} | ConvertTo-Json
try {
    Invoke-RestMethod -Method Post -Uri "$baseUrl/AddSolutionComponent" -Headers $headers -Body $addBody | Out-Null
    Write-Host "  Added to solution." -ForegroundColor Green
} catch {
    Write-Warning "  Could not add to solution (may already be present): $_"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host "`n╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  Flow deployed (Draft state)" -ForegroundColor White
Write-Host "  Unique name : $uniqueName" -ForegroundColor White
Write-Host "  Flow ID     : $flowId" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open Power Automate UI → NGISalesorder solution → find '$displayName'" -ForegroundColor Yellow
Write-Host "  2. Bind all 3 connection references (Office 365, SharePoint, Dataverse/AI Builder)" -ForegroundColor Yellow
Write-Host "  3. Turn the flow ON" -ForegroundColor Yellow
Write-Host "  4. Verify env vars pda_NGI_SharedMailbox, pda_NGI_SharePointSite, pda_NGI_SharePointLibrary are set" -ForegroundColor Yellow
Write-Host "  5. Send a test email with a PDF to the shared mailbox" -ForegroundColor Yellow
