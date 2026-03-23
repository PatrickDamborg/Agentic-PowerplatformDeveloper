param(
    [string]$SolutionName = "PPMextension"
)

Import-Module (Join-Path $PSScriptRoot "..\helpers.psm1") -Force
$conn = Initialize-DataverseConnection -EnvPath (Join-Path $PSScriptRoot "..\.env")
$h = $conn.Headers
$url = $conn.BaseUrl

Write-Host "Listing cloud flows (category=5)..." -ForegroundColor Cyan

$endpoint = "workflows?`$filter=category eq 5&`$select=workflowid,name,statecode,statuscode,createdon,modifiedon,description&`$orderby=modifiedon desc"

try {
    $result = Invoke-DataverseRequest -Method GET -Endpoint $endpoint -BaseUrl $url -Headers $h

    $stateNames = @{ 0 = "Draft"; 1 = "Activated"; 2 = "Suspended" }

    if ($result.value.Count -eq 0) {
        Write-Host "No cloud flows found." -ForegroundColor Yellow
        return
    }

    Write-Host "`nFound $($result.value.Count) cloud flow(s):`n" -ForegroundColor Green

    foreach ($flow in $result.value) {
        $state = $stateNames[[int]$flow.statecode]
        if (-not $state) { $state = "Unknown" }

        $stateColor = switch ($state) {
            "Activated" { "Green" }
            "Draft"     { "Yellow" }
            "Suspended" { "Red" }
            default     { "Gray" }
        }

        Write-Host "  $($flow.name)" -ForegroundColor White
        Write-Host "    ID       : $($flow.workflowid)" -ForegroundColor Gray
        Write-Host "    State    : $state" -ForegroundColor $stateColor
        Write-Host "    Modified : $($flow.modifiedon)" -ForegroundColor Gray
        if ($flow.description) {
            Write-Host "    Desc     : $($flow.description)" -ForegroundColor Gray
        }
        Write-Host ""
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}
