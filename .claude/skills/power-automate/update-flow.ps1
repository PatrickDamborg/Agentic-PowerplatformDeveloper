param(
    [string]$FlowId,
    [string]$FlowName,
    [Parameter(Mandatory)][string]$DefinitionPath,
    [switch]$Activate
)

if (-not $FlowId -and -not $FlowName) {
    Write-Host "Error: Provide either -FlowId or -FlowName" -ForegroundColor Red
    exit 1
}

# Resolve repository root
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) { $root = Split-Path $root -Parent }
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
Import-Module (Join-Path $root "helpers.psm1") -Force
$conn = Initialize-DataverseConnection -EnvPath (Join-Path $root ".env")
$h = $conn.Headers
$url = $conn.BaseUrl

# Resolve flow ID from name if needed
if (-not $FlowId) {
    Write-Host "Looking up flow '$FlowName'..." -ForegroundColor Cyan
    $lookup = Invoke-DataverseRequest -Method GET -Endpoint "workflows?`$filter=name eq '$FlowName' and category eq 5&`$select=workflowid,statecode" -BaseUrl $url -Headers $h
    $flow = $lookup.value | Select-Object -First 1
    if (-not $flow) {
        Write-Host "Flow '$FlowName' not found." -ForegroundColor Red
        exit 1
    }
    $FlowId = $flow.workflowid
    $currentState = $flow.statecode
}
else {
    $flowInfo = Invoke-DataverseRequest -Method GET -Endpoint "workflows($FlowId)?`$select=statecode,name" -BaseUrl $url -Headers $h
    $currentState = $flowInfo.statecode
}

# Deactivate if currently active
if ($currentState -eq 1) {
    Write-Host "Deactivating flow before update..." -ForegroundColor Yellow
    $deactivateBody = @{ statecode = 0; statuscode = 1 } | ConvertTo-Json
    Invoke-WebRequest -Method Patch -Uri "$url/workflows($FlowId)" -Headers $h -Body $deactivateBody -UseBasicParsing | Out-Null
    Write-Host "Flow deactivated." -ForegroundColor Green
}

# Read and apply new definition
if (-not (Test-Path $DefinitionPath)) {
    Write-Host "Error: Definition file not found: $DefinitionPath" -ForegroundColor Red
    exit 1
}

Write-Host "Updating flow definition from: $DefinitionPath" -ForegroundColor Cyan
$definitionContent = Get-Content -Path $DefinitionPath -Raw

try {
    $definitionContent | ConvertFrom-Json | Out-Null
}
catch {
    Write-Host "Error: Definition file is not valid JSON" -ForegroundColor Red
    exit 1
}

$escapedClientData = $definitionContent.Replace('\','\\').Replace('"','\"').Replace("`n",'').Replace("`r",'')

$updateBody = @"
{
    "clientdata": "$escapedClientData"
}
"@

try {
    Invoke-WebRequest -Method Patch -Uri "$url/workflows($FlowId)" -Headers $h -Body $updateBody -UseBasicParsing | Out-Null
    Write-Host "Flow definition updated." -ForegroundColor Green
}
catch {
    Write-Host "Error updating flow: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
    exit 1
}

# Reactivate if requested
if ($Activate) {
    Write-Host "Reactivating flow..." -ForegroundColor Cyan
    $activateBody = @{ statecode = 1; statuscode = 2 } | ConvertTo-Json
    try {
        Invoke-WebRequest -Method Patch -Uri "$url/workflows($FlowId)" -Headers $h -Body $activateBody -UseBasicParsing | Out-Null
        Write-Host "Flow reactivated." -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Could not reactivate flow: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`nFlow '$FlowId' updated successfully." -ForegroundColor Green
