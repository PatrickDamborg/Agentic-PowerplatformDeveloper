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
    Authorization             = "Bearer $($tokenResponse.access_token)"
    Accept                    = "application/json"
    "Content-Type"            = "application/json; charset=utf-8"
    "OData-MaxVersion"        = "4.0"
    "OData-Version"           = "4.0"
    "MSCRM.SolutionUniqueName" = "PPMextension"
}

# Step 1: Delete old table if it exists
Write-Host "Checking for existing tables to clean up..." -ForegroundColor Cyan

# Delete old new_ prefixed table if it exists
try {
    $existing = Invoke-RestMethod -Uri "$dataverseUrl/EntityDefinitions(LogicalName='new_steeringgroup')?`$select=MetadataId" -Headers @{
        Authorization      = "Bearer $($tokenResponse.access_token)"
        Accept             = "application/json"
        "OData-MaxVersion" = "4.0"
        "OData-Version"    = "4.0"
    }
    Write-Host "Found existing table. Deleting..." -ForegroundColor Yellow
    Invoke-RestMethod -Method Delete -Uri "$dataverseUrl/EntityDefinitions($($existing.MetadataId))" -Headers @{
        Authorization      = "Bearer $($tokenResponse.access_token)"
        Accept             = "application/json"
        "OData-MaxVersion" = "4.0"
        "OData-Version"    = "4.0"
    }
    Write-Host "Deleted old table." -ForegroundColor Green
}
catch {
    Write-Host "No existing table found. Proceeding with creation." -ForegroundColor Cyan
}

# Step 2: Create table with MSCRM.SolutionUniqueName header (per official docs)
# Reference: https://learn.microsoft.com/power-apps/developer/data-platform/webapi/create-update-entity-definitions-using-web-api
$tableJson = @'
{
  "@odata.type": "Microsoft.Dynamics.CRM.EntityMetadata",
  "Attributes": [
    {
      "AttributeType": "String",
      "AttributeTypeName": {
        "Value": "StringType"
      },
      "Description": {
        "@odata.type": "Microsoft.Dynamics.CRM.Label",
        "LocalizedLabels": [
          {
            "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel",
            "Label": "The name of the steering group",
            "LanguageCode": 1033
          }
        ]
      },
      "DisplayName": {
        "@odata.type": "Microsoft.Dynamics.CRM.Label",
        "LocalizedLabels": [
          {
            "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel",
            "Label": "Name",
            "LanguageCode": 1033
          }
        ]
      },
      "IsPrimaryName": true,
      "RequiredLevel": {
        "Value": "None",
        "CanBeChanged": true,
        "ManagedPropertyLogicalName": "canmodifyrequirementlevelsettings"
      },
      "SchemaName": "pda_Name",
      "@odata.type": "Microsoft.Dynamics.CRM.StringAttributeMetadata",
      "FormatName": {
        "Value": "Text"
      },
      "MaxLength": 200
    }
  ],
  "Description": {
    "@odata.type": "Microsoft.Dynamics.CRM.Label",
    "LocalizedLabels": [
      {
        "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel",
        "Label": "Steering Group table for tracking governance groups",
        "LanguageCode": 1033
      }
    ]
  },
  "DisplayCollectionName": {
    "@odata.type": "Microsoft.Dynamics.CRM.Label",
    "LocalizedLabels": [
      {
        "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel",
        "Label": "Steering Groups",
        "LanguageCode": 1033
      }
    ]
  },
  "DisplayName": {
    "@odata.type": "Microsoft.Dynamics.CRM.Label",
    "LocalizedLabels": [
      {
        "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel",
        "Label": "Steering Group",
        "LanguageCode": 1033
      }
    ]
  },
  "HasActivities": false,
  "HasNotes": false,
  "IsActivity": false,
  "OwnershipType": "UserOwned",
  "SchemaName": "pda_SteeringGroup"
}
'@

Write-Host "Creating 'Steering Group' table in solution 'PPMextension'..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Method Post -Uri "$dataverseUrl/EntityDefinitions" -Headers $headers -Body $tableJson -UseBasicParsing
    $entityId = $response.Headers["OData-EntityId"]
    Write-Host "Table 'Steering Group' created successfully!" -ForegroundColor Green
    Write-Host "Entity URI: $entityId" -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
}
