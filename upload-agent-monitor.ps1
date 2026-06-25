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

$webResourceId = "e742d295-8565-f111-ab0d-0022480a51dc"
$htmlPath = "/Users/patrickdamborg/Library/CloudStorage/OneDrive-Context&/xPM AI/agent-monitor/agent-monitor.html"

$bytes   = [System.IO.File]::ReadAllBytes($htmlPath)
$b64     = [System.Convert]::ToBase64String($bytes)

$body = @{ content = $b64 } | ConvertTo-Json -Depth 2

Write-Host "Uploading agent-monitor.html ($([math]::Round($bytes.Length/1024,1)) KB) to web resource $webResourceId..."
try {
  $resp = Invoke-WebRequest -Method PATCH -Uri "$baseUrl/webresourceset($webResourceId)" -Headers $headers -Body $body -ErrorAction Stop
  Write-Host "  PATCH OK: $($resp.StatusCode)"
} catch {
  Write-Host "  ERROR: $($_.ErrorDetails.Message)"
  throw
}

# Publish
Write-Host "Publishing web resource..."
$publishBody = '{"ParameterXml":"<importexportxml><webresources><webresource>{e742d295-8565-f111-ab0d-0022480a51dc}</webresource></webresources></importexportxml>"}'
$resp2 = Invoke-WebRequest -Method POST -Uri "$baseUrl/PublishXml" -Headers $headers -Body $publishBody -ErrorAction Stop
Write-Host "  Publish OK: $($resp2.StatusCode)"
Write-Host ""
Write-Host "Done. Hard-refresh the browser tab showing the Agent Monitor to pick up the changes."
