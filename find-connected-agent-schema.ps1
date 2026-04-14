# Find how connected agents are stored - check all unique componenttypes and look for bot references
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

# Get all distinct component types across all bots
Write-Host "=== All unique botcomponent types in this env ==="
$all = Invoke-RestMethod -Uri "$env:DATAVERSE_URL/botcomponents?`$select=componenttype,name&`$top=200" -Headers $headers
$all.value | Group-Object componenttype | Sort-Object Name | ForEach-Object {
    Write-Host "  Type $($_.Name): $($_.Count) components (e.g. '$($_.Group[0].name)')"
}

# Look for any botcomponent that has content referencing another bot ID
Write-Host "`n=== Botcomponents with non-empty content (first 10) ==="
$withContent = $all.value | Where-Object { $_.content -and $_.content.Length -gt 5 } | Select-Object -First 10
$withContent | ForEach-Object {
    Write-Host "  Type:$($_.componenttype) Name:'$($_.name)' Content(100c):$($_.content.Substring(0, [Math]::Min(100,$_.content.Length)))"
}
