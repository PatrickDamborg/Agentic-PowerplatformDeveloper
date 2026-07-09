#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Create a model-driven app (AppModule) with SiteMap and entity components.
.PARAMETER AppDisplayName
    Friendly display name, e.g. "Fitness Training"
.PARAMETER AppUniqueName
    Short unique identifier without publisher prefix, e.g. "FitnessTraining".
    Dataverse auto-prepends the solution publisher prefix on save.
.PARAMETER SiteMapXml
    Full SiteMap XML string. See SKILL.md for format.
.PARAMETER EntityLogicalNames
    Array of entity logical names to add to the app, e.g. @("context_trainingprofile", "context_exercise")
.PARAMETER SolutionName
    Solution unique name.
.PARAMETER Description
    Optional app description.
.EXAMPLE
    $sitemap = '<SiteMap><Area Id="a" Title="Training"><Group Id="g" Title="Data"><SubArea Id="s1" Entity="context_trainingprofile" Title="Profiles"/></Group></Area></SiteMap>'
    pwsh .claude/skills/model-driven-app/create-mda.ps1 `
        -AppDisplayName "Fitness Training" `
        -AppUniqueName "FitnessTraining" `
        -SiteMapXml $sitemap `
        -EntityLogicalNames @("context_trainingprofile","context_trainingprogramme","context_exercise") `
        -SolutionName "ContextFitnessAgent"
#>
param(
    [Parameter(Mandatory)][string]$AppDisplayName,
    [Parameter(Mandatory)][string]$AppUniqueName,
    [Parameter(Mandatory)][string]$SiteMapXml,
    [Parameter(Mandatory)][string[]]$EntityLogicalNames,
    [Parameter(Mandatory)][string]$SolutionName,
    [string]$Description = "",
    [string]$EnvPath = ""
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1" }
Import-Module (Join-Path $root "helpers.psm1") -Force

$resolvedEnvPath = if ($EnvPath) { $EnvPath } else { Join-Path $root ".env" }
$conn = Get-DataverseHeaders -SolutionName $SolutionName -EnvPath $resolvedEnvPath

# Derive the publisher prefix from the solution to build the auto-prefixed uniquename
$solResp = Invoke-RestMethod -Uri "$($conn.BaseUrl)/solutions?`$filter=uniquename eq '$SolutionName'&`$expand=publisherid(`$select=customizationprefix)&`$select=uniquename" -Headers $conn.Headers
$prefix = $solResp.value[0].publisherid.customizationprefix
$autoUniqueName = "${prefix}_${AppUniqueName}"
Write-Host "Publisher prefix : $prefix" -ForegroundColor Gray
Write-Host "Auto uniquename  : $autoUniqueName" -ForegroundColor Gray

# ── 1. App Module (idempotent) ──────────────────────────────────────────────
Write-Host "`nCreating app module '$AppDisplayName'..." -ForegroundColor Cyan
$existing = Invoke-RestMethod -Uri "$($conn.BaseUrl)/appmodules?`$filter=uniquename eq '$autoUniqueName'&`$select=appmoduleid" -Headers $conn.Headers
if ($existing.value.Count -gt 0) {
    $appId = $existing.value[0].appmoduleid
    Write-Host "  Already exists: $appId" -ForegroundColor Yellow
} else {
    # CRITICAL: clienttype=4 (Unified Interface) and formfactor=1 (Tablet) are REQUIRED.
    # Omitting either causes silent failure — API returns 204+EntityId but record is NOT saved.
    $appBody = @{
        name              = $AppDisplayName
        uniquename        = $AppUniqueName
        description       = $Description
        introducedversion = "1.0.0.0"
        clienttype        = 4    # Unified Interface — DO NOT omit
        formfactor        = 1    # Tablet/Responsive — DO NOT omit
        webresourceid     = "953b9fac-1e5e-e611-80d6-00155ded156f"  # standard default icon — required
    } | ConvertTo-Json

    $appResp = Invoke-WebRequest -Method POST -Uri "$($conn.BaseUrl)/appmodules" `
        -Headers $conn.Headers -Body $appBody -UseBasicParsing
    $appId = [regex]::Match($appResp.Headers['OData-EntityId'], '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}').Value

    # Verify — if silent failure occurred the record won't exist
    $verify = Invoke-RestMethod -Uri "$($conn.BaseUrl)/appmodules?`$filter=uniquename eq '$autoUniqueName'&`$select=appmoduleid" -Headers $conn.Headers
    if ($verify.value.Count -eq 0) {
        throw "App module creation appeared to succeed but record was not persisted. Check clienttype/formfactor values."
    }
    Write-Host "  Created: $appId" -ForegroundColor Green
}

# ── 2. SiteMap (idempotent) ─────────────────────────────────────────────────
$sitemapUniqueName = "${prefix}_${AppUniqueName}SiteMap"
Write-Host "`nCreating sitemap '$sitemapUniqueName'..." -ForegroundColor Cyan
$existingSm = Invoke-RestMethod -Uri "$($conn.BaseUrl)/sitemaps?`$filter=sitemapnameunique eq '$sitemapUniqueName'&`$select=sitemapid" -Headers $conn.Headers
if ($existingSm.value.Count -gt 0) {
    $sitemapId = $existingSm.value[0].sitemapid
    Write-Host "  Already exists: $sitemapId" -ForegroundColor Yellow
} else {
    $smBody = @{
        sitemapname             = "$AppDisplayName SiteMap"
        sitemapnameunique       = $sitemapUniqueName
        sitemapxml              = $SiteMapXml
        isappaware              = $true
        showhome                = $false
        showpinned              = $true
        showrecents             = $true
        enablecollapsiblegroups = $false
    } | ConvertTo-Json
    $smResp = Invoke-WebRequest -Method POST -Uri "$($conn.BaseUrl)/sitemaps" `
        -Headers $conn.Headers -Body $smBody -UseBasicParsing
    $sitemapId = [regex]::Match($smResp.Headers['OData-EntityId'], '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}').Value
    Write-Host "  Created: $sitemapId" -ForegroundColor Green
}

# ── 3. Resolve entity MetadataIds ───────────────────────────────────────────
Write-Host "`nResolving entity MetadataIds..." -ForegroundColor Cyan
$entityMetaIds = @()
foreach ($logicalName in $EntityLogicalNames) {
    $metaResp = Invoke-RestMethod -Uri "$($conn.BaseUrl)/EntityDefinitions?`$filter=LogicalName eq '$logicalName'&`$select=MetadataId" -Headers $conn.Headers
    if ($metaResp.value.Count -eq 0) { Write-Host "  WARNING: entity '$logicalName' not found" -ForegroundColor Yellow; continue }
    $mid = $metaResp.value[0].MetadataId
    $entityMetaIds += $mid
    Write-Host "  $logicalName => $mid" -ForegroundColor Gray
}

# ── 4. AddAppComponents — SiteMap only ──────────────────────────────────────
# Entity components (componenttype=1) cannot be added via REST — add them via App Designer UI.
# SiteMap component uses @odata.type "Microsoft.Dynamics.CRM.sitemap" + sitemapid.
Write-Host "`nAdding sitemap to app module..." -ForegroundColor Cyan
$smComponents = @([ordered]@{ '@odata.type' = 'Microsoft.Dynamics.CRM.sitemap'; sitemapid = $sitemapId })
$addBody = @{ AppId = $appId; Components = $smComponents } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Method POST -Uri "$($conn.BaseUrl)/AddAppComponents" -Headers $conn.Headers -Body $addBody
Write-Host "  Sitemap component added." -ForegroundColor Green
Write-Host "  NOTE: Add entity components manually via App Designer (REST API cannot add componenttype=1)." -ForegroundColor Yellow

# ── 5. Publish ───────────────────────────────────────────────────────────────
Write-Host "`nPublishing..." -ForegroundColor Cyan
$pubBody = @{ ParameterXml = "<importexportxml><appmodules><appmodule>$appId</appmodule></appmodules></importexportxml>" } | ConvertTo-Json
Invoke-RestMethod -Method POST -Uri "$($conn.BaseUrl)/PublishXml" -Headers $conn.Headers -Body $pubBody
Write-Host "Published." -ForegroundColor Green

Write-Host "`n✓ Model-driven app ready." -ForegroundColor Green
Write-Host "  Display name : $AppDisplayName" -ForegroundColor White
Write-Host "  Unique name  : $autoUniqueName" -ForegroundColor White
Write-Host "  App ID       : $appId" -ForegroundColor White
Write-Host "  SiteMap ID   : $sitemapId" -ForegroundColor White
