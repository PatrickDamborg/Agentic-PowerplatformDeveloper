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

# Get token
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$tokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "https://pdaprimary.api.crm4.dynamics.com/.default"
}
$tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $tokenBody

$headers = @{
    Authorization              = "Bearer $($tokenResponse.access_token)"
    Accept                     = "application/json"
    "Content-Type"             = "application/json; charset=utf-8"
    "OData-MaxVersion"         = "4.0"
    "OData-Version"            = "4.0"
    "MSCRM.SolutionUniqueName" = "PPMextension"
}

# Create One-to-Many relationship: pum_initiative (referenced/parent) -> pda_steeringgroup (referencing/child)
# Reference: https://learn.microsoft.com/power-apps/developer/data-platform/webapi/create-update-entity-relationships-using-web-api#create-a-one-to-many-relationship
$relationshipJson = @'
{
  "@odata.type": "Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata",
  "SchemaName": "pda_initiative_steeringgroup",
  "ReferencedAttribute": "pum_initiativeid",
  "ReferencedEntity": "pum_initiative",
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
          "Label": "The initiative this steering group belongs to",
          "LanguageCode": 1033
        }
      ]
    },
    "DisplayName": {
      "@odata.type": "Microsoft.Dynamics.CRM.Label",
      "LocalizedLabels": [
        {
          "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel",
          "Label": "Initiative",
          "LanguageCode": 1033
        }
      ]
    },
    "RequiredLevel": {
      "Value": "None",
      "CanBeChanged": true,
      "ManagedPropertyLogicalName": "canmodifyrequirementlevelsettings"
    },
    "SchemaName": "pda_InitiativeId"
  }
}
'@

Write-Host "Creating lookup column 'Initiative' on pda_steeringgroup -> pum_initiative..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Method Post -Uri "$dataverseUrl/RelationshipDefinitions" -Headers $headers -Body $relationshipJson -UseBasicParsing
    Write-Host "Lookup column created successfully!" -ForegroundColor Green
    $entityId = $response.Headers["OData-EntityId"]
    Write-Host "Relationship URI: $entityId" -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
}
