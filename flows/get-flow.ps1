param(
    [string]$FlowName,
    [string]$FlowId,
    [string]$OutputPath
)

if (-not $FlowName -and -not $FlowId) {
    Write-Host "Error: Provide either -FlowName or -FlowId" -ForegroundColor Red
    exit 1
}

Import-Module (Join-Path $PSScriptRoot "..\helpers.psm1") -Force
$conn = Initialize-DataverseConnection -EnvPath (Join-Path $PSScriptRoot "..\.env")
$h = $conn.Headers
$url = $conn.BaseUrl

if ($FlowId) {
    Write-Host "Fetching flow by ID: $FlowId" -ForegroundColor Cyan
    $endpoint = "workflows($FlowId)?`$select=workflowid,name,statecode,statuscode,clientdata,description,createdon,modifiedon"
}
else {
    Write-Host "Searching for flow: $FlowName" -ForegroundColor Cyan
    $endpoint = "workflows?`$filter=name eq '$FlowName' and category eq 5&`$select=workflowid,name,statecode,statuscode,clientdata,description,createdon,modifiedon"
}

try {
    $result = Invoke-DataverseRequest -Method GET -Endpoint $endpoint -BaseUrl $url -Headers $h

    # Handle single vs collection result
    $flow = if ($FlowId) { $result } else { $result.value | Select-Object -First 1 }

    if (-not $flow) {
        Write-Host "Flow not found." -ForegroundColor Yellow
        exit 1
    }

    $stateNames = @{ 0 = "Draft"; 1 = "Activated"; 2 = "Suspended" }
    $state = $stateNames[[int]$flow.statecode]

    Write-Host "`nFlow: $($flow.name)" -ForegroundColor Green
    Write-Host "  ID       : $($flow.workflowid)" -ForegroundColor Gray
    Write-Host "  State    : $state" -ForegroundColor Gray
    Write-Host "  Created  : $($flow.createdon)" -ForegroundColor Gray
    Write-Host "  Modified : $($flow.modifiedon)" -ForegroundColor Gray

    # Parse and output clientdata
    if ($flow.clientdata) {
        $clientData = $flow.clientdata | ConvertFrom-Json

        if ($OutputPath) {
            $clientData | ConvertTo-Json -Depth 20 | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Host "`nFlow definition written to: $OutputPath" -ForegroundColor Green
        }
        else {
            Write-Host "`n--- Flow Definition (clientdata) ---" -ForegroundColor Cyan
            $clientData | ConvertTo-Json -Depth 20
        }
    }
    else {
        Write-Host "`nNo clientdata found on this flow." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}
