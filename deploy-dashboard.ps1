#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys the Activity Dashboard to Dataverse as a web resource.
.DESCRIPTION
    Uploads dashboard/index.html as an HTML web resource to the xPM AI App Customizations solution.
    The web resource is named 'pda_dashboard_activity_index' and is automatically added to the solution.
#>

$ErrorActionPreference = 'Stop'

# Configuration
$baseUrl = "https://pdausa.api.crm.dynamics.com/api/data/v9.2"
$dashboardPath = Join-Path $PSScriptRoot "dashboard" "index.html"
$solutionUniqueName = "xPMAIAppCustomizations"
$publisherPrefix = "pda"
$webResourceName = "${publisherPrefix}_dashboard_activity_index"
$displayName = "Agent Activity Dashboard"

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
    Write-Host "Deploying Activity Dashboard..." -ForegroundColor Cyan

    # Read dashboard content and encode as base64
    $dashboardContent = Get-Content -Path $dashboardPath -Raw
    $dashboardBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($dashboardContent))

    # Check if web resource already exists
    Write-Host "Checking for existing web resource..." -ForegroundColor Green
    $searchUrl = "$baseUrl/webresourceset?`$filter=name eq '$webResourceName'&`$select=webresourceid"
    $searchResponse = Invoke-RestMethod -Uri $searchUrl -Headers $headers -Method Get

    if ($searchResponse.value.Count -gt 0) {
        # Update existing web resource
        $webResourceId = $searchResponse.value[0].webresourceid
        Write-Host "Updating existing web resource: $webResourceId" -ForegroundColor Yellow

        $updateUrl = "$baseUrl/webresourceset($webResourceId)"
        $updateBody = @{
            content = $dashboardBase64
            displayname = $displayName
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $updateUrl -Headers $headers -Method Patch -Body $updateBody | Out-Null
        Write-Host "✓ Web resource updated" -ForegroundColor Green
    } else {
        # Create new web resource
        Write-Host "Creating new web resource..." -ForegroundColor Yellow

        $createUrl = "$baseUrl/webresourceset"
        $createBody = @{
            name = $webResourceName
            displayname = $displayName
            description = "Agent Activity Dashboard - displays agent performance and activity metrics"
            webresourcetype = 1
            content = $dashboardBase64
        } | ConvertTo-Json

        $createResponse = Invoke-RestMethod -Uri $createUrl -Headers $headers -Method Post -Body $createBody -ResponseHeadersVariable 'respHeaders'

        # Extract webresourceid from OData-EntityId header
        if ($respHeaders.'OData-EntityId') {
            $webResourceId = [regex]::Match($respHeaders.'OData-EntityId', '\(([a-f0-9-]+)\)$').Groups[1].Value
        } else {
            $webResourceId = $createResponse.webresourceid
        }

        if (-not $webResourceId) {
            Write-Error "Failed to extract web resource ID from response"
            exit 1
        }

        Write-Host "✓ Web resource created: $webResourceId" -ForegroundColor Green

        # Add to solution
        Write-Host "Adding web resource to solution..." -ForegroundColor Green
        $addUrl = "$baseUrl/AddSolutionComponent"
        $addBody = @{
            SolutionUniqueName = $solutionUniqueName
            ComponentType = 61  # Web Resource
            ComponentId = $webResourceId
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $addUrl -Headers $headers -Method Post -Body $addBody | Out-Null
        Write-Host "✓ Added to solution: $solutionUniqueName" -ForegroundColor Green
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
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan

} catch {
    Write-Error "Deployment failed: $_"
    exit 1
}
