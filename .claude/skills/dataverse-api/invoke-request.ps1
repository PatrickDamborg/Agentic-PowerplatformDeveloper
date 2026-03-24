#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generic Dataverse Web API request wrapper.
.DESCRIPTION
    Sends an authenticated request to any Dataverse Web API endpoint.
    Resolves helpers.psm1 automatically from the repository root.
.PARAMETER Method
    HTTP method: GET, POST, PATCH, DELETE.
.PARAMETER Endpoint
    Relative API endpoint (e.g. "EntityDefinitions", "accounts?$top=5").
.PARAMETER Body
    Optional JSON string body for POST/PATCH requests.
.PARAMETER SolutionName
    Optional solution unique name to include in MSCRM.SolutionUniqueName header.
.EXAMPLE
    pwsh .claude/skills/dataverse-api/invoke-request.ps1 -Method GET -Endpoint "EntityDefinitions?\$filter=LogicalName eq 'account'"
.EXAMPLE
    pwsh .claude/skills/dataverse-api/invoke-request.ps1 -Method POST -Endpoint "accounts" -Body '{"name":"Test"}' -SolutionName "MySolution"
#>
param(
    [Parameter(Mandatory)][ValidateSet("GET","POST","PATCH","DELETE")][string]$Method,
    [Parameter(Mandatory)][string]$Endpoint,
    [string]$Body,
    [string]$SolutionName
)

$ErrorActionPreference = 'Stop'

# Resolve repository root (location of helpers.psm1)
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
Import-Module (Join-Path $root "helpers.psm1") -Force

# Connect — with or without solution header
if ($SolutionName) {
    $conn = Get-DataverseHeaders -SolutionName $SolutionName -EnvPath (Join-Path $root ".env")
} else {
    $conn = Initialize-DataverseConnection -EnvPath (Join-Path $root ".env")
    $conn = @{ Headers = $conn.Headers; BaseUrl = $conn.BaseUrl }
}

$params = @{
    Method   = $Method
    Endpoint = $Endpoint
    BaseUrl  = $conn.BaseUrl
    Headers  = $conn.Headers
}
if ($Body) { $params.Body = $Body }

$result = Invoke-DataverseRequest @params

if ($result -is [PSCustomObject] -or $result -is [hashtable]) {
    $result | ConvertTo-Json -Depth 20
} else {
    Write-Host "Request completed (HTTP $Method $Endpoint)" -ForegroundColor Green
}
