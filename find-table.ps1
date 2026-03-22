# Load .env
$envFile = Join-Path $PSScriptRoot ".env"
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim(), "Process")
    }
}

$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$env:TENANT_ID/oauth2/v2.0/token" -Body @{
    grant_type    = "client_credentials"
    client_id     = $env:CLIENT_ID
    client_secret = $env:CLIENT_SECRET
    scope         = "https://pdaprimary.api.crm4.dynamics.com/.default"
}

$headers = @{
    Authorization      = "Bearer $($tokenResponse.access_token)"
    Accept             = "application/json"
    "OData-MaxVersion" = "4.0"
    "OData-Version"    = "4.0"
}

$result = Invoke-RestMethod -Uri "$env:DATAVERSE_URL/EntityDefinitions?`$select=LogicalName,SchemaName" -Headers $headers
$result.value | Where-Object { $_.LogicalName -like "*pum_res*" } | ForEach-Object {
    Write-Host "$($_.LogicalName) - $($_.SchemaName)"
}
