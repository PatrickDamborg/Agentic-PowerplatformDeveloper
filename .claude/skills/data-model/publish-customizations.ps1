#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Publish Dataverse customizations for one or more entities.
.DESCRIPTION
    Calls the PublishXml action to make schema changes visible in the application.
    Can publish specific entities or all customizations.
.PARAMETER Entities
    Array of entity logical names to publish (e.g. "account","contact").
.PARAMETER All
    If set, publishes ALL customizations (equivalent to PublishAllXml).
.EXAMPLE
    pwsh .claude/skills/data-model/publish-customizations.ps1 -Entities "pda_steeringgroup","pda_member"
.EXAMPLE
    pwsh .claude/skills/data-model/publish-customizations.ps1 -All
#>
param(
    [string[]]$Entities,
    [switch]$All
)

$ErrorActionPreference = 'Stop'

if (-not $Entities -and -not $All) {
    throw "Provide either -Entities or -All."
}

# Resolve repository root
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
Import-Module (Join-Path $root "helpers.psm1") -Force

$conn = Initialize-DataverseConnection -EnvPath (Join-Path $root ".env")

if ($All) {
    Write-Host "Publishing ALL customizations..." -ForegroundColor Cyan
    Invoke-DataverseRequest -Method POST -Endpoint "PublishAllXml" -BaseUrl $conn.BaseUrl -Headers $conn.Headers
} else {
    $entityXml = ($Entities | ForEach-Object { "<entity>$_</entity>" }) -join ""
    $xml = "<importexportxml><entities>$entityXml</entities></importexportxml>"

    Write-Host "Publishing customizations for: $($Entities -join ', ')..." -ForegroundColor Cyan

    $body = @{ ParameterXml = $xml } | ConvertTo-Json
    Invoke-DataverseRequest -Method POST -Endpoint "PublishXml" -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $body
}

Write-Host "Published successfully." -ForegroundColor Green
