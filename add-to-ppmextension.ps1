# Load .env file
$envFile = Join-Path $PSScriptRoot ".env"
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim(), "Process")
    }
}

$tenantId = $env:TENANT_ID
$clientId = $env:CLIENT_ID
$clientSecret = $env:CLIENT_SECRET
$dataverseUrl = $env:DATAVERSE_URL

# Get token
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$tokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = $env:DATAVERSE_SCOPE
}
$tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $tokenBody

$headers = @{
    Authorization      = "Bearer $($tokenResponse.access_token)"
    Accept             = "application/json"
    "Content-Type"     = "application/json"
    "OData-MaxVersion" = "4.0"
    "OData-Version"    = "4.0"
}

# Get entity metadata ID
$entityMeta = Invoke-RestMethod -Uri "$dataverseUrl/EntityDefinitions(LogicalName='new_steeringgroup')?`$select=MetadataId" -Headers $headers

$addBody = @{
    ComponentId            = $entityMeta.MetadataId
    ComponentType          = 1
    SolutionUniqueName     = "PPMextension"
    AddRequiredComponents  = $false
} | ConvertTo-Json

try {
    Invoke-RestMethod -Method Post -Uri "$dataverseUrl/AddSolutionComponent" -Headers $headers -Body $addBody
    Write-Host "Table 'Steering Group' added to solution 'PPM extension' successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}
