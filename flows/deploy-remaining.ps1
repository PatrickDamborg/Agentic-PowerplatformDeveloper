#!/usr/bin/env pwsh
param(
    [string]$EnvPath = "/Users/patrickdamborg/Agentic-PowerplatformDeveloper/env",
    [string]$SolutionUniqueName = "XPMCopilotSkills"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module /Users/patrickdamborg/Agentic-PowerplatformDeveloper/helpers.psm1 -Force

$conn = Get-DataverseHeaders -SolutionName $SolutionUniqueName -EnvPath $EnvPath
$headers = $conn.Headers
$baseUrl = $conn.BaseUrl
Write-Host "Connected to: $baseUrl" -ForegroundColor Cyan

$skillsDir = "/Users/patrickdamborg/Agentic-PowerplatformDeveloper/flows/skills"

$flows = @(
    [PSCustomObject]@{ UniqueName = "pum_GetProjectPlan";  DisplayName = "GetProjectPlan";  File = "$skillsDir/pum_GetProjectPlan.json" },
    [PSCustomObject]@{ UniqueName = "pum_GetRisks";        DisplayName = "GetRisks";        File = "$skillsDir/pum_GetRisks.json" },
    [PSCustomObject]@{ UniqueName = "pum_GetStatusReport"; DisplayName = "GetStatusReport"; File = "$skillsDir/pum_GetStatusReport.json" }
)

foreach ($f in $flows) {
    Write-Host "`n--- Deploying: $($f.DisplayName) ($($f.UniqueName)) ---" -ForegroundColor Yellow

    $raw = Get-Content $f.File -Raw
    $def = $raw | ConvertFrom-Json
    $clientDataObj = [ordered]@{}
    foreach ($prop in $def.PSObject.Properties) {
        if ($prop.Name -ne '_comment') {
            $clientDataObj[$prop.Name] = $prop.Value
        }
    }
    $clientData = $clientDataObj | ConvertTo-Json -Depth 50 -Compress

    # Check if flow already exists
    $existing = $null
    try {
        $checkResp = Invoke-RestMethod -Method Get -Uri "$baseUrl/workflows?`$filter=uniquename eq '$($f.UniqueName)'&`$select=workflowid,statecode" -Headers $headers
        if ($checkResp.value.Count -gt 0) {
            $existing = $checkResp.value[0]
        }
    } catch {
        Write-Warning "Could not check existence: $_"
    }

    $flowId = $null

    if ($existing) {
        $flowId = $existing.workflowid
        Write-Host "  Existing: $flowId - updating..." -ForegroundColor Gray

        if ($existing.statecode -eq 1) {
            Write-Host "  Deactivating..." -ForegroundColor Gray
            $deactivateBody = '{"statecode":0,"statuscode":1}'
            Invoke-RestMethod -Method Patch -Uri "$baseUrl/workflows($flowId)" -Headers $headers -Body $deactivateBody | Out-Null
            Start-Sleep -Seconds 2
        }

        $updateBody = @{ clientdata = $clientData } | ConvertTo-Json -Compress
        Invoke-RestMethod -Method Patch -Uri "$baseUrl/workflows($flowId)" -Headers $headers -Body $updateBody | Out-Null
        Write-Host "  Updated successfully." -ForegroundColor Green
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
            $resp = Invoke-RestMethod -Method Post -Uri "$baseUrl/workflows" -Headers $createHeaders -Body $createBody
            $flowId = $resp.workflowid
            Write-Host "  Created! WorkflowId: $flowId" -ForegroundColor Green
        } catch {
            Write-Host "  CREATE FAILED!" -ForegroundColor Red
            if ($_.ErrorDetails.Message) {
                Write-Host $_.ErrorDetails.Message -ForegroundColor Red
            } else {
                Write-Host $_ -ForegroundColor Red
            }
            continue
        }
    }

    # Add to solution
    $addBody = @{
        ComponentId           = $flowId
        ComponentType         = 29
        SolutionUniqueName    = $SolutionUniqueName
        AddRequiredComponents = $false
    } | ConvertTo-Json
    try {
        Invoke-RestMethod -Method Post -Uri "$baseUrl/AddSolutionComponent" -Headers $headers -Body $addBody | Out-Null
        Write-Host "  Added to solution $SolutionUniqueName." -ForegroundColor Green
    } catch {
        Write-Host "  Warning - could not add to solution (may already be present)." -ForegroundColor Yellow
    }

    Write-Host "  FLOW ID: $flowId" -ForegroundColor Cyan
}

Write-Host "`nDone. All flows created in Draft state." -ForegroundColor Green
