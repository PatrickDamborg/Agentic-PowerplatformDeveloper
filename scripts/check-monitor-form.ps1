$envVars = Get-Content .env | ForEach-Object {
  $p = $_ -split "=", 2; if ($p.Count -eq 2) { [pscustomobject]@{ k=$p[0].Trim(); v=$p[1].Trim() } }
} | Where-Object { $_.k }
$baseUrl = ($envVars | Where-Object k -eq "DATAVERSE_URL").v
$token   = (Get-Content .token -Raw).Trim()
$headers = @{ Authorization="Bearer $token"; Accept="application/json" }

$forms = Invoke-RestMethod -Uri "$baseUrl/systemforms?`$filter=objecttypecode eq 'pda_monitoredagent' and type eq 2&`$select=formid,name,formxml" -Headers $headers
Write-Host "Forms found: $($forms.value.Count)"
foreach ($f in $forms.value) {
  Write-Host "[$($f.formid)] $($f.name)"
  $controls = [regex]::Matches($f.formxml, 'datafieldname="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
  Write-Host "Fields on form: $($controls -join ', ')"
}
