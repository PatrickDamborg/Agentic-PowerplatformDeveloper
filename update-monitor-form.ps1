$envVars = Get-Content .env | ForEach-Object {
  $p = $_ -split "=", 2; if ($p.Count -eq 2) { [pscustomobject]@{ k=$p[0].Trim(); v=$p[1].Trim() } }
} | Where-Object { $_.k }
$baseUrl = ($envVars | Where-Object k -eq "DATAVERSE_URL").v
$token   = (Get-Content .token -Raw).Trim()
$headers = @{
  Authorization              = "Bearer $token"
  "Content-Type"             = "application/json; charset=utf-8"
  Accept                     = "application/json"
  "OData-MaxVersion"         = "4.0"
  "OData-Version"            = "4.0"
  "MSCRM.SolutionUniqueName" = "xPMAIUseCasesdemo"
  "If-Match"                 = "*"
}

$formId = "60e378b6-e628-4892-b865-b9389ee0f8f2"

# Two new row cells — fresh GUIDs
$cellId1 = [System.Guid]::NewGuid().ToString("B").ToUpper()  # pda_agenttype
$cellId2 = [System.Guid]::NewGuid().ToString("B").ToUpper()  # pda_targetid

# classid reference:
#   Single-line text : {4273EDBD-AC1D-40d3-9FB2-095C621B552D}
#   Picklist (choice): {3EF39988-22BB-4f0b-BBBE-64B5A3748ADE}

$newFormXml = @"
<form><tabs><tab verticallayout="true" id="{5a3c9202-0d4a-401d-94d0-2e9e4d7898fb}" IsUserDefined="1"><labels><label description="General" languagecode="1033" /></labels><columns><column width="100%"><sections><section showlabel="false" showbar="false" IsUserDefined="0" id="{394eeef5-55af-4246-af31-730dbe3a2358}"><labels><label description="General" languagecode="1033" /></labels><rows><row><cell id="{ebcd8c13-fbd0-455a-ad2f-382fb5409ea3}"><labels><label description="Name" languagecode="1033" /></labels><control id="pda_name" classid="{4273EDBD-AC1D-40d3-9FB2-095C621B552D}" datafieldname="pda_name" /></cell></row><row><cell id="{7068d356-ed04-4bc5-ac33-d9b8a99bb5c1}"><labels><label description="Owner" languagecode="1033" /></labels><control id="ownerid" classid="{270BD3DB-D9AF-4782-9025-509E298DEC0A}" datafieldname="ownerid" /></cell></row><row><cell id="$cellId1"><labels><label description="Agent Type" languagecode="1033" /></labels><control id="pda_agenttype" classid="{3EF39988-22BB-4f0b-BBBE-64B5A3748ADE}" datafieldname="pda_agenttype" /></cell></row><row><cell id="$cellId2"><labels><label description="Target ID" languagecode="1033" /></labels><control id="pda_targetid" classid="{4273EDBD-AC1D-40d3-9FB2-095C621B552D}" datafieldname="pda_targetid" /></cell></row></rows></section></sections></column></columns></tab></tabs></form>
"@

$body = @{ formxml = $newFormXml } | ConvertTo-Json -Depth 3

Write-Host "PATCHing form $formId..."
try {
  $resp = Invoke-WebRequest -Method PATCH -Uri "$baseUrl/systemforms($formId)" -Headers $headers -Body $body -ErrorAction Stop
  Write-Host "  PATCH OK: $($resp.StatusCode)"
} catch {
  Write-Host "  ERROR: $($_.ErrorDetails.Message)"
  throw
}

# Publish
Write-Host "Publishing pda_monitoredagent..."
$publishBody = '{"ParameterXml":"<importexportxml><entities><entity>pda_monitoredagent</entity></entities></importexportxml>"}'
$resp2 = Invoke-WebRequest -Method POST -Uri "$baseUrl/PublishXml" -Headers $headers -Body $publishBody -ErrorAction Stop
Write-Host "  Publish OK: $($resp2.StatusCode)"

Write-Host ""
Write-Host "Form updated. Fields now on the Information form:"
Write-Host "  pda_name, ownerid, pda_agenttype, pda_targetid"
