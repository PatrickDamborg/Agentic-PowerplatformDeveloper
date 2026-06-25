#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Update main forms and active views for pda_product, pda_order, pda_orderline
    in the Hempel Sweet Bakery model-driven app.
#>

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
while ($root -and -not (Test-Path (Join-Path $root "helpers.psm1"))) {
    $root = Split-Path $root -Parent
}
Import-Module (Join-Path $root "helpers.psm1") -Force

$conn  = Get-DataverseHeaders -SolutionName "HempelSweetBakery" -EnvPath (Join-Path $root ".env")
$base  = $conn.BaseUrl
$hdrs  = $conn.Headers

$patchHdrs = $hdrs.Clone()
$patchHdrs["If-Match"] = "*"

function Patch-Form   { param([string]$Id, [string]$Xml)
    $body = @{ formxml = $Xml } | ConvertTo-Json -Depth 3
    Invoke-RestMethod -Method PATCH -Uri "$base/systemforms($Id)" -Headers $patchHdrs -Body $body | Out-Null
}
function Patch-View   { param([string]$Id, [string]$Fetch, [string]$Layout)
    $body = @{ fetchxml = $Fetch; layoutxml = $Layout } | ConvertTo-Json -Depth 3
    Invoke-RestMethod -Method PATCH -Uri "$base/savedqueries($Id)" -Headers $patchHdrs -Body $body | Out-Null
}
function Publish      { param([string]$Table)
    $body = @{ ParameterXml = "<importexportxml><entities><entity>$Table</entity></entities></importexportxml>" } | ConvertTo-Json
    Invoke-RestMethod -Method POST -Uri "$base/PublishXml" -Headers $hdrs -Body $body | Out-Null
}

# ── GUIDs collected from pre-flight query ───────────────────────────────────
$formProduct    = "52d1fe0b-4bf0-4cdd-ab05-374a2b5680ea"
$formOrder      = "10db4814-52dd-46c8-bc06-359514d6f564"
$formOrderLine  = "0a30ec49-d1fc-4d10-9f64-6bdd425fa87f"

$viewActiveProducts   = "37ba94f3-172e-4c37-be8f-b7599a3d9e82"
$viewActiveOrders     = "2b196e07-c9bb-4095-a738-c12042acc273"
$viewActiveOrderLines = "c3ddc9a2-c0fe-414e-afc9-8d33821a8b9c"

# ============================================================================
# FORMS
# ============================================================================

# ── Product form ─────────────────────────────────────────────────────────────
# Sections: Details (name, category, price, available) | Info (description, allergens, dailystock)
Write-Host "Patching Product form..." -ForegroundColor Cyan
Patch-Form $formProduct @'
<form>
  <tabs>
    <tab verticallayout="true" id="{A1B2C3D4-0001-0001-0001-000000000001}" IsUserDefined="1">
      <labels><label description="General" languagecode="1033" /></labels>
      <columns>
        <column width="100%">
          <sections>
            <section name="sec_details" showlabel="true" showbar="false" columns="2" id="{A1B2C3D4-0001-0001-0002-000000000001}">
              <labels><label description="Product Details" languagecode="1033" /></labels>
              <rows>
                <row>
                  <cell id="{A1B2C3D4-0001-0001-0003-000000000001}">
                    <labels><label description="Name" languagecode="1033" /></labels>
                    <control id="pda_name" classid="{4273EDBD-AC1D-40d3-9FB2-095C621B552D}" datafieldname="pda_name" disabled="false" />
                  </cell>
                  <cell id="{A1B2C3D4-0001-0001-0003-000000000002}">
                    <labels><label description="Category" languagecode="1033" /></labels>
                    <control id="pda_category" classid="{3EF39988-22BB-4f0b-BBBE-64B5A3748AEE}" datafieldname="pda_category" disabled="false" />
                  </cell>
                </row>
                <row>
                  <cell id="{A1B2C3D4-0001-0001-0003-000000000003}">
                    <labels><label description="Price" languagecode="1033" /></labels>
                    <control id="pda_price" classid="{C6D124CA-7EDA-4a60-AEA9-7FB8D318B68F}" datafieldname="pda_price" disabled="false" />
                  </cell>
                  <cell id="{A1B2C3D4-0001-0001-0003-000000000004}">
                    <labels><label description="Available" languagecode="1033" /></labels>
                    <control id="pda_available" classid="{67FAC785-CD58-4f9f-ABB3-4B7DDC6ED5ED}" datafieldname="pda_available" disabled="false" />
                  </cell>
                </row>
                <row>
                  <cell id="{A1B2C3D4-0001-0001-0003-000000000005}">
                    <labels><label description="Daily Stock" languagecode="1033" /></labels>
                    <control id="pda_dailystock" classid="{C6D124CA-7EDA-4a60-AEA9-7FB8D318B68F}" datafieldname="pda_dailystock" disabled="false" />
                  </cell>
                  <cell id="{A1B2C3D4-0001-0001-0003-000000000006}" showlabel="false" />
                </row>
              </rows>
            </section>
            <section name="sec_info" showlabel="true" showbar="false" columns="1" id="{A1B2C3D4-0001-0001-0004-000000000001}">
              <labels><label description="Description &amp; Allergens" languagecode="1033" /></labels>
              <rows>
                <row>
                  <cell id="{A1B2C3D4-0001-0001-0004-000000000002}">
                    <labels><label description="Description" languagecode="1033" /></labels>
                    <control id="pda_description" classid="{E0DECE4B-6FC8-4a8f-A065-082708572369}" datafieldname="pda_description" disabled="false" />
                  </cell>
                </row>
                <row>
                  <cell id="{A1B2C3D4-0001-0001-0004-000000000003}">
                    <labels><label description="Allergens" languagecode="1033" /></labels>
                    <control id="pda_allergens" classid="{4273EDBD-AC1D-40d3-9FB2-095C621B552D}" datafieldname="pda_allergens" disabled="false" />
                  </cell>
                </row>
              </rows>
            </section>
          </sections>
        </column>
      </columns>
    </tab>
  </tabs>
</form>
'@

# ── Order form ───────────────────────────────────────────────────────────────
# Sections: Order Details (name, status, fulfilment, pickupdate, orderdate) | Customer (customer lookup, notes) | Financials (total)
Write-Host "Patching Order form..." -ForegroundColor Cyan
Patch-Form $formOrder @'
<form>
  <tabs>
    <tab verticallayout="true" id="{B1B2C3D4-0001-0001-0001-000000000001}" IsUserDefined="1">
      <labels><label description="General" languagecode="1033" /></labels>
      <columns>
        <column width="100%">
          <sections>
            <section name="sec_order" showlabel="true" showbar="false" columns="2" id="{B1B2C3D4-0001-0001-0002-000000000001}">
              <labels><label description="Order Details" languagecode="1033" /></labels>
              <rows>
                <row>
                  <cell id="{B1B2C3D4-0001-0001-0003-000000000001}">
                    <labels><label description="Order Reference" languagecode="1033" /></labels>
                    <control id="pda_name" classid="{4273EDBD-AC1D-40d3-9FB2-095C621B552D}" datafieldname="pda_name" disabled="false" />
                  </cell>
                  <cell id="{B1B2C3D4-0001-0001-0003-000000000002}">
                    <labels><label description="Status" languagecode="1033" /></labels>
                    <control id="pda_status" classid="{3EF39988-22BB-4f0b-BBBE-64B5A3748AEE}" datafieldname="pda_status" disabled="false" />
                  </cell>
                </row>
                <row>
                  <cell id="{B1B2C3D4-0001-0001-0003-000000000003}">
                    <labels><label description="Fulfilment" languagecode="1033" /></labels>
                    <control id="pda_fulfilment" classid="{3EF39988-22BB-4f0b-BBBE-64B5A3748AEE}" datafieldname="pda_fulfilment" disabled="false" />
                  </cell>
                  <cell id="{B1B2C3D4-0001-0001-0003-000000000004}">
                    <labels><label description="Pickup / Delivery Date" languagecode="1033" /></labels>
                    <control id="pda_pickupdate" classid="{5B773807-9FB2-42db-97C3-7A91EFF8ADFF}" datafieldname="pda_pickupdate" disabled="false" />
                  </cell>
                </row>
                <row>
                  <cell id="{B1B2C3D4-0001-0001-0003-000000000005}">
                    <labels><label description="Order Date" languagecode="1033" /></labels>
                    <control id="pda_orderdate" classid="{5B773807-9FB2-42db-97C3-7A91EFF8ADFF}" datafieldname="pda_orderdate" disabled="false" />
                  </cell>
                  <cell id="{B1B2C3D4-0001-0001-0003-000000000006}">
                    <labels><label description="Total" languagecode="1033" /></labels>
                    <control id="pda_total" classid="{C6D124CA-7EDA-4a60-AEA9-7FB8D318B68F}" datafieldname="pda_total" disabled="false" />
                  </cell>
                </row>
              </rows>
            </section>
            <section name="sec_customer" showlabel="true" showbar="false" columns="2" id="{B1B2C3D4-0001-0001-0004-000000000001}">
              <labels><label description="Customer" languagecode="1033" /></labels>
              <rows>
                <row>
                  <cell id="{B1B2C3D4-0001-0001-0004-000000000002}">
                    <labels><label description="Customer" languagecode="1033" /></labels>
                    <control id="pda_customerid" classid="{270BD3DB-D9AF-4782-9025-509E298DEC0A}" datafieldname="pda_customerid" disabled="false" />
                  </cell>
                  <cell id="{B1B2C3D4-0001-0001-0004-000000000003}" showlabel="false" />
                </row>
                <row>
                  <cell id="{B1B2C3D4-0001-0001-0004-000000000004}" colspan="2">
                    <labels><label description="Notes" languagecode="1033" /></labels>
                    <control id="pda_notes" classid="{E0DECE4B-6FC8-4a8f-A065-082708572369}" datafieldname="pda_notes" disabled="false" />
                  </cell>
                </row>
              </rows>
            </section>
          </sections>
        </column>
      </columns>
    </tab>
  </tabs>
</form>
'@

# ── Order Line form ──────────────────────────────────────────────────────────
Write-Host "Patching Order Line form..." -ForegroundColor Cyan
Patch-Form $formOrderLine @'
<form>
  <tabs>
    <tab verticallayout="true" id="{C1B2C3D4-0001-0001-0001-000000000001}" IsUserDefined="1">
      <labels><label description="General" languagecode="1033" /></labels>
      <columns>
        <column width="100%">
          <sections>
            <section name="sec_line" showlabel="true" showbar="false" columns="2" id="{C1B2C3D4-0001-0001-0002-000000000001}">
              <labels><label description="Line Details" languagecode="1033" /></labels>
              <rows>
                <row>
                  <cell id="{C1B2C3D4-0001-0001-0003-000000000001}">
                    <labels><label description="Name" languagecode="1033" /></labels>
                    <control id="pda_name" classid="{4273EDBD-AC1D-40d3-9FB2-095C621B552D}" datafieldname="pda_name" disabled="false" />
                  </cell>
                  <cell id="{C1B2C3D4-0001-0001-0003-000000000002}">
                    <labels><label description="Order" languagecode="1033" /></labels>
                    <control id="pda_orderid" classid="{270BD3DB-D9AF-4782-9025-509E298DEC0A}" datafieldname="pda_orderid" disabled="false" />
                  </cell>
                </row>
                <row>
                  <cell id="{C1B2C3D4-0001-0001-0003-000000000003}">
                    <labels><label description="Product" languagecode="1033" /></labels>
                    <control id="pda_productid" classid="{270BD3DB-D9AF-4782-9025-509E298DEC0A}" datafieldname="pda_productid" disabled="false" />
                  </cell>
                  <cell id="{C1B2C3D4-0001-0001-0003-000000000004}">
                    <labels><label description="Quantity" languagecode="1033" /></labels>
                    <control id="pda_quantity" classid="{C6D124CA-7EDA-4a60-AEA9-7FB8D318B68F}" datafieldname="pda_quantity" disabled="false" />
                  </cell>
                </row>
                <row>
                  <cell id="{C1B2C3D4-0001-0001-0003-000000000005}">
                    <labels><label description="Unit Price" languagecode="1033" /></labels>
                    <control id="pda_unitprice" classid="{C6D124CA-7EDA-4a60-AEA9-7FB8D318B68F}" datafieldname="pda_unitprice" disabled="false" />
                  </cell>
                  <cell id="{C1B2C3D4-0001-0001-0003-000000000006}">
                    <labels><label description="Line Total" languagecode="1033" /></labels>
                    <control id="pda_linetotal" classid="{C6D124CA-7EDA-4a60-AEA9-7FB8D318B68F}" datafieldname="pda_linetotal" disabled="false" />
                  </cell>
                </row>
              </rows>
            </section>
          </sections>
        </column>
      </columns>
    </tab>
  </tabs>
</form>
'@

# ============================================================================
# VIEWS
# ============================================================================

# ── Active Products view ─────────────────────────────────────────────────────
Write-Host "Patching Active Products view..." -ForegroundColor Cyan
Patch-View $viewActiveProducts `
@'
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false">
  <entity name="pda_product">
    <attribute name="pda_name" />
    <attribute name="pda_category" />
    <attribute name="pda_price" />
    <attribute name="pda_available" />
    <attribute name="pda_allergens" />
    <attribute name="pda_dailystock" />
    <attribute name="pda_productid" />
    <order attribute="pda_category" descending="false" />
    <filter type="and">
      <condition attribute="statecode" operator="eq" value="0" />
    </filter>
  </entity>
</fetch>
'@ `
@'
<grid name="resultset" object="10972" jump="pda_name" select="1" preview="1" icon="1">
  <row name="result" id="pda_productid">
    <cell name="pda_name"       width="200" />
    <cell name="pda_category"   width="120" />
    <cell name="pda_price"      width="100" />
    <cell name="pda_available"  width="90"  />
    <cell name="pda_allergens"  width="200" />
    <cell name="pda_dailystock" width="100" />
  </row>
</grid>
'@

# ── Active Orders view ───────────────────────────────────────────────────────
Write-Host "Patching Active Orders view..." -ForegroundColor Cyan
Patch-View $viewActiveOrders `
@'
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false">
  <entity name="pda_order">
    <attribute name="pda_name" />
    <attribute name="pda_customerid" />
    <attribute name="pda_status" />
    <attribute name="pda_fulfilment" />
    <attribute name="pda_pickupdate" />
    <attribute name="pda_total" />
    <attribute name="pda_orderdate" />
    <attribute name="pda_orderid" />
    <order attribute="pda_orderdate" descending="true" />
    <filter type="and">
      <condition attribute="statecode" operator="eq" value="0" />
    </filter>
  </entity>
</fetch>
'@ `
@'
<grid name="resultset" object="10973" jump="pda_name" select="1" preview="1" icon="1">
  <row name="result" id="pda_orderid">
    <cell name="pda_name"       width="120" />
    <cell name="pda_customerid" width="180" />
    <cell name="pda_status"     width="140" />
    <cell name="pda_fulfilment" width="100" />
    <cell name="pda_pickupdate" width="120" />
    <cell name="pda_total"      width="100" />
    <cell name="pda_orderdate"  width="140" />
  </row>
</grid>
'@

# ── Active Order Lines view ──────────────────────────────────────────────────
Write-Host "Patching Active Order Lines view..." -ForegroundColor Cyan
Patch-View $viewActiveOrderLines `
@'
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false">
  <entity name="pda_orderline">
    <attribute name="pda_name" />
    <attribute name="pda_orderid" />
    <attribute name="pda_productid" />
    <attribute name="pda_quantity" />
    <attribute name="pda_unitprice" />
    <attribute name="pda_linetotal" />
    <attribute name="pda_orderlineid" />
    <order attribute="pda_orderid" descending="false" />
    <filter type="and">
      <condition attribute="statecode" operator="eq" value="0" />
    </filter>
  </entity>
</fetch>
'@ `
@'
<grid name="resultset" object="10974" jump="pda_name" select="1" preview="1" icon="1">
  <row name="result" id="pda_orderlineid">
    <cell name="pda_name"       width="200" />
    <cell name="pda_orderid"    width="140" />
    <cell name="pda_productid"  width="180" />
    <cell name="pda_quantity"   width="80"  />
    <cell name="pda_unitprice"  width="100" />
    <cell name="pda_linetotal"  width="100" />
  </row>
</grid>
'@

# ── Publish all three tables ─────────────────────────────────────────────────
Write-Host "`nPublishing customizations..." -ForegroundColor Cyan
foreach ($t in @("pda_product","pda_order","pda_orderline")) {
    Publish $t
    Write-Host "  Published $t" -ForegroundColor Green
}

Write-Host "`n✓ All forms and views updated." -ForegroundColor Green
