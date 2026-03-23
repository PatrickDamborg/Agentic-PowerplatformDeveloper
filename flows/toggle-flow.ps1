param(
    [string]$FlowId,
    [string]$FlowName,
    [Parameter(Mandatory)][ValidateSet("Activate","Deactivate")][string]$Action
)

if (-not $FlowId -and -not $FlowName) {
    Write-Host "Error: Provide either -FlowId or -FlowName" -ForegroundColor Red
    exit 1
}

Import-Module (Join-Path $PSScriptRoot "..\helpers.psm1") -Force
$conn = Initialize-DataverseConnection -EnvPath (Join-Path $PSScriptRoot "..\.env")
$h = $conn.Headers
$url = $conn.BaseUrl

# Resolve flow ID from name if needed
if (-not $FlowId) {
    Write-Host "Looking up flow '$FlowName'..." -ForegroundColor Cyan
    $lookup = Invoke-DataverseRequest -Method GET -Endpoint "workflows?`$filter=name eq '$FlowName' and category eq 5&`$select=workflowid,name,statecode" -BaseUrl $url -Headers $h
    $flow = $lookup.value | Select-Object -First 1
    if (-not $flow) {
        Write-Host "Flow '$FlowName' not found." -ForegroundColor Red
        exit 1
    }
    $FlowId = $flow.workflowid
    Write-Host "Found flow: $($flow.name) ($FlowId)" -ForegroundColor Green
}

if ($Action -eq "Activate") {
    Write-Host "Activating flow..." -ForegroundColor Cyan
    $body = @{ statecode = 1; statuscode = 2 } | ConvertTo-Json
}
else {
    Write-Host "Deactivating flow..." -ForegroundColor Cyan
    $body = @{ statecode = 0; statuscode = 1 } | ConvertTo-Json
}

try {
    Invoke-WebRequest -Method Patch -Uri "$url/workflows($FlowId)" -Headers $h -Body $body -UseBasicParsing | Out-Null
    Write-Host "Flow ${Action}d successfully." -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}
