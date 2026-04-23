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

# Client credentials flow
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = $env:DATAVERSE_SCOPE
}

try {
    $tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body
    $tokenResponse.access_token | Out-File (Join-Path $PSScriptRoot ".token") -NoNewline
    Write-Host "Token acquired successfully!" -ForegroundColor Green

    # Test connection with WhoAmI
    $headers = @{
        Authorization = "Bearer $($tokenResponse.access_token)"
        Accept        = "application/json"
    }
    $whoami = Invoke-RestMethod -Uri "$dataverseUrl/WhoAmI" -Headers $headers
    Write-Host "Connected as User ID: $($whoami.UserId)" -ForegroundColor Green
    Write-Host "Organization ID: $($whoami.OrganizationId)" -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
}
