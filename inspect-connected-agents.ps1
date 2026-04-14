# Inspect botcomponent type 15 (agent manifest) content and look for connected agent relationships
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

# Get botcomponent type 15 (agent manifest) content
$type15 = Invoke-RestMethod -Uri "$env:DATAVERSE_URL/botcomponents?`$filter=_parentbotid_value eq $BotId and componenttype eq 15&`$select=name,componenttype,content,botcomponentid" -Headers $headers
Write-Host "=== Type 15 components ==="
$type15.value | ForEach-Object {
    Write-Host "Name: $($_.name)"
    Write-Host "Content: $($_.content)"
    Write-Host "---"
}

# Check for bot_bot relationship (connected agents)
Write-Host "`n=== Checking bot navigation for connected agents ==="
try {
    $connectedAgents = Invoke-RestMethod -Uri "$env:DATAVERSE_URL/bots($BotId)/bot_connectedagent_bot?`$select=name,botid" -Headers $headers
    Write-Host "Connected agents via bot_connectedagent_bot: $($connectedAgents.value.Count)"
    $connectedAgents.value | ForEach-Object { Write-Host "  $($_.name) ($($_.botid))" }
} catch {
    Write-Host "bot_connectedagent_bot nav: $($_.Exception.Message)"
}

# Try another navigation
try {
    $related = Invoke-RestMethod -Uri "$env:DATAVERSE_URL/bots($BotId)/bot_parentbotid?`$select=name,botid" -Headers $headers
    Write-Host "bot_parentbotid: $($related.value.Count)"
} catch {
    Write-Host "bot_parentbotid nav: $($_.Exception.Message)"
}
