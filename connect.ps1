param(
    [string]$EnvPath = ".env"
)

# Load environment variables
if (-not (Test-Path $EnvPath)) {
    Write-Error "Environment file not found: $EnvPath"
    exit 1
}

$env_vars = @{}
Get-Content $EnvPath | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $env_vars[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$DATAVERSE_URL = $env_vars['DATAVERSE_URL']
$TENANT_ID = $env_vars['TENANT_ID']
$CLIENT_ID = $env_vars['CLIENT_ID']
$CLIENT_SECRET = $env_vars['CLIENT_SECRET']

if (-not $DATAVERSE_URL -or -not $TENANT_ID -or -not $CLIENT_ID -or -not $CLIENT_SECRET) {
    Write-Error "Missing required environment variables in $EnvPath"
    exit 1
}

# Authenticate using client credentials
$tokenUrl = "https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token"
$scope = "https://pdausa.crm.dynamics.com/.default"

$body = @{
    client_id     = $CLIENT_ID
    client_secret = $CLIENT_SECRET
    scope         = $scope
    grant_type    = "client_credentials"
}

Write-Host "Authenticating to Dataverse..."
try {
    $response = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
    $token = $response.access_token

    if (-not $token) {
        Write-Error "Failed to obtain access token"
        exit 1
    }

    # Save token to file
    $token | Out-File -FilePath ".token" -Encoding UTF8 -NoNewline
    Write-Host "✓ Authentication successful"
    Write-Host "Token saved to .token"
} catch {
    Write-Error "Authentication failed: $_"
    exit 1
}
