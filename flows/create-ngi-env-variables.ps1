#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates the 5 environment variables required by pda_NGI_SalesOrderProcessing.
.DESCRIPTION
    Creates string environment variables in the NGISalesorder solution.
    Run this before deploying the flow. Update the env var values after:
      - pda_NGI_SharedMailbox       → set to the shared mailbox address
      - pda_NGI_SharePointSite      → set to the SharePoint site URL
      - pda_NGI_SharePointLibrary   → set to the document library folder path
      - pda_NGI_AIBuilderPrompt1Id  → update after authoring Prompt 1 in AI Builder portal
      - pda_NGI_AIBuilderPrompt2Id  → update after authoring Prompt 2 (Claude) in AI Builder portal
.PARAMETER EnvPath
    Path to the env file. Defaults to root ./env.
.PARAMETER SolutionUniqueName
    Target solution. Defaults to NGISalesorder.
#>
param(
    [string]$EnvPath            = (Join-Path $PSScriptRoot ".." "env"),
    [string]$SolutionUniqueName = "NGISalesorder"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot ".." "helpers.psm1") -Force

Write-Host "`n=== Authenticating ===" -ForegroundColor Cyan
$conn    = Get-DataverseHeaders -SolutionName $SolutionUniqueName -EnvPath $EnvPath
$headers = $conn.Headers
$baseUrl = $conn.BaseUrl
Write-Host "Connected to: $baseUrl" -ForegroundColor Green

# Variables to create: schemaName, displayName, defaultValue
$envVars = @(
    @{ Schema = "pda_NGI_SharedMailbox";       Display = "NGI Shared Mailbox";           Default = "orders@ngi.dk" },
    @{ Schema = "pda_NGI_SharePointSite";      Display = "NGI SharePoint Site";           Default = "https://REPLACE.sharepoint.com/sites/REPLACE" },
    @{ Schema = "pda_NGI_SharePointLibrary";   Display = "NGI SharePoint Library";        Default = "/NGI Orders" },
    @{ Schema = "pda_NGI_AIBuilderPrompt1Id";  Display = "NGI AI Builder Prompt 1 ID";   Default = "REPLACE_AFTER_PROMPT_CREATION" },
    @{ Schema = "pda_NGI_AIBuilderPrompt2Id";  Display = "NGI AI Builder Prompt 2 ID";   Default = "REPLACE_AFTER_PROMPT_CREATION" }
)

foreach ($v in $envVars) {
    Write-Host "`n--- $($v.Schema) ---" -ForegroundColor Yellow

    # Check if already exists
    $encoded  = [System.Uri]::EscapeDataString($v.Schema)
    $checkUrl = "$baseUrl/environmentvariabledefinitions?`$filter=schemaname eq '$($v.Schema)'&`$select=environmentvariabledefinitionid,schemaname"
    $existing = $null
    try {
        $checkResp = Invoke-RestMethod -Method Get -Uri $checkUrl -Headers $headers
        if ($checkResp.value -and $checkResp.value.Count -gt 0) {
            $existing = $checkResp.value[0]
        }
    } catch {
        Write-Warning "  Could not check for existing variable: $_"
    }

    if ($existing) {
        Write-Host "  Already exists (ID: $($existing.environmentvariabledefinitionid)) — skipping." -ForegroundColor Gray
        continue
    }

    # Create the definition
    $defBody = @{
        schemaname    = $v.Schema
        displayname   = $v.Display
        type          = 100000001
        defaultvalue  = $v.Default
    } | ConvertTo-Json -Compress

    $createHeaders = $headers.Clone()
    $createHeaders["Prefer"] = "return=representation"

    $defResp = Invoke-RestMethod -Method Post -Uri "$baseUrl/environmentvariabledefinitions" -Headers $createHeaders -Body $defBody
    $defId   = $defResp.environmentvariabledefinitionid
    Write-Host "  Created definition ID: $defId" -ForegroundColor Gray

    # Add to solution
    $addBody = @{
        ComponentId           = $defId
        ComponentType         = 380
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

Write-Host "`n=== Done ===" -ForegroundColor Cyan
Write-Host "Update these env vars with real values before activating the flow:" -ForegroundColor Yellow
Write-Host "  pda_NGI_SharedMailbox       — shared mailbox email address" -ForegroundColor Yellow
Write-Host "  pda_NGI_SharePointSite      — SharePoint site URL" -ForegroundColor Yellow
Write-Host "  pda_NGI_SharePointLibrary   — document library folder path" -ForegroundColor Yellow
Write-Host "  pda_NGI_AIBuilderPrompt1Id  — after authoring Prompt 1 in AI Builder portal" -ForegroundColor Yellow
Write-Host "  pda_NGI_AIBuilderPrompt2Id  — after authoring Prompt 2 in AI Builder portal" -ForegroundColor Yellow
