$envVars = Get-Content .env | ForEach-Object {
  $p = $_ -split "=", 2; if ($p.Count -eq 2) { [pscustomobject]@{ k=$p[0].Trim(); v=$p[1].Trim() } }
} | Where-Object { $_.k }
$baseUrl = ($envVars | Where-Object k -eq "DATAVERSE_URL").v
$token   = (Get-Content .token -Raw).Trim()
$headers = @{ Authorization="Bearer $token"; Accept="application/json" }

$results = Invoke-RestMethod -Uri "$baseUrl/webresourceset?`$filter=contains(name,'monitor') or contains(name,'agent')&`$select=webresourceid,name,displayname,webresourcetype" -Headers $headers
Write-Host "Matching web resources: $($results.value.Count)"
$results.value | ForEach-Object { Write-Host "  [$($_.webresourceid)] $($_.name) — $($_.displayname) (type $($_.webresourcetype))" }
