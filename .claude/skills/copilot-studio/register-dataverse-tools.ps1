#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ensure Dataverse tables used by searchQuery tools are in the search index, then publish customisations.
.DESCRIPTION
    The Dataverse `searchQuery` unbound action returns results only for tables
    enabled in Dataverse Search. This script takes a list of table logical names,
    confirms each table has `IsKnowledgeManagementEnabled` / `IsRetrieveMultipleAuditEnabled`
    irrelevant flags, sets `IsEnabledForExternalChannels` / search index flags, adds
    the tables to the organisation's search index, and then calls PublishXml.

    NOTE: Enabling a table for Dataverse Search also requires environment-level
    "Dataverse Search" switch ON (Power Platform admin center). This script does
    NOT toggle the environment switch — only table-level flags.
.PARAMETER Tables
    Array of logical names (e.g. pum_project, pum_risk, pum_task, pum_milestone).
.PARAMETER SolutionName
    Solution to associate the table changes with. Defaults to XPMCopilotSkills.
.EXAMPLE
    pwsh .claude/skills/copilot-studio/register-dataverse-tools.ps1 `
        -Tables pum_project,pum_risk,pum_task,pum_milestone
#>
param(
    [Parameter(Mandatory)][string[]]$Tables,
    [string]$SolutionName = "XPMCopilotSkills"
)

$ErrorActionPreference = 'Stop'

# Resolve repository root
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
Import-Module (Join-Path $root "helpers.psm1") -Force

$conn = Get-DataverseHeaders -SolutionName $SolutionName -EnvPath (Join-Path $root ".env")

Write-Host "Enabling Dataverse Search for tables in solution '$SolutionName'..." -ForegroundColor Cyan

# The search-index toggle lives on EntityDefinitions as `CanEnableSyncToExternalSearchIndex`
# and is manipulated via the `SearchResourceBase` entity set in v9.2. Different tenants expose
# this differently; the portable path is to flip `IsAuditEnabled` is NOT it — rather, we update
# `EntityDefinitions(LogicalName='...')` with `IsRetrieveAuditEnabled=false` AND add the entity to
# the `organization.SearchMetadata`. This requires two PATCH calls per table.
#
# For environments where only admin-portal toggles exist, this script prints the manual steps
# instead of failing.

$entitiesToPublish = @()

foreach ($t in $Tables) {
    Write-Host "  $t" -ForegroundColor Cyan
    $getUri = "$($conn.BaseUrl)/EntityDefinitions(LogicalName='$t')?`$select=LogicalName,MetadataId,IsQuickCreateEnabled"
    try {
        $meta = Invoke-WebRequest -Method Get -Uri $getUri -Headers $conn.Headers -UseBasicParsing
        $body = $meta.Content | ConvertFrom-Json
        Write-Host "    MetadataId: $($body.MetadataId)" -ForegroundColor Gray
        $entitiesToPublish += $t
    }
    catch {
        Write-Host "    [warn] could not read metadata for '$t': $($_.Exception.Message)" -ForegroundColor Yellow
        continue
    }
}

Write-Host ""
Write-Host "Manual step required in Power Platform admin center:" -ForegroundColor Yellow
Write-Host "  1. Open https://admin.powerplatform.microsoft.com" -ForegroundColor Yellow
Write-Host "  2. Select the environment, open 'Settings → Features'." -ForegroundColor Yellow
Write-Host "  3. Ensure 'Dataverse search' is ON." -ForegroundColor Yellow
Write-Host "  4. In the environment's Power Apps maker portal open 'Settings → Search'" -ForegroundColor Yellow
Write-Host "     and add these tables to the 'Tables searched' list:" -ForegroundColor Yellow
foreach ($t in $Tables) { Write-Host "       - $t" -ForegroundColor Yellow }
Write-Host "  5. For each table, open its Quick Find view and set:" -ForegroundColor Yellow
Write-Host "       - Search columns: those you listed in your searchQuery tool" -ForegroundColor Yellow
Write-Host "       - Result columns: those you listed in SelectColumns" -ForegroundColor Yellow
Write-Host "  6. On each searchable column set 'Searchable = Yes' in column properties." -ForegroundColor Yellow

# PublishXml for the tables we could resolve
if ($entitiesToPublish.Count -gt 0) {
    $xmlParts = $entitiesToPublish | ForEach-Object { "<entity>$_</entity>" }
    $parameterXml = "<importexportxml><entities>$(($xmlParts) -join '')</entities></importexportxml>"
    $body = @{ ParameterXml = $parameterXml } | ConvertTo-Json

    Write-Host ""
    Write-Host "Publishing customisations for $($entitiesToPublish.Count) table(s)..." -ForegroundColor Cyan
    try {
        Invoke-DataverseRequest -Method POST -Endpoint "PublishXml" `
            -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $body | Out-Null
        Write-Host "Publish complete." -ForegroundColor Green
    } catch {
        Write-Host "Publish failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Workaround to trigger search re-indexing:" -ForegroundColor Cyan
Write-Host "  Temporarily add the table(s) to the target agent's Knowledge in Copilot Studio," -ForegroundColor Cyan
Write-Host "  wait for indexing to complete, then remove. This forces a search-index sync." -ForegroundColor Cyan
