# Fixes the three verified blockers preventing a real "fire agent -> Agent Run" from working:
#   A. Add pda_message (Multiline Text) column to pda_agentrun
#   B. Grant Create/Read/Write on pda_agentrun (Global) to Projectum xPM Project Manager
#   C. Set pda_scope = Initiative (100000000) on Status Reporting Auto Agent

$envFile = Join-Path $PSScriptRoot ".env"
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim(), "Process")
    }
}

$tenantId = $env:TENANT_ID
$clientId = $env:CLIENT_ID
$clientSecret = $env:CLIENT_SECRET
$baseUrl = $env:DATAVERSE_URL

$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$tokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = $env:DATAVERSE_SCOPE
}
$tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $tokenBody

$headers = @{
    Authorization              = "Bearer $($tokenResponse.access_token)"
    Accept                     = "application/json"
    "Content-Type"             = "application/json; charset=utf-8"
    "OData-MaxVersion"         = "4.0"
    "OData-Version"            = "4.0"
    "MSCRM.SolutionUniqueName" = "xPMAIUseCasesdemo"
}

# --- Fix A: pda_message column on pda_agentrun ---
Write-Host "`n=== Fix A: Creating 'pda_message' column on pda_agentrun ===" -ForegroundColor Cyan

$messageJson = @'
{
  "@odata.type": "Microsoft.Dynamics.CRM.MemoAttributeMetadata",
  "AttributeType": "Memo",
  "AttributeTypeName": { "Value": "MemoType" },
  "MaxLength": 4000,
  "Format": "TextArea",
  "Description": {
    "@odata.type": "Microsoft.Dynamics.CRM.Label",
    "LocalizedLabels": [ { "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel", "Label": "Message payload sent when firing the agent run", "LanguageCode": 1033 } ]
  },
  "DisplayName": {
    "@odata.type": "Microsoft.Dynamics.CRM.Label",
    "LocalizedLabels": [ { "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel", "Label": "Message", "LanguageCode": 1033 } ]
  },
  "RequiredLevel": {
    "Value": "None",
    "CanBeChanged": true,
    "ManagedPropertyLogicalName": "canmodifyrequirementlevelsettings"
  },
  "SchemaName": "pda_Message"
}
'@

try {
    Invoke-WebRequest -Method Post -Uri "$baseUrl/EntityDefinitions(LogicalName='pda_agentrun')/Attributes" -Headers $headers -Body $messageJson -UseBasicParsing | Out-Null
    Write-Host "pda_message created!" -ForegroundColor Green
}
catch {
    Write-Host "Error creating pda_message: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}

Write-Host "Publishing pda_agentrun..." -ForegroundColor Cyan
$publishJson = '{"ParameterXml": "<importexportxml><entities><entity>pda_agentrun</entity></entities></importexportxml>"}'
try {
    Invoke-WebRequest -Method Post -Uri "$baseUrl/PublishXml" -Headers $headers -Body $publishJson -UseBasicParsing | Out-Null
    Write-Host "Published!" -ForegroundColor Green
}
catch {
    Write-Host "Error publishing: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}

# --- Fix B: grant Create/Read/Write on pda_agentrun to Projectum xPM Project Manager ---
Write-Host "`n=== Fix B: Granting Create/Read/Write on pda_agentrun to Projectum xPM Project Manager ===" -ForegroundColor Cyan

$roleId = "745bd355-09d0-eb11-bacc-000d3a278297"
$privNames = @("prvCreatepda_agentrun", "prvReadpda_agentrun", "prvWritepda_agentrun")
$privileges = @()
foreach ($name in $privNames) {
    $priv = Invoke-RestMethod -Uri "$baseUrl/privileges?`$filter=name eq '$name'" -Headers $headers
    if ($priv.value.Count -eq 0) {
        Write-Host "Privilege not found: $name" -ForegroundColor Red
        continue
    }
    $privileges += @{ PrivilegeId = $priv.value[0].privilegeid; Depth = "Global" }
    Write-Host "Found $name -> $($priv.value[0].privilegeid)" -ForegroundColor White
}

if ($privileges.Count -gt 0) {
    $body = @{ Privileges = $privileges } | ConvertTo-Json -Depth 5
    try {
        Invoke-WebRequest -Method Post -Uri "$baseUrl/roles($roleId)/Microsoft.Dynamics.CRM.AddPrivilegesRole" -Headers $headers -Body $body -UseBasicParsing | Out-Null
        Write-Host "Privileges granted!" -ForegroundColor Green
    }
    catch {
        Write-Host "Error granting privileges: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
    }
}

# --- Fix C: set pda_scope = Initiative (100000000) on Status Reporting Auto Agent ---
Write-Host "`n=== Fix C: Setting pda_scope = Initiative on Status Reporting Auto Agent ===" -ForegroundColor Cyan

$agentId = "25c2f7cd-4279-f111-ab0e-6045bd03a8c3"
$patchHeaders = $headers.Clone()
$patchHeaders["If-Match"] = "*"
$scopeBody = @{ pda_scope = 100000000 } | ConvertTo-Json

try {
    Invoke-WebRequest -Method Patch -Uri "$baseUrl/pda_monitoredagents($agentId)" -Headers $patchHeaders -Body $scopeBody -UseBasicParsing | Out-Null
    Write-Host "pda_scope set!" -ForegroundColor Green
}
catch {
    Write-Host "Error setting pda_scope: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}

Write-Host "`nDone." -ForegroundColor Green
