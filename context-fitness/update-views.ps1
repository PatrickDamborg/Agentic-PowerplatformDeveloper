#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Update default views for the three Fitness Training tables to show relevant columns.
#>
param(
    [string]$SolutionName = "ContextFitnessAgent"
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
Import-Module (Join-Path $root "helpers.psm1") -Force
$conn = Get-DataverseHeaders -SolutionName $SolutionName -EnvPath (Join-Path $root ".env")

function Update-View {
    param(
        [string]$TableLogicalName,
        [string]$ViewNameFilter,   # partial match on name
        [string]$FetchXml,
        [string]$LayoutXml
    )

    $views = Invoke-RestMethod -Uri "$($conn.BaseUrl)/savedqueries?`$filter=returnedtypecode eq '$TableLogicalName' and querytype eq 0&`$select=savedqueryid,name&`$orderby=name" -Headers $conn.Headers
    $view = $views.value | Where-Object { $_.name -like "*$ViewNameFilter*" } | Select-Object -First 1

    if (-not $view) {
        Write-Host "  No view matching '$ViewNameFilter' on $TableLogicalName — skipping." -ForegroundColor Yellow
        return
    }

    Write-Host "  Updating view '$($view.name)' ($($view.savedqueryid))..." -ForegroundColor Gray
    $patchBody = @{ fetchxml = $FetchXml; layoutxml = $LayoutXml } | ConvertTo-Json
    $patchHeaders = $conn.Headers.Clone()
    $patchHeaders["If-Match"] = "*"

    Invoke-RestMethod -Method PATCH -Uri "$($conn.BaseUrl)/savedqueries($($view.savedqueryid))" -Headers $patchHeaders -Body $patchBody
    Write-Host "  Updated." -ForegroundColor Green
}

# ============================================================
# Training Profile — Active view
# ============================================================
Write-Host "Updating Training Profile view..." -ForegroundColor Cyan
Update-View -TableLogicalName "context_trainingprofile" -ViewNameFilter "Active" `
    -FetchXml @'
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false">
  <entity name="context_trainingprofile">
    <attribute name="context_name" />
    <attribute name="context_gender" />
    <attribute name="context_age" />
    <attribute name="context_weight" />
    <attribute name="context_goals" />
    <attribute name="context_trainingprofileid" />
    <order attribute="context_name" descending="false" />
    <filter type="and">
      <condition attribute="statecode" operator="eq" value="0" />
    </filter>
  </entity>
</fetch>
'@ `
    -LayoutXml @'
<grid name="resultset" object="10944" jump="context_name" select="1" preview="1" icon="1">
  <row name="result" id="context_trainingprofileid">
    <cell name="context_name"   width="220" />
    <cell name="context_gender" width="120" />
    <cell name="context_age"    width="80"  />
    <cell name="context_weight" width="100" />
    <cell name="context_goals"  width="380" />
  </row>
</grid>
'@

# ============================================================
# Training Programme — Active view
# ============================================================
Write-Host "Updating Training Programme view..." -ForegroundColor Cyan
Update-View -TableLogicalName "context_trainingprogramme" -ViewNameFilter "Active" `
    -FetchXml @'
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false">
  <entity name="context_trainingprogramme">
    <attribute name="context_name" />
    <attribute name="context_trainingprofileid" />
    <attribute name="context_status" />
    <attribute name="context_startdate" />
    <attribute name="context_durationweeks" />
    <attribute name="context_trainingprogrammeid" />
    <order attribute="context_name" descending="false" />
    <filter type="and">
      <condition attribute="statecode" operator="eq" value="0" />
    </filter>
  </entity>
</fetch>
'@ `
    -LayoutXml @'
<grid name="resultset" object="10945" jump="context_name" select="1" preview="1" icon="1">
  <row name="result" id="context_trainingprogrammeid">
    <cell name="context_name"              width="220" />
    <cell name="context_trainingprofileid" width="180" />
    <cell name="context_status"            width="110" />
    <cell name="context_startdate"         width="120" />
    <cell name="context_durationweeks"     width="100" />
  </row>
</grid>
'@

# ============================================================
# Exercise — Active view
# ============================================================
Write-Host "Updating Exercise view..." -ForegroundColor Cyan
Update-View -TableLogicalName "context_exercise" -ViewNameFilter "Active" `
    -FetchXml @'
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false">
  <entity name="context_exercise">
    <attribute name="context_name" />
    <attribute name="context_trainingprogrammeid" />
    <attribute name="context_dayofweek" />
    <attribute name="context_sequence" />
    <attribute name="context_sets" />
    <attribute name="context_reps" />
    <attribute name="context_weightintensity" />
    <attribute name="context_exerciseid" />
    <order attribute="context_sequence" descending="false" />
    <filter type="and">
      <condition attribute="statecode" operator="eq" value="0" />
    </filter>
  </entity>
</fetch>
'@ `
    -LayoutXml @'
<grid name="resultset" object="10946" jump="context_name" select="1" preview="1" icon="1">
  <row name="result" id="context_exerciseid">
    <cell name="context_name"               width="200" />
    <cell name="context_trainingprogrammeid" width="180" />
    <cell name="context_dayofweek"          width="110" />
    <cell name="context_sequence"           width="80"  />
    <cell name="context_sets"               width="70"  />
    <cell name="context_reps"               width="100" />
    <cell name="context_weightintensity"    width="130" />
  </row>
</grid>
'@

Write-Host "`nAll views updated." -ForegroundColor Green
