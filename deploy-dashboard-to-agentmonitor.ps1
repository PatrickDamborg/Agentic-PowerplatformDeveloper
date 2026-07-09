#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys the Activity Dashboard to Dataverse by patching the pda_agentmonitor web resource.
.DESCRIPTION
    Updates the existing pda_agentmonitor HTML web resource with the latest dashboard content
    and ensures it's part of the xPM - AI Use Cases demo solution.
#>

$ErrorActionPreference = 'Stop'

# Configuration
$baseUrl = "https://pdausa.api.crm.dynamics.com/api/data/v9.2"
$dashboardPath = Join-Path $PSScriptRoot "dashboard" "index.html"
$webResourceName = "pda_agentmonitor"
$webResourceDisplayName = "agent-monitor"
$solutionUniqueName = "xPMAIUseCasesdemo"

# Verify dashboard file exists
if (-not (Test-Path $dashboardPath)) {
    Write-Error "Dashboard file not found: $dashboardPath"
    exit 1
}

# Load token
$tokenFile = ".token"
if (-not (Test-Path $tokenFile)) {
    Write-Error "Token file not found. Run /connect first."
    exit 1
}

$token = Get-Content -Path $tokenFile -Raw

$headers = @{
    "Authorization" = "Bearer $token"
    "Accept" = "application/json"
    "Content-Type" = "application/json"
}

try {
    Write-Host "Deploying Activity Dashboard to agent-monitor..." -ForegroundColor Cyan

    # Read dashboard content and encode as base64
    $dashboardContent = Get-Content -Path $dashboardPath -Raw
    $dashboardBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($dashboardContent))

    # Get the web resource ID
    Write-Host "Finding web resource: $webResourceName..." -ForegroundColor Green
    $searchUrl = "$baseUrl/webresourceset?`$filter=name eq '$webResourceName'&`$select=webresourceid,solutionid"
    $searchResponse = Invoke-RestMethod -Uri $searchUrl -Headers $headers -Method Get

    if ($searchResponse.value.Count -eq 0) {
        Write-Error "Web resource not found: $webResourceName"
        exit 1
    }

    $webResourceId = $searchResponse.value[0].webresourceid
    $currentSolutionId = $searchResponse.value[0].solutionid

    Write-Host "✓ Found web resource: $webResourceId" -ForegroundColor Green

    # Update the web resource with new content
    Write-Host "Updating web resource content..." -ForegroundColor Yellow
    $updateUrl = "$baseUrl/webresourceset($webResourceId)"
    $updateBody = @{
        displayname = $webResourceDisplayName
        description = "Agent Activity Dashboard - displays agent performance and activity metrics"
        content = $dashboardBase64
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $updateUrl -Headers $headers -Method Patch -Body $updateBody | Out-Null
    Write-Host "✓ Web resource content updated" -ForegroundColor Green

    # Check if web resource is in the target solution
    Write-Host "Verifying solution association..." -ForegroundColor Green
    $solutionUrl = "$baseUrl/solutions?`$filter=uniquename eq '$solutionUniqueName'&`$select=solutionid"
    $solutionResponse = Invoke-RestMethod -Uri $solutionUrl -Headers $headers -Method Get

    if ($solutionResponse.value.Count -eq 0) {
        Write-Error "Solution not found: $solutionUniqueName"
        exit 1
    }

    $targetSolutionId = $solutionResponse.value[0].solutionid

    if ($currentSolutionId -ne $targetSolutionId) {
        # Add to target solution
        Write-Host "Adding to solution: $solutionUniqueName..." -ForegroundColor Green
        $addUrl = "$baseUrl/AddSolutionComponent"
        $addBody = @{
            SolutionUniqueName = $solutionUniqueName
            ComponentType = 61  # Web Resource
            ComponentId = $webResourceId
            AddRequiredComponents = $false
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $addUrl -Headers $headers -Method Post -Body $addBody | Out-Null
        Write-Host "✓ Added to solution: $solutionUniqueName" -ForegroundColor Green
    } else {
        Write-Host "✓ Already in solution: $solutionUniqueName" -ForegroundColor Green
    }

    # Publish customizations
    Write-Host "Publishing customizations..." -ForegroundColor Green
    $publishUrl = "$baseUrl/PublishAllXml"
    Invoke-RestMethod -Uri $publishUrl -Headers $headers -Method Post -Body "{}" | Out-Null
    Write-Host "✓ Customizations published" -ForegroundColor Green

    Write-Host ""
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Dashboard deployed successfully!" -ForegroundColor Cyan
    Write-Host "Web Resource: $webResourceName" -ForegroundColor Cyan
    Write-Host "Solution: $solutionUniqueName" -ForegroundColor Cyan
    Write-Host "Resource ID: $webResourceId" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan

} catch {
    Write-Error "Deployment failed: $_"
    exit 1
}
