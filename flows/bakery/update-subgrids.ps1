#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Add related-record subgrid tabs to pda_order and pda_product main forms.
    - Order form  → Order Lines subgrid (relationship: pda_order_orderline)
    - Product form → Order Lines subgrid (relationship: pda_product_orderline)
#>

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
Import-Module (Join-Path $root "helpers.psm1") -Force

$conn     = Get-DataverseHeaders -SolutionName "HempelSweetBakery" -EnvPath (Join-Path $root ".env")
$base     = $conn.BaseUrl
$hdrs     = $conn.Headers
$patchHdrs = $hdrs.Clone(); $patchHdrs["If-Match"] = "*"

$formOrder   = "10db4814-52dd-46c8-bc06-359514d6f564"
$formProduct = "52d1fe0b-4bf0-4cdd-ab05-374a2b5680ea"

function Get-FormXml { param([string]$Id)
    $r = Invoke-RestMethod -Uri "$base/systemforms($Id)?`$select=formxml" -Headers $hdrs
    return $r.formxml
}
function Patch-Form { param([string]$Id, [string]$Xml)
    $body = @{ formxml = $Xml } | ConvertTo-Json -Depth 3
    Invoke-RestMethod -Method PATCH -Uri "$base/systemforms($Id)" -Headers $patchHdrs -Body $body | Out-Null
}
function Publish { param([string]$Table)
    $body = @{ ParameterXml = "<importexportxml><entities><entity>$Table</entity></entities></importexportxml>" } | ConvertTo-Json
    Invoke-RestMethod -Method POST -Uri "$base/PublishXml" -Headers $hdrs -Body $body | Out-Null
}

# ── Order Lines view ID (used inside the subgrid parameters) ─────────────────
$viewActiveOrderLines = "c3ddc9a2-c0fe-414e-afc9-8d33821a8b9c"

# ── Subgrid tab XML snippets ─────────────────────────────────────────────────
# Order Lines tab for ORDER form (relationship: pda_order_orderline)
$orderLinesTab = @"
<tab verticallayout="true" id="{D1B2C3D4-0002-0001-0001-000000000001}" IsUserDefined="1" expanded="true">
  <labels><label description="Order Lines" languagecode="1033" /></labels>
  <columns>
    <column width="100%">
      <sections>
        <section name="sec_orderlines_grid" showlabel="false" showbar="false" columns="1" id="{D1B2C3D4-0002-0001-0002-000000000001}">
          <labels><label description="Order Lines" languagecode="1033" /></labels>
          <rows>
            <row>
              <cell id="{D1B2C3D4-0002-0001-0003-000000000001}" showlabel="false" colspan="2" rowspan="8" auto="true">
                <labels><label description="Order Lines" languagecode="1033" /></labels>
                <control id="subgrid_orderlines" classid="{E7A81278-8635-4d9e-8D4D-59480B391C5B}">
                  <parameters>
                    <TargetEntityType>pda_orderline</TargetEntityType>
                    <RelationshipName>pda_order_orderline</RelationshipName>
                    <ViewId>{$viewActiveOrderLines}</ViewId>
                    <AutoExpand>Fixed</AutoExpand>
                    <EnableQuickFind>true</EnableQuickFind>
                    <EnableViewPicker>false</EnableViewPicker>
                    <EnableJumpBar>false</EnableJumpBar>
                    <EnableChartPicker>false</EnableChartPicker>
                    <RecordsPerPage>10</RecordsPerPage>
                    <RelationshipName>pda_order_orderline</RelationshipName>
                    <TargetEntityType>pda_orderline</TargetEntityType>
                  </parameters>
                </control>
              </cell>
            </row>
          </rows>
        </section>
      </sections>
    </column>
  </columns>
</tab>
"@

# Order Lines tab for PRODUCT form (relationship: pda_product_orderline)
$productOrderLinesTab = @"
<tab verticallayout="true" id="{E1B2C3D4-0003-0001-0001-000000000001}" IsUserDefined="1" expanded="true">
  <labels><label description="Order Lines" languagecode="1033" /></labels>
  <columns>
    <column width="100%">
      <sections>
        <section name="sec_product_orderlines_grid" showlabel="false" showbar="false" columns="1" id="{E1B2C3D4-0003-0001-0002-000000000001}">
          <labels><label description="Order Lines" languagecode="1033" /></labels>
          <rows>
            <row>
              <cell id="{E1B2C3D4-0003-0001-0003-000000000001}" showlabel="false" colspan="2" rowspan="8" auto="true">
                <labels><label description="Order Lines" languagecode="1033" /></labels>
                <control id="subgrid_product_orderlines" classid="{E7A81278-8635-4d9e-8D4D-59480B391C5B}">
                  <parameters>
                    <ViewId>{$viewActiveOrderLines}</ViewId>
                    <AutoExpand>Fixed</AutoExpand>
                    <EnableQuickFind>true</EnableQuickFind>
                    <EnableViewPicker>false</EnableViewPicker>
                    <EnableJumpBar>false</EnableJumpBar>
                    <EnableChartPicker>false</EnableChartPicker>
                    <RecordsPerPage>10</RecordsPerPage>
                    <RelationshipName>pda_product_orderline</RelationshipName>
                    <TargetEntityType>pda_orderline</TargetEntityType>
                  </parameters>
                </control>
              </cell>
            </row>
          </rows>
        </section>
      </sections>
    </column>
  </columns>
</tab>
"@

# ── Patch Order form ─────────────────────────────────────────────────────────
Write-Host "Patching Order form with Order Lines subgrid..." -ForegroundColor Cyan
$orderXml = Get-FormXml $formOrder
# Inject new tab before </tabs>
$orderXml = $orderXml -replace '</tabs>', "$orderLinesTab</tabs>"
Patch-Form $formOrder $orderXml
Write-Host "  Done." -ForegroundColor Green

# ── Patch Product form ────────────────────────────────────────────────────────
Write-Host "Patching Product form with Order Lines subgrid..." -ForegroundColor Cyan
$productXml = Get-FormXml $formProduct
$productXml = $productXml -replace '</tabs>', "$productOrderLinesTab</tabs>"
Patch-Form $formProduct $productXml
Write-Host "  Done." -ForegroundColor Green

# ── Publish ───────────────────────────────────────────────────────────────────
Write-Host "Publishing..." -ForegroundColor Cyan
Publish "pda_order"
Publish "pda_product"
Write-Host "`n✓ Subgrids added to Order and Product forms." -ForegroundColor Green
