#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Look up Dataverse entity metadata by logical name or search pattern.
.DESCRIPTION
    Queries EntityDefinitions to verify exact logical names, schema names,
    entity set names, and primary keys. Use before referencing any entity
    in relationships, lookups, or queries.
.PARAMETER LogicalName
    Exact logical name to look up (e.g. "account").
.PARAMETER Search
    Partial name to search for (e.g. "resource"). Searches LogicalName contains.
.PARAMETER IncludeAttributes
    If set, also returns column/attribute definitions for the matched entity.
.EXAMPLE
    pwsh .claude/skills/dataverse-api/get-entity-metadata.ps1 -LogicalName "account"
.EXAMPLE
    pwsh .claude/skills/dataverse-api/get-entity-metadata.ps1 -Search "resource"
.EXAMPLE
    pwsh .claude/skills/dataverse-api/get-entity-metadata.ps1 -LogicalName "account" -IncludeAttributes
#>
param(
    [string]$LogicalName,
    [string]$Search,
    [switch]$IncludeAttributes
)

$ErrorActionPreference = 'Stop'

if (-not $LogicalName -and -not $Search) {
    throw "Provide either -LogicalName or -Search."
}

# Resolve repository root
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
Import-Module (Join-Path $root "helpers.psm1") -Force

$conn = Initialize-DataverseConnection -EnvPath (Join-Path $root ".env")

# Build filter
if ($LogicalName) {
    $filter = "LogicalName eq '$LogicalName'"
} else {
    $filter = "contains(LogicalName,'$($Search.ToLower())')"
}

$select = "LogicalName,SchemaName,DisplayName,EntitySetName,PrimaryIdAttribute,PrimaryNameAttribute"
$endpoint = "EntityDefinitions?`$filter=$filter&`$select=$select"

Write-Host "Querying EntityDefinitions..." -ForegroundColor Cyan
$result = Invoke-DataverseRequest -Method GET -Endpoint $endpoint -BaseUrl $conn.BaseUrl -Headers $conn.Headers

$entities = $result.value
if ($entities.Count -eq 0) {
    Write-Host "No entities found matching filter: $filter" -ForegroundColor Yellow
    exit 0
}

Write-Host "`nFound $($entities.Count) entity/entities:`n" -ForegroundColor Green

foreach ($entity in $entities) {
    $displayName = $entity.DisplayName.UserLocalizedLabel.Label
    Write-Host "  LogicalName     : $($entity.LogicalName)" -ForegroundColor White
    Write-Host "  SchemaName      : $($entity.SchemaName)" -ForegroundColor White
    Write-Host "  DisplayName     : $displayName" -ForegroundColor White
    Write-Host "  EntitySetName   : $($entity.EntitySetName)" -ForegroundColor White
    Write-Host "  PrimaryIdAttr   : $($entity.PrimaryIdAttribute)" -ForegroundColor White
    Write-Host "  PrimaryNameAttr : $($entity.PrimaryNameAttribute)" -ForegroundColor White
    Write-Host ""
}

# Optionally fetch attributes
if ($IncludeAttributes -and $LogicalName) {
    $attrEndpoint = "EntityDefinitions(LogicalName='$LogicalName')/Attributes?`$select=LogicalName,SchemaName,AttributeType,DisplayName"
    Write-Host "Fetching attributes for '$LogicalName'..." -ForegroundColor Cyan
    $attrResult = Invoke-DataverseRequest -Method GET -Endpoint $attrEndpoint -BaseUrl $conn.BaseUrl -Headers $conn.Headers

    Write-Host "`nAttributes ($($attrResult.value.Count)):`n" -ForegroundColor Green
    foreach ($attr in ($attrResult.value | Sort-Object LogicalName)) {
        $attrDisplay = $attr.DisplayName.UserLocalizedLabel.Label
        Write-Host "  $($attr.LogicalName) ($($attr.AttributeType)) - $attrDisplay"
    }
}
