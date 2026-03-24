param(
    [Parameter(Mandatory)][string]$SchemaName,
    [Parameter(Mandatory)][string]$DisplayName,
    [ValidateSet("String","Integer","Boolean","JSON")][string]$Type = "String",
    [string]$DefaultValue,
    [string]$CurrentValue,
    [string]$SolutionName = "PPMextension"
)

# Resolve repository root
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) { $root = Split-Path $root -Parent }
if (-not $root) { throw "Cannot find helpers.psm1 in any parent directory." }
Import-Module (Join-Path $root "helpers.psm1") -Force
$conn = Get-DataverseHeaders -SolutionName $SolutionName -EnvPath (Join-Path $root ".env")
$h = $conn.Headers
$url = $conn.BaseUrl

# Map type names to Dataverse type values
$typeMap = @{
    "String"  = 100000000
    "Integer" = 100000002
    "Boolean" = 100000003
    "JSON"    = 100000004
}

Write-Host "Creating environment variable '$DisplayName' ($SchemaName)..." -ForegroundColor Cyan

$defBody = @{
    schemaname  = $SchemaName
    displayname = $DisplayName
    type        = $typeMap[$Type]
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Method Post -Uri "$url/environmentvariabledefinitions" -Headers $h -Body $defBody -UseBasicParsing
    $defId = ($response.Headers["OData-EntityId"] -replace '.*\(([^)]+)\).*','$1')
    Write-Host "Definition created: $defId" -ForegroundColor Green
}
catch {
    Write-Host "Error creating definition: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
    exit 1
}

# Set default value if provided
if ($DefaultValue) {
    Write-Host "Setting default value..." -ForegroundColor Cyan
    $patchBody = @{ defaultvalue = $DefaultValue } | ConvertTo-Json
    try {
        Invoke-WebRequest -Method Patch -Uri "$url/environmentvariabledefinitions($defId)" -Headers $h -Body $patchBody -UseBasicParsing | Out-Null
        Write-Host "Default value set." -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Could not set default value: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Create current value if provided
if ($CurrentValue) {
    Write-Host "Creating current value..." -ForegroundColor Cyan
    # Remove solution header for value record — it inherits from the definition
    $valueHeaders = $h.Clone()
    $valueBody = @{
        schemaname = "${SchemaName}Value"
        value      = $CurrentValue
        "EnvironmentVariableDefinitionId@odata.bind" = "environmentvariabledefinitions($defId)"
    } | ConvertTo-Json

    try {
        Invoke-WebRequest -Method Post -Uri "$url/environmentvariablevalues" -Headers $valueHeaders -Body $valueBody -UseBasicParsing | Out-Null
        Write-Host "Current value set." -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Could not set current value: $($_.Exception.Message)" -ForegroundColor Yellow
        if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Yellow }
    }
}

Write-Host "`nEnvironment variable '$DisplayName' created successfully." -ForegroundColor Green
