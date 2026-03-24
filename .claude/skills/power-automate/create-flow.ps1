param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$DefinitionPath,
    [string]$Description = "",
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

if (-not (Test-Path $DefinitionPath)) {
    Write-Host "Error: Definition file not found: $DefinitionPath" -ForegroundColor Red
    exit 1
}

Write-Host "Reading flow definition from: $DefinitionPath" -ForegroundColor Cyan
$definitionContent = Get-Content -Path $DefinitionPath -Raw

# Validate it's valid JSON
try {
    $definitionContent | ConvertFrom-Json | Out-Null
}
catch {
    Write-Host "Error: Definition file is not valid JSON" -ForegroundColor Red
    exit 1
}

# Build the request body using PowerShell hashtable for proper JSON serialization
# clientdata must be a JSON *string* (stringified JSON inside the outer JSON)
$clientDataString = ($definitionContent | ConvertFrom-Json | ConvertTo-Json -Depth 30 -Compress)

$flowObj = @{
    name          = $Name
    type          = 1
    category      = 5
    statecode     = 0
    statuscode    = 1
    primaryentity = "none"
    description   = $Description
    clientdata    = $clientDataString
}

$flowBody = $flowObj | ConvertTo-Json -Depth 5

Write-Host "Creating cloud flow '$Name' in solution '$SolutionName'..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Method Post -Uri "$url/workflows" -Headers $h -Body $flowBody -UseBasicParsing
    $entityUri = $response.Headers["OData-EntityId"]
    $flowId = $entityUri -replace '.*\(([^)]+)\).*','$1'

    Write-Host "`nFlow created successfully!" -ForegroundColor Green
    Write-Host "  Name : $Name" -ForegroundColor Green
    Write-Host "  ID   : $flowId" -ForegroundColor Green
    Write-Host "  State: Draft (inactive)" -ForegroundColor Yellow
    Write-Host "`nTo activate, run:" -ForegroundColor Cyan
    Write-Host "  pwsh flows/toggle-flow.ps1 -FlowId '$flowId' -Action Activate" -ForegroundColor White
}
catch {
    Write-Host "Error creating flow: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}
