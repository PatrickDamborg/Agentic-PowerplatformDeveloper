#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Add an existing Dataverse component to a solution.
.DESCRIPTION
    Generic script to add a table, column, relationship, or other component
    to a Dataverse solution using the AddSolutionComponent action.
.PARAMETER SolutionName
    Solution unique name.
.PARAMETER ComponentId
    GUID of the component to add (e.g. entity metadata ID).
.PARAMETER ComponentType
    Numeric component type code. Common values:
      1 = Entity, 2 = Attribute, 10 = Relationship, 26 = View,
      60 = SystemForm, 61 = WebResource, 29 = Workflow (flow).
.PARAMETER AddRequiredComponents
    If set, also adds any required dependent components.
.PARAMETER DoNotIncludeSubcomponents
    If set, adds only the root component without subcomponents.
.EXAMPLE
    pwsh .claude/skills/data-model/add-to-solution.ps1 -SolutionName "MySolution" `
        -ComponentId "00000000-0000-0000-0000-000000000000" -ComponentType 1
#>
param(
    [Parameter(Mandatory)][string]$SolutionName,
    [Parameter(Mandatory)][string]$ComponentId,
    [Parameter(Mandatory)][int]$ComponentType,
    [switch]$AddRequiredComponents,
    [switch]$DoNotIncludeSubcomponents
)

$ErrorActionPreference = 'Stop'

# Resolve repository root
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
Import-Module (Join-Path $root "helpers.psm1") -Force

$conn = Initialize-DataverseConnection -EnvPath (Join-Path $root ".env")

$body = @{
    ComponentId               = $ComponentId
    ComponentType             = $ComponentType
    SolutionUniqueName        = $SolutionName
    AddRequiredComponents     = [bool]$AddRequiredComponents
    DoNotIncludeSubcomponents = [bool]$DoNotIncludeSubcomponents
} | ConvertTo-Json

Write-Host "Adding component $ComponentId (type $ComponentType) to solution '$SolutionName'..." -ForegroundColor Cyan

Invoke-DataverseRequest -Method POST -Endpoint "AddSolutionComponent" -BaseUrl $conn.BaseUrl -Headers $conn.Headers -Body $body

Write-Host "Component added successfully." -ForegroundColor Green
