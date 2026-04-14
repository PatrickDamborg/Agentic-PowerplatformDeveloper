param([string]$EnvFile = (Join-Path $PSScriptRoot 'env'))

Get-Content $EnvFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim(), 'Process')
    }
}
$tokenUrl = "https://login.microsoftonline.com/$env:TENANT_ID/oauth2/v2.0/token"
$body = @{ grant_type='client_credentials'; client_id=$env:CLIENT_ID; client_secret=$env:CLIENT_SECRET; scope='https://pdaprimary.api.crm4.dynamics.com/.default' }
$token = (Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body).access_token
$headers = @{
    Authorization      = "Bearer $token"
    Accept             = 'application/json'
    'Content-Type'     = 'application/json; charset=utf-8'
    'OData-MaxVersion' = '4.0'
    'OData-Version'    = '4.0'
}

$botIds = @(
    @{ name='Risk Analyst';            id='82cf57a5-4438-f111-88b5-7c1e5221480b' },
    @{ name='Project Health Monitor';  id='84cf57a5-4438-f111-88b5-7c1e5221480b' }
)

foreach ($bot in $botIds) {
    Write-Host "Adding '$($bot.name)' to XPMCopilotSkills..."
    $payload = '{"ComponentId":"' + $bot.id + '","ComponentType":10212,"SolutionUniqueName":"XPMCopilotSkills","AddRequiredComponents":false}'
    try {
        Invoke-RestMethod -Method Post -Uri "$env:DATAVERSE_URL/AddSolutionComponent" -Headers $headers -Body $payload | Out-Null
        Write-Host "  Done."
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)"
        if ($_.ErrorDetails.Message) { Write-Host "  $($_.ErrorDetails.Message)" }
    }
}
