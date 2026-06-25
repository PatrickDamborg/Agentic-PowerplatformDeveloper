param(
  [string]$EnvPath = ".env",
  [string]$TokenPath = ".token"
)

$envVars = Get-Content $EnvPath | ForEach-Object {
  $p = $_ -split "=", 2
  if ($p.Count -eq 2) { [pscustomobject]@{ k = $p[0].Trim(); v = $p[1].Trim() } }
} | Where-Object { $_.k }

$baseUrl = ($envVars | Where-Object k -eq "DATAVERSE_URL").v
$token   = (Get-Content $TokenPath -Raw).Trim()

$headers = @{
  Authorization              = "Bearer $token"
  "Content-Type"             = "application/json; charset=utf-8"
  Accept                     = "application/json"
  "OData-MaxVersion"         = "4.0"
  "OData-Version"            = "4.0"
  "MSCRM.SolutionUniqueName" = "xPMAIUseCasesdemo"
}

function Invoke-DV {
  param($Method, $Uri, $Body)
  try {
    $resp = Invoke-WebRequest -Method $Method -Uri $Uri -Headers $headers -Body $Body -ErrorAction Stop
    Write-Host "  OK $($resp.StatusCode)"
    return $resp
  } catch {
    $msg = $_.ErrorDetails.Message
    if (-not $msg) { $msg = $_.Exception.Message }
    Write-Host "  ERROR: $msg"
    throw
  }
}

# ── 1. Check / create table ────────────────────────────────────────────────
Write-Host "Checking for pda_monitoredagent..."
$check = Invoke-RestMethod -Uri "$baseUrl/EntityDefinitions?`$filter=LogicalName eq 'pda_monitoredagent'&`$select=MetadataId,LogicalName" -Headers $headers
if ($check.value.Count -gt 0) {
  $entityId = $check.value[0].MetadataId
  Write-Host "  Table already exists: $entityId"
} else {
  Write-Host "Creating table pda_monitoredagent..."
  $tableBody = @'
{
  "@odata.type": "Microsoft.Dynamics.CRM.EntityMetadata",
  "SchemaName": "pda_monitoredagent",
  "DisplayName":           { "LocalizedLabels": [{ "Label": "Monitored Agent",  "LanguageCode": 1033 }] },
  "DisplayCollectionName": { "LocalizedLabels": [{ "Label": "Monitored Agents", "LanguageCode": 1033 }] },
  "Description":           { "LocalizedLabels": [{ "Label": "Agents registered for the Context& Agent Monitor dashboard", "LanguageCode": 1033 }] },
  "OwnershipType": "UserOwned",
  "HasActivities": false,
  "HasNotes": false,
  "IsActivity": false,
  "PrimaryNameAttribute": "pda_name",
  "Attributes": [
    {
      "@odata.type": "Microsoft.Dynamics.CRM.StringAttributeMetadata",
      "SchemaName": "pda_name",
      "IsPrimaryName": true,
      "RequiredLevel": { "Value": "ApplicationRequired" },
      "MaxLength": 200,
      "DisplayName": { "LocalizedLabels": [{ "Label": "Name", "LanguageCode": 1033 }] },
      "AttributeType": "String",
      "AttributeTypeName": { "Value": "StringType" }
    }
  ]
}
'@
  $resp = Invoke-DV -Method POST -Uri "$baseUrl/EntityDefinitions" -Body $tableBody
  $entityId = [regex]::Match($resp.Headers["OData-EntityId"], "[0-9a-f-]{36}").Value
  Write-Host "  Created table: $entityId"
}

$attrUrl = "$baseUrl/EntityDefinitions($entityId)/Attributes"

# ── 2. pda_agenttype (Choice) ─────────────────────────────────────────────
Write-Host "Adding pda_agenttype (Choice)..."
$agentTypeBody = @'
{
  "@odata.type": "Microsoft.Dynamics.CRM.PicklistAttributeMetadata",
  "SchemaName": "pda_agenttype",
  "DisplayName": { "LocalizedLabels": [{ "Label": "Agent Type", "LanguageCode": 1033 }] },
  "Description": { "LocalizedLabels": [{ "Label": "Whether this is a Copilot Studio agent or a Cloud Flow", "LanguageCode": 1033 }] },
  "RequiredLevel": { "Value": "ApplicationRequired" },
  "OptionSet": {
    "@odata.type": "Microsoft.Dynamics.CRM.OptionSetMetadata",
    "IsGlobal": false,
    "OptionSetType": "Picklist",
    "Options": [
      { "Value": 100000000, "Label": { "LocalizedLabels": [{ "Label": "Copilot Studio Agent", "LanguageCode": 1033 }] } },
      { "Value": 100000001, "Label": { "LocalizedLabels": [{ "Label": "Cloud Flow",           "LanguageCode": 1033 }] } }
    ]
  }
}
'@
Invoke-DV -Method POST -Uri $attrUrl -Body $agentTypeBody | Out-Null

# ── 3. pda_targetid (Text) ────────────────────────────────────────────────
Write-Host "Adding pda_targetid (Text)..."
$targetIdBody = @'
{
  "@odata.type": "Microsoft.Dynamics.CRM.StringAttributeMetadata",
  "SchemaName": "pda_targetid",
  "DisplayName": { "LocalizedLabels": [{ "Label": "Target ID", "LanguageCode": 1033 }] },
  "Description": { "LocalizedLabels": [{ "Label": "GUID of the Copilot Studio bot or Cloud Flow (workflowid)", "LanguageCode": 1033 }] },
  "RequiredLevel": { "Value": "ApplicationRequired" },
  "MaxLength": 100,
  "AttributeType": "String",
  "AttributeTypeName": { "Value": "StringType" }
}
'@
Invoke-DV -Method POST -Uri $attrUrl -Body $targetIdBody | Out-Null

# ── 4. Publish ────────────────────────────────────────────────────────────
Write-Host "Publishing pda_monitoredagent..."
$publishBody = '{"ParameterXml": "<importexportxml><entities><entity>pda_monitoredagent</entity></entities></importexportxml>"}'
Invoke-DV -Method POST -Uri "$baseUrl/PublishXml" -Body $publishBody | Out-Null

Write-Host ""
Write-Host "Done. Table pda_monitoredagent is live in xPM - AI Use Cases demo."
Write-Host "  Entity set : pda_monitoredagents"
Write-Host "  Columns    : pda_name, pda_agenttype, pda_targetid"
