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
    Authorization              = "Bearer $($tokenResponse.access_token)"
    Accept                     = "application/json"
    "Content-Type"             = "application/json; charset=utf-8"
    "OData-MaxVersion"         = "4.0"
    "OData-Version"            = "4.0"
    "MSCRM.SolutionUniqueName" = "PPMextension"
}

$memberJson = @'
{
  "@odata.type": "Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata",
  "SchemaName": "pda_resource_steeringgroup",
  "ReferencedAttribute": "pum_resourceid",
  "ReferencedEntity": "pum_resource",
  "ReferencingEntity": "pda_steeringgroup",
  "AssociatedMenuConfiguration": {
    "Behavior": "UseLabel",
    "Group": "Details",
    "Label": {
      "@odata.type": "Microsoft.Dynamics.CRM.Label",
      "LocalizedLabels": [
        {
          "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel",
          "Label": "Steering Groups",
          "LanguageCode": 1033
        }
      ]
    },
    "Order": 10000
  },
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
    "AttributeTypeName": {
      "Value": "LookupType"
    },
    "Description": {
      "@odata.type": "Microsoft.Dynamics.CRM.Label",
      "LocalizedLabels": [
        {
          "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel",
          "Label": "The resource who is a member of this steering group",
          "LanguageCode": 1033
        }
      ]
    },
    "DisplayName": {
      "@odata.type": "Microsoft.Dynamics.CRM.Label",
      "LocalizedLabels": [
        {
          "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel",
          "Label": "Member",
          "LanguageCode": 1033
        }
      ]
    },
    "RequiredLevel": {
      "Value": "ApplicationRequired",
      "CanBeChanged": true,
      "ManagedPropertyLogicalName": "canmodifyrequirementlevelsettings"
    },
    "SchemaName": "pda_MemberId"
  }
}
'@

Write-Host "Creating 'Member' lookup to pum_resource..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Method Post -Uri "$env:DATAVERSE_URL/RelationshipDefinitions" -Headers $headers -Body $memberJson -UseBasicParsing | Out-Null
    Write-Host "Member lookup created!" -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}

# Publish
Write-Host "Publishing customizations..." -ForegroundColor Cyan
$publishJson = '{"ParameterXml": "<importexportxml><entities><entity>pda_steeringgroup</entity></entities></importexportxml>"}'
try {
    Invoke-WebRequest -Method Post -Uri "$env:DATAVERSE_URL/PublishXml" -Headers $headers -Body $publishJson -UseBasicParsing | Out-Null
    Write-Host "Published!" -ForegroundColor Green
}
catch {
    Write-Host "Error publishing: $($_.Exception.Message)" -ForegroundColor Red
}
