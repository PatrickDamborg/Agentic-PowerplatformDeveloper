#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates or updates the pda_CreateBakeryOrder flow in the HempelSweetBakery solution and activates it.
.DESCRIPTION
    Deploys the "Create Bakery Order" Copilot Studio-triggered flow that writes
    a pda_order and associated pda_orderline records into Dataverse.

    The flow is registered as a Modern Flow (category=5) workflow record.
    On first run it is created in Draft state, then activated.
    On subsequent runs the existing flow is deactivated, updated, and re-activated.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot      = Join-Path $PSScriptRoot ".." ".."
$EnvPath       = Join-Path $RepoRoot ".env"
$HelpersPath   = Join-Path $RepoRoot "helpers.psm1"
$DefinitionFile = Join-Path $PSScriptRoot "pda_CreateBakeryOrder.json"

$SolutionUniqueName = "HempelSweetBakery"
$FlowUniqueName     = "pda_CreateBakeryOrder"
$FlowDisplayName    = "Create Bakery Order"

Import-Module $HelpersPath -Force

# ---------------------------------------------------------------------------
# Authenticate
# ---------------------------------------------------------------------------
Write-Host "`n=== Authenticating ===" -ForegroundColor Cyan
$conn    = Get-DataverseHeaders -SolutionName $SolutionUniqueName -EnvPath $EnvPath
$headers = $conn.Headers
$baseUrl = $conn.BaseUrl
Write-Host "Connected to: $baseUrl" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Build clientdata from definition JSON (strip _comment property)
# ---------------------------------------------------------------------------
Write-Host "`n=== Loading flow definition ===" -ForegroundColor Cyan
$raw = Get-Content $DefinitionFile -Raw
$def = $raw | ConvertFrom-Json

$clientDataObj = [ordered]@{}
foreach ($prop in $def.PSObject.Properties) {
    if ($prop.Name -ne '_comment') {
        $clientDataObj[$prop.Name] = $prop.Value
    }
}
$clientData = $clientDataObj | ConvertTo-Json -Depth 50 -Compress
Write-Host "Definition loaded OK." -ForegroundColor Green

# ---------------------------------------------------------------------------
# Check if flow already exists
# ---------------------------------------------------------------------------
Write-Host "`n=== Checking for existing flow ===" -ForegroundColor Cyan
$checkUrl  = "$baseUrl/workflows?`$filter=uniquename eq '$FlowUniqueName'&`$select=workflowid,uniquename,statecode"
$checkResp = Invoke-RestMethod -Method Get -Uri $checkUrl -Headers $headers
$existing  = $null
if ($checkResp.value -and $checkResp.value.Count -gt 0) {
    $existing = $checkResp.value[0]
}

$flowId = $null

if ($existing) {
    $flowId = $existing.workflowid
    Write-Host "Found existing flow: $flowId  (statecode=$($existing.statecode))" -ForegroundColor Yellow

    # Deactivate if active
    if ($existing.statecode -eq 1) {
        Write-Host "Deactivating flow before update..." -ForegroundColor Gray
        $deactivateBody = @{ statecode = 0; statuscode = 1 } | ConvertTo-Json
        Invoke-RestMethod -Method Patch -Uri "$baseUrl/workflows($flowId)" -Headers $headers -Body $deactivateBody | Out-Null
        Start-Sleep -Seconds 3
        Write-Host "Deactivated." -ForegroundColor Gray
    }

    # Update clientdata
    Write-Host "Updating flow definition..." -ForegroundColor Gray
    $updateBody = @{ clientdata = $clientData } | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Patch -Uri "$baseUrl/workflows($flowId)" -Headers $headers -Body $updateBody | Out-Null
    Write-Host "Updated." -ForegroundColor Green
}
else {
    Write-Host "No existing flow found. Creating..." -ForegroundColor Gray

    $createHeaders = $headers.Clone()
    $createHeaders["Prefer"] = "return=representation"

    $createBody = @{
        name          = $FlowDisplayName
        uniquename    = $FlowUniqueName
        category      = 5
        type          = 1
        mode          = 0
        primaryentity = "none"
        clientdata    = $clientData
        languagecode  = 1033
    } | ConvertTo-Json -Compress

    $createResp = Invoke-RestMethod -Method Post -Uri "$baseUrl/workflows" -Headers $createHeaders -Body $createBody
    $flowId = $createResp.workflowid
    Write-Host "Created flow: $flowId" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Add to solution (idempotent — ignore if already present)
# ---------------------------------------------------------------------------
Write-Host "`n=== Adding flow to solution $SolutionUniqueName ===" -ForegroundColor Cyan
$addBody = @{
    ComponentId            = $flowId
    ComponentType          = 29
    SolutionUniqueName     = $SolutionUniqueName
    AddRequiredComponents  = $false
} | ConvertTo-Json
try {
    Invoke-RestMethod -Method Post -Uri "$baseUrl/AddSolutionComponent" -Headers $headers -Body $addBody | Out-Null
    Write-Host "Added to solution." -ForegroundColor Green
}
catch {
    Write-Warning "Could not add to solution (may already be present): $_"
}

# ---------------------------------------------------------------------------
# Activate the flow
# ---------------------------------------------------------------------------
Write-Host "`n=== Activating flow ===" -ForegroundColor Cyan
Start-Sleep -Seconds 2
$activateBody = @{ statecode = 1; statuscode = 2 } | ConvertTo-Json
try {
    Invoke-RestMethod -Method Patch -Uri "$baseUrl/workflows($flowId)" -Headers $headers -Body $activateBody | Out-Null
    Write-Host "Flow activated successfully." -ForegroundColor Green
}
catch {
    Write-Warning "Activation failed (connection references may need configuring in the UI): $_"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host "`n=== Deployment Complete ===" -ForegroundColor Cyan
Write-Host "  Flow Display Name : $FlowDisplayName"
Write-Host "  Flow Unique Name  : $FlowUniqueName"
Write-Host "  Flow ID           : $flowId"
Write-Host "  Solution          : $SolutionUniqueName"
Write-Host ""
Write-Host "Flow ID for debugger: $flowId" -ForegroundColor Yellow
