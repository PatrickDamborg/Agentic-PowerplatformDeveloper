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
}

# --- Create 'Program' lookup on pda_agentrun -> pum_program ---
Write-Host "Creating 'pda_program' lookup on pda_agentrun -> pum_program..." -ForegroundColor Cyan

$programJson = @'
{
  "@odata.type": "Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata",
  "SchemaName": "pda_agentrun_Program_pum_program",
  "ReferencedEntity": "pum_program",
  "ReferencingEntity": "pda_agentrun",
  "AssociatedMenuConfiguration": { "Behavior": "DoNotDisplay" },
  "CascadeConfiguration": {
    "Assign": "NoCascade",
    "Delete": "RemoveLink",
    "Merge": "NoCascade",
    "Reparent": "NoCascade",
    "Share": "NoCascade",
    "Unshare": "NoCascade"
  },
  "Lookup": {
    "@odata.type": "Microsoft.Dynamics.CRM.LookupAttributeMetadata",
    "AttributeType": "Lookup",
    "AttributeTypeName": { "Value": "LookupType" },
    "DisplayName": {
      "@odata.type": "Microsoft.Dynamics.CRM.Label",
      "LocalizedLabels": [ { "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel", "Label": "Program", "LanguageCode": 1033 } ]
    },
    "RequiredLevel": { "Value": "None", "CanBeChanged": true, "ManagedPropertyLogicalName": "canmodifyrequirementlevelsettings" },
    "SchemaName": "pda_Program"
  }
}
'@

try {
    Invoke-WebRequest -Method Post -Uri "$dataverseUrl/RelationshipDefinitions" -Headers $headers -Body $programJson -UseBasicParsing | Out-Null
    Write-Host "pda_program created!" -ForegroundColor Green
}
catch {
    Write-Host "Error creating pda_program: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}

# --- Create 'Portfolio' lookup on pda_agentrun -> pum_portfolio ---
Write-Host "Creating 'pda_portfolio' lookup on pda_agentrun -> pum_portfolio..." -ForegroundColor Cyan

$portfolioJson = @'
{
  "@odata.type": "Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata",
  "SchemaName": "pda_agentrun_Portfolio_pum_portfolio",
  "ReferencedEntity": "pum_portfolio",
  "ReferencingEntity": "pda_agentrun",
  "AssociatedMenuConfiguration": { "Behavior": "DoNotDisplay" },
  "CascadeConfiguration": {
    "Assign": "NoCascade",
    "Delete": "RemoveLink",
    "Merge": "NoCascade",
    "Reparent": "NoCascade",
    "Share": "NoCascade",
    "Unshare": "NoCascade"
  },
  "Lookup": {
    "@odata.type": "Microsoft.Dynamics.CRM.LookupAttributeMetadata",
    "AttributeType": "Lookup",
    "AttributeTypeName": { "Value": "LookupType" },
    "DisplayName": {
      "@odata.type": "Microsoft.Dynamics.CRM.Label",
      "LocalizedLabels": [ { "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel", "Label": "Portfolio", "LanguageCode": 1033 } ]
    },
    "RequiredLevel": { "Value": "None", "CanBeChanged": true, "ManagedPropertyLogicalName": "canmodifyrequirementlevelsettings" },
    "SchemaName": "pda_Portfolio"
  }
}
'@

try {
    Invoke-WebRequest -Method Post -Uri "$dataverseUrl/RelationshipDefinitions" -Headers $headers -Body $portfolioJson -UseBasicParsing | Out-Null
    Write-Host "pda_portfolio created!" -ForegroundColor Green
}
catch {
    Write-Host "Error creating pda_portfolio: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}

# --- Publish ---
Write-Host "Publishing customizations..." -ForegroundColor Cyan

$publishJson = @'
{
    "ParameterXml": "<importexportxml><entities><entity>pda_agentrun</entity></entities></importexportxml>"
}
'@

try {
    Invoke-WebRequest -Method Post -Uri "$dataverseUrl/PublishXml" -Headers $headers -Body $publishJson -UseBasicParsing | Out-Null
    Write-Host "Customizations published!" -ForegroundColor Green
}
catch {
    Write-Host "Error publishing: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}
