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

# --- Step 1: Create Role choice column ---
# Reference: https://learn.microsoft.com/power-apps/developer/data-platform/webapi/create-update-column-definitions-using-web-api#create-a-choice-column
Write-Host "Creating 'Role' choice column..." -ForegroundColor Cyan

$roleJson = @'
{
  "@odata.type": "Microsoft.Dynamics.CRM.PicklistAttributeMetadata",
  "AttributeType": "Picklist",
  "AttributeTypeName": {
    "Value": "PicklistType"
  },
  "SourceTypeMask": 0,
  "OptionSet": {
    "@odata.type": "Microsoft.Dynamics.CRM.OptionSetMetadata",
    "Options": [
      {
        "Value": 100000000,
        "Label": {
          "@odata.type": "Microsoft.Dynamics.CRM.Label",
          "LocalizedLabels": [
            {
              "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel",
              "Label": "Critical",
              "LanguageCode": 1033
            }
          ]
        }
      },
      {
        "Value": 100000001,
        "Label": {
          "@odata.type": "Microsoft.Dynamics.CRM.Label",
          "LocalizedLabels": [
            {
              "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel",
              "Label": "Essential",
              "LanguageCode": 1033
            }
          ]
        }
      }
    ],
    "IsGlobal": false,
    "OptionSetType": "Picklist"
  },
  "Description": {
    "@odata.type": "Microsoft.Dynamics.CRM.Label",
    "LocalizedLabels": [
      {
        "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel",
        "Label": "The role of the steering group member",
        "LanguageCode": 1033
      }
    ]
  },
  "DisplayName": {
    "@odata.type": "Microsoft.Dynamics.CRM.Label",
    "LocalizedLabels": [
      {
        "@odata.type": "Microsoft.Dynamics.CRM.LocalizedLabel",
        "Label": "Role",
        "LanguageCode": 1033
      }
    ]
  },
  "RequiredLevel": {
    "Value": "ApplicationRequired",
    "CanBeChanged": true,
    "ManagedPropertyLogicalName": "canmodifyrequirementlevelsettings"
  },
  "SchemaName": "pda_Role"
}
'@

try {
    Invoke-WebRequest -Method Post -Uri "$dataverseUrl/EntityDefinitions(LogicalName='pda_steeringgroup')/Attributes" -Headers $headers -Body $roleJson -UseBasicParsing | Out-Null
    Write-Host "Role column created!" -ForegroundColor Green
}
catch {
    Write-Host "Error creating Role: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}

# --- Step 2: Create Member lookup to systemuser ---
# Reference: https://learn.microsoft.com/power-apps/developer/data-platform/webapi/create-update-entity-relationships-using-web-api#create-a-one-to-many-relationship
Write-Host "Creating 'Member' lookup to systemuser..." -ForegroundColor Cyan

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

try {
    Invoke-WebRequest -Method Post -Uri "$dataverseUrl/RelationshipDefinitions" -Headers $headers -Body $memberJson -UseBasicParsing | Out-Null
    Write-Host "Member lookup created!" -ForegroundColor Green
}
catch {
    Write-Host "Error creating Member lookup: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}

# --- Step 3: Publish customizations ---
# Reference: https://learn.microsoft.com/power-apps/developer/data-platform/webapi/reference/publishxml
Write-Host "Publishing customizations..." -ForegroundColor Cyan

$publishJson = @'
{
    "ParameterXml": "<importexportxml><entities><entity>pda_steeringgroup</entity></entities></importexportxml>"
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

Write-Host "`nDone! Steering Group table now has:" -ForegroundColor Green
Write-Host "  - Name (primary column)" -ForegroundColor Green
Write-Host "  - Initiative (lookup to pum_initiative)" -ForegroundColor Green
Write-Host "  - Role (choice: Critical, Essential)" -ForegroundColor Green
Write-Host "  - Member (lookup to pum_resource)" -ForegroundColor Green
