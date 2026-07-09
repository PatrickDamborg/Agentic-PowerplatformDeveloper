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

# --- Step 1: Create 'Scope' choice column on pda_monitoredagent ---
Write-Host "Creating 'pda_scope' choice column on pda_monitoredagent..." -ForegroundColor Cyan

$scopeJson = @'
{
  "@odata.type": "Microsoft.Dynamics.CRM.PicklistAttributeMetadata",
  "AttributeType": "Picklist",
  "AttributeTypeName": { "Value": "PicklistType" },
  "SourceTypeMask": 0,
  "OptionSet": {
    "@odata.type": "Microsoft.Dynamics.CRM.OptionSetMetadata",
    "Options": [
      {
        "Value": 100000000,
        "Label": {
          "@odata.type": "Microsoft.Dynamics.CRM.Label",
          "LocalizedLabels": [ { "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel", "Label": "Initiative", "LanguageCode": 1033 } ]
        }
      },
      {
        "Value": 100000001,
        "Label": {
          "@odata.type": "Microsoft.Dynamics.CRM.Label",
          "LocalizedLabels": [ { "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel", "Label": "Program", "LanguageCode": 1033 } ]
        }
      },
      {
        "Value": 100000002,
        "Label": {
          "@odata.type": "Microsoft.Dynamics.CRM.Label",
          "LocalizedLabels": [ { "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel", "Label": "Portfolio", "LanguageCode": 1033 } ]
        }
      }
    ],
    "IsGlobal": false,
    "OptionSetType": "Picklist"
  },
  "Description": {
    "@odata.type": "Microsoft.Dynamics.CRM.Label",
    "LocalizedLabels": [ { "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel", "Label": "Which record level the dashboard's project picker should browse for this agent", "LanguageCode": 1033 } ]
  },
  "DisplayName": {
    "@odata.type": "Microsoft.Dynamics.CRM.Label",
    "LocalizedLabels": [ { "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel", "Label": "Scope", "LanguageCode": 1033 } ]
  },
  "RequiredLevel": {
    "Value": "None",
    "CanBeChanged": true,
    "ManagedPropertyLogicalName": "canmodifyrequirementlevelsettings"
  },
  "SchemaName": "pda_Scope"
}
'@

try {
    Invoke-WebRequest -Method Post -Uri "$dataverseUrl/EntityDefinitions(LogicalName='pda_monitoredagent')/Attributes" -Headers $headers -Body $scopeJson -UseBasicParsing | Out-Null
    Write-Host "pda_scope created!" -ForegroundColor Green
}
catch {
    Write-Host "Error creating pda_scope: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}

# --- Step 2: Extend pda_initiative lookup on pda_agentrun to also target pum_program ---
Write-Host "Extending pda_initiative lookup to accept pum_program..." -ForegroundColor Cyan

$programJson = @'
{
  "@odata.type": "Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata",
  "SchemaName": "pda_agentrun_Initiative_pum_program",
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
    "SchemaName": "pda_Initiative"
  }
}
'@

try {
    Invoke-WebRequest -Method Post -Uri "$dataverseUrl/RelationshipDefinitions" -Headers $headers -Body $programJson -UseBasicParsing | Out-Null
    Write-Host "pum_program target added!" -ForegroundColor Green
}
catch {
    Write-Host "Error adding pum_program target: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}

# --- Step 3: Extend pda_initiative lookup on pda_agentrun to also target pum_portfolio ---
Write-Host "Extending pda_initiative lookup to accept pum_portfolio..." -ForegroundColor Cyan

$portfolioJson = @'
{
  "@odata.type": "Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata",
  "SchemaName": "pda_agentrun_Initiative_pum_portfolio",
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
    "SchemaName": "pda_Initiative"
  }
}
'@

try {
    Invoke-WebRequest -Method Post -Uri "$dataverseUrl/RelationshipDefinitions" -Headers $headers -Body $portfolioJson -UseBasicParsing | Out-Null
    Write-Host "pum_portfolio target added!" -ForegroundColor Green
}
catch {
    Write-Host "Error adding pum_portfolio target: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}

# --- Step 4: Publish ---
Write-Host "Publishing customizations..." -ForegroundColor Cyan

$publishJson = @'
{
    "ParameterXml": "<importexportxml><entities><entity>pda_monitoredagent</entity><entity>pda_agentrun</entity></entities></importexportxml>"
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
