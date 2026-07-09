$envVars = Get-Content .env | ForEach-Object {
  $p = $_ -split "=", 2; if ($p.Count -eq 2) { [pscustomobject]@{ k=$p[0].Trim(); v=$p[1].Trim() } }
} | Where-Object { $_.k }
$baseUrl = ($envVars | Where-Object k -eq "DATAVERSE_URL").v
$token   = (Get-Content .token -Raw).Trim()
$headers = @{ Authorization="Bearer $token"; Accept="application/json" }

$forms = Invoke-RestMethod -Uri "$baseUrl/systemforms?`$filter=objecttypecode eq 'pda_monitoredagent' and type eq 2&`$select=formid,name,formxml" -Headers $headers
$f = $forms.value[0]
Write-Host "Form: $($f.name) [$($f.formid)]"
$f.formxml | Out-File -FilePath "monitor-form-current.xml" -Encoding utf8
Write-Host "Saved to monitor-form-current.xml"
