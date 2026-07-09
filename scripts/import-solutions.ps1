param()

# Load env
$envFile = Join-Path $PSScriptRoot "env"
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim())
    }
}

$baseUrl   = $env:DATAVERSE_URL
$clientId  = $env:CLIENT_ID
$tenantId  = $env:TENANT_ID
$clientSecret = $env:CLIENT_SECRET
$resource  = ($baseUrl -replace '/api/data/v9.2.*', '')

# ── Auth ──────────────────────────────────────────────────────────────────────
function Get-Token {
    $body = @{
        grant_type    = "client_credentials"
        client_id     = $clientId
        client_secret = $clientSecret
        scope         = "$resource/.default"
    }
    $resp = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
                               -Method Post -Body $body
    return $resp.access_token
}

# ── Import one solution (async) ───────────────────────────────────────────────
function Import-Solution {
    param([string]$ZipPath, [string]$Label)

    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  Importing: $Label" -ForegroundColor Cyan
    Write-Host "  File     : $(Split-Path $ZipPath -Leaf)" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

    $token = Get-Token
    $headers = @{
        Authorization    = "Bearer $token"
        "Content-Type"   = "application/json"
        "OData-MaxVersion" = "4.0"
        "OData-Version"    = "4.0"
        Accept           = "application/json"
    }

    $bytes  = [System.IO.File]::ReadAllBytes($ZipPath)
    $b64    = [Convert]::ToBase64String($bytes)
    $jobId  = [Guid]::NewGuid().ToString()

    $body = @{
        CustomizationFile              = $b64
        OverwriteUnmanagedCustomizations = $true
        PublishWorkflows               = $true
        ImportJobId                    = $jobId
        HoldingSolution                = $false
        SkipProductUpdateDependencies  = $false
        ConvertToManaged               = $false
        AsyncRibbonProcessing          = $true
    } | ConvertTo-Json -Depth 3

    Write-Host "  Submitting import job..." -ForegroundColor Yellow
    try {
        $resp = Invoke-RestMethod -Uri "$baseUrl/ImportSolutionAsync" `
                                   -Method Post -Headers $headers -Body $body
    } catch {
        Write-Host "  ERROR submitting job: $_" -ForegroundColor Red
        return $false
    }

    $asyncOpId = $resp.AsyncOperationId
    if (-not $asyncOpId) {
        Write-Host "  ERROR: No AsyncOperationId returned." -ForegroundColor Red
        return $false
    }
    Write-Host "  Job ID: $asyncOpId" -ForegroundColor Gray

    # ── Poll until done ───────────────────────────────────────────────────────
    $pollUrl = "$baseUrl/asyncoperations($asyncOpId)?`$select=statecode,statuscode,message,friendlymessage"
    $dots = 0
    while ($true) {
        Start-Sleep -Seconds 10
        $token = Get-Token   # refresh — long imports can expire token
        $headers.Authorization = "Bearer $token"

        try {
            $op = Invoke-RestMethod -Uri $pollUrl -Headers $headers
        } catch {
            Write-Host "  Polling error (will retry): $_" -ForegroundColor DarkYellow
            continue
        }

        # statecode: 0=Ready, 1=Suspended, 2=Locked, 3=Completed
        if ($op.statecode -eq 3) {
            # statuscode: 30=Succeeded, 31=Failed, 32=Cancelled
            if ($op.statuscode -eq 30) {
                Write-Host "  ✓ Succeeded" -ForegroundColor Green
                return $true
            } else {
                $msg = if ($op.friendlymessage) { $op.friendlymessage } else { $op.message }
                Write-Host "  ✗ Failed (statuscode=$($op.statuscode)): $msg" -ForegroundColor Red
                return $false
            }
        }

        $dots++
        Write-Host "  Waiting... (statecode=$($op.statecode), $($dots*10)s elapsed)" -ForegroundColor DarkGray
    }
}

# ── Solution manifest (in import order) ───────────────────────────────────────
$solutionDir = "/Users/patrickdamborg/Library/CloudStorage/OneDrive-Context&/xPM Packages APRIL"

$solutions = @(
    @{ Label = "1. Roadmap";         File = "PowerRoadmap_2.11.0.zip" }
    @{ Label = "2. Gantt";           File = "PumPowerGanttSolution_4.5.0.zip" }
    @{ Label = "3. Matrix";          File = "PowerMatrix_2.3.0.zip" }
    @{ Label = "4. UX";              File = "PowerUX_1.6.7.zip" }
    @{ Label = "5. Financials";      File = "PowerFinancialsSolution_3.18.0.zip" }
    @{ Label = "6. Board";           File = "PowerBoard_2.12.0.zip" }
    @{ Label = "7. Essentials";      File = "PowerPPMEssentials_4.2.0.zip" }
    @{ Label = "8. Resource Planner";File = "ResourcePlan_1.0.0.39.zip" }
    @{ Label = "9. Power Heatmap";   File = "PowerHeatmap_2.1.0.zip" }
)

$results = @()
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($s in $solutions) {
    $path = Join-Path $solutionDir $s.File
    if (-not (Test-Path $path)) {
        Write-Host "  FILE NOT FOUND: $path" -ForegroundColor Red
        $results += [PSCustomObject]@{ Solution = $s.Label; Status = "File not found" }
        continue
    }

    $ok = Import-Solution -ZipPath $path -Label $s.Label
    $results += [PSCustomObject]@{ Solution = $s.Label; Status = if ($ok) { "✓ Success" } else { "✗ Failed" } }
}

$stopwatch.Stop()

Write-Host "`n════════════════════════════════════════" -ForegroundColor White
Write-Host "  IMPORT SUMMARY  (total: $([int]$stopwatch.Elapsed.TotalMinutes) min)" -ForegroundColor White
Write-Host "════════════════════════════════════════" -ForegroundColor White
$results | Format-Table -AutoSize
