param([string]$BotId = 'bdda9805-bbf2-f011-8406-7c1e5221480b')

$env_file = Join-Path $PSScriptRoot 'env'
Get-Content $env_file | ForEach-Object {
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
    'OData-MaxVersion' = '4.0'
    'OData-Version'    = '4.0'
}

$botDetail = Invoke-RestMethod -Uri "$env:DATAVERSE_URL/bots($BotId)?`$select=name,configuration" -Headers $headers
Write-Host "=== $($botDetail.name) ==="
Write-Host $botDetail.configuration

$components = Invoke-RestMethod -Uri "$env:DATAVERSE_URL/botcomponents?`$filter=_parentbotid_value eq $BotId&`$select=name,componenttype&`$top=30" -Headers $headers
Write-Host "`nBotComponents ($($components.value.Count) total):"
$components.value | ForEach-Object { Write-Host "  Type:$($_.componenttype) Name:$($_.name)" }
