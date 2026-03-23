param(
    [string]$SolutionName = "PPMextension",
    [string]$Filter
)

Import-Module (Join-Path $PSScriptRoot "..\helpers.psm1") -Force
$conn = Initialize-DataverseConnection -EnvPath (Join-Path $PSScriptRoot "..\.env")
$h = $conn.Headers
$url = $conn.BaseUrl

Write-Host "Querying environment variables..." -ForegroundColor Cyan

$endpoint = "environmentvariabledefinitions?`$select=schemaname,displayname,type,defaultvalue&`$expand=environmentvariablevalues(`$select=value)"

if ($Filter) {
    $endpoint += "&`$filter=contains(schemaname,'$Filter') or contains(displayname,'$Filter')"
}

try {
    $result = Invoke-DataverseRequest -Method GET -Endpoint $endpoint -BaseUrl $url -Headers $h

    # Map type values to names
    $typeNames = @{
        100000000 = "String"
        100000001 = "Number"
        100000002 = "Integer"
        100000003 = "Boolean"
        100000004 = "JSON"
        100000005 = "DataSource"
    }

    if ($result.value.Count -eq 0) {
        Write-Host "No environment variables found." -ForegroundColor Yellow
        return
    }

    Write-Host "`nFound $($result.value.Count) environment variable(s):`n" -ForegroundColor Green

    foreach ($v in $result.value) {
        $typeName = $typeNames[[int]$v.type]
        if (-not $typeName) { $typeName = "Unknown ($($v.type))" }

        $currentValue = ""
        if ($v.environmentvariablevalues -and $v.environmentvariablevalues.Count -gt 0) {
            $currentValue = $v.environmentvariablevalues[0].value
        }

        Write-Host "  $($v.schemaname)" -ForegroundColor White
        Write-Host "    Display Name : $($v.displayname)" -ForegroundColor Gray
        Write-Host "    Type         : $typeName" -ForegroundColor Gray
        Write-Host "    Default      : $($v.defaultvalue)" -ForegroundColor Gray
        Write-Host "    Current      : $currentValue" -ForegroundColor Gray
        Write-Host ""
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}
