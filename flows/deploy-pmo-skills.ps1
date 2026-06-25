#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys the 4 PMO Status Reporting Agent flows to XPMCopilotSkills solution.
.DESCRIPTION
    Creates pum_GetInitiativeDetails, pum_GetProjectPlan, pum_GetRisks, pum_GetStatusReport
    as Modern Flow (category=5) workflow records and adds each to the XPMCopilotSkills solution.
#>
param(
    [string]$EnvPath = (Join-Path $PSScriptRoot ".." "env"),
    [string]$SolutionUniqueName = "XPMCopilotSkills",
    [string]$SolutionId = "5f239f36-ae3d-f111-bec6-70a8a59a44c4"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot ".." "helpers.psm1") -Force

# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
Write-Host "`n=== Authenticating ===" -ForegroundColor Cyan
$conn = Get-DataverseHeaders -SolutionName $SolutionUniqueName -EnvPath $EnvPath
$headers = $conn.Headers
$baseUrl = $conn.BaseUrl
Write-Host "Connected to: $baseUrl" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Helper: create or update a flow
# ---------------------------------------------------------------------------
function Deploy-Flow {
    param(
        [string]$UniqueName,
        [string]$DisplayName,
        [string]$DefinitionFile
    )

    Write-Host "`n--- Deploying: $DisplayName ($UniqueName) ---" -ForegroundColor Yellow

    # Load and validate definition JSON
    $raw = Get-Content $DefinitionFile -Raw
    $def = $raw | ConvertFrom-Json
    # clientdata = { schemaVersion, properties: { connectionReferences, definition, templateName } }
    # The JSON file root has: schemaVersion, properties, _comment
    # We strip _comment and re-serialize the rest as clientdata.
    $clientDataObj = [ordered]@{}
    foreach ($prop in $def.PSObject.Properties) {
        if ($prop.Name -ne '_comment') {
            $clientDataObj[$prop.Name] = $prop.Value
        }
    }
    $clientData = $clientDataObj | ConvertTo-Json -Depth 50 -Compress

    # Check if flow already exists
    $encodedName = [System.Uri]::EscapeDataString($UniqueName)
    $checkUrl = "$baseUrl/workflows?`$filter=uniquename eq '$UniqueName'&`$select=workflowid,uniquename,statecode"
    $existing = $null
    try {
        $checkResp = Invoke-RestMethod -Method Get -Uri $checkUrl -Headers $headers
        if ($checkResp.value -and $checkResp.value.Count -gt 0) {
            $existing = $checkResp.value[0]
        }
    }
    catch {
        Write-Warning "Could not check for existing flow: $_"
    }

    if ($existing) {
        $flowId = $existing.workflowid
        Write-Host "  Found existing flow ID: $flowId (statecode=$($existing.statecode))" -ForegroundColor Gray

        # Deactivate if active (statecode=1)
        if ($existing.statecode -eq 1) {
            Write-Host "  Deactivating flow before update..." -ForegroundColor Gray
            $deactivateBody = @{
                statecode  = 0
                statuscode = 1
            } | ConvertTo-Json
            Invoke-RestMethod -Method Patch -Uri "$baseUrl/workflows($flowId)" -Headers $headers -Body $deactivateBody | Out-Null
            Start-Sleep -Seconds 2
        }

        # Update
        $updateBody = @{
            clientdata = $clientData
        } | ConvertTo-Json -Compress
        Invoke-RestMethod -Method Patch -Uri "$baseUrl/workflows($flowId)" -Headers $headers -Body $updateBody | Out-Null
        Write-Host "  Updated successfully." -ForegroundColor Green
    }
    else {
        # Create
        $createBody = @{
            name           = $DisplayName
            uniquename     = $UniqueName
            category       = 5
            type           = 1
            mode           = 0
            primaryentity  = "none"
            clientdata     = $clientData
            languagecode   = 1033
        } | ConvertTo-Json -Compress

        $createHeaders = $headers.Clone()
        $createHeaders["Prefer"] = "return=representation"

        $createResp = Invoke-RestMethod -Method Post -Uri "$baseUrl/workflows" -Headers $createHeaders -Body $createBody
        $flowId = $createResp.workflowid
        Write-Host "  Created with ID: $flowId" -ForegroundColor Green
    }

    # Add to solution
    Write-Host "  Adding to solution $SolutionUniqueName..." -ForegroundColor Gray
    $addBody = @{
        ComponentId   = $flowId
        ComponentType = 29
        SolutionUniqueName = $SolutionUniqueName
        AddRequiredComponents = $false
    } | ConvertTo-Json
    try {
        Invoke-RestMethod -Method Post -Uri "$baseUrl/AddSolutionComponent" -Headers $headers -Body $addBody | Out-Null
        Write-Host "  Added to solution." -ForegroundColor Green
    }
    catch {
        Write-Warning "  Could not add to solution (may already be present): $_"
    }

    return $flowId
}

# ---------------------------------------------------------------------------
# Deploy all 4 flows
# ---------------------------------------------------------------------------
$skillsDir = Join-Path $PSScriptRoot "skills"

$results = @{}

$results["pum_GetInitiativeDetails"] = Deploy-Flow `
    -UniqueName "pum_GetInitiativeDetails" `
    -DisplayName "GetInitiativeDetails" `
    -DefinitionFile (Join-Path $skillsDir "pum_GetInitiativeDetails.json")

$results["pum_GetProjectPlan"] = Deploy-Flow `
    -UniqueName "pum_GetProjectPlan" `
    -DisplayName "GetProjectPlan" `
    -DefinitionFile (Join-Path $skillsDir "pum_GetProjectPlan.json")

$results["pum_GetRisks"] = Deploy-Flow `
    -UniqueName "pum_GetRisks" `
    -DisplayName "GetRisks" `
    -DefinitionFile (Join-Path $skillsDir "pum_GetRisks.json")

$results["pum_GetStatusReport"] = Deploy-Flow `
    -UniqueName "pum_GetStatusReport" `
    -DisplayName "GetStatusReport" `
    -DefinitionFile (Join-Path $skillsDir "pum_GetStatusReport.json")

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host "`n=== Deployment Summary ===" -ForegroundColor Cyan
foreach ($key in $results.Keys) {
    Write-Host "  $key : $($results[$key])" -ForegroundColor White
}
Write-Host "`nDone. All flows are in Draft state." -ForegroundColor Green
Write-Host "Next: open Power Automate UI, configure connection references, then activate each flow." -ForegroundColor Yellow
